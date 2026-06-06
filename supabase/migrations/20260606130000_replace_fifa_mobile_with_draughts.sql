-- ============================================================================
-- Remplace le jeu "FIFA Mobile" par "Jeu de Dames" (draughts)
-- ============================================================================
-- La table public.competitions porte une contrainte CHECK inline sur la
-- colonne `game` (cf. 20260505100002_core_user_and_competitions.sql ligne ~80).
-- Une CHECK inline sans nom explicite reçoit le nom auto-généré Postgres
-- `competitions_game_check`. On la supprime puis on la recrée avec la nouvelle
-- liste de valeurs autorisées.
--
-- Aucune migration de données n'est nécessaire : il n'existe AUCUNE ligne
-- competitions.game = 'fifa_mobile' en base (vérifié). La valeur est
-- simplement retirée de la liste autorisée et remplacée par 'draughts'.
-- ----------------------------------------------------------------------------

alter table public.competitions
  drop constraint if exists competitions_game_check;

alter table public.competitions
  add constraint competitions_game_check
  check (game in ('efootball', 'draughts', 'ea_sports_fc'));
