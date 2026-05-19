-- ════════════════════════════════════════════════════════════════════
-- Hard delete d'un chat channel par un membre (item 3 wave D)
-- ════════════════════════════════════════════════════════════════════
-- Test phone 2026-05-19 : "j'ai supprimé la conv mais quand je rouvre
-- avec le même profil, l'historique est toujours là, et la conv ne
-- réapparaît plus dans l'inbox".
--
-- Cause : softDeleteChannel posait juste deleted_at. ensureMatchChannel
-- (et ensureFriendChannel) retrouvaient le MÊME channel par
-- (match_id|friendship_id) → channelMessages stream re-affiche tout.
-- En face, l'inbox filtre par deleted_at IS NULL → la conv reste
-- masquée → expérience cassée.
--
-- Solution : hard delete (sémantique WhatsApp "Supprimer pour tout le
-- monde"). La FK chat_messages.channel_id a ON DELETE CASCADE depuis
-- 20260505100004, donc les messages sont supprimés automatiquement.
-- ensureXxxChannel ne trouvera plus le channel → en créera un nouveau
-- au prochain ouverture → fresh start + conv réapparaît en inbox.
--
-- L'UPDATE policy chat_channels_soft_delete_self (20260519180000)
-- reste en place pour une éventuelle feature future "Supprimer pour
-- moi seulement" (V2).

CREATE POLICY chat_channels_delete_self_member ON public.chat_channels
FOR DELETE TO authenticated
USING (
  (type = 'match' AND EXISTS (
    SELECT 1 FROM matches m
    WHERE m.id = chat_channels.match_id
      AND ((SELECT auth.uid()) = m.player1_id
           OR (SELECT auth.uid()) = m.player2_id)
  ))
  OR (type = 'friend' AND EXISTS (
    SELECT 1 FROM friendships f
    WHERE f.id = chat_channels.friendship_id
      AND ((SELECT auth.uid()) = f.requester_id
           OR (SELECT auth.uid()) = f.addressee_id)
  ))
);
