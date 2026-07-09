-- =============================================================================
-- ARENA — Ré-audit 2026-07-09 : résiduel (même fil rouge — voies RLS directes)
-- =============================================================================
-- Le ré-audit post-fixes a confirmé que plusieurs durcissements posés au niveau
-- RPC gardaient une voie d'ÉCRITURE RLS DIRECTE ouverte à l'admin simple.
--
-- P1  competition_payment_options : la RPC set_competition_payment_options a été
--     cloisonnée pays (P2b), mais la TABLE reste écrivable en direct par tout
--     is_admin() → un admin réécrit transfer_code (code de collecte affiché au
--     joueur) d'une compétition HORS PAYS → détournement des frais. FIX : revoke
--     des writes directs client → la RPC (déjà cloisonnée) devient l'unique voie.
-- P1  matches (1re désignation) : le guard bloquait l'inversion + le ré-arbitrage
--     terminal d'un match à prix, PAS la 1re saisie → un admin simple pouvait
--     poser winner_id/status='completed' sur un match à prix non décidé (truquage
--     bracket). DÉCISION produit : FERMER — toute écriture de résultat d'un match
--     À PRIX par un non-super-admin passe par le super-admin (resolve_dispute).
-- P2  app_release_config : policy is_admin() alors que l'UI est super-admin →
--     un admin simple pousse un APK malveillant (MAJ in-app). FIX : is_super_admin().
-- P2  anti-rejeu 'disputed' : finalize_match_score/forfeit_match n'incluaient pas
--     'disputed' → un joueur pouvait forfaiter/finaliser un match sous revue de
--     preuve (F4), court-circuitant l'arbitrage super-admin. FIX : ajouter 'disputed'.
-- P3  guard streams : exemptait TOUT is_admin() → un admin simple pouvait poser
--     proof_hash_verified=true (blanchir une preuve). Ces colonnes ne sont écrites
--     QUE par les EF service-role → figer pour tout client (admins inclus).
-- P3  registration_fee non couvert par le guard financier competitions.
-- P3  unicité (competition_id, rank) sur payouts (fiabilité classement).
--
-- (payouts_admin_update = déjà is_super_admin() en prod → rien à faire.
--  index write-once natif = 4 doublons existants → reporté, requiert dédup.)
-- =============================================================================

-- ─── P1 : competition_payment_options — RPC comme unique voie d'écriture ─────
revoke insert, update, delete on public.competition_payment_options
  from authenticated, anon;
-- (SELECT conservé : le client lit les options ; les écritures passent par la
--  RPC DEFINER set_competition_payment_options, cloisonnée admin_can_country.)

-- ─── P1 : guard matches — fermer la 1re saisie d'un résultat à prix ─────────
create or replace function public.guard_matches_protected_columns()
returns trigger
language plpgsql
security invoker
set search_path = public, pg_temp
as $$
begin
  -- (1) Bloc joueur (non-admin) — inchangé.
  if current_user in ('authenticated', 'anon') and not public.is_admin() then
    if new.score1 is distinct from old.score1
       or new.score2 is distinct from old.score2
       or new.winner_id is distinct from old.winner_id
    then
      raise exception 'Modification interdite : le score et le vainqueur d''un match ne peuvent etre poses que via la finalisation serveur (accord des deux joueurs)'
        using errcode = '42501';
    end if;
    if new.status is distinct from old.status
       and new.status in ('completed', 'forfeited')
    then
      raise exception 'Modification interdite : passer un match en "%" exige la finalisation serveur', new.status
        using errcode = '42501';
    end if;
    if new.player1_id is distinct from old.player1_id
       or new.player2_id is distinct from old.player2_id
       or new.next_match_id is distinct from old.next_match_id
       or new.competition_id is distinct from old.competition_id
       or new.phase_id is distinct from old.phase_id
       or new.group_id is distinct from old.group_id
       or new.round is distinct from old.round
       or new.match_number is distinct from old.match_number
    then
      raise exception 'Modification interdite : l''appariement et la position d''un match dans le bracket sont geres par l''organisateur, pas par les joueurs'
        using errcode = '42501';
    end if;
  end if;

  -- (2) Bloc admin SIMPLE — sur un match À PRIX, TOUTE écriture de résultat
  -- (winner_id / score / transition terminale) est réservée au super-admin
  -- (via resolve_dispute). Ferme la 1re désignation (ré-audit 2026-07-09) EN PLUS
  -- de l'inversion et du ré-arbitrage. Les DEFINER (finalize/resolve) et le
  -- service_role restent exemptés (current_user = owner).
  if current_user in ('authenticated', 'anon')
     and public.is_admin()
     and not public.is_super_admin()
     and public.competition_has_prize(new.competition_id)
     and (new.winner_id is distinct from old.winner_id
          or new.score1 is distinct from old.score1
          or new.score2 is distinct from old.score2
          or (new.status is distinct from old.status
              and new.status in ('completed', 'forfeited')))
  then
    raise exception 'Modification interdite : poser ou modifier le resultat d''un match a cagnotte est reserve au super-admin (via resolve_dispute)'
      using errcode = '42501';
  end if;

  return new;
