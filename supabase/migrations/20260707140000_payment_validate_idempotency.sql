-- =============================================================================
-- ARENA — Audit 2026-07-07 (P2 #7) : validation de paiement idempotente
-- =============================================================================
-- `AdminPaymentsRepository.validate()` / `reject()` faisaient un UPDATE filtré
-- uniquement par `id`, sans précondition de statut, et la policy
-- `payments_admin_update` autorisait le super-admin à poser un statut sur un
-- paiement dans N'IMPORTE QUEL statut.
--
-- Scénario (course avec annulation) : une compétition est annulée → ses
-- paiements `awaiting_admin` passent `refund_pending`/`rejected` ; un second
-- super-admin avec une liste « en attente » périmée clique Valider → le paiement
-- déjà clos bascule `succeeded`, le trigger `on_payment_validated` ré-insère une
-- registration `confirmed` dans une compétition annulée, et le paiement est
-- recompté en revenu tout en ÉCHAPPANT à la file de remboursement.
--
-- CORRECTIF (autoritatif, serveur) : la policy `payments_admin_update` ne rend
-- modifiables QUE les paiements encore `awaiting_admin` (USING), et n'autorise
-- comme cible QUE `succeeded` / `rejected` (WITH CHECK) — la seule transition
-- légitime du flux admin RLS. Un UPDATE sur un paiement déjà clos ne matche
-- plus aucune ligne (no-op idempotent), impossible de ressusciter un paiement
-- `rejected`/`refund_pending`/`refunded`.
--
-- Les transitions serveur (mark_payment_refunded, cancel_competition →
-- refund_pending) passent par des RPC SECURITY DEFINER qui contournent la RLS :
-- elles ne sont PAS affectées.
-- =============================================================================

drop policy if exists payments_admin_update on public.payments;
create policy payments_admin_update on public.payments
  for update to public
  using (public.is_super_admin() and status = 'awaiting_admin')
  with check (public.is_super_admin() and status in ('succeeded', 'rejected'));

comment on policy payments_admin_update on public.payments is
  'P2 audit 2026-07-07 : validation/rejet idempotents — seul un paiement encore '
  '`awaiting_admin` est modifiable (USING) et uniquement vers succeeded/rejected '
  '(WITH CHECK). Empêche de ressusciter un paiement déjà clos lors d''une course '
  'avec annulation. Les transitions refund passent par des RPC DEFINER (hors RLS).';
