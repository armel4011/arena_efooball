-- ════════════════════════════════════════════════════════════════════
-- Activation / désactivation des jeux par le super-admin
-- ════════════════════════════════════════════════════════════════════
-- Un jeu désactivé :
--   - ne permet PLUS de créer de compétition (garde serveur ci-dessous,
--     y compris via les RPC de duplication) ;
--   - disparaît des choix côté joueur (sondage, onglets) — côté app.
-- Les compétitions DÉJÀ créées continuent normalement (inscriptions et
-- matchs en cours ne sont pas bloqués). Au moins un jeu reste actif.
--
-- Un jeu sans ligne dans `game_settings` est considéré ACTIF : ajouter un
-- jeu au catalogue ne le bloque pas par oubli de seed.
-- ════════════════════════════════════════════════════════════════════

create table if not exists public.game_settings (
  game        text primary key,
  is_enabled  boolean not null default true,
  updated_at  timestamptz not null default now(),
  updated_by  uuid references public.profiles(id) on delete set null
);

alter table public.game_settings enable row level security;

-- Lecture publique : l'état des jeux n'a rien de secret (l'app user filtre
-- ses choix avec, y compris avant connexion).
drop policy if exists game_settings_select_all on public.game_settings;
create policy game_settings_select_all
  on public.game_settings for select to anon, authenticated
  using (true);

revoke insert, update, delete, truncate on public.game_settings from anon, authenticated;
grant select on public.game_settings to anon, authenticated;

create index if not exists idx_game_settings_updated_by
  on public.game_settings(updated_by) where updated_by is not null;

insert into public.game_settings (game) values
  ('efootball'), ('draughts'), ('ea_sports_fc'), ('dream_league')
on conflict (game) do nothing;

-- ─── Réglage super-admin ─────────────────────────────────────────────
create or replace function public.set_game_enabled(p_game text, p_enabled boolean)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if not public.is_super_admin() then
    raise exception 'Réservé au super-admin' using errcode = '42501';
  end if;
  if p_game is null or btrim(p_game) = '' or p_enabled is null then
    raise exception 'Paramètres invalides' using errcode = '22023';
  end if;

  insert into public.game_settings (game) values (p_game)
  on conflict (game) do nothing;

  if not p_enabled and not exists (
    select 1 from public.game_settings
     where is_enabled and game <> p_game
  ) then
    raise exception 'Au moins un jeu doit rester actif' using errcode = '22023';
  end if;

  update public.game_settings
     set is_enabled = p_enabled,
         updated_at = now(),
         updated_by = (select auth.uid())
   where game = p_game;
end;
$$;

revoke all on function public.set_game_enabled(text, boolean) from public, anon;
grant execute on function public.set_game_enabled(text, boolean) to authenticated;

-- ─── Lecture super-admin (état + compétitions en cours par jeu) ──────
create or replace function public.admin_list_game_settings()
returns table (game text, is_enabled boolean, active_competitions bigint)
language plpgsql
stable
security definer
set search_path = public
as $$
#variable_conflict use_column
begin
  if not public.is_super_admin() then
    raise exception 'Réservé au super-admin' using errcode = '42501';
  end if;
  return query
  select gs.game, gs.is_enabled,
         (select count(*) from public.competitions c
           where c.game = gs.game
             and c.status in ('registration_open', 'registration_closed',
                              'ongoing', 'to_reprogram'))
    from public.game_settings gs
   order by gs.game;
end;
$$;

revoke all on function public.admin_list_game_settings() from public, anon;
grant execute on function public.admin_list_game_settings() to authenticated;

-- ─── Garde : pas de NOUVELLE compétition sur un jeu désactivé ────────
-- INSERT (création, duplication « édition 2 »…) et UPDATE qui change le jeu.
create or replace function public.guard_competition_game_enabled()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if tg_op = 'UPDATE' and new.game is not distinct from old.game then
    return new;
  end if;
  if exists (
    select 1 from public.game_settings
     where game = new.game and not is_enabled
  ) then
    raise exception 'Ce jeu est désactivé : impossible d''y créer une compétition'
      using errcode = '42501';
  end if;
  return new;
end;
$$;

revoke all on function public.guard_competition_game_enabled() from public, anon, authenticated;

drop trigger if exists trg_guard_competition_game_enabled on public.competitions;
create trigger trg_guard_competition_game_enabled
  before insert or update of game on public.competitions
  for each row execute function public.guard_competition_game_enabled();
