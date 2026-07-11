-- ════════════════════════════════════════════════════════════════════
-- Reprogrammation : plancher les matchs à « maintenant + 5 min »
-- ════════════════════════════════════════════════════════════════════
-- Complète 20260711140000 : le décalage du delta pouvait placer un match dans
-- le PASSÉ si l'admin reprogramme à une date antérieure. On plancher désormais
-- chaque match décalé à `now() + 5 min` via GREATEST.
--
-- Décalage vers le FUTUR : `scheduled_at + delta` est déjà > now()+5min →
-- GREATEST le garde tel quel (delta pur, espacement préservé). Seuls les matchs
-- qui tomberaient dans le passé sont remontés à maintenant+5min (choix produit ;
-- si plusieurs rounds tombent dans le passé, ils se retrouvent à la même heure).
-- ════════════════════════════════════════════════════════════════════

create or replace function public.shift_competition_matches_on_reschedule()
returns trigger
language plpgsql
security definer
set search_path to 'public', 'pg_temp'
as $function$
begin
  update public.matches
     set scheduled_at = greatest(
           scheduled_at + (new.start_date - old.start_date),
           now() + interval '5 minutes'
         )
   where competition_id = new.id
     and scheduled_at is not null
     and status in ('pending', 'scheduled', 'ready');
  return new;
end;
$function$;

comment on function public.shift_competition_matches_on_reschedule() is
  'Décale les matchs non démarrés (pending/scheduled/ready) du delta de '
  'start_date quand une compétition est reprogrammée, planché à maintenant+5min '
  'pour ne jamais programmer un match dans le passé.';
