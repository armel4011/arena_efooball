-- Vidéos in-app ADAPTÉES À LA LANGUE : une vidéo peut cibler une langue précise
-- (fr/en/es/pt) ; `locale` NULL = vidéo par défaut (toutes langues). L'app
-- affiche la vidéo de la langue de l'utilisateur, à défaut la vidéo par défaut.
--
-- Unicité mise à jour pour inclure la langue (coalesce NULL→'' pour qu'une
-- seule vidéo « par défaut » + une par langue coexistent).

alter table public.tutorial_video add column if not exists locale text;

alter table public.tutorial_video
  drop constraint if exists tutorial_video_locale_chk;
alter table public.tutorial_video
  add constraint tutorial_video_locale_chk
  check (locale is null or locale in ('fr', 'en', 'es', 'pt'));

-- install_check : une vidéo par (jeu, langue).
drop index if exists tutorial_video_active_game_ctx;
create unique index tutorial_video_active_game_ctx
  on public.tutorial_video (target_page, game, coalesce(locale, ''))
  where (is_active and target_page = 'install_check');

-- intro de rôle : une vidéo par (jeu, côté, langue).
drop index if exists tutorial_video_active_role_intro_ctx;
create unique index tutorial_video_active_role_intro_ctx
  on public.tutorial_video (game, role_side, coalesce(locale, ''))
  where (is_active and target_page = 'match_role_intro');

-- match_locked reste SANS unicité (plusieurs vidéos par jeu, cf. migration
-- 20260805130000) — la langue s'y ajoute librement.
