-- =============================================================================
-- ARENA — Durcissement argent (audit complet 2026-06-24)
-- =============================================================================
-- P0 (CRITIQUE) — resolve_dispute acceptait n'importe quel `p_winner_id` :
--   la RPC écrivait `winner_id = p_winner_id` SANS vérifier que ce joueur est
--   bien l'un des deux participants du match, ni que les scores sont >= 0.
--   Gate = is_admin() (admin simple). Un admin pouvait donc désigner un
--   complice (même non-inscrit) vainqueur d'une finale → cascade_match_winner →
--   final_rank 1 → generate_payouts lui versait la cagnotte. Détournement de
--   gains au prix d'un simple compte admin.
--   Correctif : charger player1_id/player2_id du match (FOR UPDATE) et rejeter
--   tout winner hors {player1, player2} ; exiger des scores >= 0.
--
-- P1 (ÉLEVÉ) — generate_payouts ne bornait rien : la somme des
--   `prize_distribution` (montants absolus saisis librement par l'admin)
--   n'était comparée à aucune référence. Une `prize_distribution` incohérente
--   (édition directe hors wizard, supérieure au budget déclaré) versait des
--   payouts > budget prévu, sans garde.
--   NB : dans ARENA la cagnotte est DÉCIDÉE par l'admin (tournois promo /
--   sponsorisés où la plateforme abonde) → elle PEUT légitimement dépasser les
--   frais encaissés. Pas de plafond dur sur les frais. Deux gardes à la place :
--     1. Cap dur d'intégrité : SUM(payouts) <= prize_pool_local DÉCLARÉ
--        (le wizard pose prize_pool_local = somme des prix → backstop contre une
--        distribution corrompue/désynchronisée du budget).
--     2. Alerte non-bloquante : si SUM(payouts) > frais encaissés (subvention
--        plateforme), trace une entrée admin_audit_log pour que la subvention
--        soit un acte conscient et tracé, pas un typo silencieux.
-- =============================================================================

-- ─── P0. resolve_dispute : valide le vainqueur et les scores ──────────────────
create or replace function public.resolve_dispute(
  p_match_id      uuid,
  p_dispute_id    uuid,
  p_justification text,
  p_cancel        boolean default false,
  p_winner_id     uuid    default null,
  p_score1        integer default null,
  p_score2        integer default null
)
returns void
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_admin uuid := auth.uid();
  v_p1    uuid;
  v_p2    uuid;
