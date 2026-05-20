-- ════════════════════════════════════════════════════════════════════
-- LOT A — Auto-management des compétitions (auto-bracket + auto-schedule)
-- ════════════════════════════════════════════════════════════════════
-- 1. Nouvelles colonnes : intervalle entre rounds + flag d'auto-gen.
-- 2. SQL fn `generate_single_elim_bracket(competition_id)` qui crée
--    phase + matches + bracket_nodes en pure SQL (mirror du
--    generateSingleElimination Dart).
-- 3. Trigger AFTER INSERT competition_registrations → si quota atteint
--    + auto_generate_bracket=true + format=single_elimination, génère.
-- 4. SQL fn `try_schedule_next_round(match_id)` qui scheduling le round
--    suivant `match_interval_minutes` après la fin du round courant.
-- 5. Trigger AFTER UPDATE matches → quand status flip vers completed/
--    forfeited, call try_schedule_next_round.

-- ─── 1. Nouvelles colonnes ──────────────────────────────────────────
ALTER TABLE competitions
  ADD COLUMN IF NOT EXISTS match_interval_minutes integer NOT NULL DEFAULT 60,
  ADD COLUMN IF NOT EXISTS auto_generate_bracket boolean NOT NULL DEFAULT true;

COMMENT ON COLUMN competitions.match_interval_minutes IS
  'Minutes entre la fin d''un round et le scheduled_at du round suivant. Typiquement 30/60/120/240/1440.';
COMMENT ON COLUMN competitions.auto_generate_bracket IS
  'Si true, le bracket est généré automatiquement dès que max_players est atteint (single_elimination uniquement V1).';

-- ─── 2. Helper power of two ─────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.next_power_of_two(n integer)
RETURNS integer LANGUAGE sql IMMUTABLE AS $$
  SELECT CASE WHEN n <= 1 THEN 1 ELSE power(2, ceil(log(2, n::numeric)))::integer END;
$$;

-- ─── 3. SQL function : génère un bracket single-elimination ─────────
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

  -- ═══ Pass 4 : avance les bye winners au round 2 via cascade existant
  -- (cascade_match_winner s'exécute déjà sur UPDATE matches, donc on
  -- force un re-update no-op des byes pour le déclencher)
  UPDATE matches SET updated_at = now()
   WHERE competition_id = p_competition_id
     AND status::text = 'forfeited';

  -- Compétition passe en ongoing
  UPDATE competitions
     SET status = 'ongoing'::competition_status,
         updated_at = now()
   WHERE id = p_competition_id;
END;
$$;

COMMENT ON FUNCTION public.generate_single_elim_bracket(uuid) IS
  'Lot A — Génère un bracket single-elimination pour une compétition dont le quota est atteint. Idempotent (skip si matches déjà existants).';

GRANT EXECUTE ON FUNCTION public.generate_single_elim_bracket(uuid) TO authenticated;

-- ─── 4. Trigger : auto-gen quand le quota d'inscription est atteint ─
CREATE OR REPLACE FUNCTION public.trigger_auto_generate_bracket()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
  v_comp record;
  v_confirmed_count integer;
