-- =============================================================================
-- ARENA — Audit 2026-07-18 (P3) : cloisonner la policy UPDATE de `payouts`
-- =============================================================================
-- La policy `payouts_admin_update` autorisait tout UPDATE direct dès lors que
-- `is_super_admin()` — SANS `admin_can_country` ni `admin_can_section`, contrai-
-- rement à :
--   • `payouts_select`         (déjà cloisonné pays pour is_admin),
--   • `payments_admin_update`  (cloisonné pays),
--   • la RPC `mark_payout_paid` (exige admin_can_section('payouts') + pays).
--
-- Trou (défense en profondeur, latent aujourd'hui car l'unique super-admin est
-- GLOBAL) : un super-admin *scopé* pays/section pourrait, par PATCH REST direct
-- sur `payouts` (en contournant la RPC), écrire `status='completed'` /
-- `completed_at` sur un versement d'un AUTRE pays ou hors de sa section, alors
-- que la RPC le lui interdit. Les montants/bénéficiaire restent gelés par
-- `guard_payouts_financial_columns` (pas de vol possible), mais le cloisonnement
-- pays/section est contournable — on l'aligne ici sur le reste du pipeline.
--
-- `payouts` n'a pas de colonne `section` : la section est un littéral 'payouts'
-- (même convention que `mark_payout_paid`).
-- =============================================================================
-- Depends on: 20260605142815 (payouts + payouts_admin_update),
--   20260706100200 (payouts.country_code), 20260706100400 (admin_can_section/country).
-- =============================================================================

drop policy if exists payouts_admin_update on public.payouts;

create policy payouts_admin_update on public.payouts
  for update to authenticated
  using (
    public.is_super_admin()
    and public.admin_can_section((select auth.uid()), 'payouts')
    and public.admin_can_country((select auth.uid()), country_code)
  )
  with check (
    public.is_super_admin()
    and public.admin_can_section((select auth.uid()), 'payouts')
    and public.admin_can_country((select auth.uid()), country_code)
  );

comment on policy payouts_admin_update on public.payouts is
  'UPDATE direct reserve au super-admin, cloisonne section (''payouts'') + pays '
  '(country_code), aligne sur mark_payout_paid et payments_admin_update '
  '(audit 2026-07-18 P3). Montants/beneficiaire restent geles par le trigger '
  'guard_payouts_financial_columns.';
