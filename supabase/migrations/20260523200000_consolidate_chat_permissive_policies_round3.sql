-- Round 3 — Consolide les multiple_permissive_policies restantes
-- signalées par l'advisor performance après audit 2026-05-23 :
--   chat_channels : UPDATE + DELETE
--   chat_messages : UPDATE
-- La logique est strictement équivalente : `policy_a OR policy_b`
-- dans une seule policy. Préserve l'admin override.

-- ============================================================
-- chat_channels : UPDATE (admin OR soft delete par membre)
-- ============================================================
DROP POLICY IF EXISTS chat_channels_soft_delete_self ON public.chat_channels;
DROP POLICY IF EXISTS chat_channels_update_admin    ON public.chat_channels;
CREATE POLICY chat_channels_update ON public.chat_channels
  FOR UPDATE TO public
  USING (
    (SELECT public.is_admin())
    OR (
      (type = 'match' AND EXISTS (
        SELECT 1 FROM public.matches m
        WHERE m.id = chat_channels.match_id
          AND (SELECT auth.uid()) IN (m.player1_id, m.player2_id)
      ))
      OR (type = 'friend' AND EXISTS (
        SELECT 1 FROM public.friendships f
        WHERE f.id = chat_channels.friendship_id
          AND (SELECT auth.uid()) IN (f.requester_id, f.addressee_id)
      ))
    )
  )
  WITH CHECK (
    (SELECT public.is_admin())
    OR (
      (type = 'match' AND EXISTS (
        SELECT 1 FROM public.matches m
        WHERE m.id = chat_channels.match_id
          AND (SELECT auth.uid()) IN (m.player1_id, m.player2_id)
      ))
      OR (type = 'friend' AND EXISTS (
        SELECT 1 FROM public.friendships f
        WHERE f.id = chat_channels.friendship_id
          AND (SELECT auth.uid()) IN (f.requester_id, f.addressee_id)
      ))
    )
  );

-- ============================================================
-- chat_channels : DELETE (admin OR membre du channel)
-- ============================================================
DROP POLICY IF EXISTS chat_channels_delete_admin       ON public.chat_channels;
DROP POLICY IF EXISTS chat_channels_delete_self_member ON public.chat_channels;
CREATE POLICY chat_channels_delete ON public.chat_channels
  FOR DELETE TO public
  USING (
    (SELECT public.is_admin())
    OR (
      (type = 'match' AND EXISTS (
        SELECT 1 FROM public.matches m
        WHERE m.id = chat_channels.match_id
          AND (SELECT auth.uid()) IN (m.player1_id, m.player2_id)
      ))
      OR (type = 'friend' AND EXISTS (
        SELECT 1 FROM public.friendships f
        WHERE f.id = chat_channels.friendship_id
          AND (SELECT auth.uid()) IN (f.requester_id, f.addressee_id)
      ))
    )
  );

-- ============================================================
-- chat_messages : UPDATE (admin OR soft delete par sender)
-- ============================================================
DROP POLICY IF EXISTS chat_messages_soft_delete_self ON public.chat_messages;
DROP POLICY IF EXISTS chat_messages_update_admin    ON public.chat_messages;
CREATE POLICY chat_messages_update ON public.chat_messages
  FOR UPDATE TO public
  USING (
    (SELECT public.is_admin())
    OR sender_id = (SELECT auth.uid())
  )
  WITH CHECK (
    (SELECT public.is_admin())
    OR sender_id = (SELECT auth.uid())
  );
