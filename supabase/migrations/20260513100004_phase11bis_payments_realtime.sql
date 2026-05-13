-- =============================================================================
-- PHASE 11bis — Ajouter `payments` à la publication realtime Supabase
-- =============================================================================
-- Sans cette publication, P3 PaymentProcessingPage ne reçoit jamais l'event
-- quand le super-admin valide le paiement (`status` passe à `succeeded` ou
-- `rejected`) — la page reste figée sur le spinner au lieu de router vers
-- P4 PaymentSuccess ou P5 PaymentFailed.
--
-- Découvert pendant le test live de l'app user/admin.
-- =============================================================================

alter publication supabase_realtime add table public.payments;
