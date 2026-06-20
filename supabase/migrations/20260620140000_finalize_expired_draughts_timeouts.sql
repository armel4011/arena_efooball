-- ════════════════════════════════════════════════════════════════════
-- Dames : finalisation SERVEUR des parties expirées au temps
-- ════════════════════════════════════════════════════════════════════
-- Aujourd'hui, le timeout est réclamé par un client (n'importe lequel des 2
-- joueurs, via l'EF `draughts-game` action `timeout`, idempotente). Ça couvre
-- le cas normal (au moins une app ouverte → la partie s'arrête pour les deux
-- via Realtime). Mais si les DEUX apps sont fermées/en veille au moment où le
-- temps expire, rien ne finalise → la partie reste `active` indéfiniment.
--
-- On ajoute une finalisation autonome côté serveur (cron à la minute) qui
-- balaie les `draughts_games` `active` dont l'horloge du joueur AU TRAIT est
-- épuisée, et finalise EXACTEMENT comme `finishMatch` de l'EF : l'adversaire
-- gagne (score 1-0), on clôt la partie, on met `matches` à jour (déclenche la
-- cascade bracket via `cascade_match_winner`, AFTER UPDATE sur matches) et on
-- écrit la ligne d'audit `match_events score_validated` (parité avec l'EF).
-- Le changement de `draughts_games.status` est poussé aux 2 clients via
-- Realtime → l'écran des deux joueurs s'arrête automatiquement.
-- ════════════════════════════════════════════════════════════════════

create or replace function public.finalize_expired_draughts_timeouts()
 returns integer
 language plpgsql
 security definer
 set search_path to 'public'
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
       AND g.last_move_at + (
             (CASE WHEN g.current_turn = 'white'
                   THEN g.white_clock_ms ELSE g.black_clock_ms END)
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

    -- Si une course a déjà clôt la partie entre le SELECT et l'UPDATE, on
    -- n'écrit ni le match ni l'événement (l'autre chemin l'a fait).
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

    -- 3) Audit, à parité avec l'EF finishMatch (created_by = gagnant : c'est
    --    lui qui « réclame » le timeout côté EF ; ici la finalisation est
    --    serveur, on marque la raison).
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

-- Cron : balaye chaque minute (cohérent avec match_reminders_minute).
DO $cron$
BEGIN
  IF EXISTS (SELECT 1 FROM cron.job WHERE jobname = 'finalize_draughts_timeouts_minute') THEN
    PERFORM cron.unschedule('finalize_draughts_timeouts_minute');
  END IF;
  PERFORM cron.schedule(
    'finalize_draughts_timeouts_minute',
    '* * * * *',
    $$ SELECT public.finalize_expired_draughts_timeouts(); $$
  );
END;
$cron$;
