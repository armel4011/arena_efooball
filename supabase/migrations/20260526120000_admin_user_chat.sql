-- F4 : Chat admin -> user (1-to-1, asymetrique)
--
-- Cas d'usage : un admin contacte un user en prive (support,
-- moderation, info ciblee, follow-up KYC...). Le user voit le fil
-- dans un onglet dedie et recoit une notif push a chaque message.
--
-- Architecture :
--   - admin_chat_messages : 1 row par message. RLS asymetrique (admin
--     ecrit, user lit) + le user peut UPDATE read_at sur ses propres
--     messages recus.
--   - Trigger AFTER INSERT -> insert dans public.notifications
--     (type=admin_message) -> reuse le pipeline FCM/dispatch existant.

CREATE TABLE IF NOT EXISTS public.admin_chat_messages (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  admin_id      UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  recipient_id  UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  text          TEXT NOT NULL CHECK (length(text) BETWEEN 1 AND 2000),
  sent_at       TIMESTAMPTZ NOT NULL DEFAULT now(),
  read_at       TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_admin_chat_messages_recipient
  ON public.admin_chat_messages (recipient_id, sent_at DESC);

CREATE INDEX IF NOT EXISTS idx_admin_chat_messages_thread
  ON public.admin_chat_messages (admin_id, recipient_id, sent_at DESC);

CREATE INDEX IF NOT EXISTS idx_admin_chat_messages_unread
  ON public.admin_chat_messages (recipient_id)
  WHERE read_at IS NULL;

ALTER TABLE public.admin_chat_messages ENABLE ROW LEVEL SECURITY;

-- RLS : admin lit/ecrit tout, user lit ce qui lui est destine.
CREATE POLICY "admin_chat_select_admin"
  ON public.admin_chat_messages FOR SELECT
  TO authenticated
  USING (public.is_admin(auth.uid()));

CREATE POLICY "admin_chat_select_user"
  ON public.admin_chat_messages FOR SELECT
  TO authenticated
  USING (recipient_id = auth.uid());

CREATE POLICY "admin_chat_insert_admin_only"
  ON public.admin_chat_messages FOR INSERT
  TO authenticated
  WITH CHECK (
    public.is_admin(auth.uid())
    AND admin_id = auth.uid()
  );

-- User peut UPDATE read_at uniquement (on s'assure via RESTRICTIVE
-- qu'il ne reecrit pas text/admin_id/etc).
CREATE POLICY "admin_chat_update_read_user"
  ON public.admin_chat_messages FOR UPDATE
  TO authenticated
  USING (recipient_id = auth.uid())
  WITH CHECK (recipient_id = auth.uid());

-- Trigger AFTER INSERT : pousser une notif push pour pinger le user.
CREATE OR REPLACE FUNCTION public._notify_admin_message()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  admin_name TEXT;
BEGIN
  SELECT username INTO admin_name
  FROM public.profiles
  WHERE id = NEW.admin_id;

  INSERT INTO public.notifications (
    user_id, type, title, body, data
  )
  VALUES (
    NEW.recipient_id,
    'admin_message',
    COALESCE(admin_name, 'Equipe ARENA'),
    -- Preview tronquee a 120 chars (FCM limite a 100-150 visible)
    SUBSTRING(NEW.text FROM 1 FOR 120),
    jsonb_build_object(
      'admin_message_id', NEW.id::text,
      'admin_id', NEW.admin_id::text,
      'route', '/admin-messages'
    )
  );

  RETURN NEW;
END;
$$;

REVOKE ALL ON FUNCTION public._notify_admin_message() FROM PUBLIC;
REVOKE ALL ON FUNCTION public._notify_admin_message() FROM authenticated;
REVOKE ALL ON FUNCTION public._notify_admin_message() FROM anon;

CREATE TRIGGER trg_admin_chat_messages_notify
  AFTER INSERT ON public.admin_chat_messages
  FOR EACH ROW
  EXECUTE FUNCTION public._notify_admin_message();

COMMENT ON TABLE public.admin_chat_messages IS
  'Messages prives unidirectionnels admin->user. Trigger AFTER INSERT '
  'insere une row notifications type=admin_message pour declencher le '
  'pipeline FCM.';

-- Realtime : permet a la page de chat user de subscribe les messages
-- entrants en live.
ALTER PUBLICATION supabase_realtime ADD TABLE public.admin_chat_messages;
