-- =============================================================================
-- PHASE 11bis — Retire le timeout 15 min sur les paiements
-- =============================================================================
-- Décision produit : un paiement P2P reste en `awaiting_admin` jusqu'à
-- validation ou refus explicite par le super-admin. Pas d'auto-expiration.
--
-- Cleanup :
--   1. Drop la fonction expire_stale_payments() (devenue inutile)
--   2. Drop l'index partiel idx_payments_awaiting_admin (sur expires_at)
--      et le remplace par un index sur created_at pour le tri admin
--   3. Drop la colonne expires_at (nullable, plus utilisée)
--
-- Note : la valeur 'expired' reste dans le check `payments_status_check`
-- par défensive (au cas où un row legacy aurait ce statut).
-- =============================================================================

drop function if exists public.expire_stale_payments();

drop index if exists public.idx_payments_awaiting_admin;

create index if not exists idx_payments_awaiting_admin
  on public.payments (created_at)
  where status = 'awaiting_admin';

alter table public.payments
  drop column if exists expires_at;
