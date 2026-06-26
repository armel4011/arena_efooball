-- ════════════════════════════════════════════════════════════════════
-- P3 — Durcissements backend (audit 2026-06-26)
-- ════════════════════════════════════════════════════════════════════
-- 1. reprogram_competition : garde de statut (ne pas rouvrir une compétition
--    ongoing/completed/cancelled aux inscriptions).
-- 2. finalize_expired_draughts_timeouts : révocation anon/authenticated
--    (fonction cron interne) + tolérance horloge NULL (COALESCE → 0 = expiré)
--    + search_path harmonisé (public, pg_temp).
-- 3. Harmonisation search_path = public, pg_temp sur les fonctions DEFINER qui
--    n'avaient que `public` (cosmétique/durcissement, via ALTER sans réécriture).
-- ════════════════════════════════════════════════════════════════════

-- ─── 1. reprogram_competition : garde de statut ─────────────────────
create or replace function public.reprogram_competition(
  p_competition_id uuid,
  p_new_start_date timestamptz
)
returns integer
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_name  text;
  v_count integer;
begin
  if not public.is_admin() then
    raise exception 'forbidden' using errcode = '42501';
  end if;
  if p_new_start_date <= now() then
    raise exception 'La nouvelle date doit être dans le futur';
  end if;

  -- Réouvre les inscriptions à la nouvelle date — UNIQUEMENT depuis un état
  -- pré-démarrage. Interdit de « reprogrammer » une compétition ongoing /
  -- completed / cancelled (casserait son cycle de vie et rouvrirait des
  -- inscriptions sur un tournoi déjà lancé ou clos).
  update public.competitions
     set status     = 'registration_open',
         start_date = p_new_start_date
   where id = p_competition_id
     and status in ('draft', 'registration_open', 'registration_closed', 'to_reprogram')
   returning name into v_name;

  if v_name is null then
    if exists (select 1 from public.competitions where id = p_competition_id) then
      raise exception
        'Reprogrammation impossible : la compétition n''est pas dans un état reprogrammable (déjà démarrée, terminée ou annulée)'
        using errcode = '42501';
    else
      raise exception 'Compétition introuvable' using errcode = 'P0002';
    end if;
  end if;

  insert into public.notifications (user_id, type, title, body, data)
  select distinct r.player_id, 'competition_reprogrammed',
    '📅 Tournoi reprogrammé',
    'La compétition « ' || v_name || ' » est reprogrammée au '
      || to_char(p_new_start_date at time zone 'Africa/Douala',
                 'DD/MM/YYYY "à" HH24"h"MI')
      || '. Les inscriptions sont rouvertes — invite tes amis pour compléter '
      || 'le tableau !',
    jsonb_build_object('competition_id', p_competition_id,
                       'route', '/competitions/' || p_competition_id)
  from public.competition_registrations r
  where r.competition_id = p_competition_id and r.status = 'confirmed';

  get diagnostics v_count = row_count;
  return v_count;
end;
$$;

comment on function public.reprogram_competition(uuid, timestamptz) is
  'Admin : reprogramme une compétition (depuis draft/registration_*/to_reprogram '
  'uniquement) à une nouvelle date et rouvre les inscriptions. Refuse si la '
  'compétition est ongoing/completed/cancelled (fix audit 2026-06-26). Notifie '
  'les inscrits confirmés. Retourne le nombre de joueurs notifiés.';

revoke all on function public.reprogram_competition(uuid, timestamptz)
  from anon, public;
grant execute on function public.reprogram_competition(uuid, timestamptz)
  to authenticated;

-- ─── 2. finalize_expired_draughts_timeouts : revoke + horloge NULL ──
create or replace function public.finalize_expired_draughts_timeouts()
 returns integer
 language plpgsql
 security definer
 set search_path to 'public', 'pg_temp'
as $function$
DECLARE
  r             record;
  v_count       integer := 0;
  v_winner_id   uuid;
  v_score1      integer;
  v_score2      integer;
  v_game_status text;
BEGIN
  FOR r IN
    SELECT g.id AS game_id, g.match_id, g.current_turn, g.white_id, g.black_id,
           m.player1_id, m.player2_id
      FROM draughts_games g
      JOIN matches m ON m.id = g.match_id
     WHERE g.status = 'active'
       AND m.status::text NOT IN ('completed', 'cancelled', 'forfeited')
       -- COALESCE(...,0) : une horloge NULL (anomalie de données) est traitée
       -- comme épuisée (0 ms) plutôt que de rendre tout le prédicat NULL, ce qui
       -- laissait la partie expirée bloquée en `active` indéfiniment.
       AND g.last_move_at + (
             COALESCE(CASE WHEN g.current_turn = 'white'
                           THEN g.white_clock_ms ELSE g.black_clock_ms END, 0)
             || ' milliseconds')::interval < now()
  LOOP
    -- Joueur au trait flaggé → l'adversaire gagne (cf. finishMatch / EF).
    IF r.current_turn = 'white' THEN
      v_winner_id := r.black_id; v_game_status := 'black_won';
    ELSE
      v_winner_id := r.white_id; v_game_status := 'white_won';
    END IF;

    v_score1 := CASE WHEN v_winner_id = r.player1_id THEN 1 ELSE 0 END;
    v_score2 := CASE WHEN v_winner_id = r.player2_id THEN 1 ELSE 0 END;

    -- 1) Clôt la partie (compare-and-swap status='active' → idempotent vs un
    --    timeout/coup décisif concurrent qui aurait déjà finalisé).
    UPDATE draughts_games
       SET status = v_game_status, updated_at = now()
     WHERE id = r.game_id AND status = 'active';

    IF NOT FOUND THEN
      CONTINUE;
    END IF;

    -- 2) Résultat du match → déclenche cascade_match_winner (AFTER UPDATE).
    UPDATE matches
       SET status      = 'completed',
           winner_id   = v_winner_id,
           finished_at = now(),
           score1      = v_score1,
           score2      = v_score2
     WHERE id = r.match_id
       AND status::text NOT IN ('completed', 'cancelled', 'forfeited');

    -- 3) Audit, à parité avec l'EF finishMatch.
    INSERT INTO match_events (match_id, type, created_by, payload)
    VALUES (
      r.match_id,
      'score_validated',
      v_winner_id,
      jsonb_build_object(
        'via', 'draughts',
        'reason', 'timeout_expired_cron',
        'winner_id', v_winner_id,
        'score1', v_score1,
        'score2', v_score2
      )
    );

    v_count := v_count + 1;
  END LOOP;

  RETURN v_count;
END;
$function$;

-- Fonction cron interne : tourne sous le rôle propriétaire (postgres). Aucun
-- client n'a à l'appeler → on révoque anon/authenticated/public (purge l'advisor
-- anon_security_definer_function_executable + supprime une surface DoS inutile).
revoke all on function public.finalize_expired_draughts_timeouts()
  from anon, authenticated, public;

-- ─── 3. Harmonisation search_path = public, pg_temp (sans réécriture) ─
alter function public.admin_filter_users(text, text, text, boolean, boolean, boolean, boolean, integer, uuid[], integer)
  set search_path = public, pg_temp;
alter function public.get_super_admin_kpis()
  set search_path = public, pg_temp;
alter function public.get_monthly_revenue(integer)
  set search_path = public, pg_temp;
alter function public.get_revenue_breakdown(timestamptz, timestamptz)
  set search_path = public, pg_temp;
alter function public.recalculate_all_player_stats()
  set search_path = public, pg_temp;
alter function public.regenerate_competition(uuid)
  set search_path = public, pg_temp;