end;
$$;

-- ─── P2 : app_release_config écriture réservée au super-admin ────────────────
drop policy if exists app_release_config_write_admin on public.app_release_config;
create policy app_release_config_write_admin on public.app_release_config
  for all
  using ((select public.is_super_admin()))
  with check ((select public.is_super_admin()));

-- ─── P3 : guard streams — figer les colonnes de preuve pour TOUT client ─────
-- (les proof_*/capture_* ne sont écrites que par les EF service-role ; un admin
--  n'a aucun flux légitime pour les poser en direct. is_public/is_active restent
--  libres pour les admins via streams_update_admin.)
create or replace function public.guard_streams_protected_columns()
returns trigger
language plpgsql
security invoker
set search_path = public, pg_temp
as $$
begin
  if current_user in ('authenticated', 'anon') then
    if new.proof_sha256 is distinct from old.proof_sha256
       or new.proof_bytes is distinct from old.proof_bytes
       or new.proof_duration_seconds is distinct from old.proof_duration_seconds
       or new.proof_committed_at is distinct from old.proof_committed_at
       or new.proof_claimed_at is distinct from old.proof_claimed_at
       or new.proof_uploaded_at is distinct from old.proof_uploaded_at
       or new.proof_hash_verified is distinct from old.proof_hash_verified
       or new.capture_status is distinct from old.capture_status
       or new.capture_note is distinct from old.capture_note
       or new.storage_path is distinct from old.storage_path
       or new.url is distinct from old.url
       or new.egress_id is distinct from old.egress_id
       or new.provider is distinct from old.provider
       or new.match_id is distinct from old.match_id
       or new.player_id is distinct from old.player_id
       or new.started_at is distinct from old.started_at
       or new.ended_at is distinct from old.ended_at
    then
      raise exception 'Modification interdite : colonnes de preuve/capture d''un enregistrement reservees au service anti-triche'
        using errcode = '42501';
    end if;
  end if;
  return new;
end;
$$;

-- ─── P3 : registration_fee dans le guard financier competitions ─────────────
create or replace function public.guard_competitions_financial_columns()
returns trigger
language plpgsql
security invoker
set search_path = public, pg_temp
as $$
begin
  if current_user in ('authenticated', 'anon') and not public.is_super_admin() then
    if new.prize_pool_local is distinct from old.prize_pool_local
       or new.commission_xaf is distinct from old.commission_xaf
       or new.commission_pct is distinct from old.commission_pct
       or new.prize_distribution is distinct from old.prize_distribution
       or new.authorized_subsidy_local is distinct from old.authorized_subsidy_local
       or new.registration_fee is distinct from old.registration_fee
    then
      raise exception 'Modification interdite : les montants d''une compétition (frais, cagnotte, commission, répartition, subvention) sont réservés au super-admin'
        using errcode = '42501';
    end if;
  end if;
  return new;
end;
$$;

