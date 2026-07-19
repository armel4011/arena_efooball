-- ============================================================================
-- Vidéo tuto CONTEXTUELLE : contrôle d'installation avant inscription
-- ============================================================================
-- Nouvelle cible `install_check` : vidéo jouée IN-APP dans le dialogue de
-- contrôle affiché AVANT l'inscription à une compétition sur jeu EXTERNE
-- (efootball | ea_sports_fc | dream_league). Les Dames (draughts) sont in-app
-- → pas de contrôle d'installation, pas de vidéo install_check.
--
-- Additif : réutilise table/RLS/realtime/écrans admin existants (le formulaire
-- admin itère sur TutorialPage.values). Deux ajustements de contrainte :
--   1) `game` autorise désormais `dream_league` (absent jusqu'ici — bloquait
--      toute vidéo par jeu pour Dream League, y compris match_locked) ;
--   2) `install_check` s'ajoute aux cibles, avec sa règle de cohérence.
-- ----------------------------------------------------------------------------

-- 1) `game` : ajouter dream_league (aligné sur competitions_game_check).
--    ⚠️ AJOUTER UN JEU = mettre à jour CETTE contrainte aussi (game_catalog_wiring).
ALTER TABLE public.tutorial_video
  DROP CONSTRAINT IF EXISTS tutorial_video_game_chk;
ALTER TABLE public.tutorial_video
  ADD CONSTRAINT tutorial_video_game_chk
  CHECK (game IS NULL
         OR game IN ('efootball', 'draughts', 'ea_sports_fc', 'dream_league'));

-- 2) Ajouter `install_check` aux cibles autorisées.
ALTER TABLE public.tutorial_video
  DROP CONSTRAINT IF EXISTS tutorial_video_target_page_chk;
ALTER TABLE public.tutorial_video
  ADD CONSTRAINT tutorial_video_target_page_chk
  CHECK (target_page IN (
    'home', 'competitions', 'profile', 'messages', 'all',
    'match_locked', 'match_role_intro', 'payment_tutorial', 'install_check'
  ));

-- 3) Cohérence cible ↔ discriminant. `install_check` vise les 3 jeux EXTERNES
--    (pas draughts, in-app). On en profite pour aligner `match_role_intro` sur
--    le client (gamesForTutorialPage offrait déjà dream_league — football).
--    COALESCE(..., false) : `game IN (...)` vaut NULL si game NULL, or un CHECK
--    laisse passer NULL → on force un booléen strict pour rejeter game NULL.
ALTER TABLE public.tutorial_video
  DROP CONSTRAINT IF EXISTS tutorial_video_context_coherence_chk;
ALTER TABLE public.tutorial_video
  ADD CONSTRAINT tutorial_video_context_coherence_chk
  CHECK (
    CASE target_page
      WHEN 'match_locked'
        THEN game IS NOT NULL AND country_code IS NULL
      WHEN 'match_role_intro'
        THEN COALESCE(
               game IN ('efootball', 'ea_sports_fc', 'dream_league'), false)
             AND country_code IS NULL
      WHEN 'install_check'
        THEN COALESCE(
               game IN ('efootball', 'ea_sports_fc', 'dream_league'), false)
             AND country_code IS NULL
      WHEN 'payment_tutorial'
        THEN country_code IS NOT NULL AND game IS NULL
      ELSE game IS NULL AND country_code IS NULL
    END
  );

-- 4) Au plus UNE vidéo active par (cible, jeu) — inclut install_check.
DROP INDEX IF EXISTS public.tutorial_video_active_game_ctx;
CREATE UNIQUE INDEX IF NOT EXISTS tutorial_video_active_game_ctx
  ON public.tutorial_video (target_page, game)
  WHERE is_active
    AND target_page IN ('match_locked', 'match_role_intro', 'install_check');
