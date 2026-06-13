-- ════════════════════════════════════════════════════════════════════
-- Clôture automatique des inscriptions quand la compétition est pleine
-- ════════════════════════════════════════════════════════════════════
-- Aujourd'hui, rien ne pose `registration_closed` automatiquement :
--   * single_elimination + auto_generate_bracket : la jauge pleine fait sauter
--     directement la compétition à `ongoing` (génération du bracket) ;
--   * round_robin / groups_then_knockout / auto_generate_bracket=false : la
--     compétition reste `registration_open` À VIE malgré le quota atteint.
--
-- On ajoute un trigger qui passe la compétition de `registration_open` à
-- `registration_closed` dès que le nombre d'inscrits CONFIRMÉS atteint
-- `max_players`. Idempotent (garde `status='registration_open'`), et compatible
-- avec la génération de bracket existante (`trigger_auto_generate_bracket`
-- accepte déjà `status IN (registration_open, registration_closed)`).
--
-- Ordre des triggers AFTER (alphabétique sous Postgres) :
--   trg_registration_player_count  (compteur)
--   tz_close_registrations_*       (CE trigger — pose registration_closed)
--   z_auto_generate_bracket_*      (génère le bracket → ongoing si applicable)
-- ════════════════════════════════════════════════════════════════════

create or replace function public.trigger_close_registrations_when_full()
 returns trigger
 language plpgsql
 security definer
 set search_path to 'public'
as $function$
DECLARE
  v_status      text;
  v_max_players integer;
  v_confirmed   integer;
BEGIN
  SELECT status::text, max_players
    INTO v_status, v_max_players
    FROM competitions
   WHERE id = NEW.competition_id;

  IF NOT FOUND OR v_status <> 'registration_open' THEN
    RETURN NEW;
  END IF;

  -- Recompte EN DIRECT (current_players peut être stale selon l'ordre des
  -- triggers ; on ne dépend pas du compteur).
  SELECT count(*) INTO v_confirmed
    FROM competition_registrations
   WHERE competition_id = NEW.competition_id AND status = 'confirmed';

  IF v_confirmed >= v_max_players THEN
    UPDATE competitions
       SET status = 'registration_closed'::competition_status,
           updated_at = now()
     WHERE id = NEW.competition_id
       AND status = 'registration_open'::competition_status; -- idempotent
  END IF;

  RETURN NEW;
END;
$function$;

drop trigger if exists tz_close_registrations_on_insert on public.competition_registrations;
create trigger tz_close_registrations_on_insert
  after insert on public.competition_registrations
  for each row
  execute function public.trigger_close_registrations_when_full();

drop trigger if exists tz_close_registrations_on_update on public.competition_registrations;
create trigger tz_close_registrations_on_update
  after update on public.competition_registrations
  for each row
  when (old.status is distinct from new.status and new.status = 'confirmed')
  execute function public.trigger_close_registrations_when_full();
