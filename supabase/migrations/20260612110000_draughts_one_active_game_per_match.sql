-- ============================================================================
-- Invariant DB : au plus UNE partie de dames `active` par match.
-- ============================================================================
-- Défense en profondeur contre une course entre deux `start` simultanés (les
-- deux joueurs lancent la partie en même temps). La contrainte existante
-- (match_id, game_number) empêchait déjà deux parties n°1, mais pas deux
-- parties actives de numéros différents. La fonction edge `draughts-game`
-- gère désormais le conflit gracieusement (renvoie la partie active existante),
-- mais cet index garantit l'invariant quelle que soit la voie d'écriture.
--
-- Vérifié avant création : aucun match n'a actuellement >1 partie active.
-- ----------------------------------------------------------------------------

create unique index if not exists draughts_games_one_active_per_match
  on public.draughts_games (match_id)
  where status = 'active';
