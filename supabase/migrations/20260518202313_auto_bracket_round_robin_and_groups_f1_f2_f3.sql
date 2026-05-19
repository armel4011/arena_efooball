-- ════════════════════════════════════════════════════════════════════
-- LOT F.1 — Auto-bracket pour round_robin + groups_then_knockout
-- ════════════════════════════════════════════════════════════════════
-- Port des Dart generators en SQL pour que `trigger_auto_generate_bracket`
-- puisse dispatcher sur le format de la compétition au lieu d'être
-- limité à single_elimination.
--
-- Pour groups_then_knockout, on lit la config groupes via
-- `competitions.format_config jsonb` si présent (clé "group_count" +
-- "qualifiers_per_group"). Defaults : 4 groupes × 2 qualifiés.

-- ─── Helper : config pour le format groupes ─────────────────────────
ALTER TABLE competitions
  ADD COLUMN IF NOT EXISTS format_config jsonb NOT NULL DEFAULT '{}'::jsonb;

COMMENT ON COLUMN competitions.format_config IS
  'Lot F.1 — Config dépendante du format. Pour groups_then_knockout : '
  '{group_count: int, qualifiers_per_group: int}. Defaults 4 groupes x 2.';

-- ─── 1. SQL fn : generate_round_robin_bracket ───────────────────────
-- Reproduit le `generateRoundRobin` Dart : circle method, N*(N-1)/2
-- matches sur (N-1) rounds. Pad avec NULL si nb impair.
CREATE OR REPLACE FUNCTION public.generate_round_robin_bracket(p_competition_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
  v_competition   record;
  v_players       uuid[];
  v_padded        uuid[];
  v_player_count  integer;
  v_n             integer;
  v_rounds        integer;
  v_half          integer;
  v_phase_id      uuid;
  v_round         integer;
  v_i             integer;
  v_a             uuid;
  v_b             uuid;
  v_rotation      uuid[];
  v_match_count   integer := 0;
  v_scheduled_at  timestamptz;
BEGIN
  SELECT * INTO v_competition FROM competitions
    WHERE id = p_competition_id FOR UPDATE;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Competition % not found', p_competition_id;
  END IF;

  IF v_competition.format::text <> 'round_robin' THEN
    RAISE EXCEPTION 'generate_round_robin_bracket called on format %', v_competition.format;
  END IF;

  IF EXISTS (SELECT 1 FROM matches WHERE competition_id = p_competition_id) THEN
    RAISE NOTICE 'Bracket already exists for %, skipping', p_competition_id;
    RETURN;
  END IF;

  SELECT array_agg(player_id ORDER BY random()) INTO v_players
    FROM competition_registrations
   WHERE competition_id = p_competition_id AND status = 'confirmed';

  v_player_count := COALESCE(array_length(v_players, 1), 0);
  IF v_player_count < 2 THEN
    RAISE EXCEPTION 'Need at least 2 confirmed registrations, got %', v_player_count;
  END IF;
  IF v_player_count > 32 THEN
    RAISE EXCEPTION 'Round robin capped at 32 players, got % (use groups_then_knockout for larger fields)', v_player_count;
  END IF;

  -- Pad avec NULL si impair
  IF v_player_count % 2 = 1 THEN
    v_padded := v_players || ARRAY[NULL::uuid];
  ELSE
    v_padded := v_players;
  END IF;
  v_n := array_length(v_padded, 1);
  v_rounds := v_n - 1;
  v_half := v_n / 2;
  v_rotation := v_padded;

  INSERT INTO phases (competition_id, phase_order, type, status, started_at)
  VALUES (p_competition_id, 1, 'round_robin', 'in_progress', now())
  RETURNING id INTO v_phase_id;

  v_scheduled_at := GREATEST(v_competition.start_date, now() + interval '5 minutes');

  FOR v_round IN 1..v_rounds LOOP
    FOR v_i IN 0..(v_half - 1) LOOP
      v_a := v_rotation[v_i + 1];          -- Postgres 1-indexed
      v_b := v_rotation[v_n - v_i];        -- n-1-i en 0-indexed = n-i en 1-indexed
      IF v_a IS NULL OR v_b IS NULL THEN
        CONTINUE;  -- bye
      END IF;
      v_match_count := v_match_count + 1;
      INSERT INTO matches (
        competition_id, phase_id, round, match_number,
        player1_id, player2_id, status, scheduled_at, home_player_id
      ) VALUES (
        p_competition_id, v_phase_id, v_round, v_match_count,
        v_a, v_b,
        CASE WHEN v_round = 1 THEN 'scheduled'::match_status ELSE 'pending'::match_status END,
        CASE WHEN v_round = 1 THEN v_scheduled_at ELSE NULL END,
        v_a
      );
    END LOOP;
    -- Rotate : last element moves to position 2 (index 0 fixed)
    v_rotation := v_rotation[1:1] || ARRAY[v_rotation[v_n]] || v_rotation[2:v_n - 1];
  END LOOP;

  -- Round robin ne crée pas de bracket_nodes (le classement = leaderboard
  -- agrégé par standings, pas d'avancement par paire).

  UPDATE competitions SET status = 'ongoing'::competition_status, updated_at = now()
   WHERE id = p_competition_id;
END;
$$;

COMMENT ON FUNCTION public.generate_round_robin_bracket(uuid) IS
  'Lot F.1 — Génère un bracket round-robin (circle method, N*(N-1)/2 matches).';

GRANT EXECUTE ON FUNCTION public.generate_round_robin_bracket(uuid) TO authenticated;

-- ─── 2. SQL fn : generate_groups_then_knockout_bracket ──────────────
-- Distribue les joueurs en snake-draft dans G groupes, round-robin par
-- groupe, puis bracket KO single-elim pour les qualifiés (slots vides,
-- l'admin fait advanceQualifiers après les groupes).
CREATE OR REPLACE FUNCTION public.generate_groups_then_knockout_bracket(p_competition_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
  v_competition       record;
  v_players           uuid[];
  v_player_count      integer;
  v_group_count       integer;
  v_qualifiers_pg     integer;
  v_qualifier_total   integer;
  v_phase_groups_id   uuid;
  v_phase_ko_id       uuid;
  v_group_player_ids  uuid[][];  -- jagged via 2D not supported, on stocke autrement
  v_group_id          uuid;
  v_group_ids         uuid[] := ARRAY[]::uuid[];
  v_i                 integer;
  v_row               integer;
  v_col               integer;
  v_match_count       integer;
  v_round             integer;
  v_n                 integer;
  v_rounds            integer;
  v_half              integer;
  v_rotation          uuid[];
  v_inner             uuid[];
  v_a                 uuid;
  v_b                 uuid;
  v_scheduled_at      timestamptz;
  -- KO
  v_ko_size           integer;
  v_ko_rounds         integer;
  v_ko_match_ids      uuid[] := ARRAY[]::uuid[];
  v_ko_round          integer;
  v_ko_matches_round  integer;
  v_pos               integer;
  v_match_id          uuid;
  v_node_ids          uuid[] := ARRAY[]::uuid[];
  v_round_offset      integer[] := ARRAY[0];
  v_match_idx         integer;
  v_next_match_idx    integer;
  v_next_position     text;
  v_node_id           uuid;
BEGIN
  SELECT * INTO v_competition FROM competitions
    WHERE id = p_competition_id FOR UPDATE;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Competition % not found', p_competition_id;
  END IF;

  IF v_competition.format::text <> 'groups_then_knockout' THEN
    RAISE EXCEPTION 'generate_groups_then_knockout_bracket called on format %', v_competition.format;
  END IF;

  IF EXISTS (SELECT 1 FROM matches WHERE competition_id = p_competition_id) THEN
    RAISE NOTICE 'Bracket already exists for %, skipping', p_competition_id;
    RETURN;
  END IF;

  -- Config groupes (fallback : 4 groupes × 2 qualifiés)
  v_group_count   := COALESCE((v_competition.format_config->>'group_count')::integer, 4);
  v_qualifiers_pg := COALESCE((v_competition.format_config->>'qualifiers_per_group')::integer, 2);

  IF v_group_count < 2 THEN
    RAISE EXCEPTION 'group_count must be >= 2, got %', v_group_count;
  END IF;
  IF v_qualifiers_pg < 1 THEN
    RAISE EXCEPTION 'qualifiers_per_group must be >= 1, got %', v_qualifiers_pg;
  END IF;

  SELECT array_agg(player_id ORDER BY random()) INTO v_players
    FROM competition_registrations
   WHERE competition_id = p_competition_id AND status = 'confirmed';

  v_player_count := COALESCE(array_length(v_players, 1), 0);
  IF v_player_count < v_group_count * 2 THEN
    RAISE EXCEPTION 'Need at least % players (%×2), got %',
      v_group_count * 2, v_group_count, v_player_count;
  END IF;

  -- Crée phase 1 (groupes) + phase 2 (KO)
  INSERT INTO phases (competition_id, phase_order, type, status, started_at)
  VALUES (p_competition_id, 1, 'groups', 'in_progress', now())
  RETURNING id INTO v_phase_groups_id;

  INSERT INTO phases (competition_id, phase_order, type, status)
  VALUES (p_competition_id, 2, 'knockout', 'pending')
  RETURNING id INTO v_phase_ko_id;

  -- Crée les rows `groups` (A, B, C, ...)
  FOR v_i IN 0..(v_group_count - 1) LOOP
    INSERT INTO groups (competition_id, phase_id, name, group_number)
    VALUES (
      p_competition_id, v_phase_groups_id,
      'Groupe ' || chr(65 + v_i),
      v_i + 1
    )
    RETURNING id INTO v_group_id;
    v_group_ids := v_group_ids || v_group_id;
  END LOOP;

  v_scheduled_at := GREATEST(v_competition.start_date, now() + interval '5 minutes');

  -- Snake-draft : distribue les joueurs dans les groupes par sérpentin
  -- (col 0 -> 1 -> ... -> n-1 -> n-1 -> n-2 -> ... -> 0 -> 0 -> 1 -> ...)
  -- Pour chaque groupe v_col, on fait round-robin sur ses joueurs.
  FOR v_col IN 0..(v_group_count - 1) LOOP
    -- Recompose la liste des joueurs du groupe v_col
    v_inner := ARRAY[]::uuid[];
    FOR v_i IN 0..(v_player_count - 1) LOOP
      v_row := v_i / v_group_count;
      IF v_row % 2 = 0 THEN
        IF v_i % v_group_count = v_col THEN
          v_inner := v_inner || v_players[v_i + 1];
        END IF;
      ELSE
        IF (v_group_count - 1 - (v_i % v_group_count)) = v_col THEN
          v_inner := v_inner || v_players[v_i + 1];
        END IF;
      END IF;
    END LOOP;

    -- Round-robin interne au groupe (circle method, NULL pad si impair)
    IF array_length(v_inner, 1) % 2 = 1 THEN
      v_rotation := v_inner || ARRAY[NULL::uuid];
    ELSE
      v_rotation := v_inner;
    END IF;
    v_n := array_length(v_rotation, 1);
    v_rounds := v_n - 1;
    v_half := v_n / 2;
    v_match_count := 0;

    FOR v_round IN 1..v_rounds LOOP
      FOR v_i IN 0..(v_half - 1) LOOP
        v_a := v_rotation[v_i + 1];
        v_b := v_rotation[v_n - v_i];
        IF v_a IS NULL OR v_b IS NULL THEN CONTINUE; END IF;
        v_match_count := v_match_count + 1;
        INSERT INTO matches (
          competition_id, phase_id, group_id, round, match_number,
          player1_id, player2_id, status, scheduled_at, home_player_id
        ) VALUES (
          p_competition_id, v_phase_groups_id, v_group_ids[v_col + 1],
          v_round, v_match_count,
          v_a, v_b,
          CASE WHEN v_round = 1 THEN 'scheduled'::match_status ELSE 'pending'::match_status END,
          CASE WHEN v_round = 1 THEN v_scheduled_at ELSE NULL END,
          v_a
        );
      END LOOP;
      v_rotation := v_rotation[1:1] || ARRAY[v_rotation[v_n]] || v_rotation[2:v_n - 1];
    END LOOP;
  END LOOP;

  -- ═══ KO phase : single-elim avec slots vides ═════════════════════
  v_qualifier_total := v_group_count * v_qualifiers_pg;
  -- next power of 2
  v_ko_size := 1;
  WHILE v_ko_size < v_qualifier_total LOOP
    v_ko_size := v_ko_size * 2;
  END LOOP;
  v_ko_rounds := log(2, v_ko_size::numeric)::integer;

  -- Pass 1 : crée les matches (tous players=NULL, status=pending)
  FOR v_ko_round IN 1..v_ko_rounds LOOP
    v_ko_matches_round := v_ko_size / power(2, v_ko_round)::integer;
    FOR v_pos IN 0..(v_ko_matches_round - 1) LOOP
      INSERT INTO matches (
        competition_id, phase_id, round, match_number,
        player1_id, player2_id, status
      ) VALUES (
        p_competition_id, v_phase_ko_id, v_ko_round,
        COALESCE(array_length(v_ko_match_ids, 1), 0) + 1,
        NULL, NULL, 'pending'::match_status
      ) RETURNING id INTO v_match_id;
      v_ko_match_ids := v_ko_match_ids || v_match_id;
    END LOOP;
    v_round_offset := v_round_offset || (COALESCE(array_length(v_ko_match_ids, 1), 0));
  END LOOP;

  -- Pass 2 : bracket_nodes
  FOR v_ko_round IN 1..v_ko_rounds LOOP
    v_ko_matches_round := v_ko_size / power(2, v_ko_round)::integer;
    FOR v_pos IN 0..(v_ko_matches_round - 1) LOOP
      v_match_idx := v_round_offset[v_ko_round] + v_pos + 1;
      INSERT INTO bracket_nodes (
        competition_id, phase_id, round_number, position_in_round, total_rounds,
        match_id, is_grand_final
      ) VALUES (
        p_competition_id, v_phase_ko_id, v_ko_round, v_pos, v_ko_rounds,
        v_ko_match_ids[v_match_idx],
        v_ko_round = v_ko_rounds
      ) RETURNING id INTO v_node_id;
      v_node_ids := v_node_ids || v_node_id;
    END LOOP;
  END LOOP;

  -- Pass 3 : patch next_node_id + matches.next_match_id
  FOR v_ko_round IN 1..(v_ko_rounds - 1) LOOP
    v_ko_matches_round := v_ko_size / power(2, v_ko_round)::integer;
    FOR v_pos IN 0..(v_ko_matches_round - 1) LOOP
      v_match_idx       := v_round_offset[v_ko_round] + v_pos + 1;
      v_next_match_idx  := v_round_offset[v_ko_round + 1] + (v_pos / 2) + 1;
      v_next_position   := CASE WHEN v_pos % 2 = 0 THEN 'player1' ELSE 'player2' END;

      UPDATE bracket_nodes
         SET next_node_id  = v_node_ids[v_next_match_idx],
             next_position = v_next_position
       WHERE id = v_node_ids[v_match_idx];

      UPDATE matches
         SET next_match_id = v_ko_match_ids[v_next_match_idx]
       WHERE id = v_ko_match_ids[v_match_idx];
    END LOOP;
  END LOOP;

  UPDATE competitions SET status = 'ongoing'::competition_status, updated_at = now()
   WHERE id = p_competition_id;
END;
$$;

COMMENT ON FUNCTION public.generate_groups_then_knockout_bracket(uuid) IS
  'Lot F.1 — Génère un bracket groupes+KO. Lit format_config.group_count et qualifiers_per_group.';

GRANT EXECUTE ON FUNCTION public.generate_groups_then_knockout_bracket(uuid) TO authenticated;

-- ─── 3. Dispatcher : trigger_auto_generate_bracket multi-format ─────
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

  IF NOT v_comp.auto_generate_bracket
     OR v_comp.status::text NOT IN ('registration_open', 'registration_closed')
     OR EXISTS (SELECT 1 FROM matches WHERE competition_id = v_comp.id) THEN
    RETURN NEW;
  END IF;

  SELECT count(*) INTO v_confirmed_count
    FROM competition_registrations
   WHERE competition_id = v_comp.id AND status = 'confirmed';

  IF v_confirmed_count < v_comp.max_players THEN
    RETURN NEW;
  END IF;

  BEGIN
    CASE v_comp.format::text
      WHEN 'single_elimination' THEN
        PERFORM generate_single_elim_bracket(v_comp.id);
      WHEN 'round_robin' THEN
        PERFORM generate_round_robin_bracket(v_comp.id);
      WHEN 'groups_then_knockout' THEN
        PERFORM generate_groups_then_knockout_bracket(v_comp.id);
      ELSE
        RAISE WARNING 'Auto-bracket: unsupported format % for competition %', v_comp.format, v_comp.id;
    END CASE;
  EXCEPTION WHEN OTHERS THEN
    RAISE WARNING 'Auto-bracket generation failed for %: %', v_comp.id, SQLERRM;
  END;

  RETURN NEW;
END;
$$;

COMMENT ON FUNCTION public.trigger_auto_generate_bracket() IS
  'Lot A + F.1 — Dispatcher multi-format. Génère bracket auto quand quota atteint, route sur single_elim / round_robin / groups_then_knockout.';
