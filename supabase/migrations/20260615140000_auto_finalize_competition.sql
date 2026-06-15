-- ════════════════════════════════════════════════════════════════════
-- Clôture automatique d'une compétition + calcul du classement final
-- ════════════════════════════════════════════════════════════════════
-- Jusqu'ici, le passage à `completed` et la saisie de
-- `competition_registrations.final_rank` étaient 100 % MANUELS (admin).
-- On automatise : dès que TOUS les matchs d'une compétition `ongoing` sont
-- terminés, on calcule le rang final de chaque participant selon le format,
-- puis on bascule la compétition en `completed`.
--
-- Les PAIEMENTS restent une action super-admin délibérée (generate_payouts,
-- inchangé) : le super-admin revoit le classement auto avant de verser.
--
-- Règles de classement (rangs DISTINCTS 1..N, requis par generate_payouts) :
--   * round_robin            → rang = position au classement (group_memberships).
--   * single_elimination     → champion (vainqueur du dernier round) = 1 ;
--                              finaliste = 2 ; demi-finalistes 3/4 (départagés
--                              par le match 3e place si présent) ; puis par
--                              round d'élimination décroissant. Départage final :
--                              perf 3e place → buts pour → buts contre → id.
--   * groups_then_knockout   → idem KO pour les qualifiés ; les éliminés en
--                              poule sont classés APRÈS, par leur classement de
--                              poule (points → diff → BP).
--
-- Convention : un match `cancelled` est considéré comme terminé (ignoré).
-- Idempotent : ne s'exécute que sur une compétition `ongoing` (guard).
-- Depends on: 20260615120000 (group_memberships standings), bracket_nodes.
-- ════════════════════════════════════════════════════════════════════

-- ─── 1. Calcul du classement final ──────────────────────────────────
create or replace function public.compute_competition_final_ranks(p_competition_id uuid)
returns void
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_format text;
begin
  select format::text into v_format from competitions where id = p_competition_id;

  with parts as (
    select player_id as pid
      from competition_registrations
     where competition_id = p_competition_id and status = 'confirmed'
  ),
  -- Matchs du bracket KO (ceux qui ont un bracket_node) + méta.
  ko as (
    select m.id, m.player1_id, m.player2_id, m.winner_id,
           bn.round_number, bn.is_third_place_match
      from matches m
      join bracket_nodes bn on bn.match_id = m.id
     where m.competition_id = p_competition_id
  ),
  meta as (
    select coalesce(max(round_number) filter (where not is_third_place_match), 0) as max_round
      from ko
  ),
  ko_player as (
    select
      pa.pid,
      exists (
        select 1 from ko k, meta
         where not k.is_third_place_match
           and k.round_number = meta.max_round
           and k.winner_id = pa.pid
      ) as is_champion,
      exists (
        select 1 from ko k
         where k.player1_id = pa.pid or k.player2_id = pa.pid
      ) as played_ko,
      (
        select max(k.round_number) from ko k
         where not k.is_third_place_match
           and (k.player1_id = pa.pid or k.player2_id = pa.pid)
           and k.winner_id is not null and k.winner_id <> pa.pid
      ) as elim_round,
      (
        select case
                 when bool_or(k.is_third_place_match and k.winner_id = pa.pid) then 0
                 when bool_or(k.is_third_place_match and k.winner_id is not null
                              and k.winner_id <> pa.pid) then 1
               end
          from ko k
         where k.is_third_place_match
           and (k.player1_id = pa.pid or k.player2_id = pa.pid)
      ) as third_place
    from parts pa
  ),
  gstand as (
    select gm.profile_id as pid, gm.position, gm.points, gm.goal_diff
      from group_memberships gm
      join groups g on g.id = gm.group_id
     where g.competition_id = p_competition_id
  ),
  goals as (
    select pa.pid,
      coalesce(sum(case when m.player1_id = pa.pid then coalesce(m.score1, 0)
                        when m.player2_id = pa.pid then coalesce(m.score2, 0) end), 0) as gf,
      coalesce(sum(case when m.player1_id = pa.pid then coalesce(m.score2, 0)
                        when m.player2_id = pa.pid then coalesce(m.score1, 0) end), 0) as ga
      from parts pa
      left join matches m on m.competition_id = p_competition_id
        and (m.player1_id = pa.pid or m.player2_id = pa.pid)
     group by pa.pid
  ),
  ranked as (
    select pa.pid,
      row_number() over (
        order by
          -- a) bande de classement
          case
            when v_format = 'round_robin' then coalesce(gs.position, 9999)
            when kp.is_champion then 0
            when kp.played_ko and kp.elim_round is not null
              then (m.max_round - kp.elim_round) + 1
            else 100000  -- éliminé en poule / hors KO → après les joueurs KO
          end asc,
          -- b) match 3e place : vainqueur (0) avant perdant (1)
          coalesce(kp.third_place, 0) asc,
          -- c) départage par classement de poule (éliminés groups_then_knockout)
          coalesce(gs.points, 0) desc,
          coalesce(gs.goal_diff, 0) desc,
          -- d) départage par buts
          g.gf desc, g.ga asc,
          pa.pid asc
      ) as rnk
    from parts pa
    left join ko_player kp on kp.pid = pa.pid
    left join gstand gs on gs.pid = pa.pid
    left join goals g on g.pid = pa.pid
    cross join meta m
  )
  update competition_registrations cr
     set final_rank = r.rnk
    from ranked r
   where cr.competition_id = p_competition_id
     and cr.player_id = r.pid;
