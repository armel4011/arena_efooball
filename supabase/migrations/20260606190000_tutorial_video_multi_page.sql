-- ============================================================================
-- Bannières tuto : multi-bannières + ciblage par page
-- ============================================================================
-- Évolution : on passe d'UNE bannière active à PLUSIEURS, chacune ciblant une
-- page (`home`, `competitions`) ou TOUTES les pages (`all`). La fenêtre
-- d'affichage par nouvel utilisateur (display_days depuis la 1re impression,
-- via tutorial_video_views) reste inchangée et fonctionne déjà par bannière.
-- ----------------------------------------------------------------------------

-- 1) Plus de contrainte « une seule bannière active » : on autorise N actives.
DROP INDEX IF EXISTS public.tutorial_video_single_active;

-- 2) Page cible de chaque bannière.
ALTER TABLE public.tutorial_video
  ADD COLUMN IF NOT EXISTS target_page text NOT NULL DEFAULT 'home';

ALTER TABLE public.tutorial_video
  DROP CONSTRAINT IF EXISTS tutorial_video_target_page_chk;
ALTER TABLE public.tutorial_video
  ADD CONSTRAINT tutorial_video_target_page_chk
  CHECK (target_page IN ('home', 'competitions', 'all'));

COMMENT ON COLUMN public.tutorial_video.target_page IS
  'Page d''affichage de la banniere : home | competitions | all (toutes).';

-- 3) Index pour récupérer rapidement les bannières actives par page.
CREATE INDEX IF NOT EXISTS idx_tutorial_video_active_page
  ON public.tutorial_video (target_page)
  WHERE is_active;
