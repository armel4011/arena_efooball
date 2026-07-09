-- =============================================================================
-- ARENA — Audit 2026-07-09 F4 : soft-gate enforced doit créer une ligne disputes
-- =============================================================================
-- Bug introduit par la soft-gate (20260709120000) : quand
-- `app_config.proof_gate_enforced = true`, `finalize_match_score` passe le match
-- en `disputed` puis `return` SANS créer de ligne dans la table `disputes`.
-- Or la file d'arbitrage admin lit la TABLE `disputes` (admin_disputes_repository)
-- et `resolve_dispute` opère sur une ligne `disputes`. Résultat : le match serait
-- `disputed` mais INVISIBLE dans la file → gains gelés et bracket figé jusqu'à
-- intervention manuelle. (Le flux normal « joueurs en désaccord » crée bien une
-- ligne via disputes_party_insert côté client.)
--
-- FIX : à l'enforcement, insérer une ligne `disputes` (raison `proof_missing`,
-- status `admin_review`, escalation_level 3 = super-admin — cohérent avec le gate
-- resolve_dispute des matchs à prix). Idempotent : une seule dispute ouverte par
-- match. Le reste de la fonction est INCHANGÉ (recréé verbatim depuis prod).
-- =============================================================================
-- Depends on: 20260709120000 (soft-gate), 20260505100004 (table disputes),
--   20260605154411 (resolve_dispute), 20260625120000 (super-admin match à prix).
-- =============================================================================

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
  -- Verrou de ligne : empêche une double finalisation concurrente.
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

  -- Dernière soumission de chaque joueur (serveur autoritaire).
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

  -- Concordance stricte des deux soumissions.
  if v_s1 is distinct from (v_pb->>'score1')::int
     or v_s2 is distinct from (v_pb->>'score2')::int
     or v_via_pen is distinct from coalesce((v_pb->>'via_penalties')::boolean, false)
     or (v_via_pen and (v_pen1 is distinct from (v_pb->>'penalty1')::int
                        or v_pen2 is distinct from (v_pb->>'penalty2')::int))
  then
    raise exception 'Finalisation impossible : les scores soumis par les deux joueurs ne concordent pas'
      using errcode = '22023';
  end if;

  -- Vainqueur.
  if v_via_pen and v_pen1 is not null and v_pen2 is not null then
    v_winner := case when v_pen1 > v_pen2 then v_p1
                     when v_pen2 > v_pen1 then v_p2
                     else null end;
  else
    v_winner := case when v_s1 > v_s2 then v_p1
                     when v_s2 > v_s1 then v_p2
                     else null end;
  end if;

  -- SOFT-GATE PREUVE (P1 #5) : comp à prix + vainqueur désigné uniquement.
  if v_winner is not null and public.competition_has_prize(v_competition) then
    select exists (
      select 1 from public.streams s
      where s.match_id = p_match_id
        and s.player_id = v_winner
        and s.proof_committed_at is not null
    ) into v_has_commit;

    if not v_has_commit then
      select s.capture_status, s.capture_note
        into v_cap_status, v_cap_note
        from public.streams s
        where s.match_id = p_match_id
          and s.player_id = v_winner
          and s.capture_status is not null
        order by s.started_at desc nulls last
        limit 1;

      -- Journalise TOUJOURS le trou de preuve (indépendant de l'enforcement).
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

      -- Enforcement optionnel : route vers disputed si le flag est activé.
      select coalesce(
        (select (value #>> '{}')::boolean
           from public.app_config where key = 'proof_gate_enforced'),
        false)
        into v_enforced;

      if v_enforced then
        update public.matches
          set status = 'disputed'
          where id = p_match_id;

        -- F4 : matérialiser le litige dans la TABLE disputes (la file admin la
        -- lit) sinon le match resterait invisible/gelé. Idempotent : une seule
        -- dispute ouverte par match. escalation_level 3 = super-admin (aligné
        -- sur le gate resolve_dispute des matchs à prix).
        if not exists (
          select 1 from public.disputes d
          where d.match_id = p_match_id
            and d.status in ('open', 'bot_review', 'admin_review')
        ) then
          insert into public.disputes
            (match_id, opened_by, status, reason, escalation_level, evidence)
          values (
            p_match_id, v_uid, 'admin_review', 'proof_missing', 3,
            jsonb_build_object(
              'winner_id', v_winner,
              'capture_status', coalesce(v_cap_status, 'missing'),
              'score1', v_s1, 'score2', v_s2
            )
          );
        end if;

        return;
      end if;
    end if;
  end if;

  update public.matches
    set score1      = v_s1,
        score2      = v_s2,
        winner_id   = v_winner,
        status      = 'completed',
        finished_at = now()
    where id = p_match_id;

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
  '(toujours) et, si app_config.proof_gate_enforced, route vers disputed EN '
  'creant une ligne disputes (admin_review/proof_missing, idempotent) — F4. '
  'SECURITY DEFINER → contourne le guard de colonnes.';
