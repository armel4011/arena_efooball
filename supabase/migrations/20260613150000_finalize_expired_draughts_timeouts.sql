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
-- épuisée, et finalise comme `finishMatch` de l'EF : l'adversaire gagne. La
-- mise à jour de `matches` déclenche la cascade bracket, et le changement de
-- `draughts_games.status` est poussé aux 2 clients via Realtime → l'écran des
-- deux joueurs s'arrête automatiquement.
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

    UPDATE draughts_games
       SET status = v_game_status, updated_at = now()
     WHERE id = r.game_id AND status = 'active';

    UPDATE matches
       SET status      = 'completed',
           winner_id   = v_winner_id,
           finished_at = now(),
           score1      = CASE WHEN v_winner_id = r.player1_id THEN 1 ELSE 0 END,
           score2      = CASE WHEN v_winner_id = r.player2_id THEN 1 ELSE 0 END
     WHERE id = r.match_id
       AND status::text NOT IN ('completed', 'cancelled', 'forfeited');

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
