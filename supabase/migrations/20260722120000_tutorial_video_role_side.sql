-- Intro de rôle (étape 1 du match) : vidéos DIFFÉRENTES pour Domicile vs
-- Extérieur. Ajoute une dimension `role_side` (home/away), requise pour la cible
-- `match_role_intro`, NULL pour toutes les autres. Aucune vidéo match_role_intro
-- n'existe encore → pas de données à migrer.

alter table public.tutorial_video add column role_side text;

alter table public.tutorial_video
  add constraint tutorial_video_role_side_chk check (
    (target_page = 'match_role_intro' and role_side in ('home', 'away'))
    or (target_page <> 'match_role_intro' and role_side is null)
  );

-- Unicité : l'intro de rôle devient unique par (jeu, côté) au lieu de (cible,
-- jeu). On retire donc match_role_intro de l'index (cible, jeu) et on lui donne
-- son propre index (jeu, côté).
drop index if exists tutorial_video_active_game_ctx;
create unique index tutorial_video_active_game_ctx
  on public.tutorial_video (target_page, game)
  where (is_active and target_page in ('match_locked', 'install_check'));
create unique index tutorial_video_active_role_intro_ctx
  on public.tutorial_video (game, role_side)
  where (is_active and target_page = 'match_role_intro');
