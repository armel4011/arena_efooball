-- ════════════════════════════════════════════════════════════════════
-- Bracket auto : avancement bye + visibilité des échecs
-- ════════════════════════════════════════════════════════════════════
-- Corrige deux bugs de la gestion automatique des compétitions (diagnostic
-- 2026-06-13). La GÉNÉRATION reste déclenchée « quand la compétition est
-- pleine » (choix produit) — on ne touche QUE :
--
--   (a) AVANCEMENT FIGÉ — `try_schedule_next_round` ne planifiait un match du
--       round suivant que s'il avait SES DEUX joueurs. Un match laissé avec un
--       seul joueur (bye / forfait sans adversaire) restait `pending` à vie →
--       le bracket se figeait. On l'auto-résout désormais en WALKOVER : le
--       joueur présent gagne (status=completed, winner_id), ce qui relance la
--       cascade et débloque la suite. Sûr : on n'arrive ici qu'avec le round
--       courant ENTIÈREMENT résolu, donc un slot vide est structurel.
--
--   (b) ÉCHECS INVISIBLES — les handlers `EXCEPTION WHEN OTHERS THEN RAISE
--       WARNING` avalaient silencieusement les erreurs de génération /
--       scheduling. On les journalise désormais dans
--       `competitions.last_bracket_error` (+ timestamp), affichable côté
--       admin, en plus du WARNING.
-- ════════════════════════════════════════════════════════════════════

-- ─── (b) Colonne de visibilité des erreurs ──────────────────────────
alter table public.competitions
  add column if not exists last_bracket_error text,
  add column if not exists last_bracket_error_at timestamptz;

comment on column public.competitions.last_bracket_error is
  'Dernier échec de génération/scheduling auto du bracket (NULL si aucun). '
  'Renseigné par les triggers trigger_auto_generate_bracket / '
  'trigger_try_schedule_next_round à la place d''un WARNING invisible.';

-- ─── (a) Avancement : walkover des matchs à un seul joueur ───────────
create or replace function public.try_schedule_next_round(p_match_id uuid)
 returns void
 language plpgsql
 security definer
 set search_path to 'public'
as $function$
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

  -- WALKOVER : un match du round suivant resté avec un SEUL joueur (l'autre
  -- feeder était un bye / forfait sans adversaire) est auto-gagné par le
  -- joueur présent, sinon il ne devient jamais jouable et le bracket se fige.
  -- Le passage à 'completed' relance cascade_match_winner (propagation du
  -- gagnant) et ce trigger (résolution des rounds suivants en chaîne).
  UPDATE matches
     SET status      = 'completed'::match_status,
         winner_id   = COALESCE(player1_id, player2_id),
         finished_at = now(),
         updated_at  = now()
   WHERE competition_id = v_match.competition_id
     AND round          = v_next_round
     AND status::text   = 'pending'
     AND winner_id IS NULL
     AND (
           (player1_id IS NOT NULL AND player2_id IS NULL)
        OR (player1_id IS NULL AND player2_id IS NOT NULL)
         );
END;
$function$;

-- ─── (b) Scheduling : journalise l'échec au lieu d'un WARNING muet ───
create or replace function public.trigger_try_schedule_next_round()
 returns trigger
 language plpgsql
 security definer
 set search_path to 'public'
as $function$
BEGIN
  IF NEW.status::text IN ('completed', 'forfeited')
     AND (OLD.status IS NULL OR OLD.status::text NOT IN ('completed', 'forfeited')) THEN
    BEGIN
      PERFORM try_schedule_next_round(NEW.id);
    EXCEPTION WHEN OTHERS THEN
      UPDATE competitions
         SET last_bracket_error    = 'scheduling: ' || SQLERRM,
             last_bracket_error_at = now()
       WHERE id = NEW.competition_id;
      RAISE WARNING 'try_schedule_next_round failed for match %: %', NEW.id, SQLERRM;
    END;
  END IF;
  RETURN NEW;
END;
$function$;

-- ─── (b) Génération : journalise l'échec au lieu d'un WARNING muet ───
create or replace function public.trigger_auto_generate_bracket()
 returns trigger
 language plpgsql
 security definer
 set search_path to 'public'
as $function$
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
        UPDATE competitions
           SET last_bracket_error    = 'generation: unsupported format ' || v_comp.format::text,
               last_bracket_error_at = now()
         WHERE id = v_comp.id;
        RAISE WARNING 'Auto-bracket: unsupported format % for competition %', v_comp.format, v_comp.id;
    END CASE;
  EXCEPTION WHEN OTHERS THEN
    UPDATE competitions
       SET last_bracket_error    = 'generation: ' || SQLERRM,
           last_bracket_error_at = now()
     WHERE id = v_comp.id;
    RAISE WARNING 'Auto-bracket generation failed for %: %', v_comp.id, SQLERRM;
  END;

  RETURN NEW;
END;
$function$;
