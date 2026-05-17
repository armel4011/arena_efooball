-- Consolide les policies PERMISSIVE redondantes signalées par
-- multiple_permissive_policies (advisor performance). La logique
-- est strictement équivalente : `policy_a OR policy_b` dans une
-- seule policy.

-- chat_channels : INSERT (admin OR player propriétaire du match)
DROP POLICY IF EXISTS chat_channels_insert_admin           ON public.chat_channels;
DROP POLICY IF EXISTS chat_channels_player_insert_match    ON public.chat_channels;
CREATE POLICY chat_channels_insert ON public.chat_channels
  FOR INSERT TO public
  WITH CHECK (
    (SELECT public.is_admin())
    OR (
      type = 'match' AND match_id IS NOT NULL
      AND EXISTS (
        SELECT 1 FROM public.matches m
        WHERE m.id = chat_channels.match_id
          AND ((SELECT auth.uid()) IN (m.player1_id, m.player2_id))
      )
    )
  );

-- competition_registrations : INSERT (admin OR self gratuit confirmé)
DROP POLICY IF EXISTS registrations_free_self_insert ON public.competition_registrations;
DROP POLICY IF EXISTS registrations_insert_admin     ON public.competition_registrations;
CREATE POLICY registrations_insert ON public.competition_registrations
  FOR INSERT TO public
  WITH CHECK (
    (SELECT public.is_admin())
    OR (
      (SELECT auth.uid()) = player_id
      AND status = 'confirmed' AND payment_id IS NULL
      AND EXISTS (
        SELECT 1 FROM public.competitions c
        WHERE c.id = competition_registrations.competition_id
          AND c.registration_fee = 0::numeric
      )
    )
  );

-- match_events : INSERT (admin OR player owner du match)
DROP POLICY IF EXISTS match_events_insert_admin   ON public.match_events;
DROP POLICY IF EXISTS match_events_player_insert  ON public.match_events;
CREATE POLICY match_events_insert ON public.match_events
  FOR INSERT TO public
  WITH CHECK (
    (SELECT public.is_admin())
    OR (
      (SELECT auth.uid()) = created_by
      AND EXISTS (
        SELECT 1 FROM public.matches m
        WHERE m.id = match_events.match_id
          AND ((SELECT auth.uid()) IN (m.player1_id, m.player2_id))
      )
    )
  );

-- matches : UPDATE (admin OR player1 OR player2)
DROP POLICY IF EXISTS matches_player_update ON public.matches;
DROP POLICY IF EXISTS matches_update_admin  ON public.matches;
CREATE POLICY matches_update ON public.matches
  FOR UPDATE TO public
  USING (
    (SELECT public.is_admin())
    OR (SELECT auth.uid()) IN (player1_id, player2_id)
  )
  WITH CHECK (
    (SELECT public.is_admin())
    OR (SELECT auth.uid()) IN (player1_id, player2_id)
  );

-- friendships : éclate "ALL admin" + consolide SELECT
-- Les INSERT/UPDATE/DELETE non-admin transitent par les RPC
-- SECURITY DEFINER (send_friend_request, accept_friend_request, ...)
DROP POLICY IF EXISTS friendships_admin_all   ON public.friendships;
DROP POLICY IF EXISTS friendships_self_select ON public.friendships;
CREATE POLICY friendships_select ON public.friendships
  FOR SELECT TO authenticated
  USING (
    (SELECT public.is_admin())
    OR (SELECT auth.uid()) IN (requester_id, addressee_id)
  );
CREATE POLICY friendships_admin_insert ON public.friendships
  FOR INSERT TO authenticated WITH CHECK ((SELECT public.is_admin()));
CREATE POLICY friendships_admin_update ON public.friendships
  FOR UPDATE TO authenticated
  USING ((SELECT public.is_admin())) WITH CHECK ((SELECT public.is_admin()));
CREATE POLICY friendships_admin_delete ON public.friendships
  FOR DELETE TO authenticated USING ((SELECT public.is_admin()));
