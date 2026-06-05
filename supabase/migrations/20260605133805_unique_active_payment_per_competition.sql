-- =============================================================================
-- ARENA — Intégrité paiement C-3 : un seul paiement actif par (joueur, compét.)
-- =============================================================================
-- Rien n'empêchait un joueur d'insérer DEUX lignes `payments` en
-- `awaiting_admin` pour la même compétition (le garde-fou
-- `myPendingPaymentByCompetitionProvider` est purement côté client). Si le
-- super-admin validait les deux, on obtenait deux paiements `succeeded` →
-- double encaissement réel possible + KPIs revenus faussés.
--
-- Index unique PARTIEL : au plus une ligne "active" (awaiting_admin OU
-- succeeded) par couple (user_id, competition_id). Les statuts terminaux
-- (failed/rejected/expired/refunded) restent illimités → un joueur dont le
-- paiement a été rejeté peut réessayer normalement.
-- Données vérifiées : 0 doublon actif au moment de la migration.
-- =============================================================================

create unique index if not exists uniq_payments_active_per_competition
  on public.payments (user_id, competition_id)
  where status in ('awaiting_admin', 'succeeded');
