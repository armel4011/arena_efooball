-- ============================================================================
-- Bannières tuto : nouvelles pages cibles Profil + Messagerie
-- ============================================================================
-- Étend `target_page` aux pages `profile` (page profil du joueur) et
-- `messages` (boîte de réception). Valeurs : home | competitions | profile |
-- messages | all (toutes).
-- ----------------------------------------------------------------------------

ALTER TABLE public.tutorial_video
  DROP CONSTRAINT IF EXISTS tutorial_video_target_page_chk;
ALTER TABLE public.tutorial_video
  ADD CONSTRAINT tutorial_video_target_page_chk
  CHECK (target_page IN ('home', 'competitions', 'profile', 'messages', 'all'));
