-- ════════════════════════════════════════════════════════════════════
-- FIX P1 — Avancement des vainqueurs de byes (générateur SQL single-elim)
-- ════════════════════════════════════════════════════════════════════
-- Bug (audit 2026-06-26) : `generate_single_elim_bracket` Pass 4 tentait de
-- propager le gagnant d'un bye au round suivant via un UPDATE NO-OP
-- (`SET updated_at = now()` sur les matchs déjà `forfeited`), censé re-déclencher
-- `cascade_match_winner`. Or la garde de ce trigger exige une transition RÉELLE :
--   (old.status IS DISTINCT FROM new.status OR old.winner_id IS DISTINCT FROM new.winner_id)
-- Un re-update qui ne change ni le statut ni le winner ne satisfait PAS cette
-- garde → le gagnant du bye n'était jamais avancé.
--
-- Conséquences sur tout effectif non-puissance-de-2 (ex. démarrage via
-- `start_competition_now` du workflow `to_reprogram`, ou max_players non
-- puissance de 2) :
--   • 3 joueurs (A,B,C) : C gagne son bye mais n'est jamais placé en finale →
--     A bat B, puis `try_schedule_next_round` voit une finale à un seul joueur →
--     WALKOVER : A « gagne » la finale sans jouer, C est éliminé sans match.
--     `compute_competition_final_ranks` couronne A → `generate_payouts` verse au
--     mauvais joueur.
--   • 5/7 joueurs : un match du round suivant peut rester SANS aucun joueur →
--     ni schedulable ni walkover-able → bracket figé, compétition jamais
--     clôturée, aucun payout.
--
-- Correctif : Pass 4 propage EXPLICITEMENT chaque vainqueur de bye dans le slot
-- (player1/player2) de son `next_match`, au lieu de compter sur un no-op. C'est
-- déterministe et indépendant du timing des triggers. Le reste de la chaîne
-- (`try_schedule_next_round` / walkover) reste inchangé et débloque la suite.
-- Le chemin Dart (`admin_bracket_repository`) n'était pas affecté (il fait une
-- vraie transition de statut) — ce fix aligne le chemin SQL sur ce comportement.
-- ════════════════════════════════════════════════════════════════════

