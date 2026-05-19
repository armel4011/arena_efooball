-- ════════════════════════════════════════════════════════════════════
-- Chat extension : médias + friend channels + soft-delete
-- ════════════════════════════════════════════════════════════════════
-- Audit 2026-05-19 — item 3 du prompt : amène le chat au niveau
-- WhatsApp/Messenger. Schéma changes :
--   1. chat_channels.type accepte 'friend' (en plus de match/broadcast/admin)
--   2. chat_channels.friendship_id uuid → references friendships
--   3. chat_channels.deleted_at timestamptz (soft-delete conversation côté user)
--   4. chat_messages.media_url text (URL Storage signed)
--   5. chat_messages.media_type text (image/video/audio)
--   6. chat_messages.deleted_at timestamptz (soft-delete message côté user)
--   7. RPC ensure_friend_channel(p_friendship_id uuid) — get-or-create
--   8. RLS extension : chat_messages_select couvre friend channels
--   9. RLS UPDATE : sender peut soft-delete son msg, membre peut soft-delete sa conv

-- ─── 1. chat_channels : enum + friendship_id + deleted_at ───────────

ALTER TABLE public.chat_channels
  DROP CONSTRAINT IF EXISTS chat_channels_type_check;

ALTER TABLE public.chat_channels
  ADD CONSTRAINT chat_channels_type_check CHECK (type IN (
    'match',
    'competition_broadcast',
    'admin_user',
    'global',
    'friend'
  ));

ALTER TABLE public.chat_channels
  ADD COLUMN IF NOT EXISTS friendship_id uuid
    REFERENCES public.friendships(id) ON DELETE CASCADE;

ALTER TABLE public.chat_channels
  ADD COLUMN IF NOT EXISTS deleted_at timestamptz;

-- Cohérence : un friend channel DOIT avoir friendship_id, et c'est le
-- seul cas où friendship_id est non-null.
ALTER TABLE public.chat_channels
  DROP CONSTRAINT IF EXISTS chat_channels_check;

ALTER TABLE public.chat_channels
  ADD CONSTRAINT chat_channels_coherence_check CHECK (
    (type = 'match' AND match_id IS NOT NULL AND friendship_id IS NULL)
    OR (type = 'competition_broadcast' AND competition_id IS NOT NULL AND friendship_id IS NULL)
    OR (type IN ('admin_user', 'global') AND friendship_id IS NULL)
    OR (type = 'friend' AND friendship_id IS NOT NULL
        AND match_id IS NULL AND competition_id IS NULL)
  );

CREATE UNIQUE INDEX IF NOT EXISTS chat_channels_friendship_uniq
  ON public.chat_channels(friendship_id)
  WHERE type = 'friend';

-- ─── 2. chat_messages : media + deleted_at ──────────────────────────

ALTER TABLE public.chat_messages
  ADD COLUMN IF NOT EXISTS media_url text;

ALTER TABLE public.chat_messages
  ADD COLUMN IF NOT EXISTS media_type text
    CHECK (media_type IS NULL OR media_type IN ('image', 'video', 'audio'));

ALTER TABLE public.chat_messages
  ADD COLUMN IF NOT EXISTS deleted_at timestamptz;

-- Relax la contrainte `content` 1-2000 : un message media peut avoir
-- content vide (la légende est optionnelle).
ALTER TABLE public.chat_messages
  DROP CONSTRAINT IF EXISTS chat_messages_content_check;

ALTER TABLE public.chat_messages
  ADD CONSTRAINT chat_messages_content_check CHECK (
    -- Soit un media (content vide OK), soit du texte (1-2000 chars)
    (media_url IS NOT NULL AND length(content) BETWEEN 0 AND 2000)
    OR (media_url IS NULL AND length(content) BETWEEN 1 AND 2000)
  );

-- ─── 3. RPC ensure_friend_channel ───────────────────────────────────
-- Get-or-create un channel type='friend' pour la friendship donnée.
-- Authorization : le caller doit être l'un des 2 membres de la
-- friendship + status='accepted'.

CREATE OR REPLACE FUNCTION public.ensure_friend_channel(p_friendship_id uuid)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_uid uuid := auth.uid();
  v_channel_id uuid;
BEGIN
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'not_authenticated' USING ERRCODE = 'P0001';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM friendships
    WHERE id = p_friendship_id
      AND status = 'accepted'
      AND (requester_id = v_uid OR addressee_id = v_uid)
  ) THEN
    RAISE EXCEPTION 'not_a_friend' USING ERRCODE = 'P0001';
  END IF;

  SELECT id INTO v_channel_id FROM chat_channels
   WHERE type = 'friend' AND friendship_id = p_friendship_id;

  IF v_channel_id IS NULL THEN
    INSERT INTO chat_channels (type, friendship_id)
    VALUES ('friend', p_friendship_id)
    RETURNING id INTO v_channel_id;
  END IF;

  RETURN v_channel_id;
