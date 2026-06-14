-- ─────────────────────────────────────────────────────────────────
-- Fix stats joueur désynchronisées (profiles.stats ≠ matchs réels)
-- ─────────────────────────────────────────────────────────────────
-- Bug : le trigger `trg_matches_recalc_stats` ne se déclenchait QUE sur
-- `update of status` quand le match passe à 'completed'. Or le `winner_id`
-- (et les scores) peut être corrigé APRÈS la complétion — résolution de
-- litige (`resolve_dispute`), correction admin — sans repasser par un
-- changement de status. Résultat : `profiles.stats` restait figé sur le
-- calcul d'origine, divergent des matchs réels (wins/losses faux, voire
-- inversés). L'accueil + le profil public (qui lisent profiles.stats)
-- affichaient donc des stats erronées vs le profil perso (recalcul live).
--
-- Fix : (1) élargir le trigger pour recalculer dès qu'un champ qui
-- influence les stats change sur un match completed ; (2) backfill de
-- toutes les stats existantes.

-- 1) Trigger élargi : recalcule sur status / winner_id / score1 / score2,
--    pour tout match completed (idempotent : recalculate_player_stats
--    relit toujours l'ensemble des matchs du joueur).
drop trigger if exists trg_matches_recalc_stats on public.matches;
create trigger trg_matches_recalc_stats
  after update of status, winner_id, score1, score2 on public.matches
  for each row
  when (new.status = 'completed')
  execute function public._recalc_stats_on_match_completed();

-- 2) Backfill : recalcule profiles.stats pour tous les joueurs ayant au
--    moins un match completed (corrige les valeurs désynchronisées).
do $$
declare
  v_id uuid;
begin
  for v_id in
    select distinct id from (
      select player1_id as id from public.matches where status = 'completed'
      union
      select player2_id as id from public.matches where status = 'completed'
    ) t
    where id is not null
  loop
    perform public.recalculate_player_stats(v_id);
  end loop;
end $$;