BEGIN
  SELECT * INTO v_comp FROM competitions WHERE id = NEW.competition_id;
  IF NOT FOUND THEN RETURN NEW; END IF;

  -- Garde-fous : auto-gen activé, format supporté, pas déjà généré
  IF NOT v_comp.auto_generate_bracket
     OR v_comp.format::text <> 'single_elimination'
     OR v_comp.status::text NOT IN ('registration_open', 'registration_closed')
     OR EXISTS (SELECT 1 FROM matches WHERE competition_id = v_comp.id) THEN
    RETURN NEW;
  END IF;

  -- Compte des confirmations en direct (current_players peut être stale
  -- selon l'ordre des triggers)
  SELECT count(*) INTO v_confirmed_count
    FROM competition_registrations
   WHERE competition_id = v_comp.id AND status = 'confirmed';

  IF v_confirmed_count < v_comp.max_players THEN
    RETURN NEW;
  END IF;

  BEGIN
    PERFORM generate_single_elim_bracket(v_comp.id);
  EXCEPTION WHEN OTHERS THEN
    RAISE WARNING 'Auto-bracket generation failed for %: %', v_comp.id, SQLERRM;
  END;

  RETURN NEW;
END;
$$;

COMMENT ON FUNCTION public.trigger_auto_generate_bracket() IS
  'Lot A — Wrapper trigger AFTER INSERT competition_registrations qui vérifie le quota et appelle generate_single_elim_bracket.';

-- z_ prefix pour s'exécuter APRÈS update_competition_player_count
DROP TRIGGER IF EXISTS z_auto_generate_bracket_on_registration ON competition_registrations;
CREATE TRIGGER z_auto_generate_bracket_on_registration
  AFTER INSERT ON competition_registrations
  FOR EACH ROW
  EXECUTE FUNCTION trigger_auto_generate_bracket();

-- ─── 5. SQL fn : scheduling automatique du round suivant ────────────
CREATE OR REPLACE FUNCTION public.try_schedule_next_round(p_match_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
  v_match            record;
  v_comp             record;
  v_remaining        integer;
  v_next_round       integer;
  v_last_finished    timestamptz;
  v_next_scheduled   timestamptz;
BEGIN
  SELECT * INTO v_match FROM matches WHERE id = p_match_id;
  IF NOT FOUND OR v_match.competition_id IS NULL OR v_match.round IS NULL THEN
    RETURN;
  END IF;

  SELECT * INTO v_comp FROM competitions WHERE id = v_match.competition_id;
  IF NOT FOUND THEN RETURN; END IF;

  -- Reste-t-il des matches non terminés dans ce round ?
  SELECT count(*) INTO v_remaining
    FROM matches
   WHERE competition_id = v_match.competition_id
     AND round = v_match.round
     AND status::text NOT IN ('completed', 'forfeited', 'cancelled');
  IF v_remaining > 0 THEN RETURN; END IF;

  -- Round complet : schedule le suivant
  v_next_round := v_match.round + 1;

  IF NOT EXISTS (
    SELECT 1 FROM matches
     WHERE competition_id = v_match.competition_id AND round = v_next_round
  ) THEN
    RETURN; -- pas de round suivant (finale)
  END IF;

  SELECT max(COALESCE(finished_at, updated_at)) INTO v_last_finished
    FROM matches
   WHERE competition_id = v_match.competition_id AND round = v_match.round;

  v_next_scheduled := COALESCE(v_last_finished, now())
                       + (v_comp.match_interval_minutes || ' minutes')::interval;

  -- Programme les matchs du round suivant qui ont leurs deux joueurs
  UPDATE matches
     SET status       = 'scheduled'::match_status,
         scheduled_at = v_next_scheduled,
         updated_at   = now()
   WHERE competition_id = v_match.competition_id
     AND round          = v_next_round
     AND status::text   = 'pending'
     AND player1_id IS NOT NULL
     AND player2_id IS NOT NULL;
END;
$$;

COMMENT ON FUNCTION public.try_schedule_next_round(uuid) IS
  'Lot A — Programme les matchs du round suivant `match_interval_minutes` après la fin du round courant. Idempotent.';

GRANT EXECUTE ON FUNCTION public.try_schedule_next_round(uuid) TO authenticated;

-- ─── 6. Trigger : appelle try_schedule_next_round après complétion ──
CREATE OR REPLACE FUNCTION public.trigger_try_schedule_next_round()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
BEGIN
  IF NEW.status::text IN ('completed', 'forfeited')
     AND (OLD.status IS NULL OR OLD.status::text NOT IN ('completed', 'forfeited')) THEN
    BEGIN
      PERFORM try_schedule_next_round(NEW.id);
    EXCEPTION WHEN OTHERS THEN
      RAISE WARNING 'try_schedule_next_round failed for match %: %', NEW.id, SQLERRM;
    END;
  END IF;
  RETURN NEW;
END;
$$;

COMMENT ON FUNCTION public.trigger_try_schedule_next_round() IS
  'Lot A — Wrapper trigger AFTER UPDATE matches qui détecte la transition vers completed/forfeited et appelle try_schedule_next_round.';

DROP TRIGGER IF EXISTS z_auto_schedule_next_round_on_match_complete ON matches;
CREATE TRIGGER z_auto_schedule_next_round_on_match_complete
  AFTER UPDATE ON matches
  FOR EACH ROW
  WHEN (OLD.status IS DISTINCT FROM NEW.status)
  EXECUTE FUNCTION trigger_try_schedule_next_round();
