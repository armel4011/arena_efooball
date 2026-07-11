-- ════════════════════════════════════════════════════════════════════
-- Reprogrammation d'une compétition → décalage des matchs programmés
-- ════════════════════════════════════════════════════════════════════
-- BUG : `scheduled_at` du round 1 est calculé UNE fois à la génération du
-- bracket (GREATEST(start_date, now()+5min)). Quand l'admin modifie ensuite
-- `competitions.start_date` (édition d'une compétition PLEINE, bracket déjà
-- généré), les matchs déjà programmés gardent leur ancienne date/heure.
--
-- FIX : un trigger AFTER UPDATE OF start_date décale les matchs NON DÉMARRÉS
-- (pending/scheduled/ready) du MÊME delta que la nouvelle date. Le décalage
-- préserve l'espacement relatif entre les rounds. Les matchs déjà joués /
-- en cours (in_progress, completed, disputed, cancelled…) ne bougent pas.
--
-- Le décalage ne touche que `scheduled_at` (pas `status`) : le trigger de
-- notification de salle (`notify_match_room_activated`) se garde justement
-- contre un simple changement de date (OLD.status='scheduled' → return), donc
-- aucun spam de notifications.
-- ════════════════════════════════════════════════════════════════════

create or replace function public.shift_competition_matches_on_reschedule()
returns trigger
language plpgsql
security definer
set search_path to 'public', 'pg_temp'
as $function$
begin
  update public.matches
     set scheduled_at = scheduled_at + (new.start_date - old.start_date)
   where competition_id = new.id
     and scheduled_at is not null
     and status in ('pending', 'scheduled', 'ready');
  return new;
end;
$function$;

revoke all on function public.shift_competition_matches_on_reschedule() from public;
revoke all on function public.shift_competition_matches_on_reschedule() from anon;
revoke all on function public.shift_competition_matches_on_reschedule() from authenticated;

comment on function public.shift_competition_matches_on_reschedule() is
  'Décale les matchs non démarrés (pending/scheduled/ready) du delta de '
  'start_date quand une compétition est reprogrammée, pour que les dates de '
  'match suivent la nouvelle date de compétition.';

drop trigger if exists trg_shift_matches_on_competition_reschedule on public.competitions;
create trigger trg_shift_matches_on_competition_reschedule
  after update of start_date on public.competitions
  for each row
  when (new.start_date is distinct from old.start_date)
  execute function public.shift_competition_matches_on_reschedule();
