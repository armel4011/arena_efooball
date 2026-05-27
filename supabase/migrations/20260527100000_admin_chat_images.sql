-- F4.b : images + caption dans le chat admin -> user (style WhatsApp)
--
-- - `text` devient NULLABLE : un message peut etre image-only.
-- - `image_url` : URL publique d'une image hostee dans le bucket
--   `notification_images` (reutilise — meme RLS admin-write/public-read,
--   sous prefixe `admin_chat/<adminId>/...`).
-- - `caption` : texte optionnel sous l'image (<=1024 chars, style
--   WhatsApp).
-- - CHECK : au moins un des deux (texte ou image) doit etre present.
-- - Trigger _notify_admin_message adapte pour generer un preview
--   correct dans le push FCM quand le message est image-only ou a une
--   caption.

ALTER TABLE public.admin_chat_messages
  ALTER COLUMN text DROP NOT NULL;

ALTER TABLE public.admin_chat_messages
  ADD COLUMN IF NOT EXISTS image_url TEXT,
  ADD COLUMN IF NOT EXISTS caption   TEXT;

ALTER TABLE public.admin_chat_messages
  ADD CONSTRAINT admin_chat_messages_caption_length
  CHECK (caption IS NULL OR length(caption) BETWEEN 1 AND 1024);

ALTER TABLE public.admin_chat_messages
  ADD CONSTRAINT admin_chat_messages_text_or_image
  CHECK (text IS NOT NULL OR image_url IS NOT NULL);

COMMENT ON COLUMN public.admin_chat_messages.image_url IS
  'Optional public URL of an image attached to this message. Hosted in '
  'the notification_images Storage bucket under admin_chat/<adminId>/.';
COMMENT ON COLUMN public.admin_chat_messages.caption IS
  'Optional caption shown under the image (WhatsApp-style, <=1024 chars).';

-- Adapte le preview FCM pour les messages image-only / avec caption.
CREATE OR REPLACE FUNCTION public._notify_admin_message()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  admin_name TEXT;
  preview    TEXT;
BEGIN
  SELECT username INTO admin_name
  FROM public.profiles
  WHERE id = NEW.admin_id;

  -- Ordre de priorite pour le preview push :
  --  1. caption si presente (souvent + descriptive que le texte court)
  --  2. text si present
  --  3. label generique "Image" si message image-only
  IF NEW.caption IS NOT NULL AND length(NEW.caption) > 0 THEN
    preview := SUBSTRING(NEW.caption FROM 1 FOR 120);
  ELSIF NEW.text IS NOT NULL AND length(NEW.text) > 0 THEN
    preview := SUBSTRING(NEW.text FROM 1 FOR 120);
  ELSIF NEW.image_url IS NOT NULL THEN
    preview := 'Image';
  ELSE
    preview := '';
  END IF;

  INSERT INTO public.notifications (
    user_id, type, title, body, image_url, data
  )
  VALUES (
    NEW.recipient_id,
    'admin_message',
    COALESCE(admin_name, 'Equipe ARENA'),
    preview,
    NEW.image_url,
    jsonb_build_object(
      'admin_message_id', NEW.id::text,
      'admin_id', NEW.admin_id::text,
      'route', '/admin-messages'
    )
  );

  RETURN NEW;
END;
$$;
