-- F3 : Rappels automatiques de matches
--
-- Avant le debut d'un match (status scheduled|ready) :
--   - T-60 min : notif standard "Ton match commence dans 1h"
--   - T-30 min : notif standard "Ton match commence dans 30 min"
--   - T-10 min : notif standard "Ton match commence dans 10 min"
--   - T-05 min : notif type=call_invite (reuse infra callkit_incoming
--     pour declencher une sonnerie plein-ecran sur l'appareil)
--
-- Architecture :
--   1. Table match_reminders_sent : ledger idempotent (match_id +
--      player_id + kind), PK composite. Si la cron fire 2x dans la
--      meme minute, la 2e INSERT est rejetee (ON CONFLICT DO NOTHING).
--   2. Index composite matches(status, scheduled_at) pour rendre la
--      requete cron rapide.
--   3. Fonction _dispatch_match_reminders() SECURITY DEFINER, lookups
--      les matches sur [now + interval, now + interval + 1 min] pour
--      chaque kind, JOIN les 2 player_id et INSERT dans notifications
--      + ledger.
--   4. pg_cron toutes les minutes (* * * * *).

-- 1. Ledger d'idempotence ----------------------------------------------
CREATE TABLE IF NOT EXISTS public.match_reminders_sent (
  match_id  UUID NOT NULL REFERENCES public.matches(id) ON DELETE CASCADE,
  player_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  kind      TEXT NOT NULL CHECK (kind IN ('t60','t30','t10','t5')),
  sent_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY (match_id, player_id, kind)
);

COMMENT ON TABLE public.match_reminders_sent IS
  'Idempotence ledger pour les rappels match auto (1h/30m/10m/5m). '
  'PK composite empeche les doublons si pg_cron tire deux fois la '
  'meme fenetre.';

-- 2. Index composite pour la requete cron -----------------------------
CREATE INDEX IF NOT EXISTS idx_matches_status_scheduled_at
  ON public.matches (status, scheduled_at)
  WHERE status IN ('scheduled', 'ready');

-- 3. Fonction dispatch ------------------------------------------------
CREATE OR REPLACE FUNCTION public._dispatch_match_reminders()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  rec RECORD;
  reminder_kind TEXT;
  minutes_before INT;
  title_text TEXT;
  body_text TEXT;
  notif_type TEXT;
  notif_data JSONB;
BEGIN
  -- Tableau des 4 fenetres : kind, minutes avant, titre, type FCM
  FOR reminder_kind, minutes_before, title_text, notif_type IN
    SELECT * FROM (VALUES
      ('t60', 60, 'Match dans 1h',     'match_reminder'),
      ('t30', 30, 'Match dans 30 min', 'match_reminder'),
      ('t10', 10, 'Match dans 10 min', 'match_reminder'),
      ('t5',   5, 'MATCH DANS 5 MIN',  'call_invite')
    ) AS v(kind, mins, title, ntype)
  LOOP
    -- Fenetre [now + N min, now + N min + 1 min[ : la cron fire
    -- toutes les minutes donc chaque match passe exactement 1x par
    -- fenetre. Le ledger garantit l'idempotence si jamais la cron
    -- fire en double.
    FOR rec IN
      SELECT
        m.id              AS match_id,
        m.player1_id,
        m.player2_id,
        m.scheduled_at,
        m.competition_id,
        p1.username       AS p1_name,
        p2.username       AS p2_name
      FROM public.matches m
      LEFT JOIN public.profiles p1 ON p1.id = m.player1_id
      LEFT JOIN public.profiles p2 ON p2.id = m.player2_id
      WHERE m.status IN ('scheduled', 'ready')
        AND m.player1_id IS NOT NULL
        AND m.player2_id IS NOT NULL
        AND m.scheduled_at >= now() + make_interval(mins => minutes_before)
        AND m.scheduled_at <  now() + make_interval(mins => minutes_before + 1)
    LOOP
      -- Player 1
      body_text := 'Adversaire : ' || COALESCE(rec.p2_name, '?');
      IF reminder_kind = 't5' THEN
        notif_data := jsonb_build_object(
          'call_id', rec.match_id::text,
          'caller_name', title_text,
          'scope', 'match_reminder',
          'scope_id', rec.match_id::text,
          'caller_id', COALESCE(rec.player2_id::text, ''),
          'route', '/matches/' || rec.match_id::text
        );
      ELSE
        notif_data := jsonb_build_object(
          'match_id', rec.match_id::text,
          'route', '/matches/' || rec.match_id::text
        );
      END IF;

      INSERT INTO public.match_reminders_sent (match_id, player_id, kind)
      VALUES (rec.match_id, rec.player1_id, reminder_kind)
      ON CONFLICT DO NOTHING;

      IF FOUND THEN
        INSERT INTO public.notifications (user_id, type, title, body, data)
        VALUES (rec.player1_id, notif_type, title_text, body_text, notif_data);
      END IF;

      -- Player 2 (adversaire = p1)
      body_text := 'Adversaire : ' || COALESCE(rec.p1_name, '?');
      IF reminder_kind = 't5' THEN
        notif_data := jsonb_build_object(
          'call_id', rec.match_id::text,
          'caller_name', title_text,
          'scope', 'match_reminder',
          'scope_id', rec.match_id::text,
          'caller_id', COALESCE(rec.player1_id::text, ''),
          'route', '/matches/' || rec.match_id::text
        );
      ELSE
        notif_data := jsonb_build_object(
          'match_id', rec.match_id::text,
          'route', '/matches/' || rec.match_id::text
        );
      END IF;

      INSERT INTO public.match_reminders_sent (match_id, player_id, kind)
      VALUES (rec.match_id, rec.player2_id, reminder_kind)
      ON CONFLICT DO NOTHING;

      IF FOUND THEN
        INSERT INTO public.notifications (user_id, type, title, body, data)
        VALUES (rec.player2_id, notif_type, title_text, body_text, notif_data);
      END IF;
    END LOOP;
  END LOOP;
END;
$$;

REVOKE ALL ON FUNCTION public._dispatch_match_reminders() FROM PUBLIC;
REVOKE ALL ON FUNCTION public._dispatch_match_reminders() FROM authenticated;
REVOKE ALL ON FUNCTION public._dispatch_match_reminders() FROM anon;

COMMENT ON FUNCTION public._dispatch_match_reminders() IS
  'Insere les notifs de rappel match (T-60/30/10/5 min) en respectant '
  'le ledger match_reminders_sent. SECURITY DEFINER : call depuis '
  'pg_cron uniquement.';

-- 4. Cron schedule ----------------------------------------------------
-- Idempotence : unschedule le job existant avant de le reschedule.
DO $$
DECLARE
  existing_jobid INT;
BEGIN
  SELECT jobid INTO existing_jobid
  FROM cron.job
  WHERE jobname = 'match_reminders_minute';
  IF existing_jobid IS NOT NULL THEN
    PERFORM cron.unschedule(existing_jobid);
  END IF;
END;
$$;

SELECT cron.schedule(
  'match_reminders_minute',
  '* * * * *',
  $cron$ SELECT public._dispatch_match_reminders(); $cron$
);