begin
  if not public.is_admin() then
    raise exception 'Reserve aux administrateurs' using errcode = '42501';
  end if;
  if coalesce(trim(p_justification), '') = '' then
    raise exception 'Justification obligatoire' using errcode = '22023';
  end if;

  -- Charge + verrouille le match : sert d'existence ET de source de vérité pour
  -- valider le vainqueur (anti-détournement de gains).
  select player1_id, player2_id into v_p1, v_p2
    from public.matches
    where id = p_match_id
    for update;
  if not found then
    raise exception 'Match introuvable' using errcode = 'P0002';
  end if;

  -- 1. Verdict (score/winner/completed) OU annulation du match.
  if p_cancel then
    update public.matches
       set status = 'cancelled', finished_at = now()
     where id = p_match_id;
  else
    -- P0 : le vainqueur DOIT être l'un des deux participants du match.
    if p_winner_id is not null and p_winner_id <> v_p1 and p_winner_id <> v_p2 then
      raise exception 'Le vainqueur doit etre un des deux joueurs du match'
        using errcode = '22023';
    end if;
    -- P0 : pas de scores négatifs.
    if coalesce(p_score1, 0) < 0 or coalesce(p_score2, 0) < 0 then
      raise exception 'Les scores ne peuvent pas etre negatifs' using errcode = '22023';
    end if;

    update public.matches
       set score1 = p_score1, score2 = p_score2, winner_id = p_winner_id,
           status = 'completed', finished_at = now()
     where id = p_match_id;
  end if;

  -- 2. Résout le litige (s'il existe) — même transaction.
  if p_dispute_id is not null then
    update public.disputes
       set status      = case when p_cancel then 'cancelled' else 'resolved' end,
           resolved_at = now(),
           resolved_by = v_admin,
           resolution  = p_justification
     where id = p_dispute_id;
  end if;

  -- 3. Trace d'audit — même transaction.
  insert into public.admin_audit_log
    (admin_id, action, target_type, target_id, after_state)
  values (
    v_admin,
    case when p_cancel then 'dispute_cancelled' else 'dispute_resolved' end,
    'match', p_match_id,
    case when p_cancel
      then jsonb_build_object('justification', p_justification)
      else jsonb_build_object('winner_id', p_winner_id, 'score1', p_score1,
                              'score2', p_score2, 'justification', p_justification)
    end
  );
end;
$$;

comment on function public.resolve_dispute(uuid, uuid, text, boolean, uuid, integer, integer) is
  'Robustesse : résout un litige de façon ATOMIQUE (verdict/annulation match + '
  'resolve dispute + audit) dans une seule transaction. Gate is_admin(). '
  'P0 audit 2026-06-24 : valide que winner_id ∈ {player1, player2} et scores >= 0.';

-- ACL inchangée (rejoue revoke/grant pour idempotence de la migration).
revoke execute on function public.resolve_dispute(uuid, uuid, text, boolean, uuid, integer, integer)
  from anon, public;
grant execute on function public.resolve_dispute(uuid, uuid, text, boolean, uuid, integer, integer)
  to authenticated;

-- ─── P1. generate_payouts : cap budget déclaré + alerte subvention ────────────
create or replace function public.generate_payouts(p_competition_id uuid)
returns integer
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_status     public.competition_status;
  v_pool       numeric;
  v_dist       jsonb;
  v_currency   text;
  v_name       text;
  v_n          integer;
  i            integer;
  v_amount     numeric;
  v_user       uuid;
  v_count      integer := 0;
  v_had_prize  boolean := false;
  v_collected  numeric := 0;   -- frais d'inscription réellement encaissés
  v_paid_total numeric := 0;   -- somme des payouts générés
begin
  if not public.is_super_admin() then
    raise exception 'Reserve au super-admin' using errcode = '42501';
  end if;

  select status, prize_pool_local, prize_distribution, registration_currency, name
    into v_status, v_pool, v_dist, v_currency, v_name
    from public.competitions
    where id = p_competition_id;
  if not found then
    raise exception 'Competition introuvable' using errcode = 'P0002';
  end if;
  if v_status <> 'completed' then
    raise exception 'Les versements ne se generent qu''une fois la competition terminee'
      using errcode = '42501';
  end if;

  -- Idempotence : ne pas regenerer si des payouts existent deja.
  if exists (select 1 from public.payouts where competition_id = p_competition_id) then
    return 0;
  end if;
  if v_dist is null or jsonb_typeof(v_dist) <> 'array' then
    return 0;
  end if;

  -- P1 : recettes encaissées (status terminal 'succeeded' ; refunds/échecs exclus).
  select coalesce(sum(amount_local), 0) into v_collected
    from public.payments
    where competition_id = p_competition_id and status = 'succeeded';

  v_n := jsonb_array_length(v_dist);
  i := 1;
  while i <= v_n loop
    v_amount := coalesce((v_dist->>(i - 1))::numeric, 0);
    if v_amount > 0 then
      v_had_prize := true;
      select player_id into v_user
        from public.competition_registrations
        where competition_id = p_competition_id and final_rank = i
        limit 1;
      if v_user is not null then
        v_paid_total := v_paid_total + v_amount;
        -- P1.1 : cap dur d'intégrité — ne jamais verser plus que le budget
        -- déclaré (prize_pool_local). Backstop contre une prize_distribution
        -- désynchronisée du pool (ex. édition directe hors wizard).
        if v_pool is not null and v_paid_total > v_pool then
          raise exception 'Versements (%) superieurs a la cagnotte declaree (% %). Verifie la repartition des gains.',
            v_paid_total, v_pool, v_currency
            using errcode = '23514';
        end if;

        insert into public.payouts
          (user_id, competition_id, amount_local, currency, status, rank, payout_provider)
        values
          (v_user, p_competition_id, v_amount, v_currency,
           'pending_admin_validation', i, 'mobile_money_manual');

        insert into public.notifications (user_id, type, title, body, data)
        values (v_user, 'payout_available', 'Tu as gagne !',
          'Felicitations ! Tu as remporte ' || v_amount::text || ' ' || v_currency
            || ' a « ' || v_name || ' ». Reclame tes gains dans l''app pour '
            || 'recevoir ton versement Mobile Money.',
          jsonb_build_object('competition_id', p_competition_id, 'rank', i,
                             'amount_local', v_amount, 'route', '/payments/history'));
        v_count := v_count + 1;
      end if;
    end if;
    i := i + 1;
  end loop;

  -- Garde anti-echec-silencieux : des prix sont prevus mais aucun joueur classe.
  if v_count = 0 and v_had_prize then
    raise exception 'Aucun joueur classe pour les rangs recompenses. Publie d''abord le classement final, puis genere les versements.'
      using errcode = 'P0002';
  end if;

  -- P1.2 : alerte non-bloquante — la plateforme subventionne (payouts > recettes
  -- confirmees). Legitime (tournoi promo) mais doit etre trace et conscient.
  if v_paid_total > v_collected then
    insert into public.admin_audit_log
      (admin_id, action, target_type, target_id, after_state)
    values (
      auth.uid(), 'payout_pool_subsidy', 'competition', p_competition_id,
      jsonb_build_object('paid_total', v_paid_total, 'collected_fees', v_collected,
                         'currency', v_currency, 'payouts_count', v_count));
  end if;

  return v_count;
end;
$$;

comment on function public.generate_payouts(uuid) is
  'F-1 : genere les payouts (gains) d''une competition completed depuis '
  'prize_distribution + final_rank. Notifie (route GAINS). Idempotent. '
  'Erreur explicite si prix prevus mais classement non publie. Gate super-admin. '
  'P1 audit 2026-06-24 : cap dur SUM(payouts) <= prize_pool_local declare ; '
  'alerte audit non-bloquante si versements > frais encaisses (subvention plateforme).';
