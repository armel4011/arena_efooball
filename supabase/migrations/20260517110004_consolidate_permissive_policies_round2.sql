-- MIGRATION D — Consolide les 4 tables restantes signalées par
-- multiple_permissive_policies + corrige un bug sémantique sur
-- chat_messages_no_blocked_pair (PERMISSIVE → RESTRICTIVE).

-- ============================================================
-- profiles : INSERT (admin OR self_player conforme)
-- ============================================================
DROP POLICY IF EXISTS profiles_insert_admin ON public.profiles;
DROP POLICY IF EXISTS profiles_self_insert  ON public.profiles;
CREATE POLICY profiles_insert ON public.profiles
  FOR INSERT TO public
  WITH CHECK (
    (SELECT public.is_admin())
    OR (
      (SELECT auth.uid()) = id
      AND role = 'player'::user_role
      AND is_active = true
      AND deleted_at IS NULL
    )
  );

-- ============================================================
-- streams : INSERT + UPDATE consolidés
-- ============================================================
DROP POLICY IF EXISTS streams_insert_admin       ON public.streams;
DROP POLICY IF EXISTS streams_player_insert_self ON public.streams;
CREATE POLICY streams_insert ON public.streams
  FOR INSERT TO public
  WITH CHECK (
    (SELECT public.is_admin())
    OR (
      (SELECT auth.uid()) = player_id
      AND EXISTS (
        SELECT 1 FROM public.matches m
        WHERE m.id = streams.match_id
          AND ((SELECT auth.uid()) IN (m.player1_id, m.player2_id))
      )
    )
  );

DROP POLICY IF EXISTS streams_player_update_own ON public.streams;
DROP POLICY IF EXISTS streams_update_admin      ON public.streams;
CREATE POLICY streams_update ON public.streams
  FOR UPDATE TO public
  USING (
    (SELECT public.is_admin())
    OR (SELECT auth.uid()) = player_id
  )
  WITH CHECK (
    (SELECT public.is_admin())
    OR (
      (SELECT auth.uid()) = player_id
      AND is_public = false
    )
  );

-- ============================================================
-- reintegration_requests : éclate ALL admin + consolide
-- ============================================================
DROP POLICY IF EXISTS reintegration_admin_all   ON public.reintegration_requests;
DROP POLICY IF EXISTS reintegration_self_insert ON public.reintegration_requests;
DROP POLICY IF EXISTS reintegration_self_select ON public.reintegration_requests;

CREATE POLICY reintegration_insert ON public.reintegration_requests
  FOR INSERT TO public
  WITH CHECK (
    (SELECT public.is_admin())
    OR (
      user_id = (SELECT auth.uid())
      AND EXISTS (
        SELECT 1 FROM public.profiles p
        WHERE p.id = (SELECT auth.uid())
          AND p.permanent_ban = true
      )
    )
  );

CREATE POLICY reintegration_select ON public.reintegration_requests
  FOR SELECT TO public
  USING (
    (SELECT public.is_admin())
    OR user_id = (SELECT auth.uid())
  );

CREATE POLICY reintegration_admin_update ON public.reintegration_requests
  FOR UPDATE TO public
  USING ((SELECT public.is_admin())) WITH CHECK ((SELECT public.is_admin()));
CREATE POLICY reintegration_admin_delete ON public.reintegration_requests
  FOR DELETE TO public USING ((SELECT public.is_admin()));

-- ============================================================
-- chat_messages : convertit no_blocked_pair en RESTRICTIVE
-- FIX SÉMANTIQUE — en PERMISSIVE la policy était inactive
-- (PERMISSIVE A OR PERMISSIVE B : un sender légitime passait
-- toujours). RESTRICTIVE applique le NOT EXISTS en plus.
-- ============================================================
DROP POLICY IF EXISTS chat_messages_no_blocked_pair ON public.chat_messages;
CREATE POLICY chat_messages_no_blocked_pair ON public.chat_messages
  AS RESTRICTIVE
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
