-- ============================================================================
-- Ajoute le jeu "Dream League Soccer" (dream_league) à la liste autorisée
-- ============================================================================
-- La table public.competitions porte une contrainte CHECK inline sur la
-- colonne `game` (nom auto-généré `competitions_game_check`, cf.
-- 20260505100002 puis 20260606130000). On la remplace pour AJOUTER la valeur
-- 'dream_league' sans rien retirer — élargissement rétrocompatible, aucune
-- migration de données nécessaire (les valeurs existantes restent valides).
--
-- NB : le renommage d'affichage « EA SPORTS FC Mobile » → « Mobile FC » est
-- purement client (label de l'enum GameType) ; la valeur DB reste 'ea_sports_fc'
-- donc AUCUN changement de données ni de contrainte pour ce renommage.
-- ----------------------------------------------------------------------------

alter table public.competitions
  drop constraint if exists competitions_game_check;

alter table public.competitions
  add constraint competitions_game_check
  check (game in ('efootball', 'draughts', 'ea_sports_fc', 'dream_league'));
