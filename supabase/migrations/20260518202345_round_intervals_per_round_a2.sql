-- ════════════════════════════════════════════════════════════════════
-- LOT F.2 — Scheduling par round customisé (A.2)
-- ════════════════════════════════════════════════════════════════════
-- L'admin peut override l'intervalle global `match_interval_minutes`
-- avec un tableau `round_intervals` (1 entrée par round suivant le round
-- 1). Si NULL, on garde le comportement actuel (interval global).

ALTER TABLE competitions
  ADD COLUMN IF NOT EXISTS round_intervals jsonb;

COMMENT ON COLUMN competitions.round_intervals IS
  'Lot A.2 — Tableau d''int (minutes) pour overrider match_interval_minutes par round. round_intervals[N-1] = délai après round N. NULL = utilise interval global.';

-- Update try_schedule_next_round pour lire round_intervals si présent.
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
  v_interval_minutes integer;
  v_round_override   integer;
BEGIN
  SELECT * INTO v_match FROM matches WHERE id = p_match_id;
  IF NOT FOUND OR v_match.competition_id IS NULL OR v_match.round IS NULL THEN
    RETURN;
  END IF;

  SELECT * INTO v_comp FROM competitions WHERE id = v_match.competition_id;
  IF NOT FOUND THEN RETURN; END IF;

  SELECT count(*) INTO v_remaining
    FROM matches
   WHERE competition_id = v_match.competition_id
     AND round = v_match.round
     AND status::text NOT IN ('completed', 'forfeited', 'cancelled');
  IF v_remaining > 0 THEN RETURN; END IF;

  v_next_round := v_match.round + 1;

  IF NOT EXISTS (
    SELECT 1 FROM matches
     WHERE competition_id = v_match.competition_id AND round = v_next_round
  ) THEN
    RETURN;
  END IF;

  SELECT max(COALESCE(finished_at, updated_at)) INTO v_last_finished
    FROM matches
   WHERE competition_id = v_match.competition_id AND round = v_match.round;

  -- Lot A.2 : override par round si jsonb fourni.
  -- round_intervals[v_match.round - 1] = délai en min après le round courant.
  v_interval_minutes := v_comp.match_interval_minutes;
  IF v_comp.round_intervals IS NOT NULL AND jsonb_typeof(v_comp.round_intervals) = 'array' THEN
    v_round_override := (v_comp.round_intervals -> (v_match.round - 1))::text::integer;
    IF v_round_override IS NOT NULL AND v_round_override > 0 THEN
      v_interval_minutes := v_round_override;
    END IF;
  END IF;

  v_next_scheduled := COALESCE(v_last_finished, now())
                       + (v_interval_minutes || ' minutes')::interval;

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
  'Lot A + A.2 — Schedule le round suivant. Lit competitions.round_intervals[N-1] si présent, sinon match_interval_minutes.';
