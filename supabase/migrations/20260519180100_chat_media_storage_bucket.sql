-- ════════════════════════════════════════════════════════════════════
-- Bucket Storage chat-media + RLS
-- ════════════════════════════════════════════════════════════════════
-- Note: les buckets/objects sont sous schema `storage`. Le MCP applique
-- ces commandes en tant que role privilégié sur le projet Supabase ;
-- en local (supabase db reset), nécessite que le user supabase ait les
-- droits owner sur storage.* (par défaut OK).

INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'chat-media',
  'chat-media',
  false,
  52428800,
  ARRAY['image/jpeg','image/png','image/webp','image/gif','video/mp4','video/quicktime','audio/mpeg','audio/aac','audio/ogg','audio/mp4']
)
ON CONFLICT (id) DO NOTHING;

-- Path convention: <channel_id>/<filename>
-- storage.foldername(name) renvoie l'array des dossiers ; [1] = 1er folder = channel_id.

DROP POLICY IF EXISTS chat_media_insert_member ON storage.objects;
CREATE POLICY chat_media_insert_member ON storage.objects
FOR INSERT TO authenticated
WITH CHECK (
  bucket_id = 'chat-media'
  AND EXISTS (
    SELECT 1 FROM public.chat_channels c
    LEFT JOIN public.matches m ON m.id = c.match_id
    LEFT JOIN public.friendships f ON f.id = c.friendship_id
    WHERE c.id::text = (storage.foldername(name))[1]
      AND (
        (c.type = 'match' AND ((SELECT auth.uid()) = m.player1_id OR (SELECT auth.uid()) = m.player2_id))
        OR (c.type = 'friend' AND f.status = 'accepted' AND ((SELECT auth.uid()) = f.requester_id OR (SELECT auth.uid()) = f.addressee_id))
      )
  )
);

DROP POLICY IF EXISTS chat_media_select_member ON storage.objects;
CREATE POLICY chat_media_select_member ON storage.objects
FOR SELECT TO authenticated
USING (
  bucket_id = 'chat-media'
  AND EXISTS (
    SELECT 1 FROM public.chat_channels c
    LEFT JOIN public.matches m ON m.id = c.match_id
    LEFT JOIN public.friendships f ON f.id = c.friendship_id
    WHERE c.id::text = (storage.foldername(name))[1]
      AND (
        (c.type = 'match' AND ((SELECT auth.uid()) = m.player1_id OR (SELECT auth.uid()) = m.player2_id))
        OR (c.type = 'friend' AND f.status = 'accepted' AND ((SELECT auth.uid()) = f.requester_id OR (SELECT auth.uid()) = f.addressee_id))
      )
  )
);
