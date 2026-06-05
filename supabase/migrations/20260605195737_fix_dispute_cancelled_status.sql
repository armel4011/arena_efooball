-- =============================================================================
-- ARENA — Fix : autorise le statut 'cancelled' sur disputes (audit v5, HIGH)
-- =============================================================================
-- BUG (introduit par 20260605154411_resolve_dispute_atomic) : la RPC atomique
-- `resolve_dispute(p_cancel=true)` écrit `disputes.status = 'cancelled'`, mais la
-- contrainte `disputes_status_check` ne l'autorisait pas
-- ('open','bot_review','admin_review','resolved','closed'). La violation CHECK
-- (23514) faisait ÉCHOUER ET ROLLBACK toute la transaction atomique : le match
-- n'était PAS annulé et le litige restait 'open' (réapparition dans la file).
-- → le chemin « annuler un match en litige » était cassé de façon déterministe.
--
-- Correctif additif (élargit les valeurs permises, aucune row existante violée).
-- =============================================================================

alter table public.disputes drop constraint disputes_status_check;

alter table public.disputes add constraint disputes_status_check
  check (
    status in (
      'open', 'bot_review', 'admin_review', 'resolved', 'closed', 'cancelled'
    )
  );
