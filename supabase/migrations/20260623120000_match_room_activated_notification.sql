-- ════════════════════════════════════════════════════════════════════
-- Notification + alerte sonore à l'ACTIVATION de la salle de match.
-- ════════════════════════════════════════════════════════════════════
-- Problème : quand la salle de match d'un joueur devient jouable, aucun
-- push ni sonnerie n'arrivait de façon fiable (le rappel T-5 du cron
-- `_dispatch_match_reminders` dépend du scheduling et a jusqu'à 60 s de
-- latence).
--
-- Correctif : dès qu'un match devient JOUABLE MAINTENANT — status
-- 'scheduled' avec un `scheduled_at` imminent (≤ 6 min) — chaque joueur
-- reçoit immédiatement une notif `type='call_invite'`. L'infra existante
-- (trigger notifications → Edge `dispatch_notification` → FCM data-only /
-- APNs VoIP → CallKit) déclenche alors une sonnerie plein écran.
--
-- Idempotence / pas de doublon avec le cron : on RÉUTILISE le ledger
-- `match_reminders_sent` avec kind='t5'. Le premier des deux (ce trigger
-- ou le cron T-5) qui passe pose la ligne ; l'autre est neutralisé par
-- `ON CONFLICT DO NOTHING`.
--
-- On NE déclenche PAS sur 'in_progress' : à ce moment les deux joueurs
-- sont déjà dans la salle (cf. gate de présence dames) → une sonnerie
-- plein écran serait intrusive.

CREATE OR REPLACE FUNCTION public.notify_match_room_activated()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_p1_name text;
  v_p2_name text;
BEGIN
  -- Garde-fous : match à 2 joueurs, programmé, imminent.
  IF NEW.status::text <> 'scheduled'
     OR NEW.player1_id IS NULL OR NEW.player2_id IS NULL
     OR NEW.scheduled_at IS NULL
     OR NEW.scheduled_at > now() + interval '6 minutes' THEN
    RETURN NEW;
  END IF;

  -- Sur UPDATE : ne rien faire si le match était déjà 'scheduled' (on ne
  -- re-notifie pas un simple changement de colonne annexe ou de date).
  IF TG_OP = 'UPDATE' AND OLD.status::text = 'scheduled' THEN
    RETURN NEW;
  END IF;

  SELECT username INTO v_p1_name FROM public.profiles WHERE id = NEW.player1_id;
  SELECT username INTO v_p2_name FROM public.profiles WHERE id = NEW.player2_id;

  -- Joueur 1 (adversaire = p2)
  INSERT INTO public.match_reminders_sent (match_id, player_id, kind)
  VALUES (NEW.id, NEW.player1_id, 't5')
  ON CONFLICT DO NOTHING;
  IF FOUND THEN
    INSERT INTO public.notifications (user_id, type, title, body, data)
    VALUES (
      NEW.player1_id,
      'call_invite',
      'Ta salle de match est ouverte',
      'Match contre ' || COALESCE(v_p2_name, '?') || ' — rejoins maintenant !',
      jsonb_build_object(
        'call_id', NEW.id::text,
        'caller_name', 'Salle de match',
        'scope', 'match_activated',
        'scope_id', NEW.id::text,
        'caller_id', COALESCE(NEW.player2_id::text, ''),
        'route', '/matches/' || NEW.id::text
      )
    );
  END IF;

  -- Joueur 2 (adversaire = p1)
  INSERT INTO public.match_reminders_sent (match_id, player_id, kind)
  VALUES (NEW.id, NEW.player2_id, 't5')
  ON CONFLICT DO NOTHING;
  IF FOUND THEN
    INSERT INTO public.notifications (user_id, type, title, body, data)
    VALUES (
      NEW.player2_id,
      'call_invite',
      'Ta salle de match est ouverte',
      'Match contre ' || COALESCE(v_p1_name, '?') || ' — rejoins maintenant !',
      jsonb_build_object(
        'call_id', NEW.id::text,
        'caller_name', 'Salle de match',
        'scope', 'match_activated',
        'scope_id', NEW.id::text,
        'caller_id', COALESCE(NEW.player1_id::text, ''),
        'route', '/matches/' || NEW.id::text
      )
    );
  END IF;

  RETURN NEW;
END;
$$;

REVOKE ALL ON FUNCTION public.notify_match_room_activated() FROM PUBLIC;
REVOKE ALL ON FUNCTION public.notify_match_room_activated() FROM anon;
REVOKE ALL ON FUNCTION public.notify_match_room_activated() FROM authenticated;

COMMENT ON FUNCTION public.notify_match_room_activated() IS
  'Alerte sonore (call_invite) immédiate aux 2 joueurs quand leur match '
  'devient jouable maintenant (scheduled + scheduled_at ≤ 6 min). '
  'Réutilise le ledger match_reminders_sent (kind t5) pour ne pas doubler '
  'le cron _dispatch_match_reminders.';

-- Round 1 d'un tournoi lancé : les matchs sont créés directement en
-- 'scheduled' (INSERT), d'où le trigger AFTER INSERT.
DROP TRIGGER IF EXISTS trg_notify_match_room_activated_ins ON public.matches;
CREATE TRIGGER trg_notify_match_room_activated_ins
  AFTER INSERT ON public.matches
  FOR EACH ROW
  EXECUTE FUNCTION public.notify_match_room_activated();

-- Rounds suivants : passage pending → scheduled (UPDATE) par
-- try_schedule_next_round.
DROP TRIGGER IF EXISTS trg_notify_match_room_activated_upd ON public.matches;
CREATE TRIGGER trg_notify_match_room_activated_upd
  AFTER UPDATE OF status, scheduled_at ON public.matches
  FOR EACH ROW
  WHEN (NEW.status::text = 'scheduled')
  EXECUTE FUNCTION public.notify_match_room_activated();