END;
$$;

REVOKE ALL ON FUNCTION public.ensure_friend_channel(uuid) FROM public, anon;
GRANT EXECUTE ON FUNCTION public.ensure_friend_channel(uuid) TO authenticated;

COMMENT ON FUNCTION public.ensure_friend_channel(uuid) IS
  '[SECURITY DEFINER intentional] User RPC. Get-or-create chat_channels(type=friend) pour une friendship. Authorization: caller doit etre membre de la friendship et status=accepted.';

-- ─── 4. RLS chat_messages_select : extend friend channels ───────────

DROP POLICY IF EXISTS chat_messages_select ON public.chat_messages;

CREATE POLICY chat_messages_select ON public.chat_messages
FOR SELECT
USING (
  (SELECT is_admin())
  OR EXISTS (
    SELECT 1
    FROM chat_channels c
    LEFT JOIN matches m ON m.id = c.match_id
    LEFT JOIN friendships f ON f.id = c.friendship_id
    WHERE c.id = chat_messages.channel_id
      AND (
        c.type IN ('competition_broadcast', 'global')
        OR (c.type = 'match' AND (
          (SELECT auth.uid()) = m.player1_id OR (SELECT auth.uid()) = m.player2_id
        ))
        OR (c.type = 'friend' AND f.status = 'accepted' AND (
          (SELECT auth.uid()) = f.requester_id OR (SELECT auth.uid()) = f.addressee_id
        ))
      )
  )
);

-- ─── 5. RLS chat_channels_insert : extend friend channels ───────────
-- L'INSERT direct côté Flutter pour les friend channels est BLOQUÉ —
-- on force le passage par RPC ensure_friend_channel (security definer)
-- qui valide friendship.status. Mais on doit aussi laisser passer le
-- match channel direct (existant) sans casser.

DROP POLICY IF EXISTS chat_channels_insert ON public.chat_channels;

CREATE POLICY chat_channels_insert ON public.chat_channels
FOR INSERT
WITH CHECK (
  (SELECT is_admin())
  OR (
    type = 'match' AND match_id IS NOT NULL AND EXISTS (
      SELECT 1 FROM matches m
      WHERE m.id = chat_channels.match_id
        AND ((SELECT auth.uid()) = m.player1_id OR (SELECT auth.uid()) = m.player2_id)
    )
  )
);

-- ─── 6. RLS chat_messages_update : sender peut soft-delete son msg ─

CREATE POLICY chat_messages_soft_delete_self ON public.chat_messages
FOR UPDATE
USING (sender_id = (SELECT auth.uid()))
WITH CHECK (sender_id = (SELECT auth.uid()));

-- ─── 7. RLS chat_channels_update : member peut soft-delete sa conv ─

CREATE POLICY chat_channels_soft_delete_self ON public.chat_channels
FOR UPDATE
USING (
  (
    type = 'match' AND EXISTS (
      SELECT 1 FROM matches m
      WHERE m.id = chat_channels.match_id
        AND ((SELECT auth.uid()) = m.player1_id OR (SELECT auth.uid()) = m.player2_id)
    )
  )
  OR (
    type = 'friend' AND EXISTS (
      SELECT 1 FROM friendships f
      WHERE f.id = chat_channels.friendship_id
        AND ((SELECT auth.uid()) = f.requester_id OR (SELECT auth.uid()) = f.addressee_id)
    )
  )
)
WITH CHECK (
  -- Même check qu'au USING : empêche de pousser le channel hors de sa
  -- membership courante.
  (
    type = 'match' AND EXISTS (
      SELECT 1 FROM matches m
      WHERE m.id = chat_channels.match_id
        AND ((SELECT auth.uid()) = m.player1_id OR (SELECT auth.uid()) = m.player2_id)
    )
  )
  OR (
    type = 'friend' AND EXISTS (
      SELECT 1 FROM friendships f
      WHERE f.id = chat_channels.friendship_id
        AND ((SELECT auth.uid()) = f.requester_id OR (SELECT auth.uid()) = f.addressee_id)
    )
  )
);

COMMENT ON COLUMN public.chat_messages.media_url IS
  'URL Storage (bucket chat-media) — null si message texte pur.';
COMMENT ON COLUMN public.chat_messages.media_type IS
  'image / video / audio (NULL pour texte).';
COMMENT ON COLUMN public.chat_messages.deleted_at IS
  'Soft delete par sender — UI affiche "Message supprime" placeholder.';
COMMENT ON COLUMN public.chat_channels.deleted_at IS
  'Soft delete par membre — UI masque cette conversation de son inbox.';
COMMENT ON COLUMN public.chat_channels.friendship_id IS
  'Reference friendship pour les channels type=friend (1-on-1 amis).';