end;
$$;

comment on function public.compute_competition_final_ranks(uuid) is
  'Calcule competition_registrations.final_rank (rangs distincts 1..N) selon le '
  'format : round_robin=position de poule ; KO=progression bracket (+ match 3e '
  'place) ; groups_then_knockout=qualifiés par KO puis éliminés par classement '
  'de poule. SECURITY DEFINER.';

revoke all on function public.compute_competition_final_ranks(uuid) from public, anon;

-- ─── 2. Clôture si tous les matchs sont terminés ────────────────────
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
begin
  if p_competition_id is null then
    return;
  end if;

  select status::text into v_status from competitions where id = p_competition_id;
  if v_status is distinct from 'ongoing' then
    return;  -- idempotent : on ne clôture qu'une compétition en cours
  end if;

  select count(*) into v_total
    from matches where competition_id = p_competition_id;
  if v_total = 0 then
    return;  -- pas de bracket → rien à clôturer
  end if;

  select count(*) into v_pending
    from matches
   where competition_id = p_competition_id
     and status::text not in ('completed', 'forfeited', 'cancelled');
  if v_pending > 0 then
    return;  -- des matchs restent à jouer
  end if;

  perform public.compute_competition_final_ranks(p_competition_id);

  update competitions
     set status = 'completed'::competition_status, updated_at = now()
   where id = p_competition_id
     and status = 'ongoing'::competition_status;
end;
$$;

comment on function public.finalize_competition_if_complete(uuid) is
  'Si tous les matchs d''une compétition ongoing sont terminés : calcule le '
  'classement final puis passe en completed. Idempotent. Les versements '
  '(generate_payouts) restent une action super-admin séparée.';

revoke all on function public.finalize_competition_if_complete(uuid) from public, anon;

-- ─── 3. Trigger sur matches ─────────────────────────────────────────
create or replace function public.trigger_finalize_competition()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
  if new.competition_id is not null
     and new.status::text in ('completed', 'forfeited', 'cancelled') then
    perform public.finalize_competition_if_complete(new.competition_id);
  end if;
  return new;
end;
$$;

comment on function public.trigger_finalize_competition() is
  'Tente la clôture auto de la compétition au passage d''un match en état '
  'terminal (le dernier match déclenche le calcul du classement + completed).';

drop trigger if exists trg_matches_finalize_competition on public.matches;
create trigger trg_matches_finalize_competition
  after update of status on public.matches
  for each row
  execute function public.trigger_finalize_competition();
