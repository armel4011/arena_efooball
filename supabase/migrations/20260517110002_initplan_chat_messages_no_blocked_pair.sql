-- Élimine le dernier warning auth_rls_initplan (advisor performance).
-- Wrap les auth.uid() en (SELECT auth.uid()) pour caching planner.
-- (friendships_self_select a déjà été absorbée par 20260517110001)

DROP POLICY IF EXISTS chat_messages_no_blocked_pair ON public.chat_messages;
CREATE POLICY chat_messages_no_blocked_pair ON public.chat_messages
  FOR INSERT TO authenticated
  WITH CHECK (
    NOT EXISTS (
      SELECT 1
      FROM public.chat_channels cc
      JOIN public.matches m ON m.id = cc.match_id
      WHERE cc.id = chat_messages.channel_id
        AND cc.type = 'match'
        AND public.is_blocked_pair(
          (SELECT auth.uid()),
          CASE WHEN m.player1_id = (SELECT auth.uid())
               THEN m.player2_id ELSE m.player1_id END
        )
    )
  );
