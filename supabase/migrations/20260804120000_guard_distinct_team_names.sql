-- Empêche les deux joueurs d'un match d'utiliser la MÊME équipe.
-- Comparaison insensible à la casse et aux espaces de bord. Le garde serveur
-- est le filet infalsifiable (couvre la course où les deux joueurs saisissent
-- le même nom quasi simultanément) ; le client fait un contrôle en amont pour
-- un message immédiat.

create or replace function public.guard_distinct_team_names()
  returns trigger
  language plpgsql
  set search_path = public
as $$
begin
  if new.player1_team_name is not null
     and new.player2_team_name is not null
     and lower(btrim(new.player1_team_name)) <> ''
     and lower(btrim(new.player1_team_name)) = lower(btrim(new.player2_team_name)) then
    raise exception
      'Les deux joueurs ne peuvent pas utiliser la même équipe'
      using errcode = '23514';
  end if;
  return new;
end;
$$;

drop trigger if exists trg_guard_distinct_team_names on public.matches;
create trigger trg_guard_distinct_team_names
  before update of player1_team_name, player2_team_name on public.matches
  for each row execute function public.guard_distinct_team_names();
