-- ════════════════════════════════════════════════════════════════════
-- chat_channel_user_state.last_read_at : badge messages non-lus
-- ════════════════════════════════════════════════════════════════════
-- Test phone 2026-05-19 (user req) : "il faut signaler les utilisateurs
-- des nouveaux messages et le nombre de nouveaux messages dans la
-- conversation".
--
-- Compte des non-lus côté client :
--   COUNT messages WHERE channel_id = X
--     AND sender_id != me
--     AND created_at > my last_read_at (NULL = lu jamais → tous comptent)
--
-- Quand user ouvre la chat page → markChannelAsRead → upsert
-- last_read_at = now() → badge disparaît.

ALTER TABLE public.chat_channel_user_state
  ADD COLUMN IF NOT EXISTS last_read_at timestamptz;

CREATE INDEX IF NOT EXISTS chat_channel_user_state_last_read_at_idx
  ON public.chat_channel_user_state(user_id, channel_id, last_read_at);

COMMENT ON COLUMN public.chat_channel_user_state.last_read_at IS
  'Timestamp du dernier message lu par cet utilisateur dans ce channel. Les messages dont created_at > last_read_at ET sender_id != user_id comptent comme non-lus.';
