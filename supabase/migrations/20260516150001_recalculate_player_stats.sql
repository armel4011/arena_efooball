-- Phase 12.5 — Persistance des stats joueur en jsonb `profiles.stats`.
--
-- Avant : `MatchStatsRepository` (Flutter) re-foldait toutes les
-- matches du joueur à chaque ouverture de profil. OK en V1.0 (volumes
-- faibles) mais ne scale pas et empêche un leaderboard ORDER BY stats.
--
-- Maintenant : un trigger AFTER UPDATE matches WHEN status passe à
-- 'completed' relance `recalculate_player_stats` pour player1 ET
-- player2. Le résultat est écrit dans `profiles.stats` (jsonb). Le
-- client peut continuer à utiliser son fold pour les écrans live,
-- mais les classements/leaderboards lisent maintenant la valeur
-- persistée.

-- ─────────────────────────────────────────────────────────────────────
-- 1. Fonction de recalcul pour un seul joueur.
-- ─────────────────────────────────────────────────────────────────────
create or replace function public.recalculate_player_stats(p_player_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_wins int;
  v_losses int;
  v_draws int;
  v_goals_scored int;
  v_goals_conceded int;
  v_result jsonb;
begin
  -- Agrégation : un match counted une seule fois ; le joueur peut être
  -- player1 ou player2. Un draw = winner_id null sur match completed
  -- (rare — la plupart des matchs ont un winner via penalty shootout).
  select
    count(*) filter (where m.winner_id = p_player_id),
    count(*) filter (
      where m.winner_id is not null and m.winner_id <> p_player_id
    ),
    count(*) filter (where m.winner_id is null),
    coalesce(sum(
      case when m.player1_id = p_player_id then m.score1 else m.score2 end
    ), 0)::int,
    coalesce(sum(
      case when m.player1_id = p_player_id then m.score2 else m.score1 end
    ), 0)::int
    into v_wins, v_losses, v_draws, v_goals_scored, v_goals_conceded
    from public.matches m
   where m.status = 'completed'
     and (m.player1_id = p_player_id or m.player2_id = p_player_id);

  v_result := jsonb_build_object(
    'wins',           coalesce(v_wins, 0),
    'losses',         coalesce(v_losses, 0),
    'draws',          coalesce(v_draws, 0),
    'goals_scored',   coalesce(v_goals_scored, 0),
    'goals_conceded', coalesce(v_goals_conceded, 0)
  );

  update public.profiles
     set stats = v_result
   where id = p_player_id;

  return v_result;
end;
$$;

revoke all on function public.recalculate_player_stats(uuid) from public, anon;
-- authenticated peut appeler la fonction pour son propre profil (sécurisé
-- par le filtre côté client) ; en pratique le trigger fait le travail.
grant execute on function public.recalculate_player_stats(uuid) to authenticated;

comment on function public.recalculate_player_stats(uuid) is
  'Recompute wins/losses/draws/goals_scored/goals_conceded depuis '
  '`matches` et persiste dans `profiles.stats`. Idempotent.';

-- ─────────────────────────────────────────────────────────────────────
-- 2. Trigger handler : recalcule pour les 2 joueurs concernés quand un
--    match passe à 'completed'.
-- ─────────────────────────────────────────────────────────────────────
create or replace function public._recalc_stats_on_match_completed()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if new.player1_id is not null then
    perform public.recalculate_player_stats(new.player1_id);
  end if;
  if new.player2_id is not null and new.player2_id <> new.player1_id then
    perform public.recalculate_player_stats(new.player2_id);
  end if;
  return new;
end;
$$;

revoke all on function public._recalc_stats_on_match_completed() from public, anon, authenticated;

drop trigger if exists trg_matches_recalc_stats on public.matches;
create trigger trg_matches_recalc_stats
  after update of status on public.matches
  for each row
  when (
    new.status = 'completed'
    and old.status is distinct from 'completed'
  )
  execute function public._recalc_stats_on_match_completed();

comment on function public._recalc_stats_on_match_completed() is
  'Trigger handler — recompute profiles.stats pour les 2 joueurs '
  'd''un match quand son status transitionne vers ''completed''.';

-- ─────────────────────────────────────────────────────────────────────
-- 3. Bulk recalc pour les admins (utile en migration / fix incident).
-- ─────────────────────────────────────────────────────────────────────
create or replace function public.recalculate_all_player_stats()
returns int
language plpgsql
security definer
set search_path = public
as $$
declare
  v_player_id uuid;
  v_count int := 0;
begin
  if not exists (
    select 1 from public.profiles
    where id = auth.uid() and role = 'super_admin'
  ) then
    raise exception 'forbidden_role';
  end if;

  for v_player_id in
    select distinct id from (
      select player1_id as id from public.matches where status = 'completed'
      union
      select player2_id as id from public.matches where status = 'completed'
    ) t
    where id is not null
  loop
    perform public.recalculate_player_stats(v_player_id);
    v_count := v_count + 1;
  end loop;
  return v_count;
end;
$$;

revoke all on function public.recalculate_all_player_stats() from public, anon;
grant execute on function public.recalculate_all_player_stats() to authenticated;

comment on function public.recalculate_all_player_stats() is
  'Recompute toutes les `profiles.stats` à partir de `matches`. '
  'Réservé super_admin. Utilisé en backfill / fix incident.';
