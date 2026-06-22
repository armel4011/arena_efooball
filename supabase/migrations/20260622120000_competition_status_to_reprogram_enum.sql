-- =============================================================================
-- ARENA — Statut « à reprogrammer » (to_reprogram) — ajout valeur d'enum
-- =============================================================================
-- Nouvelle valeur du type `public.competition_status`. Une compétition dont la
-- date de début est atteinte SANS que le quota de joueurs soit complet ne sera
-- plus annulée automatiquement : elle bascule en `to_reprogram`, laissant à
-- l'admin 3 choix (reprogrammer / démarrer avec les inscrits / annuler &
-- rembourser). Voir la migration de logique 20260622120100.
--
-- ⚠️ `ALTER TYPE ... ADD VALUE` doit être COMMITé avant que la nouvelle valeur
-- puisse être utilisée (littéral `'to_reprogram'::competition_status`). C'est
-- pourquoi l'ajout de valeur est ISOLÉ dans sa propre migration — les fonctions
-- qui s'en servent vivent dans le fichier suivant (transaction distincte).
-- `IF NOT EXISTS` rend la migration idempotente (replays / db reset).
-- =============================================================================

alter type public.competition_status add value if not exists 'to_reprogram';
