-- =============================================================================
-- ARENA — Litige « désaccord de score » : matérialisation + auto-résolution
-- =============================================================================
-- Deux bugs corrélés :
--
--  (#2) Le ré-audit 2026-07-09 a ajouté 'disputed' à la garde anti-rejeu de
--       finalize_match_score / forfeit_match → quand un joueur corrige son score
--       et que les deux concordent, la RPC REFUSE de valider (42501) au lieu de
--       finaliser → le litige ne se referme jamais.
--
--  (#4) `flagDisputed` côté client ne posait QUE matches.status='disputed', sans
--       créer de ligne dans `disputes` → la file d'arbitrage admin (qui lit la
--       table disputes) était vide → l'admin ne pouvait pas trancher.
--
-- Conception réconciliée :
--   * flag_score_dispute (RPC, ci-dessous) : pose 'disputed' + crée UNE ligne
--     disputes ('open', escalation 0) idempotente → visible et arbitrable côté
--     admin (resolve_dispute).
--   * finalize/forfeit : ne bloquent 'disputed' QUE s'il existe un litige FORMEL
--     (revue de preuve F4 / arbitrage : status bot_review|admin_review). Le
--     simple désaccord de score ('open') reste re-finalisable ; à la validation
--     on referme la ligne disputes ('resolved'). Le litige de preuve F4 reste
--     réservé au super-admin.
-- =============================================================================

-- ── RPC : ouvre un litige de désaccord de score (atomique + idempotent) ──────
create or replace function public.flag_score_dispute(p_match_id uuid)
returns void
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_uid    uuid := auth.uid();
  v_p1     uuid;
  v_p2     uuid;
  v_status public.match_status;
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
    raise exception 'Seul un joueur du match peut ouvrir un litige'
      using errcode = '42501';
  end if;

  if v_status in ('completed', 'cancelled', 'forfeited') then
    raise exception 'Match deja finalise (statut %)', v_status
      using errcode = '42501';
  end if;

  update public.matches
     set status = 'disputed'
   where id = p_match_id
     and status is distinct from 'disputed';

  -- Idempotent : une seule ligne litige ouverte par match.
  if not exists (
    select 1 from public.disputes d
    where d.match_id = p_match_id
      and d.status in ('open', 'bot_review', 'admin_review')
  ) then
    insert into public.disputes
      (match_id, opened_by, status, reason, escalation_level)
    values
      (p_match_id, v_uid, 'open', 'Désaccord sur le score', 0);
  end if;
end;
$$;

comment on function public.flag_score_dispute(uuid) is
  'Ouvre un litige « désaccord de score » : pose matches.status=disputed et crée '
  'une ligne disputes (open) idempotente, arbitrable par l''admin (resolve_dispute).';

revoke execute on function public.flag_score_dispute(uuid) from anon, public;
grant execute on function public.flag_score_dispute(uuid) to authenticated;

-- ── finalize_match_score : garde assouplie + auto-fermeture du litige ────────
create or replace function public.finalize_match_score(p_match_id uuid)
returns void
language plpgsql
security definer
set search_path to 'public', 'pg_temp'
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

  if v_status in ('completed', 'cancelled', 'forfeited') then
    raise exception 'Ce match est deja finalise (statut %)', v_status
      using errcode = '42501';
  end if;

  -- 'disputed' bloqué UNIQUEMENT sous revue formelle (preuve F4 / arbitrage).
  -- Le simple désaccord de score ('open') reste re-finalisable → fermeture auto.
  if v_status = 'disputed' and exists (
    select 1 from public.disputes d
    where d.match_id = p_match_id
      and d.status in ('bot_review', 'admin_review')
  ) then
    raise exception 'Match sous revue d''arbitrage — resolution reservee au super-admin (resolve_dispute)'
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
        update public.matches set status = 'disputed' where id = p_match_id;

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

  -- Referme un litige « désaccord de score » (ligne 'open') : scores concordants.
  update public.disputes
     set status = 'resolved', resolved_at = now(),
         resolution = 'auto_scores_concordants'
   where match_id = p_match_id
     and status = 'open';

  insert into public.match_events (match_id, type, created_by, payload)
  values (
    p_match_id, 'score_validated', v_uid,
    jsonb_build_object('score1', v_s1, 'score2', v_s2,
                       'winner_id', v_winner, 'via', 'mutual_agreement')
  );
end;
$$;

-- ── forfeit_match : même garde assouplie + fermeture du litige ───────────────
create or replace function public.forfeit_match(p_match_id uuid, p_reason text default null)
returns void
language plpgsql
security definer
set search_path to 'public', 'pg_temp'
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

  if v_status in ('completed', 'cancelled', 'forfeited') then
    raise exception 'Ce match est deja finalise (statut %)', v_status
      using errcode = '42501';
  end if;

  if v_status = 'disputed' and exists (
    select 1 from public.disputes d
    where d.match_id = p_match_id
      and d.status in ('bot_review', 'admin_review')
  ) then
    raise exception 'Match sous revue d''arbitrage — resolution reservee au super-admin (resolve_dispute)'
      using errcode = '42501';
  end if;

  v_opponent := case when v_uid = v_p1 then v_p2 else v_p1 end;

  update public.matches
    set status      = 'forfeited',
        winner_id   = v_opponent,
        finished_at = now()
    where id = p_match_id;

  -- Le forfait résout aussi un éventuel litige « désaccord de score » ouvert.
  update public.disputes
     set status = 'resolved', resolved_at = now(),
         resolution = 'auto_forfeit'
   where match_id = p_match_id
     and status = 'open';

  insert into public.match_events (match_id, type, created_by, payload)
  values (
    p_match_id, 'forfeit', v_uid,
    jsonb_build_object('opponent_id', v_opponent)
      || case when p_reason is not null then jsonb_build_object('reason', p_reason)
              else '{}'::jsonb end
  );
end;
$$;
