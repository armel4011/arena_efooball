-- ─────────────────────────────────────────────────────────────────────
-- profiles.stats = COMPTEUR DE CARRIÈRE PERMANENT
-- ─────────────────────────────────────────────────────────────────────
-- Décision produit (2026-06-15) : les statistiques d'un joueur doivent
-- être CONSERVÉES. Elles s'accumulent à chaque match terminé et ne sont
-- JAMAIS recalculées depuis zéro ni décrémentées. La suppression / purge
-- de matchs (fin de compétition, cleanup, suppression admin) n'a AUCUN
-- effet sur `profiles.stats`.
--
-- Avant : `profiles.stats` était dérivé de `matches` (recompute idempotent
-- via recalculate_player_stats). Conséquence : supprimer un match ramenait
-- les stats vers le bas (voire à zéro si la table était vidée). C'est ce
-- qui faisait apparaître des profils « remis à zéro ».
--
-- Maintenant : un trigger INCRÉMENTE `profiles.stats` une seule fois, au
-- passage d'un match à l'état `completed`. Plus aucun trigger de
-- suppression / de sortie d'état ne touche aux stats.
--
-- Cette migration SUPERSÈDE 20260615210000 (handler recompute + trigger
-- DELETE), qui est entièrement remplacé ici.

-- ─────────────────────────────────────────────────────────────────────
-- 1. Handler incrémental : +1 win/loss/draw + buts marqués/encaissés,
--    pour chaque joueur, au passage à `completed`.
-- ─────────────────────────────────────────────────────────────────────
create or replace function public._increment_stats_on_match_completed()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_s1 int := coalesce(new.score1, 0);
  v_s2 int := coalesce(new.score2, 0);
begin
  -- player1
  if new.player1_id is not null then
    update public.profiles
       set stats = jsonb_build_object(
         'wins',           coalesce((stats->>'wins')::int, 0)
                           + (case when new.winner_id = new.player1_id then 1 else 0 end),
         'losses',         coalesce((stats->>'losses')::int, 0)
                           + (case when new.winner_id is not null
                                    and new.winner_id <> new.player1_id then 1 else 0 end),
         'draws',          coalesce((stats->>'draws')::int, 0)
                           + (case when new.winner_id is null then 1 else 0 end),
         'goals_scored',   coalesce((stats->>'goals_scored')::int, 0)   + v_s1,
         'goals_conceded', coalesce((stats->>'goals_conceded')::int, 0) + v_s2
       )
     where id = new.player1_id;
  end if;

  -- player2 (skip si identique — cas BYE en bracket)
  if new.player2_id is not null and new.player2_id is distinct from new.player1_id then
    update public.profiles
       set stats = jsonb_build_object(
         'wins',           coalesce((stats->>'wins')::int, 0)
                           + (case when new.winner_id = new.player2_id then 1 else 0 end),
         'losses',         coalesce((stats->>'losses')::int, 0)
                           + (case when new.winner_id is not null
                                    and new.winner_id <> new.player2_id then 1 else 0 end),
         'draws',          coalesce((stats->>'draws')::int, 0)
                           + (case when new.winner_id is null then 1 else 0 end),
         'goals_scored',   coalesce((stats->>'goals_scored')::int, 0)   + v_s2,
         'goals_conceded', coalesce((stats->>'goals_conceded')::int, 0) + v_s1
       )
     where id = new.player2_id;
  end if;

  return new;
end;
$$;

revoke all on function public._increment_stats_on_match_completed()
  from public, anon, authenticated;

comment on function public._increment_stats_on_match_completed() is
  'Trigger handler — INCRÉMENTE profiles.stats (wins/losses/draws/goals) '
  'pour les 2 joueurs au passage d''un match à completed. Modèle compteur '
  'de carrière : jamais décrémenté, jamais recalculé depuis zéro.';

-- ─────────────────────────────────────────────────────────────────────
-- 2. Triggers : incrément une fois au passage à completed (UPDATE) et
--    pour un match créé directement completed (INSERT). On supprime les
--    triggers recompute/delete de la migration précédente.
-- ─────────────────────────────────────────────────────────────────────
drop trigger if exists trg_matches_recalc_stats on public.matches;
drop trigger if exists trg_matches_recalc_stats_delete on public.matches;

create trigger trg_matches_increment_stats
  after update of status on public.matches
  for each row
  when (new.status = 'completed' and old.status is distinct from 'completed')
  execute function public._increment_stats_on_match_completed();

create trigger trg_matches_increment_stats_insert
  after insert on public.matches
  for each row
  when (new.status = 'completed')
  execute function public._increment_stats_on_match_completed();

-- Handler recompute de la migration précédente : plus aucun trigger ne le
-- référence.
drop function if exists public._recalc_stats_on_match_change();

-- ─────────────────────────────────────────────────────────────────────
-- 3. recalculate_player_stats / recalculate_all_player_stats RECOMPUTENT
--    depuis `matches` → DESTRUCTIF dans le modèle compteur (écrase les
--    stats accumulées par la somme des matchs actuels). On les conserve
--    comme outils de REBUILD manuel uniquement et on retire l'accès
--    `authenticated` à recalculate_player_stats (footgun : un client
--    pourrait effacer ses propres stats).
-- ─────────────────────────────────────────────────────────────────────
revoke execute on function public.recalculate_player_stats(uuid) from authenticated;

comment on function public.recalculate_player_stats(uuid) is
  'REBUILD destructif : réécrit profiles.stats = somme des matchs '
  'completed actuels. À n''utiliser qu''en reconstruction depuis un '
  'historique de matchs complet. Le flux normal incrémente via trigger.';
