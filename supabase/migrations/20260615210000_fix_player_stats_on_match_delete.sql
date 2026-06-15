-- ─────────────────────────────────────────────────────────────────────
-- Fix : profiles.stats périmé quand un match `completed` est SUPPRIMÉ
-- ou quitte l'état `completed`.
-- ─────────────────────────────────────────────────────────────────────
-- Bug : `trg_matches_recalc_stats` ne se déclenchait que sur
-- `UPDATE OF status,winner_id,score1,score2 WHEN new.status='completed'`.
-- Il ne couvrait donc PAS :
--   • la SUPPRESSION d'un match completed (aucun trigger AFTER DELETE) ;
--   • la transition completed → cancelled/forfeited/autre (sortie de
--     l'état completed sans repasser par new.status='completed').
-- Conséquence : après suppression/annulation d'un match, `profiles.stats`
-- gardait des wins/losses fantômes. L'accueil + le profil public (qui
-- lisent `profiles.stats`) affichaient des chiffres périmés, tandis que
-- le profil perso (fold live sur `matches`) montrait 0 → incohérence.
--
-- Fix : (1) handler unifié INSERT/UPDATE/DELETE ; (2) trigger DELETE +
-- élargissement du trigger UPDATE à la sortie de `completed` ;
-- (3) backfill des stats déjà désynchronisées.

-- ─────────────────────────────────────────────────────────────────────
-- 1. Handler unifié. `recalculate_player_stats` est idempotent (relit
--    tous les matchs completed du joueur), donc on peut le rappeler sur
--    n'importe quel joueur impacté par le changement de ligne.
-- ─────────────────────────────────────────────────────────────────────
create or replace function public._recalc_stats_on_match_change()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if tg_op = 'DELETE' then
    if old.player1_id is not null then
      perform public.recalculate_player_stats(old.player1_id);
    end if;
    if old.player2_id is not null
       and old.player2_id is distinct from old.player1_id then
      perform public.recalculate_player_stats(old.player2_id);
    end if;
    return old;
  end if;

  -- INSERT / UPDATE : recalcule les joueurs courants...
  if new.player1_id is not null then
    perform public.recalculate_player_stats(new.player1_id);
  end if;
  if new.player2_id is not null
     and new.player2_id is distinct from new.player1_id then
    perform public.recalculate_player_stats(new.player2_id);
  end if;

  -- ...et tout joueur retiré/remplacé sur la ligne (UPDATE).
  if tg_op = 'UPDATE' then
    if old.player1_id is not null
       and old.player1_id is distinct from new.player1_id
       and old.player1_id is distinct from new.player2_id then
      perform public.recalculate_player_stats(old.player1_id);
    end if;
    if old.player2_id is not null
       and old.player2_id is distinct from new.player1_id
       and old.player2_id is distinct from new.player2_id then
      perform public.recalculate_player_stats(old.player2_id);
    end if;
  end if;

  return new;
end;
$$;

revoke all on function public._recalc_stats_on_match_change()
  from public, anon, authenticated;

comment on function public._recalc_stats_on_match_change() is
  'Trigger handler — recompute profiles.stats pour tous les joueurs '
  'impactés par un INSERT/UPDATE/DELETE de match (gère la suppression '
  'et la sortie de l''état completed, contrairement à l''ancien handler).';

-- ─────────────────────────────────────────────────────────────────────
-- 2. Triggers : UPDATE (entrée OU sortie de completed) + DELETE.
-- ─────────────────────────────────────────────────────────────────────
drop trigger if exists trg_matches_recalc_stats on public.matches;
create trigger trg_matches_recalc_stats
  after update of status, winner_id, score1, score2, player1_id, player2_id
  on public.matches
  for each row
  when (new.status = 'completed' or old.status = 'completed')
  execute function public._recalc_stats_on_match_change();

drop trigger if exists trg_matches_recalc_stats_delete on public.matches;
create trigger trg_matches_recalc_stats_delete
  after delete on public.matches
  for each row
  when (old.status = 'completed')
  execute function public._recalc_stats_on_match_change();

-- L'ancien handler n'est plus référencé par aucun trigger.
drop function if exists public._recalc_stats_on_match_completed();

-- ─────────────────────────────────────────────────────────────────────
-- 3. Backfill : recalcule profiles.stats pour tout profil ayant des
--    stats non vides OU présent dans un match completed. Remet à zéro
--    les profils dont les matchs ont été supprimés.
-- ─────────────────────────────────────────────────────────────────────
do $$
declare
  v_id uuid;
begin
  for v_id in
    select id from public.profiles
     where stats is not null and stats <> '{}'::jsonb
    union
    select player1_id from public.matches where status = 'completed'
    union
    select player2_id from public.matches where status = 'completed'
  loop
    if v_id is not null then
      perform public.recalculate_player_stats(v_id);
    end if;
  end loop;
end $$;
