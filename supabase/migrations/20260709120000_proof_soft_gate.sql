-- =============================================================================
-- ARENA — Anti-triche P1 #5 : soft-gate « preuve » de la finalisation de score
-- =============================================================================
-- Constat audit 2026-07-07 : la capture anti-triche est FACULTATIVE et la
-- soumission de score n'est gatée sur RIEN (match_recording_lifecycle.dart).
-- Permissions refusées / capture échouée → score soumis SANS AUCUNE TRACE, donc
-- indiscernable d'un simple échec réseau. Un tricheur qui désactive sa capture
-- passe inaperçu.
--
-- Parti-pris (décision produit « soft-gate + trace ») :
--   1. TRACE TOUJOURS. On matérialise l'état de capture par (match, joueur) :
--        - `committed`   : un commitment (proof_committed_at) a été engagé ;
--        - `unavailable` : le client a explicitement signalé qu'il ne pouvait
--          pas capturer (permission refusée / échec device) — cf. anticheat-commit ;
--        - (absence de ligne / des deux) = jamais rapporté.
--      À la finalisation d'un match À PRIX dont le vainqueur n'a PAS de
--      commitment, on journalise TOUJOURS un event `proof_missing` (avec le
--      capture_status connu) — les admins voient enfin le phénomène.
--
--   2. ENFORCEMENT DERRIÈRE UN FLAG (défaut OFF). Router chaque match à prix
--      sans commit vers la revue admin inonderait la file tant que la capture
--      native échoue souvent (MIUI, FGS targetSdk36 — prod = native_recorder).
--      On livre donc le MÉCANISME (route vers `disputed` = revue super-admin,
--      cf. resolve_dispute_super_admin_for_prize_matches) mais on ne l'ACTIVE
--      que via `app_config.proof_gate_enforced` = true, quand la fiabilité de
--      capture sera prouvée. Défaut false → aucun changement de flux immédiat,
--      seulement la trace.
--
-- Portée STRICTE : uniquement les compétitions à enjeu financier
-- (`competition_has_prize`), uniquement quand un vainqueur non-null est calculé
-- (un nul n'a personne à payer). Les matchs sans prix / nuls finalisent comme
-- avant.
--
-- Additif + idempotent. Réutilise `streams`, `competition_has_prize` (#269),
-- `app_config` (feature flags k/v jsonb).
-- =============================================================================
-- Depends on: 20260629120000 (streams.proof_*), 20260605100000
--   (finalize_match_score), 20260707120000 (competition_has_prize),
--   20260505100002 (app_config), 20260625120000 (resolve_dispute super-admin).
-- =============================================================================

-- ─── 1. Trace de l'état de capture par (match, joueur) ──────────────────────
-- `committed` est déjà porté par proof_committed_at ; cette colonne matérialise
-- surtout le NÉGATIF (`unavailable`) pour que l'admin distingue « le joueur ne
-- pouvait pas filmer » d'un « capture silencieusement absente ».
alter table public.streams
  add column if not exists capture_status text;

alter table public.streams
  add column if not exists capture_note text;

alter table public.streams
  drop constraint if exists streams_capture_status_check;
alter table public.streams
  add constraint streams_capture_status_check
  check (capture_status is null or capture_status in ('committed', 'unavailable'));

comment on column public.streams.capture_status is
  'État de capture rapporté par le client : committed (commitment engagé) | '
  'unavailable (le joueur ne pouvait pas capturer). null = jamais rapporté.';
comment on column public.streams.capture_note is
  'Raison libre quand capture_status = unavailable (permission_denied, '
  'start_failed, …). Métadonnée de triage admin.';

-- ─── 1b. Nouveau type d'event `proof_missing` (trou de preuve) ──────────────
-- finalize_match_score journalise ce type ; il DOIT être ajouté à la contrainte
-- CHECK de match_events.type (sinon violation à la finalisation, en prod aussi).
-- Drop+recreate idempotent, liste complète (8 types d'origine + proof_missing).
alter table public.match_events
  drop constraint if exists match_events_type_check;
alter table public.match_events
  add constraint match_events_type_check check (type in (
    'match_started',
    'goal',
    'score_submitted',
    'score_validated',
    'score_disputed',
    'forfeit',
    'admin_adjustment',
    'match_finished',
    'proof_missing'
  ));

-- ─── 2. Flag d'enforcement (défaut OFF : trace seule tant que non activé) ────
insert into public.app_config (key, value, description)
values (
  'proof_gate_enforced',
  'false'::jsonb,
  'Anti-triche P1 #5 : si true, un match À PRIX dont le vainqueur n''a pas '
  'engagé de commitment est routé vers la revue admin (disputed) au lieu de '
  'completed. Défaut false = trace seule (event proof_missing), aucun blocage.'
)
on conflict (key) do nothing;

-- ─── 3. finalize_match_score : trace + soft-gate ────────────────────────────
-- Signature INCHANGÉE. Seul le bloc « après calcul du vainqueur » est ajouté.
create or replace function public.finalize_match_score(p_match_id uuid)
returns void
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_uid          uuid := auth.uid();
  v_p1           uuid;
  v_p2           uuid;
  v_competition  uuid;
  v_status       public.match_status;
  v_pa           jsonb;   -- dernière soumission du joueur 1
  v_pb           jsonb;   -- dernière soumission du joueur 2
  v_s1           int;
  v_s2           int;
  v_via_pen      boolean;
  v_pen1         int;
  v_pen2         int;
  v_winner       uuid;
  v_has_commit   boolean;
  v_cap_status   text;
  v_cap_note     text;
  v_enforced     boolean;
begin
  -- Verrou de ligne : empêche une double finalisation concurrente (les deux
  -- clients détectent la concordance quasi simultanément).
  select player1_id, player2_id, competition_id, status
    into v_p1, v_p2, v_competition, v_status
    from public.matches
    where id = p_match_id
    for update;

  if not found then
    raise exception 'Match introuvable' using errcode = 'P0002';
  end if;

  -- Seul un joueur assis sur le match peut finaliser.
  if v_uid is null or (v_uid is distinct from v_p1 and v_uid is distinct from v_p2) then
    raise exception 'Seul un joueur du match peut finaliser le score'
      using errcode = '42501';
  end if;

  -- Anti-rejeu : pas de re-finalisation d'un match déjà clos.
  if v_status in ('completed', 'cancelled', 'forfeited') then
    raise exception 'Ce match est deja finalise (statut %)', v_status
      using errcode = '42501';
  end if;

  -- Dernière soumission de chaque joueur (le client ne fournit aucun score :
  -- le serveur est autoritaire et relit match_events).
  select payload into v_pa
    from public.match_events
    where match_id = p_match_id and type = 'score_submitted' and created_by = v_p1
    order by created_at desc limit 1;

  select payload into v_pb
    from public.match_events
    where match_id = p_match_id and type = 'score_submitted' and created_by = v_p2
    order by created_at desc limit 1;

  if v_pa is null or v_pb is null then
    raise exception 'Finalisation impossible : les deux joueurs doivent avoir soumis un score'
      using errcode = '22023';
  end if;

  v_s1      := (v_pa->>'score1')::int;
  v_s2      := (v_pa->>'score2')::int;
  v_via_pen := coalesce((v_pa->>'via_penalties')::boolean, false);
  v_pen1    := (v_pa->>'penalty1')::int;
  v_pen2    := (v_pa->>'penalty2')::int;

  -- Concordance stricte des deux soumissions (score réglementaire + tirs
  -- au but le cas échéant). En cas de désaccord → dispute (côté client).
  if v_s1 is distinct from (v_pb->>'score1')::int
     or v_s2 is distinct from (v_pb->>'score2')::int
     or v_via_pen is distinct from coalesce((v_pb->>'via_penalties')::boolean, false)
     or (v_via_pen and (v_pen1 is distinct from (v_pb->>'penalty1')::int
                        or v_pen2 is distinct from (v_pb->>'penalty2')::int))
  then
    raise exception 'Finalisation impossible : les scores soumis par les deux joueurs ne concordent pas'
      using errcode = '22023';
  end if;

  -- Vainqueur : tirs au but si égalité réglementaire jouée aux penalties,
  -- sinon différence de buts, sinon nul (winner_id null — round-robin).
  if v_via_pen and v_pen1 is not null and v_pen2 is not null then
    v_winner := case when v_pen1 > v_pen2 then v_p1
                     when v_pen2 > v_pen1 then v_p2
                     else null end;
  else
    v_winner := case when v_s1 > v_s2 then v_p1
                     when v_s2 > v_s1 then v_p2
                     else null end;
  end if;

  -- ─── SOFT-GATE PREUVE (P1 #5) ──────────────────────────────────────────
  -- Uniquement les matchs à prix avec un vainqueur désigné : un nul n'a
  -- personne à payer, un match amical n'a pas d'enjeu.
  if v_winner is not null and public.competition_has_prize(v_competition) then
    -- Le vainqueur a-t-il engagé un commitment sur CE match ?
    select exists (
      select 1 from public.streams s
      where s.match_id = p_match_id
        and s.player_id = v_winner
        and s.proof_committed_at is not null
    ) into v_has_commit;

    if not v_has_commit then
      -- Trace de capture connue pour le vainqueur (unavailable + raison), si
      -- le client l'a rapportée — sinon null (= silencieusement absente).
      select s.capture_status, s.capture_note
        into v_cap_status, v_cap_note
        from public.streams s
        where s.match_id = p_match_id
          and s.player_id = v_winner
          and s.capture_status is not null
        order by s.started_at desc nulls last
        limit 1;

      -- Journalise TOUJOURS le trou de preuve (indépendant de l'enforcement) :
      -- c'est le signal que les admins n'avaient pas jusqu'ici.
      insert into public.match_events (match_id, type, created_by, payload)
      values (
        p_match_id, 'proof_missing', v_uid,
        jsonb_build_object(
          'winner_id', v_winner,
          'capture_status', coalesce(v_cap_status, 'missing'),
          'capture_note', v_cap_note,
          'score1', v_s1, 'score2', v_s2
        )
      );

      -- Enforcement optionnel : route vers la revue (super-)admin au lieu de
      -- completed. `disputed` réutilise le flux resolve_dispute existant (les
      -- matchs à prix y exigent déjà un super-admin, cf. migration 20260625).
      select coalesce(
        (select (value #>> '{}')::boolean
           from public.app_config where key = 'proof_gate_enforced'),
        false)
        into v_enforced;

      if v_enforced then
        update public.matches
          set status = 'disputed'
          where id = p_match_id;
        return;   -- NE PAS compléter : l'admin tranchera + libèrera le bracket.
      end if;
    end if;
  end if;
  -- ───────────────────────────────────────────────────────────────────────

  update public.matches
    set score1      = v_s1,
        score2      = v_s2,
        winner_id   = v_winner,
        status      = 'completed',
        finished_at = now()
    where id = p_match_id;

  -- Trace d'arbitrage : score validé par accord mutuel.
  insert into public.match_events (match_id, type, created_by, payload)
  values (
    p_match_id, 'score_validated', v_uid,
    jsonb_build_object('score1', v_s1, 'score2', v_s2,
                       'winner_id', v_winner, 'via', 'mutual_agreement')
  );
end;
$$;

comment on function public.finalize_match_score(uuid) is
  '#1 : seule voie joueur vers status=completed. Relit les deux score_submitted, '
  'exige leur concordance cote serveur, calcule le vainqueur et ecrit le resultat. '
  'P1 #5 : sur comp a prix + vainqueur sans commitment, journalise proof_missing '
  '(toujours) et route vers disputed si app_config.proof_gate_enforced. '
  'SECURITY DEFINER → contourne le guard de colonnes.';
