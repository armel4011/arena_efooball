-- =============================================================================
-- ARENA — Audit 2026-07-09 F2 : subvention plateforme bornée (payouts ≤ recettes
--         + subvention explicitement autorisée)
-- =============================================================================
-- Constat : generate_payouts capait au prize_pool_local DÉCLARÉ mais ne
-- réconciliait PAS avec les frais ENCAISSÉS — un pool déclaré > recettes faisait
-- verser la plateforme de sa poche, avec pour seul garde-fou une alerte audit
-- non-bloquante (payout_pool_subsidy). Rien ne distinguait une subvention voulue
-- (tournoi promo) d'un détournement.
--
-- Décision produit (« champ subvention explicite ») :
--   * Nouvelle colonne competitions.authorized_subsidy_local (défaut 0). C'est le
--     montant que la plateforme accepte EXPLICITEMENT de subventionner au-delà
--     des frais encaissés. Réservée au super-admin (guard financier F3 + pas de
--     grant UPDATE client ; posée via la RPC set_competition_subsidy).
--   * generate_payouts BLOQUE désormais si
--       total_versé > frais_encaissés + subvention_autorisée
--     (au lieu de la simple alerte). La trace audit reste quand une subvention
--     autorisée est effectivement consommée.
--
-- ⚠️ competitions a des GRANTS COLONNE (piège C-1) → la nouvelle colonne exige un
-- `grant select` explicite, sinon les lectures `select *` cassent (42501). PAS de
-- grant UPDATE (la colonne se pose uniquement via la RPC DEFINER super-admin).
-- =============================================================================
-- Depends on: 20260706100400 (generate_payouts, admin_can_*), 20260709170000
--   (guard_competitions_financial_columns F3), 20260505100005 (is_super_admin).
-- =============================================================================

-- ─── 1. Colonne + grant SELECT (lecture, jamais UPDATE côté client) ─────────
alter table public.competitions
  add column if not exists authorized_subsidy_local numeric not null default 0
    check (authorized_subsidy_local >= 0);

grant select (authorized_subsidy_local) on public.competitions to authenticated, anon;

comment on column public.competitions.authorized_subsidy_local is
  'Audit 2026-07-09 F2 : montant que la plateforme accepte de subventionner '
  'au-delà des frais encaissés (tournoi promo). Défaut 0. Super-admin only '
  '(guard financier + RPC set_competition_subsidy). generate_payouts refuse '
  'toute subvention au-delà de ce plafond.';

-- ─── 2. Guard financier F3 : figer aussi authorized_subsidy_local ───────────
create or replace function public.guard_competitions_financial_columns()
returns trigger
language plpgsql
security invoker
set search_path = public, pg_temp
as $$
begin
  if current_user in ('authenticated', 'anon') and not public.is_super_admin() then
    if new.prize_pool_local        is distinct from old.prize_pool_local
       or new.commission_xaf           is distinct from old.commission_xaf
       or new.commission_pct           is distinct from old.commission_pct
       or new.prize_distribution       is distinct from old.prize_distribution
       or new.authorized_subsidy_local is distinct from old.authorized_subsidy_local
    then
      raise exception 'Modification interdite : les montants d''une compétition (cagnotte, commission, répartition, subvention) sont réservés au super-admin'
        using errcode = '42501';
    end if;
  end if;
  return new;
end;
$$;

-- ─── 3. RPC super-admin pour poser la subvention ────────────────────────────
create or replace function public.set_competition_subsidy(
  p_competition_id uuid,
  p_amount numeric
)
returns void
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
  if not public.is_super_admin() then
    raise exception 'Reserve au super-admin' using errcode = '42501';
  end if;
  if p_amount is null or p_amount < 0 then
    raise exception 'Subvention invalide (doit etre >= 0)' using errcode = '23514';
  end if;
  update public.competitions
     set authorized_subsidy_local = p_amount
   where id = p_competition_id;
  if not found then
    raise exception 'Competition introuvable' using errcode = 'P0002';
  end if;
end;
$$;

revoke execute on function public.set_competition_subsidy(uuid, numeric) from anon, public;
grant execute on function public.set_competition_subsidy(uuid, numeric) to authenticated;

comment on function public.set_competition_subsidy(uuid, numeric) is
  'Audit 2026-07-09 F2 : pose competitions.authorized_subsidy_local (super-admin '
  'only). Autorise explicitement une subvention plateforme au-delà des frais '
  'encaissés pour un tournoi promo. DEFINER → contourne les grants colonne.';

