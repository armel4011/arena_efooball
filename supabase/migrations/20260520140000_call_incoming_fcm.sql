-- ════════════════════════════════════════════════════════════════════
-- Lot 3 — Sonnerie d'appel en arrière-plan (FCM)
-- ════════════════════════════════════════════════════════════════════
-- Quand un appel passe en `ringing`, on insère une notification de type
-- `call_invite` pour le destinataire. La webhook `notifications`
-- existante la pousse alors en FCM (`dispatch_notification` détecte le
-- type `call_invite` et envoie un message DATA haute priorité), ce qui
-- réveille l'app et fait sonner l'écran d'appel — même app fermée.

CREATE OR REPLACE FUNCTION public.notify_incoming_call()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
  v_caller_name text;
BEGIN
  IF NEW.status <> 'ringing' THEN
    RETURN NEW;
  END IF;

  SELECT username INTO v_caller_name
    FROM public.profiles WHERE id = NEW.caller_id;
  v_caller_name := COALESCE(v_caller_name, 'Quelqu''un');

  INSERT INTO public.notifications (user_id, type, title, body, data)
  VALUES (
    NEW.callee_id,
    'call_invite',
    'Appel entrant',
    v_caller_name || ' vous appelle',
    jsonb_build_object(
      'call_id',     NEW.id,
      'scope',       NEW.scope,
      'scope_id',    NEW.scope_id,
      'caller_id',   NEW.caller_id,
      'caller_name', v_caller_name
    )
  );
  RETURN NEW;
END;
$$;

COMMENT ON FUNCTION public.notify_incoming_call() IS
  'Lot 3 appels — insère une notification call_invite (→ FCM via webhook) '
  'quand un appel sonne.';

DROP TRIGGER IF EXISTS trg_notify_incoming_call ON public.calls;
CREATE TRIGGER trg_notify_incoming_call
  AFTER INSERT ON public.calls
  FOR EACH ROW
  EXECUTE FUNCTION public.notify_incoming_call();
