-- =============================================================================
-- ARENA — Notification « code de salle partagé/mis à jour »
-- =============================================================================
-- Quand l'hôte (domicile = matches.home_player_id) renseigne OU modifie le code
-- de salle (matches.room_code), l'adversaire doit être notifié pour aller taper
-- le code (le bouton flottant overlay l'affiche aussi côté client, cf. feature).
--
-- Trigger AFTER UPDATE OF room_code : insère une ligne `notifications` pour le
-- SEUL adversaire (le joueur qui n'est pas l'hôte). Le webhook dispatch_notif
-- pousse ensuite le FCM (route deep-link `/match/<id>`). SECURITY DEFINER : le
-- joueur hôte n'a pas le droit d'INSERT dans notifications d'autrui, mais le
-- trigger, lui, le peut. Idempotence naturelle : ne notifie que si la valeur
-- CHANGE réellement (is distinct) et n'est pas nulle.
-- =============================================================================

create or replace function public.notify_room_code_shared()
returns trigger
language plpgsql
security definer
set search_path to 'public', 'pg_temp'
as $function$
declare
  v_away   uuid;
  v_action text;
begin
  -- Ne notifier qu'à un vrai changement vers une valeur non nulle (évite les
  -- UPDATE qui touchent room_code sans le modifier, ou une remise à null).
  if NEW.room_code is null
     or NEW.room_code is not distinct from OLD.room_code then
    return NEW;
  end if;

  -- L'adversaire = le joueur assis qui n'est PAS l'hôte.
  v_away := case
    when NEW.home_player_id = NEW.player1_id then NEW.player2_id
    when NEW.home_player_id = NEW.player2_id then NEW.player1_id
    else null
  end;
  if v_away is null then
    return NEW; -- pas d'hôte désigné / pas d'adversaire → rien à notifier.
  end if;

  v_action := case when OLD.room_code is null then 'partagé' else 'mis à jour' end;

  insert into public.notifications (user_id, type, title, body, data)
  values (
    v_away,
    'room_code_shared',
    'Code de salle ' || v_action,
    'Le code de la salle de match est disponible : ' || NEW.room_code,
    jsonb_build_object(
      'notification_type', 'room_code_shared',
      'route', '/match/' || NEW.id::text,
      'match_id', NEW.id::text,
      'room_code', NEW.room_code
    )
  );

  return NEW;
end;
$function$;

drop trigger if exists trg_notify_room_code_shared on public.matches;
create trigger trg_notify_room_code_shared
  after update of room_code on public.matches
  for each row
  execute function public.notify_room_code_shared();
