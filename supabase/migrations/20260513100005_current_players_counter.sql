-- =============================================================================
-- PHASE 11bis — Compteur current_players auto via trigger
-- =============================================================================
-- Le compteur `competitions.current_players` était laissé à zéro car
-- l'INSERT côté Edge Function (qui devait l'incrémenter) n'a jamais
-- existé. Avec le flux V1 (RLS self-insert + trigger payment validation),
-- aucun code applicatif ne bump le compteur.
--
-- On installe un trigger sur `competition_registrations` qui maintient
-- `current_players` aligné sur le nombre de rows confirmées :
--   • INSERT confirmed                  → +1
--   • DELETE confirmed                  → −1
--   • UPDATE  non-confirmed → confirmed → +1
--   • UPDATE  confirmed → non-confirmed → −1
--
-- Puis backfill des comps existantes pour resynchroniser tout de suite.
-- =============================================================================

create or replace function public.update_competition_player_count()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if tg_op = 'INSERT' then
    if new.status = 'confirmed' then
      update public.competitions
         set current_players = current_players + 1
       where id = new.competition_id;
    end if;
    return new;
  elsif tg_op = 'DELETE' then
    if old.status = 'confirmed' then
      update public.competitions
         set current_players = greatest(0, current_players - 1)
       where id = old.competition_id;
    end if;
    return old;
  elsif tg_op = 'UPDATE' then
    if old.status <> 'confirmed' and new.status = 'confirmed' then
      update public.competitions
         set current_players = current_players + 1
       where id = new.competition_id;
    elsif old.status = 'confirmed' and new.status <> 'confirmed' then
      update public.competitions
         set current_players = greatest(0, current_players - 1)
       where id = new.competition_id;
    end if;
    return new;
  end if;
  return null;
end;
$$;

comment on function public.update_competition_player_count is
  'Maintient competitions.current_players synchronisé avec le nombre de competition_registrations en status=confirmed (PHASE 11bis).';

drop trigger if exists trg_registration_player_count
  on public.competition_registrations;

create trigger trg_registration_player_count
  after insert or update or delete on public.competition_registrations
  for each row execute function public.update_competition_player_count();

-- Backfill — resynchronise les compteurs à partir des registrations existantes.
update public.competitions c
   set current_players = coalesce(sub.confirmed_count, 0)
  from (
    select competition_id, count(*) as confirmed_count
      from public.competition_registrations
     where status = 'confirmed'
     group by competition_id
  ) sub
 where c.id = sub.competition_id;

-- Aussi mettre à zéro les comps sans aucune registration confirmée.
update public.competitions c
   set current_players = 0
 where not exists (
   select 1 from public.competition_registrations r
    where r.competition_id = c.id and r.status = 'confirmed'
 )
   and current_players <> 0;
