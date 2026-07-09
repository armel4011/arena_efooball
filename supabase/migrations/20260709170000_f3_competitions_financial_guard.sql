-- =============================================================================
-- ARENA — Audit 2026-07-09 F3 : gardes financières competitions + scoping pays
-- =============================================================================
-- Constat : `competitions_update_admin` = `is_admin()` seul (ni super-admin ni
-- scoping pays), et AUCUN guard de colonnes sur les champs financiers de
-- `competitions` (contrairement à matches/payouts/profiles). Un admin SIMPLE
-- pouvait donc gonfler `prize_pool_local` / `commission_xaf` / `prize_distribution`
-- de n'importe quelle compétition (amplifie la subvention non bornée F2, fausse
-- les KPI de commission), et éditer une compétition hors de son pays.
--
-- FIX 1 — trigger `guard_competitions_financial_columns` : fige prize_pool_local,
--   commission_xaf, commission_pct, prize_distribution en UPDATE pour un client
--   non-super-admin. La CRÉATION (INSERT via wizard) reste libre ; seule la
--   modification post-création des montants exige le super-admin. Éditer les
--   champs non-financiers (nom, dates…) reste possible pour un admin.
-- FIX 2 — `competitions_update_admin` cloisonné pays (admin_can_country), miroir
--   payouts/recordings/paiement. super-admin (scope NULL) = partout.
-- =============================================================================
-- Depends on: 20260505185438 (competitions_update_admin), 20260706100000
--   (competitions.country_code), 20260706100400 (admin_can_country),
--   20260505100005 (is_admin/is_super_admin).
-- =============================================================================

-- ─── FIX 1 : guard des colonnes financières ────────────────────────────────
create or replace function public.guard_competitions_financial_columns()
returns trigger
language plpgsql
security invoker
set search_path = public, pg_temp
as $$
begin
  -- service_role + fonctions SECURITY DEFINER (auto-management, payouts) restent
  -- libres (current_user = owner). Seul le client PostgREST non-super-admin est bridé.
  if current_user in ('authenticated', 'anon') and not public.is_super_admin() then
    if new.prize_pool_local  is distinct from old.prize_pool_local
       or new.commission_xaf     is distinct from old.commission_xaf
       or new.commission_pct     is distinct from old.commission_pct
       or new.prize_distribution is distinct from old.prize_distribution
    then
      raise exception 'Modification interdite : les montants d''une compétition (cagnotte, commission, répartition) sont réservés au super-admin'
        using errcode = '42501';
    end if;
  end if;
  return new;
end;
$$;

comment on function public.guard_competitions_financial_columns() is
  'Audit 2026-07-09 F3 : fige prize_pool_local/commission_xaf/commission_pct/'
  'prize_distribution en UPDATE cote client non-super-admin (empêche un admin '
  'simple de gonfler une cagnotte). INSERT (création) libre. service_role/DEFINER libres.';

drop trigger if exists trg_competitions_guard_financial on public.competitions;
create trigger trg_competitions_guard_financial
  before update on public.competitions
  for each row execute function public.guard_competitions_financial_columns();

-- ─── FIX 2 : scoping pays de l'édition de compétition ───────────────────────
-- On remplace l'unique policy UPDATE (pas d'ajout permissif). admin_can_country
-- renvoie true pour un scope NULL (super-admin) → partout ; sinon appartenance.
drop policy if exists "competitions_update_admin" on public.competitions;
create policy "competitions_update_admin"
  on public.competitions for update
  using (
    (select public.is_admin())
    and public.admin_can_country((select auth.uid()), country_code)
  )
  with check (
    (select public.is_admin())
    and public.admin_can_country((select auth.uid()), country_code)
  );