CREATE OR REPLACE FUNCTION public.generate_single_elim_bracket(p_competition_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
  v_competition   record;
  v_players       uuid[];
  v_player_count  integer;
  v_size          integer;
  v_total_rounds  integer;
  v_byes          integer;
  v_phase_id      uuid;
  v_round         integer;
  v_matches_round integer;
  v_pos           integer;
  v_p1            uuid;
  v_p2            uuid;
  v_is_bye        boolean;
  v_lone_player   uuid;
  v_match_id      uuid;
  v_match_ids     uuid[] := ARRAY[]::uuid[];
  v_node_ids      uuid[] := ARRAY[]::uuid[];
  v_round_offset  integer[] := ARRAY[0];
  v_node_cursor   integer := 0;
  v_round1_padded uuid[];
  v_match_idx     integer;
  v_next_match_idx integer;
  v_next_position text;
  v_node_id       uuid;
  v_scheduled_at  timestamptz;
  v_bye           record;
BEGIN
  SELECT * INTO v_competition FROM competitions
    WHERE id = p_competition_id FOR UPDATE;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Competition % not found', p_competition_id;
  END IF;

  IF v_competition.format::text <> 'single_elimination' THEN
    RAISE EXCEPTION 'Auto-bracket only supports single_elimination, got %', v_competition.format;
  END IF;

  IF EXISTS (SELECT 1 FROM matches WHERE competition_id = p_competition_id) THEN
    RAISE NOTICE 'Bracket already exists for %, skipping', p_competition_id;
    RETURN;
  END IF;

  -- Joueurs confirmés, shuffle déterministe basé sur registered_at + id
  SELECT array_agg(player_id ORDER BY random()) INTO v_players
  FROM competition_registrations
  WHERE competition_id = p_competition_id AND status = 'confirmed';

  v_player_count := COALESCE(array_length(v_players, 1), 0);
  IF v_player_count < 2 THEN
    RAISE EXCEPTION 'Need at least 2 confirmed registrations, got %', v_player_count;
  END IF;
  IF v_player_count > 256 THEN
    RAISE EXCEPTION 'Single elimination capped at 256 players, got %', v_player_count;
  END IF;

  v_size := next_power_of_two(v_player_count);
  v_total_rounds := log(2, v_size::numeric)::integer;
  v_byes := v_size - v_player_count;

  -- Padding pour atteindre une puissance de 2 (les NULL sont des byes)
  IF v_byes > 0 THEN
    v_round1_padded := v_players || array_fill(NULL::uuid, ARRAY[v_byes]);
  ELSE
    v_round1_padded := v_players;
  END IF;

  -- Crée la phase
  INSERT INTO phases (competition_id, phase_order, type, status, started_at)
  VALUES (p_competition_id, 1, 'knockout', 'in_progress', now())
  RETURNING id INTO v_phase_id;

  -- scheduled_at round 1 = max(start_date, now() + 5min) pour éviter de
  -- programmer dans le passé
  v_scheduled_at := GREATEST(v_competition.start_date, now() + interval '5 minutes');

  -- ═══ Pass 1 : create all matches round by round ═══════════════════
  FOR v_round IN 1..v_total_rounds LOOP
    v_matches_round := v_size / power(2, v_round)::integer;

    FOR v_pos IN 0..(v_matches_round - 1) LOOP
      IF v_round = 1 THEN
        v_p1 := v_round1_padded[v_pos * 2 + 1];
        v_p2 := v_round1_padded[v_pos * 2 + 2];
      ELSE
        v_p1 := NULL;
        v_p2 := NULL;
      END IF;

      v_is_bye := (v_round = 1) AND (v_p1 IS NULL OR v_p2 IS NULL);
      v_lone_player := COALESCE(v_p1, v_p2);

      INSERT INTO matches (
        competition_id, phase_id, round, match_number,
        player1_id, player2_id,
        status, scheduled_at,
        home_player_id,
        winner_id, score1, score2,
        finished_at
      ) VALUES (
        p_competition_id, v_phase_id, v_round,
        COALESCE(array_length(v_match_ids, 1), 0) + 1,
        v_p1, v_p2,
        CASE
          WHEN v_is_bye THEN 'forfeited'::match_status
          WHEN v_round = 1 THEN 'scheduled'::match_status
          ELSE 'pending'::match_status
        END,
        CASE WHEN v_round = 1 AND NOT v_is_bye THEN v_scheduled_at ELSE NULL END,
        v_p1,
        CASE WHEN v_is_bye THEN v_lone_player ELSE NULL END,
        CASE WHEN v_is_bye THEN 0 ELSE NULL END,
        CASE WHEN v_is_bye THEN 0 ELSE NULL END,
        CASE WHEN v_is_bye THEN now() ELSE NULL END
      ) RETURNING id INTO v_match_id;

      v_match_ids := v_match_ids || v_match_id;
    END LOOP;

    -- Offset pour le prochain round dans le tableau v_match_ids
    v_round_offset := v_round_offset || (COALESCE(array_length(v_match_ids, 1), 0));
  END LOOP;

  -- ═══ Pass 2 : create bracket_nodes (1 par match) ══════════════════
  FOR v_round IN 1..v_total_rounds LOOP
    v_matches_round := v_size / power(2, v_round)::integer;

    FOR v_pos IN 0..(v_matches_round - 1) LOOP
      v_match_idx := v_round_offset[v_round] + v_pos + 1;

      INSERT INTO bracket_nodes (
        competition_id, phase_id, round_number, position_in_round, total_rounds,
        match_id, is_grand_final, is_bye, bye_player_id
      ) VALUES (
        p_competition_id, v_phase_id, v_round, v_pos, v_total_rounds,
        v_match_ids[v_match_idx],
        v_round = v_total_rounds,
        (v_round = 1) AND
          (SELECT status::text = 'forfeited' FROM matches WHERE id = v_match_ids[v_match_idx]),
        (SELECT winner_id FROM matches WHERE id = v_match_ids[v_match_idx] AND status::text = 'forfeited')
      ) RETURNING id INTO v_node_id;

      v_node_ids := v_node_ids || v_node_id;
    END LOOP;
  END LOOP;

  -- ═══ Pass 3 : patch next_node_id + matches.next_match_id ═════════
  FOR v_round IN 1..(v_total_rounds - 1) LOOP
    v_matches_round := v_size / power(2, v_round)::integer;

    FOR v_pos IN 0..(v_matches_round - 1) LOOP
      v_match_idx       := v_round_offset[v_round] + v_pos + 1;
      v_next_match_idx  := v_round_offset[v_round + 1] + (v_pos / 2) + 1;
      v_next_position   := CASE WHEN v_pos % 2 = 0 THEN 'player1' ELSE 'player2' END;

      UPDATE bracket_nodes
         SET next_node_id  = v_node_ids[v_next_match_idx],
             next_position = v_next_position
       WHERE id = v_node_ids[v_match_idx];

      UPDATE matches
         SET next_match_id = v_match_ids[v_next_match_idx]
       WHERE id = v_match_ids[v_match_idx];
    END LOOP;
  END LOOP;

  -- ═══ Pass 4 : avance EXPLICITEMENT les vainqueurs de byes au round suivant
  -- NE PAS compter sur un UPDATE no-op : la garde de `cascade_match_winner`
  -- exige une transition réelle de status/winner_id, qu'un re-update n'apporte
  -- pas. On réplique donc directement l'avancement (winner du bye → slot
  -- player1/player2 du next_match, selon bracket_nodes.next_position). Les byes
  -- dégénérés sans joueur (winner_id IS NULL) sont ignorés ; le walkover de
  -- `try_schedule_next_round` résoudra les matchs restés à un seul joueur quand
  -- le round courant sera entièrement joué.
  FOR v_bye IN
    SELECT m.winner_id, m.next_match_id, bn.next_position
      FROM matches m
      JOIN bracket_nodes bn ON bn.match_id = m.id
     WHERE m.competition_id = p_competition_id
       AND m.status::text   = 'forfeited'
       AND m.winner_id IS NOT NULL
       AND m.next_match_id IS NOT NULL
  LOOP
    IF v_bye.next_position = 'player1' THEN
      UPDATE matches SET player1_id = v_bye.winner_id
       WHERE id = v_bye.next_match_id AND player1_id IS NULL;
    ELSIF v_bye.next_position = 'player2' THEN
      UPDATE matches SET player2_id = v_bye.winner_id
       WHERE id = v_bye.next_match_id AND player2_id IS NULL;
    END IF;
  END LOOP;

  -- Compétition passe en ongoing
  UPDATE competitions
     SET status = 'ongoing'::competition_status,
         updated_at = now()
   WHERE id = p_competition_id;
END;
$$;

COMMENT ON FUNCTION public.generate_single_elim_bracket(uuid) IS
  'Lot A — Génère un bracket single-elimination pour une compétition dont le quota est atteint. Idempotent (skip si matches déjà existants). Pass 4 propage explicitement les vainqueurs de byes (fix audit 2026-06-26).';

GRANT EXECUTE ON FUNCTION public.generate_single_elim_bracket(uuid) TO authenticated;
