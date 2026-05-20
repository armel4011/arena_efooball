-- ════════════════════════════════════════════════════════════════════
-- Régénération d'une compétition terminée
-- ════════════════════════════════════════════════════════════════════
-- Permet à un admin de "rejouer" une compétition `completed` : crée une
-- NOUVELLE compétition (nouvel id) qui copie toute la configuration de
-- base, repart avec :
--   - status            = 'registration_open' (inscriptions à venir)
--   - current_players   = 0  (inscriptions remises à zéro)
--   - start_date        = now() + 7 jours (la date d'origine est passée)
--   - created_by        = l'admin appelant
-- Aucune inscription / match / bracket / phase n'est copié.
--
-- Le nom reçoit un suffixe " (édition N)" incrémental pour distinguer les
-- rééditions sans collision visuelle.

CREATE OR REPLACE FUNCTION public.regenerate_competition(p_competition_id uuid)
RETURNS SETOF public.competitions
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
  v_src       public.competitions%rowtype;
  v_base_name text;
  v_edition   integer;
  v_new_name  text;
  v_new       public.competitions%rowtype;
BEGIN
  IF NOT public.is_admin() THEN
    RAISE EXCEPTION 'forbidden: admin only';
  END IF;

  SELECT * INTO v_src FROM public.competitions WHERE id = p_competition_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'competition % not found', p_competition_id;
  END IF;
  IF v_src.status <> 'completed' THEN
    RAISE EXCEPTION 'only completed competitions can be regenerated (status=%)',
      v_src.status;
  END IF;

  -- Calcule le numéro d'édition : strip un éventuel suffixe existant.
  IF v_src.name ~ ' \(édition [0-9]+\)$' THEN
    v_base_name := regexp_replace(v_src.name, ' \(édition [0-9]+\)$', '');
    v_edition   := (regexp_match(v_src.name, ' \(édition ([0-9]+)\)$'))[1]::int + 1;
  ELSE
    v_base_name := v_src.name;
    v_edition   := 2;
  END IF;
  v_new_name := v_base_name || ' (édition ' || v_edition || ')';

  INSERT INTO public.competitions (
    name, game, description, banner_url, format,
    status, start_date, max_players,
    registration_fee, registration_currency,
    commission_pct, prize_pool_local, prize_pool_currency, sponsor_bonus_local,
    created_by,
    orange_money_code, mtn_momo_code,
    prize_distribution,
    match_interval_minutes, auto_generate_bracket,
    commission_xaf, referral_quota, format_config, round_intervals,
    referral_activity_mode, android_store_url, ios_store_url
  )
  VALUES (
    v_new_name, v_src.game, v_src.description, v_src.banner_url, v_src.format,
    'registration_open', now() + interval '7 days', v_src.max_players,
    v_src.registration_fee, v_src.registration_currency,
    v_src.commission_pct, v_src.prize_pool_local, v_src.prize_pool_currency,
    v_src.sponsor_bonus_local,
    auth.uid(),
    v_src.orange_money_code, v_src.mtn_momo_code,
    v_src.prize_distribution,
    v_src.match_interval_minutes, v_src.auto_generate_bracket,
    v_src.commission_xaf, v_src.referral_quota, v_src.format_config,
    v_src.round_intervals,
    v_src.referral_activity_mode, v_src.android_store_url, v_src.ios_store_url
  )
  RETURNING * INTO v_new;

  RETURN NEXT v_new;
END;
$$;

COMMENT ON FUNCTION public.regenerate_competition(uuid) IS
  'Duplique une compétition terminée en une nouvelle compétition '
  '(registration_open, inscriptions à 0, date J+7). Admin only.';

-- ACL : pas d'anon, authenticated uniquement (le gate is_admin() est
-- vérifié dans le corps de la fonction).
REVOKE EXECUTE ON FUNCTION public.regenerate_competition(uuid) FROM anon, public;
GRANT  EXECUTE ON FUNCTION public.regenerate_competition(uuid) TO authenticated;
