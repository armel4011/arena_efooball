-- ════════════════════════════════════════════════════════════════════
-- Bug fix : RLS storage chat-media — name shadowing
-- ════════════════════════════════════════════════════════════════════
-- Migration `20260519180100` créait les policies avec un sub-EXISTS qui
-- joignait `chat_channels c`. Or `chat_channels` a une colonne `name`
-- (utilisée pour les channels broadcast). Postgres résolvait `name`
-- vers `c.name` au lieu de `storage.objects.name` (le path du fichier).
-- Résultat : `storage.foldername(NULL)[1] = NULL`, comparé à
-- `c.id::text` → toujours faux, donc tous les uploads échouaient avec
-- 403 RLS.
--
-- Fix : qualifier explicitement `storage.objects.name` dans le subquery.
-- Bonus : INNER JOIN remplace LEFT JOIN (plus précis) et 2 EXISTS
-- séparés (match vs friend) au lieu d'un seul avec OR — plus lisible.

DROP POLICY IF EXISTS chat_media_insert_member ON storage.objects;
CREATE POLICY chat_media_insert_member ON storage.objects
FOR INSERT TO authenticated
WITH CHECK (
  bucket_id = 'chat-media'
  AND (
    EXISTS (
      SELECT 1 FROM public.chat_channels cc
      JOIN public.matches m ON m.id = cc.match_id
      WHERE cc.id::text = (storage.foldername(storage.objects.name))[1]
        AND cc.type = 'match'
        AND (auth.uid() = m.player1_id OR auth.uid() = m.player2_id)
    )
    OR
    EXISTS (
      SELECT 1 FROM public.chat_channels cc
      JOIN public.friendships f ON f.id = cc.friendship_id
      WHERE cc.id::text = (storage.foldername(storage.objects.name))[1]
        AND cc.type = 'friend'
        AND f.status = 'accepted'
        AND (auth.uid() = f.requester_id OR auth.uid() = f.addressee_id)
    )
  )
);

DROP POLICY IF EXISTS chat_media_select_member ON storage.objects;
CREATE POLICY chat_media_select_member ON storage.objects
FOR SELECT TO authenticated
USING (
  bucket_id = 'chat-media'
  AND (
    EXISTS (
      SELECT 1 FROM public.chat_channels cc
      JOIN public.matches m ON m.id = cc.match_id
      WHERE cc.id::text = (storage.foldername(storage.objects.name))[1]
        AND cc.type = 'match'
        AND (auth.uid() = m.player1_id OR auth.uid() = m.player2_id)
    )
    OR
    EXISTS (
      SELECT 1 FROM public.chat_channels cc
      JOIN public.friendships f ON f.id = cc.friendship_id
      WHERE cc.id::text = (storage.foldername(storage.objects.name))[1]
        AND cc.type = 'friend'
        AND f.status = 'accepted'
        AND (auth.uid() = f.requester_id OR auth.uid() = f.addressee_id)
    )
  )
);
