-- =============================================================================
-- ARENA — Intégrité compta DB-1 : bornes sur les montants
-- =============================================================================
-- `payments.amount_local` (> 0) et `payouts.amount_usd` (> 0) ont leur CHECK,
-- mais deux colonnes monétaires en étaient dépourvues → un montant nul/négatif
-- pouvait s'écrire et fausser les agrégats de revenus :
--   • platform_revenue.amount_local (commission plateforme)
--   • payouts.amount_local (montant versé au gagnant, en devise locale)
-- Données vérifiées : 0 ligne en violation au moment de la migration.
--
-- platform_revenue : >= 0 (une ligne d'ajustement/sponsoring peut être nulle).
-- payouts.amount_local : > 0 (un versement nul n'a pas de sens, comme amount_usd).
-- =============================================================================

alter table public.platform_revenue
  drop constraint if exists platform_revenue_amount_local_check;
alter table public.platform_revenue
  add constraint platform_revenue_amount_local_check
    check (amount_local >= 0);

alter table public.payouts
  drop constraint if exists payouts_amount_local_check;
alter table public.payouts
  add constraint payouts_amount_local_check
    check (amount_local > 0);
