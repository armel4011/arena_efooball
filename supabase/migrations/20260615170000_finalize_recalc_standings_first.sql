-- ════════════════════════════════════════════════════════════════════
-- Fix ordre des triggers : classement de poule à jour avant le rang final
-- ════════════════════════════════════════════════════════════════════
-- Bug (20260615140000) : les triggers AFTER UPDATE sur `matches` s'exécutent
-- par ordre ALPHABÉTIQUE de nom → `trg_matches_finalize_competition` se déclenche
-- AVANT `trg_matches_recalc_group_standings`. Au DERNIER match d'une compétition
-- à poules (round_robin / groups_then_knockout), `finalize` calculait donc le
-- `final_rank` à partir d'un `group_memberships` PÉRIMÉ (le résultat du dernier
-- match pas encore agrégé) → classement faux (ex. un joueur à 0 pt classé devant
-- un joueur à 3 pts). Exposé par competition_finalize_test (round-robin).
--
-- Correctif : `finalize_competition_if_complete` recalcule les classements de
-- TOUS les groupes de la compétition AVANT d'appeler
-- `compute_competition_final_ranks` → indépendant de l'ordre des triggers.
-- (Le single_elimination n'était pas touché : son classement se lit directement
-- sur `matches.winner_id`, pas via un agrégat de poule.)
-- Depends on: 20260615140000, 20260615120000.
-- ════════════════════════════════════════════════════════════════════

create or replace function public.finalize_competition_if_complete(p_competition_id uuid)
returns void
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_status  text;
  v_pending integer;
  v_total   integer;
  g         record;
begin
  if p_competition_id is null then
    return;
  end if;
  select status::text into v_status from competitions where id = p_competition_id;
  if v_status is distinct from 'ongoing' then
    return;
  end if;
  select count(*) into v_total from matches where competition_id = p_competition_id;
  if v_total = 0 then
    return;
  end if;
  select count(*) into v_pending
    from matches
   where competition_id = p_competition_id
     and status::text not in ('completed', 'forfeited', 'cancelled');
  if v_pending > 0 then
    return;
  end if;

  -- Classements de poule à jour AVANT le calcul du rang final (sinon le
  -- dernier match n'est pas encore reflété, cf. ordre des triggers AFTER).
  for g in select id from groups where competition_id = p_competition_id loop
    perform public.recalculate_group_standings(g.id);
  end loop;

  perform public.compute_competition_final_ranks(p_competition_id);

  update competitions
     set status = 'completed'::competition_status, updated_at = now()
   where id = p_competition_id
     and status = 'ongoing'::competition_status;
end;
$$;
