-- ════════════════════════════════════════════════════════════════════
-- chat_channel_user_state : sémantique "Supprimer pour moi" (WhatsApp)
-- ════════════════════════════════════════════════════════════════════
-- Test phone 2026-05-19 (user req) : "Prévois que ce n'est pas obligé
-- de supprimer les conversations des deux utilisateurs — un peut
-- supprimer pour lui mais l'autre garde sa conversation".
--
-- Une row par (user, channel) qui track 2 things :
--   - hidden : conv masquée de mon inbox (par-user, peer pas affecté)
--   - cleared_at : timestamp avant lequel les messages sont masqués
--                  pour moi (clearing history par-user)
--
-- Pattern :
--   "Supprimer pour moi" → upsert: hidden=true, cleared_at=now()
--   Re-ouvrir le chat (via ensureXxxChannel) → update: hidden=false
--     (on garde cleared_at pour ne pas re-afficher l'historique)
--   Tap delete à nouveau → upsert: hidden=true, cleared_at=now()
--   Le peer ne voit jamais ces rows (RLS per-user).

CREATE TABLE IF NOT EXISTS public.chat_channel_user_state (
  user_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  channel_id uuid NOT NULL REFERENCES public.chat_channels(id) ON DELETE CASCADE,
  hidden boolean NOT NULL DEFAULT false,
  cleared_at timestamptz,
  updated_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (user_id, channel_id)
);

CREATE INDEX IF NOT EXISTS chat_channel_user_state_user_idx
  ON public.chat_channel_user_state(user_id);
CREATE INDEX IF NOT EXISTS chat_channel_user_state_channel_idx
  ON public.chat_channel_user_state(channel_id);

ALTER TABLE public.chat_channel_user_state ENABLE ROW LEVEL SECURITY;

CREATE POLICY chat_channel_user_state_select_self
  ON public.chat_channel_user_state
  FOR SELECT TO authenticated
  USING (user_id = (SELECT auth.uid()));

CREATE POLICY chat_channel_user_state_insert_self
  ON public.chat_channel_user_state
  FOR INSERT TO authenticated
  WITH CHECK (user_id = (SELECT auth.uid()));

CREATE POLICY chat_channel_user_state_update_self
  ON public.chat_channel_user_state
  FOR UPDATE TO authenticated
  USING (user_id = (SELECT auth.uid()))
  WITH CHECK (user_id = (SELECT auth.uid()));

CREATE POLICY chat_channel_user_state_delete_self
  ON public.chat_channel_user_state
  FOR DELETE TO authenticated
  USING (user_id = (SELECT auth.uid()));

COMMENT ON TABLE public.chat_channel_user_state IS
  'Per-user view state d''une conv : hidden (visibilité inbox), cleared_at (history filter). Pattern WhatsApp "Supprimer pour moi".';
