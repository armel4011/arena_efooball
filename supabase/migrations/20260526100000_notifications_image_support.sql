-- F2 : Support des images dans les notifications push
--
-- 1. Colonne `image_url` sur public.notifications (text, nullable) — URL
--    publique d'une image hostée dans le bucket notification_images.
--    Stocké top-level (pas dans data jsonb) pour faciliter le passage
--    au payload FCM v1 par l'EF dispatch_notification.
--
-- 2. Bucket Storage `notification_images` : public READ (pour que les
--    serveurs FCM puissent fetcher l'image), INSERT/UPDATE/DELETE
--    reserves aux admins (is_admin()) — pas de write user.
--
-- Pas de breaking change : la colonne est nullable, l'EF gere null en
-- passant juste un payload texte comme aujourd'hui.

ALTER TABLE public.notifications
  ADD COLUMN IF NOT EXISTS image_url TEXT;

COMMENT ON COLUMN public.notifications.image_url IS
  'Optional public URL of a notification image (FCM v1 notification.image). '
  'Hosted in the notification_images Storage bucket.';

-- Bucket public-read.
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'notification_images',
  'notification_images',
  TRUE,
  5 * 1024 * 1024,
  ARRAY['image/png', 'image/jpeg', 'image/webp', 'image/gif']
)
ON CONFLICT (id) DO UPDATE
  SET public = EXCLUDED.public,
      file_size_limit = EXCLUDED.file_size_limit,
      allowed_mime_types = EXCLUDED.allowed_mime_types;

-- RLS storage.objects pour ce bucket.
-- READ public (le bucket est marque public=true, mais on garde une
-- policy explicite SELECT pour la coherence audit).
CREATE POLICY "notification_images_public_read"
  ON storage.objects FOR SELECT
  TO anon, authenticated
  USING (bucket_id = 'notification_images');

-- WRITE admin uniquement (INSERT / UPDATE / DELETE).
CREATE POLICY "notification_images_admin_insert"
  ON storage.objects FOR INSERT
  TO authenticated
  WITH CHECK (
    bucket_id = 'notification_images'
    AND public.is_admin(auth.uid())
  );

CREATE POLICY "notification_images_admin_update"
  ON storage.objects FOR UPDATE
  TO authenticated
  USING (
    bucket_id = 'notification_images'
    AND public.is_admin(auth.uid())
  );

CREATE POLICY "notification_images_admin_delete"
  ON storage.objects FOR DELETE
  TO authenticated
  USING (
    bucket_id = 'notification_images'
    AND public.is_admin(auth.uid())
  );
