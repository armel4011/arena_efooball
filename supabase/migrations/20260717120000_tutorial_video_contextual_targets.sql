-- ============================================================================
-- Vidéos tuto CONTEXTUELLES : salle verrouillée, intro de rôle, tuto paiement
-- ============================================================================
-- Jusqu'ici `tutorial_video` = bannières de prise en main affichées sur une
-- PAGE (home | competitions | profile | messages | all), lues EN EXTERNE.
-- On étend le MÊME support à trois vidéos jouées IN-APP, en contexte :
--
--   * match_locked     — écran de verrouillage de la salle : règles du JEU
--   * match_role_intro — étape 1 du match : rôle DOMICILE/EXTÉRIEUR (football)
--   * payment_tutorial — page de paiement : mode d'emploi par PAYS
--
-- Deux discriminants contextuels s'ajoutent :
--   * game         — pour match_locked / match_role_intro (règles / rôle par jeu)
--   * country_code — pour payment_tutorial (un système de paiement par pays)
--
-- On réutilise ainsi repo, RLS admin, realtime, compteur de vues et écrans
-- d'admin existants, SANS nouvelle table. Purement additif : les bannières de
-- page existantes gardent exactement leur comportement (game/country NULL).
-- ----------------------------------------------------------------------------

-- 1) Discriminants contextuels (nullable : les bannières de page n'en ont pas).
ALTER TABLE public.tutorial_video
  ADD COLUMN IF NOT EXISTS game         text,
  ADD COLUMN IF NOT EXISTS country_code text;

-- game : miroir de competitions.game (efootball | draughts | ea_sports_fc).
ALTER TABLE public.tutorial_video
  DROP CONSTRAINT IF EXISTS tutorial_video_game_chk;
ALTER TABLE public.tutorial_video
  ADD CONSTRAINT tutorial_video_game_chk
  CHECK (game IS NULL OR game IN ('efootball', 'draughts', 'ea_sports_fc'));

-- country_code : ISO-3166 alpha-2, même format que profiles / payments.
ALTER TABLE public.tutorial_video
  DROP CONSTRAINT IF EXISTS tutorial_video_country_code_chk;
ALTER TABLE public.tutorial_video
  ADD CONSTRAINT tutorial_video_country_code_chk
  CHECK (country_code IS NULL OR country_code ~ '^[A-Z]{2}$');

COMMENT ON COLUMN public.tutorial_video.game IS
  'Jeu ciblé (efootball|draughts|ea_sports_fc) pour les cibles match_locked / '
  'match_role_intro. NULL pour les bannieres de page et payment_tutorial.';
COMMENT ON COLUMN public.tutorial_video.country_code IS
  'Pays ciblé (ISO alpha-2) pour la cible payment_tutorial. NULL sinon.';

-- 2) Trois nouvelles cibles contextuelles s'ajoutent aux 5 pages existantes.
ALTER TABLE public.tutorial_video
  DROP CONSTRAINT IF EXISTS tutorial_video_target_page_chk;
ALTER TABLE public.tutorial_video
  ADD CONSTRAINT tutorial_video_target_page_chk
  CHECK (target_page IN (
    'home', 'competitions', 'profile', 'messages', 'all',
    'match_locked', 'match_role_intro', 'payment_tutorial'
  ));

-- 3) Cohérence cible ↔ discriminant : chaque cible contextuelle exige SON
--    discriminant et interdit l'autre ; les bannières de page n'en portent
--    aucun. match_role_intro ne vise que le football (les Dames se jouent
--    in-app, sans rôle DOMICILE/EXTÉRIEUR).
--    COALESCE(..., false) sur match_role_intro : `game IN (...)` vaut NULL si
--    game est NULL, or un CHECK laisse passer un résultat NULL — on force donc
--    un booléen strict pour rejeter game NULL.
ALTER TABLE public.tutorial_video
  DROP CONSTRAINT IF EXISTS tutorial_video_context_coherence_chk;
ALTER TABLE public.tutorial_video
  ADD CONSTRAINT tutorial_video_context_coherence_chk
  CHECK (
    CASE target_page
      WHEN 'match_locked'
        THEN game IS NOT NULL AND country_code IS NULL
      WHEN 'match_role_intro'
        THEN COALESCE(game IN ('efootball', 'ea_sports_fc'), false)
             AND country_code IS NULL
      WHEN 'payment_tutorial'
        THEN country_code IS NOT NULL AND game IS NULL
      ELSE game IS NULL AND country_code IS NULL
    END
  );

-- 4) Au plus UNE vidéo active par contexte : (cible, jeu) pour la salle et
--    l'intro de rôle, (cible, pays) pour le tuto paiement. Sinon le client ne
--    saurait laquelle jouer. Les bannières de page gardent le N-actives.
CREATE UNIQUE INDEX IF NOT EXISTS tutorial_video_active_game_ctx
  ON public.tutorial_video (target_page, game)
  WHERE is_active AND target_page IN ('match_locked', 'match_role_intro');

CREATE UNIQUE INDEX IF NOT EXISTS tutorial_video_active_country_ctx
  ON public.tutorial_video (target_page, country_code)
  WHERE is_active AND target_page = 'payment_tutorial';
