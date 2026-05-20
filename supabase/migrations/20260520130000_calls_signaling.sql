-- ════════════════════════════════════════════════════════════════════
-- Signalisation des appels entrants (sonnerie + décrocher / refuser)
-- ════════════════════════════════════════════════════════════════════
-- La table `calls` ne porte QUE la signalisation : qui appelle qui, et
-- l'état de l'appel. Le flux média reste géré par Agora RTC via
-- `get-agora-call-token` (canal `call_<scope>_<scope_id>`) — inchangé.
--
-- Cycle de vie du statut :
--   ringing → accepted   (le destinataire décroche)
--   ringing → declined   (le destinataire refuse)
--   ringing → cancelled  (l'appelant raccroche avant réponse)
--   ringing → missed     (timeout sans réponse)
--   accepted → ended     (un des deux raccroche en cours d'appel)

CREATE TYPE public.call_status AS ENUM
  ('ringing', 'accepted', 'declined', 'cancelled', 'missed', 'ended');

CREATE TABLE public.calls (
  id            uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  scope         text NOT NULL CHECK (scope IN ('friend', 'match')),
  scope_id      uuid NOT NULL,
  caller_id     uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  callee_id     uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  status        public.call_status NOT NULL DEFAULT 'ringing',
  agora_channel text NOT NULL,
  created_at    timestamptz NOT NULL DEFAULT now(),
  answered_at   timestamptz,
  ended_at      timestamptz,
  CONSTRAINT calls_distinct_peers CHECK (caller_id <> callee_id)
);

COMMENT ON TABLE public.calls IS
  'Signalisation des appels 1v1 (sonnerie + décrocher/refuser). Le média passe par Agora RTC.';

-- L''écoute des appels entrants ne lit que les `ringing` du destinataire.
CREATE INDEX idx_calls_callee_ringing ON public.calls(callee_id, created_at DESC)
  WHERE status = 'ringing';
CREATE INDEX idx_calls_caller ON public.calls(caller_id);

ALTER TABLE public.calls ENABLE ROW LEVEL SECURITY;

-- Appelant + destinataire voient leurs appels.
CREATE POLICY calls_select_party ON public.calls FOR SELECT
  USING ((SELECT auth.uid()) IN (caller_id, callee_id));

-- Seul l'appelant crée l'appel, et seulement en tant qu'appelant.
CREATE POLICY calls_insert_caller ON public.calls FOR INSERT
  WITH CHECK ((SELECT auth.uid()) = caller_id);

-- Appelant + destinataire peuvent faire évoluer le statut.
CREATE POLICY calls_update_party ON public.calls FOR UPDATE
  USING ((SELECT auth.uid()) IN (caller_id, callee_id))
  WITH CHECK ((SELECT auth.uid()) IN (caller_id, callee_id));

-- Realtime : le client écoute les INSERT (appel entrant) + UPDATE (statut).
ALTER PUBLICATION supabase_realtime ADD TABLE public.calls;
