-- Nom d'equipe saisi par chaque joueur en salle de match.
--
-- Permet a l'admin d'etre plus precis lors de l'examen des matchs en cas
-- de litige anti-triche : on sait quelle equipe chaque joueur a utilisee.
--
-- La saisie passe par le flow client existant (RLS `matches_player_update`
-- de la migration phase5 autorise deja les 2 joueurs a updater leur row ;
-- l'intent per-colonne est porte par le repo Dart `setTeamName`).

ALTER TABLE public.matches
  ADD COLUMN IF NOT EXISTS player1_team_name TEXT,
  ADD COLUMN IF NOT EXISTS player2_team_name TEXT;

COMMENT ON COLUMN public.matches.player1_team_name IS
  'Nom de l''equipe utilisee par le joueur 1, saisi en salle de match '
  '(donnee d''aide a l''arbitrage anti-triche).';
COMMENT ON COLUMN public.matches.player2_team_name IS
  'Nom de l''equipe utilisee par le joueur 2, saisi en salle de match '
  '(donnee d''aide a l''arbitrage anti-triche).';
