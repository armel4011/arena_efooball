-- =============================================================================
-- ARENA — Durcissement RLS (audit sécurité 2026-07-10)
-- =============================================================================
-- Findings de l'audit global du 2026-07-10 (fil « un simple admin ne doit pas
-- faire d'action super-admin ni cross-pays ») :
--
--  P2  competitions : la policy DELETE était `is_admin()` seule (ni super-admin
--      ni cloisonnement pays) alors que l'UPDATE est `is_admin() AND
--      admin_can_country(...)`. `authenticated` ayant le GRANT DELETE, un simple
--      admin pouvait DELETE via REST une compétition d'un autre pays, contournant
--      le RPC super-admin `delete_competition_cascade` (+ son garde-fou de
--      remboursement). On aligne la policy sur le RPC : super-admin uniquement.
--
--  P3  payments : lecture admin non cloisonnée (`is_admin()`) alors que payouts
--      l'est. On applique le MÊME cloisonnement pays qu'aux payouts (super-admin
--      à scope NULL = accès partout ; la validation reste super-admin only).
--
--  P3  platform_revenue : lecture par TOUT admin alors que toutes les analytics
--      de revenus (get_super_admin_kpis, get_revenue_*, get_country_breakdown)
--      sont super-admin only → on aligne la table sur ses consommateurs.
-- =============================================================================

-- ── P2 : suppression de compétition réservée au super-admin ──────────────────
drop policy if exists competitions_delete_admin on public.competitions;
create policy competitions_delete_admin on public.competitions
  for delete
  using ((select public.is_super_admin()));

-- ── P3 : lecture des paiements cloisonnée par pays (miroir payouts_select) ───
drop policy if exists payments_select on public.payments;
create policy payments_select on public.payments
  for select
  using (
    (user_id = (select auth.uid()))
    OR (
      (select public.is_admin())
      AND (
        (public.admin_allowed_countries((select auth.uid())) IS NULL)
        OR (country_code = ANY (public.admin_allowed_countries((select auth.uid()))))
      )
    )
  );

-- ── P3 : revenus plateforme réservés au super-admin (miroir des RPC KPI) ─────
drop policy if exists platform_revenue_select_admin on public.platform_revenue;
create policy platform_revenue_select_admin on public.platform_revenue
  for select
  using ((select public.is_super_admin()));
