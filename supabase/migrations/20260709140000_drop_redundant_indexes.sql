-- =============================================================================
-- ARENA — Perf : suppression d'index REDONDANTS (doublons de contraintes uniques)
-- =============================================================================
-- L'advisor performance signale de nombreux index « unused », mais `pg_stat_user_
-- indexes` est encore biaisé (trafic pré-ouverture : idx_scan = 0 même sur des
-- index sûrement utilisés). Cf docs/UNUSED_INDEXES_TRACKING.md → règle : attendre
-- ≥ 2026-07-22 avant toute purge basée sur l'usage.
--
-- Cette migration ne touche PAS aux index « usage-based » : elle ne retire que
-- des DOUBLONS EXACTS, sûrs indépendamment des stats. Chacun de ces 3 index
-- non-uniques porte exactement le MÊME jeu de colonnes qu'un index de contrainte
-- UNIQUE déjà présent sur la table — l'index unique sert donc les mêmes lookups
-- (y compris les filtres sur la seule 1re colonne du préfixe), le doublon
-- non-unique n'apporte rien et ne fait que ralentir les écritures.
--
--   idx_bracket_nodes_phase          (phase_id, round_number, position_in_round)
--     ⤷ couvert par bracket_nodes_phase_id_round_number_position_in_round_key (UNIQUE)
--   idx_draughts_moves_game_ply      (game_id, ply)
--     ⤷ couvert par draughts_moves_game_id_ply_key (UNIQUE)
--   idx_phases_competition           (competition_id, phase_order)
--     ⤷ couvert par phases_competition_id_phase_order_key (UNIQUE)
--
-- Réversible : recréer via CREATE INDEX si un plan le réclamait (peu probable,
-- l'index unique suffit). Idempotent (IF EXISTS).
-- =============================================================================

drop index if exists public.idx_bracket_nodes_phase;
drop index if exists public.idx_draughts_moves_game_ply;
drop index if exists public.idx_phases_competition;
