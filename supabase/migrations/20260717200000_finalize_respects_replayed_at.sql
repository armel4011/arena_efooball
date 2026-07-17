-- =============================================================================
-- ARENA — Audit 2026-07-17 : P1 « le rejeu d'un match est annulable par un joueur »
-- =============================================================================
-- `replay_match` (20260716140000) pose `matches.replayed_at`, dont le COMMENTAIRE
-- énonce le contrat :
--     « Les match_events / preuves antérieurs appartiennent à une manche
--       périmée : tout consommateur de scores soumis doit filtrer
--       created_at > replayed_at. »
-- Or `replayed_at` n'était lu NULLE PART : ni dans une fonction, ni en Dart.
-- Le contrat était écrit, jamais appliqué.
--
-- LE TROU. Après un rejeu, le match repasse `scheduled`. `finalize_match_score`
-- ne refuse que `completed|cancelled|forfeited` → `scheduled` passe ; le litige
-- ayant été résolu par `replay_match`, la garde « sous revue d'arbitrage »
-- passe aussi ; et les deux SELECT reprennent la DERNIÈRE soumission de chaque
-- joueur, sans borne temporelle — donc celles de la manche périmée, par
-- construction concordantes puisque le match avait été finalisé avec.
--
-- SCÉNARIO (gate de preuve OFF = défaut prod, cf. 20260709120000) :
--   1. A et B soumettent 3-0 → match completed, A cascade.
--   2. B ouvre un litige, non tranchable faute de preuve.
--   3. L'admin fait exactement ce pour quoi #342/#344 a été livrée :
--      `replay_match` → stats décrémentées, A dé-propagé du bracket,
--      compétition rouverte, status=scheduled, replayed_at=now().
--   4. Dans la seconde qui suit, A appelle `finalize_match_score`. Les vieilles
--      soumissions 3-0 sont relues → match RE-finalisé 3-0 pour A.
--   La décision de l'admin est annulée en un appel RPC, sans que le match soit
--   rejoué et sans B. A re-cascade et progresse vers le final_rank qui alimente
--   `generate_payouts`. La feature rejeu est inopérante face à un adversaire
--   malveillant.
--
-- FIX : `finalize_match_score` applique enfin le contrat — les soumissions
-- antérieures à `replayed_at` sont ignorées. Un match rejoué exige donc de
-- NOUVELLES soumissions des deux joueurs (sinon « les deux joueurs doivent
-- avoir soumis un score »), ce qui est précisément l'intention du rejeu.
--
-- Périmètre : `forfeit_match` a été vérifié et n'est PAS concerné — il ne lit
-- aucun `match_events`, il désigne l'adversaire vainqueur directement.
-- =============================================================================
-- Depends on: 20260711120100 (dernière définition de finalize_match_score),
--   20260716140000 (replay_match / matches.replayed_at).
-- =============================================================================

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
  v_replayed_at  timestamptz;
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
  select player1_id, player2_id, competition_id, status, replayed_at
    into v_p1, v_p2, v_competition, v_status, v_replayed_at
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

  -- Un match rejoué repart d'une page blanche : les soumissions de la manche
  -- périmée ne valent plus rien. Sans ce filtre, le rejeu décidé par l'admin
  -- était annulable par le joueur favorisé, qui re-finalisait l'ancien score.
  select payload into v_pa
    from public.match_events
    where match_id = p_match_id and type = 'score_submitted' and created_by = v_p1
      and (v_replayed_at is null or created_at > v_replayed_at)
    order by created_at desc limit 1;

  select payload into v_pb
    from public.match_events
    where match_id = p_match_id and type = 'score_submitted' and created_by = v_p2
      and (v_replayed_at is null or created_at > v_replayed_at)
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

comment on function public.finalize_match_score(uuid) is
  'Finalise un match sur accord mutuel des deux joueurs. Ignore les soumissions '
  'anterieures a matches.replayed_at : un match rejoue exige de NOUVELLES '
  'soumissions, sinon le joueur favorise re-finalisait l''ancien score et '
  'annulait le rejeu decide par l''admin (P1 du 2026-07-17).';