-- ─── 4. generate_payouts : cap dur sur recettes + subvention autorisée ──────
-- Corps repris verbatim de 20260706100400 ; seuls le SELECT (ajout de
-- authorized_subsidy_local) et le bloc final « P1.2 alerte » (→ refus F2) changent.
create or replace function public.generate_payouts(p_competition_id uuid)
returns integer
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_status              public.competition_status;
  v_pool                numeric;
  v_dist                jsonb;
  v_currency            text;
  v_name                text;
  v_country             text;
  v_n                   integer;
  i                     integer;
  v_amount              numeric;
  v_user                uuid;
  v_count               integer := 0;
  v_had_prize           boolean := false;
  v_collected           numeric := 0;
  v_paid_total          numeric := 0;
  v_dist_total          numeric := 0;
  v_authorized_subsidy  numeric := 0;
begin
  if not public.is_super_admin() then
    raise exception 'Reserve au super-admin' using errcode = '42501';
  end if;

  select status, prize_pool_local, prize_distribution, registration_currency,
         name, country_code, authorized_subsidy_local
    into v_status, v_pool, v_dist, v_currency, v_name, v_country, v_authorized_subsidy
    from public.competitions
    where id = p_competition_id;
  if not found then
    raise exception 'Competition introuvable' using errcode = 'P0002';
  end if;

  -- Scope admin : section « versements » + pays de la compétition.
  if not public.admin_can_section(auth.uid(), 'payouts') then
    raise exception 'Compte non autorise sur les versements' using errcode = '42501';
  end if;
  if not public.admin_can_country(auth.uid(), v_country) then
    raise exception 'Compte non autorise sur ce pays' using errcode = '42501';
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

  -- Cohérence budget : des prix prévus mais aucune cagnotte déclarée → refus.
  select coalesce(sum(
           case when coalesce(nullif(val, '')::numeric, 0) > 0
                then nullif(val, '')::numeric else 0 end), 0)
    into v_dist_total
    from jsonb_array_elements_text(v_dist) as e(val);
  if v_dist_total > 0 and coalesce(v_pool, 0) <= 0 then
    raise exception 'Cagnotte non declaree (prize_pool_local = 0) alors que des prix sont prevus. Renseigne la cagnotte de la competition avant de generer les versements.'
      using errcode = '23514';
  end if;

  -- Recettes encaissées (status terminal 'succeeded').
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
        -- Cap dur : ne jamais verser plus que la cagnotte déclarée.
        if v_pool is not null and v_pool > 0 and v_paid_total > v_pool then
          raise exception 'Versements (%) superieurs a la cagnotte declaree (% %). Verifie la repartition des gains.',
            v_paid_total, v_pool, v_currency
            using errcode = '23514';
        end if;

        insert into public.payouts
          (user_id, competition_id, amount_local, currency, status, rank,
           payout_provider, country_code)
        values
          (v_user, p_competition_id, v_amount, v_currency,
           'pending_admin_validation', i, 'mobile_money_manual', v_country);

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

  -- Garde anti-echec-silencieux : des prix prevus mais aucun joueur classe.
  if v_count = 0 and v_had_prize then
    raise exception 'Aucun joueur classe pour les rangs recompenses. Publie d''abord le classement final, puis genere les versements.'
      using errcode = 'P0002';
  end if;

  -- F2 : la plateforme ne peut subventionner (versements > frais encaissés) que
  -- dans la limite EXPLICITEMENT autorisée. Au-delà → refus (rollback total).
  if v_paid_total > v_collected + coalesce(v_authorized_subsidy, 0) then
    raise exception 'Versements (% %) depassent les frais encaisses (%) + la subvention autorisee (%). Declare une subvention (set_competition_subsidy) ou corrige la repartition.',
      v_paid_total, v_currency, v_collected, coalesce(v_authorized_subsidy, 0)
      using errcode = '23514';
  end if;

  -- Trace : subvention autorisée effectivement consommée (payouts > recettes).
  if v_paid_total > v_collected then
    insert into public.admin_audit_log
      (admin_id, action, target_type, target_id, after_state)
    values (
      auth.uid(), 'payout_pool_subsidy', 'competition', p_competition_id,
      jsonb_build_object('paid_total', v_paid_total, 'collected_fees', v_collected,
                         'authorized_subsidy', coalesce(v_authorized_subsidy, 0),
                         'currency', v_currency, 'payouts_count', v_count));
  end if;

  return v_count;
end;
$$;