-- ─── P3 : unicité (competition_id, rank) sur payouts ────────────────────────
create unique index if not exists uniq_payouts_competition_rank
  on public.payouts (competition_id, rank)
  where rank is not null;

-- ─── P2 : anti-rejeu 'disputed' — finalize_match_score ──────────────────────
-- (corps F4 verbatim ; seule la liste anti-rejeu gagne 'disputed'.)
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
  v_pa           jsonb;
  v_pb           jsonb;
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
  select player1_id, player2_id, competition_id, status
    into v_p1, v_p2, v_competition, v_status
    from public.matches
    where id = p_match_id
    for update;

  if not found then
    raise exception 'Match introuvable' using errcode = 'P0002';
  end if;

  if v_uid is null or (v_uid is distinct from v_p1 and v_uid is distinct from v_p2) then
    raise exception 'Seul un joueur du match peut finaliser le score'
      using errcode = '42501';
  end if;

  -- Anti-rejeu : match déjà clos OU sous litige (disputed = revue admin, réservée
  -- à resolve_dispute — ré-audit 2026-07-09).
  if v_status in ('completed', 'cancelled', 'forfeited', 'disputed') then
    raise exception 'Ce match est deja finalise ou sous litige (statut %)', v_status
      using errcode = '42501';
  end if;

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

  if v_s1 is distinct from (v_pb->>'score1')::int
     or v_s2 is distinct from (v_pb->>'score2')::int
     or v_via_pen is distinct from coalesce((v_pb->>'via_penalties')::boolean, false)
     or (v_via_pen and (v_pen1 is distinct from (v_pb->>'penalty1')::int
                        or v_pen2 is distinct from (v_pb->>'penalty2')::int))
  then
    raise exception 'Finalisation impossible : les scores soumis par les deux joueurs ne concordent pas'
      using errcode = '22023';
  end if;

  if v_via_pen and v_pen1 is not null and v_pen2 is not null then
    v_winner := case when v_pen1 > v_pen2 then v_p1
                     when v_pen2 > v_pen1 then v_p2
                     else null end;
  else
    v_winner := case when v_s1 > v_s2 then v_p1
                     when v_s2 > v_s1 then v_p2
                     else null end;
  end if;

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

      select coalesce(
        (select (value #>> '{}')::boolean
           from public.app_config where key = 'proof_gate_enforced'),
        false)
        into v_enforced;

      if v_enforced then
        update public.matches
          set status = 'disputed'
          where id = p_match_id;

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

-- ─── P2 : anti-rejeu 'disputed' — forfeit_match ─────────────────────────────
create or replace function public.forfeit_match(p_match_id uuid, p_reason text default null)
returns void
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_uid      uuid := auth.uid();
  v_p1       uuid;
  v_p2       uuid;
  v_status   public.match_status;
  v_opponent uuid;
begin
  select player1_id, player2_id, status
    into v_p1, v_p2, v_status
    from public.matches
    where id = p_match_id
    for update;

  if not found then
    raise exception 'Match introuvable' using errcode = 'P0002';
  end if;

  if v_uid is null or (v_uid is distinct from v_p1 and v_uid is distinct from v_p2) then
    raise exception 'Seul un joueur du match peut declarer forfait'
      using errcode = '42501';
  end if;

  -- Anti-rejeu : match clos OU sous litige (disputed = arbitrage super-admin).
  if v_status in ('completed', 'cancelled', 'forfeited', 'disputed') then
    raise exception 'Ce match est deja finalise ou sous litige (statut %)', v_status
      using errcode = '42501';
  end if;

  v_opponent := case when v_uid = v_p1 then v_p2 else v_p1 end;

  update public.matches
    set status      = 'forfeited',
        winner_id   = v_opponent,
        finished_at = now()
    where id = p_match_id;

  insert into public.match_events (match_id, type, created_by, payload)
  values (
    p_match_id, 'forfeit', v_uid,
    jsonb_build_object('opponent_id', v_opponent)
      || case when p_reason is not null then jsonb_build_object('reason', p_reason)
              else '{}'::jsonb end
  );
end;
$$;
