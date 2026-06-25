-- =============================================================================
-- ARENA — generate_payouts : exiger une cagnotte déclarée si des prix existent
-- =============================================================================
-- Dernier point résiduel de l'audit (BASSE). Le cap d'intégrité P1.1 (migration
-- 20260624140000) ne s'active que si `prize_pool_local > 0`. Quand le pool vaut
-- 0 (défaut) mais que `prize_distribution` contient des prix, le cap était sauté
-- → versements non bornés (seule l'alerte de subvention le traçait).
--
-- Capper contre `sum(prize_distribution)` serait tautologique (v_paid_total y est
-- toujours inférieur ou égal par construction). La vraie protection est d'exiger
-- une cagnotte DÉCLARÉE dès qu'il y a des prix : on refuse de générer les
-- versements si `prize_distribution` a des montants > 0 mais `prize_pool_local
-- <= 0`. Le wizard pose toujours prize_pool_local = somme des prix, donc aucune
-- compétition légitime n'est bloquée ; les tournois gratuits (distribution à 0)
-- ne sont pas concernés. Le cap P1.1 devient ainsi infaillible.
-- =============================================================================

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
  v_dist_total numeric := 0;   -- somme des prix déclarés dans prize_distribution
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

  -- Cohérence budget : des prix sont prévus mais aucune cagnotte n'est déclarée
  -- (prize_pool_local <= 0) → état incohérent. On refuse plutôt que de verser
  -- sans plafond (rend le cap P1.1 infaillible).
  select coalesce(sum(
           case when coalesce(nullif(val, '')::numeric, 0) > 0
                then nullif(val, '')::numeric else 0 end), 0)
    into v_dist_total
    from jsonb_array_elements_text(v_dist) as e(val);
  if v_dist_total > 0 and coalesce(v_pool, 0) <= 0 then
    raise exception 'Cagnotte non declaree (prize_pool_local = 0) alors que des prix sont prevus. Renseigne la cagnotte de la competition avant de generer les versements.'
      using errcode = '23514';
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
        -- déclaré (prize_pool_local, désormais garanti > 0 si des prix existent).
        if v_pool is not null and v_pool > 0 and v_paid_total > v_pool then
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
  'alerte audit non-bloquante si versements > frais encaisses (subvention). '
  'Durcissement 2026-06-25 : refuse si des prix existent sans cagnotte declaree.';
