-- Écran de verrouillage de salle : autoriser PLUSIEURS vidéos actives par jeu
-- (règles, prolongations, tirs au but…). On retire `match_locked` de l'index
-- d'unicité (cible, jeu) — `install_check` y reste (une seule vidéo par jeu).
-- `match_role_intro` garde son propre index (jeu, côté).

drop index if exists tutorial_video_active_game_ctx;
create unique index tutorial_video_active_game_ctx
  on public.tutorial_video (target_page, game)
  where (is_active and target_page = 'install_check');
