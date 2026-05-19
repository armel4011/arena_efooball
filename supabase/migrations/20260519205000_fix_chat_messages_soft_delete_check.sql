-- ════════════════════════════════════════════════════════════════════
-- Bug fix : soft-delete d'un message text violait content_check
-- ════════════════════════════════════════════════════════════════════
-- Migration `20260519180000` posait content_check :
--   (media_url IS NOT NULL AND length(content) BETWEEN 0 AND 2000)
--   OR (media_url IS NULL AND length(content) BETWEEN 1 AND 2000)
--
-- Le `softDeleteMessage()` set content='' + media_url=null → viole la
-- 2e branche (length >= 1 requis si pas de media). Test du téléphone
-- 2026-05-19 : delete silencieux, RLS UPDATE refuse.
--
-- Fix : ajouter une 3e branche qui accepte tout quand deleted_at est
-- posé (mode soft-delete).

ALTER TABLE public.chat_messages
  DROP CONSTRAINT IF EXISTS chat_messages_content_check;

ALTER TABLE public.chat_messages
  ADD CONSTRAINT chat_messages_content_check CHECK (
    deleted_at IS NOT NULL
    OR (media_url IS NOT NULL AND length(content) BETWEEN 0 AND 2000)
    OR (media_url IS NULL AND length(content) BETWEEN 1 AND 2000)
  );
