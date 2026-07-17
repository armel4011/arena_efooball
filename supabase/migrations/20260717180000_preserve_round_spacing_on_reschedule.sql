-- ════════════════════════════════════════════════════════════════════
-- Reprogrammation en arrière : préserver l'espacement des rounds
-- ════════════════════════════════════════════════════════════════════
-- BUG (latent depuis 20260711150000). Le plancher était appliqué match PAR
-- match : `greatest(scheduled_at + delta, now() + 5 min)`. Quand l'admin
-- reprogramme une compétition vers une date assez antérieure, PLUSIEURS rounds
-- tombent dans le passé après décalage — et `greatest` les écrase alors TOUS
-- sur la même valeur, `now() + 5 min`.
--
-- Exemple : rounds à J+10, J+11, J+12 ; start_date reprogrammée à J-1
-- (delta = -11 j) → rounds décalés à J-1, J0, J+1. Les deux premiers sont dans
-- le passé → planchés tous les deux à now()+5min. Le round 1 et le round 2 se
-- retrouvent à la MÊME heure, alors que le round 2 ne peut par construction se
-- jouer qu'une fois le round 1 terminé (ses joueurs en sont les vainqueurs).
-- La grille devient injouable, en silence.
--
-- FIX : le plancher devient un décalage UNIFORME. On calcule le match décalé le
-- plus précoce ; s'il tombe sous `now() + 5 min`, on relève TOUS les matchs du
-- même complément (`v_lift`). L'espacement relatif entre rounds est ainsi
-- préservé exactement — ce que 20260711140000 annonçait déjà comme principe et
-- que le `greatest` par ligne cassait.
--
-- Conséquence assumée : reprogrammer en arrière ne rapproche pas la grille plus
-- que le plancher ne l'autorise ; elle glisse en bloc et garde sa forme. Un
-- décalage vers le futur (ou vers un passé qui laisse tout le monde au-dessus
-- du plancher) a `v_lift = 0` → delta pur, comportement inchangé.
-- ════════════════════════════════════════════════════════════════════

create or replace function public.shift_competition_matches_on_reschedule()
returns trigger
language plpgsql
security definer
set search_path to 'public', 'pg_temp'
as $function$
declare
  v_delta interval := new.start_date - old.start_date;
  v_floor timestamptz := now() + interval '5 minutes';
  v_earliest timestamptz;
  v_lift interval := interval '0';
begin
  -- Le match décalé le plus précoce décide du relèvement de toute la grille.
  select min(scheduled_at + v_delta)
    into v_earliest
    from public.matches
   where competition_id = new.id
     and scheduled_at is not null
     and status in ('pending', 'scheduled', 'ready');

  -- Aucun match déplaçable : rien à faire.
  if v_earliest is null then
    return new;
  end if;

  if v_earliest < v_floor then
    v_lift := v_floor - v_earliest;
  end if;

  update public.matches
     set scheduled_at = scheduled_at + v_delta + v_lift
   where competition_id = new.id
     and scheduled_at is not null
     and status in ('pending', 'scheduled', 'ready');

  return new;
end;
$function$;

comment on function public.shift_competition_matches_on_reschedule() is
  'Décale les matchs non démarrés (pending/scheduled/ready) du delta de '
  'start_date quand une compétition est reprogrammée. Si le décalage placerait '
  'le match le plus précoce avant maintenant+5min, TOUTE la grille est relevée '
  'du même complément : l''espacement entre rounds est préservé et deux rounds '
  'ne peuvent jamais se retrouver à la même heure.';
