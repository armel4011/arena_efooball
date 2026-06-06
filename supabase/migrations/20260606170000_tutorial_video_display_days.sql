-- Enrichissement de la vidéo tutoriel : durée d'affichage ciblée nouveaux users.
--
-- Règle produit : la bannière vidéo tutoriel ne s'affiche qu'aux NOUVEAUX
-- utilisateurs, pendant `display_days` jours à compter de la création de leur
-- compte (profiles.created_at). Passé ce délai (compte plus vieux que N jours),
-- la bannière disparaît pour cet utilisateur. La condition côté user est :
--   is_active = TRUE ET (now() - profil.created_at) < display_days jours.
--
-- `display_days` est configuré par le super-admin lors de la publication.

ALTER TABLE public.tutorial_video
  ADD COLUMN IF NOT EXISTS display_days integer NOT NULL DEFAULT 7;

COMMENT ON COLUMN public.tutorial_video.display_days IS
  'Durée en jours pendant laquelle la bannière s''affiche à un user, à partir '
  'de la création de son compte (profiles.created_at). Au-delà, masquée.';

-- Contrainte de bornes raisonnables (1 jour à 1 an). Idempotente :
-- on droppe d'abord la contrainte si elle existe, puis on la (re)crée.
ALTER TABLE public.tutorial_video
  DROP CONSTRAINT IF EXISTS tutorial_video_display_days_chk;

ALTER TABLE public.tutorial_video
  ADD CONSTRAINT tutorial_video_display_days_chk
  CHECK (display_days BETWEEN 1 AND 365);
