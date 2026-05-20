-- ════════════════════════════════════════════════════════════════════
-- LOT B — SQL agrégats pour super-admin dashboard + revenue (item 7)
-- ════════════════════════════════════════════════════════════════════
-- 4 SECURITY DEFINER functions exposées en RPC :
--   1. get_super_admin_kpis()         → JSON KPIs globaux (dashboard)
--   2. get_top_players_by_wins(int)   → top joueurs par victoires
--   3. get_country_breakdown()        → répartition pays
--   4. get_revenue_breakdown(tz, tz)  → décomposition revenu période
--   5. get_revenue_per_competition(int) → revenu par compétition
--
-- Chaque function vérifie en interne que le caller est super_admin.

-- ─── Helper : check super_admin ─────────────────────────────────────
CREATE OR REPLACE FUNCTION public._require_super_admin()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM profiles
     WHERE id = auth.uid() AND role = 'super_admin'
  ) THEN
    RAISE EXCEPTION 'Forbidden: super_admin role required';
  END IF;
END;
$$;

-- ─── 1. KPIs globaux ────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.get_super_admin_kpis()
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
  v_total_users     integer;
  v_active_30d      integer;
  v_active_24h      integer;
  v_competitions    integer;
  v_ongoing         integer;
  v_total_commission numeric;
  v_total_revenue   numeric;
  v_total_payouts   numeric;
  v_margin_30d      numeric;
BEGIN
  PERFORM _require_super_admin();

  SELECT count(*) INTO v_total_users FROM profiles WHERE is_active = true;

  -- Approximation MAU : joueurs ayant joué un match OU payé OU s'être
  -- inscrit dans les 30 derniers jours.
  SELECT count(DISTINCT id) INTO v_active_30d FROM (
    SELECT player1_id AS id FROM matches WHERE updated_at >= now() - interval '30 days' AND player1_id IS NOT NULL
    UNION
    SELECT player2_id FROM matches WHERE updated_at >= now() - interval '30 days' AND player2_id IS NOT NULL
    UNION
    SELECT user_id FROM payments WHERE created_at >= now() - interval '30 days'
    UNION
    SELECT player_id FROM competition_registrations WHERE registered_at >= now() - interval '30 days'
  ) s WHERE id IS NOT NULL;

  -- DAU même logique sur 24h
  SELECT count(DISTINCT id) INTO v_active_24h FROM (
    SELECT player1_id AS id FROM matches WHERE updated_at >= now() - interval '24 hours' AND player1_id IS NOT NULL
    UNION
    SELECT player2_id FROM matches WHERE updated_at >= now() - interval '24 hours' AND player2_id IS NOT NULL
    UNION
    SELECT user_id FROM payments WHERE created_at >= now() - interval '24 hours'
    UNION
    SELECT player_id FROM competition_registrations WHERE registered_at >= now() - interval '24 hours'
  ) s WHERE id IS NOT NULL;

  SELECT count(*) INTO v_competitions FROM competitions;
  SELECT count(*) INTO v_ongoing FROM competitions WHERE status = 'ongoing';

  -- Commission ARENA des compétitions encaissables (au-delà de draft)
  SELECT COALESCE(sum(commission_xaf), 0) INTO v_total_commission
    FROM competitions
   WHERE status::text NOT IN ('draft', 'cancelled');

  -- Revenue brut = somme des paiements confirmés
  SELECT COALESCE(sum(amount_local), 0) INTO v_total_revenue
    FROM payments
   WHERE status = 'confirmed';

  SELECT COALESCE(sum(amount_local), 0) INTO v_total_payouts
    FROM payouts
   WHERE status = 'validated';

  -- Marge 30j = paiements confirmés - payouts validés sur 30j
  SELECT COALESCE(
    (SELECT sum(amount_local) FROM payments
       WHERE status = 'confirmed' AND validated_at >= now() - interval '30 days')
    -
    COALESCE(
      (SELECT sum(amount_local) FROM payouts
         WHERE status = 'validated' AND validated_at >= now() - interval '30 days'),
      0
    ),
    0
  ) INTO v_margin_30d;

  RETURN jsonb_build_object(
    'total_users', v_total_users,
    'active_30d', v_active_30d,
    'active_24h', v_active_24h,
    'dau_mau_ratio', CASE WHEN v_active_30d > 0
                          THEN ROUND(v_active_24h::numeric / v_active_30d * 100, 1)
                          ELSE 0 END,
    'total_competitions', v_competitions,
    'ongoing_competitions', v_ongoing,
    'total_commission_xaf', v_total_commission,
    'total_revenue_xaf', v_total_revenue,
    'total_payouts_xaf', v_total_payouts,
    'margin_30d_xaf', v_margin_30d
  );
END;
$$;

COMMENT ON FUNCTION public.get_super_admin_kpis() IS
  'Lot B — KPIs globaux pour SA1 super-admin dashboard. Verrouillé super_admin.';

GRANT EXECUTE ON FUNCTION public.get_super_admin_kpis() TO authenticated;

-- ─── 2. Top players by wins ─────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.get_top_players_by_wins(p_limit integer DEFAULT 10)
RETURNS TABLE (
  id uuid,
  username text,
  country_code text,
  avatar_color text,
  wins integer,
  total_earnings_xaf numeric
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
BEGIN
  PERFORM _require_super_admin();

  RETURN QUERY
  SELECT p.id,
         p.username,
         p.country_code,
         p.avatar_color,
         COALESCE((p.stats->>'wins')::integer, 0) AS wins,
         COALESCE((
           SELECT sum(amount_local) FROM payouts
            WHERE user_id = p.id AND status = 'validated'
         ), 0) AS total_earnings_xaf
    FROM profiles p
   WHERE p.is_active = true
   ORDER BY wins DESC NULLS LAST, total_earnings_xaf DESC NULLS LAST
   LIMIT p_limit;
END;
$$;

COMMENT ON FUNCTION public.get_top_players_by_wins(integer) IS
  'Lot B — Top joueurs par victoires (stats.wins) + earnings cumulés.';

GRANT EXECUTE ON FUNCTION public.get_top_players_by_wins(integer) TO authenticated;

-- ─── 3. Country breakdown ───────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.get_country_breakdown()
RETURNS TABLE (
  country_code text,
  user_count integer,
  ratio numeric
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
  v_total integer;
BEGIN
  PERFORM _require_super_admin();

  SELECT count(*) INTO v_total FROM profiles WHERE is_active = true;

  RETURN QUERY
  SELECT p.country_code,
         count(*)::integer AS user_count,
         CASE WHEN v_total > 0
              THEN ROUND(count(*)::numeric / v_total, 3)
              ELSE 0 END AS ratio
    FROM profiles p
   WHERE p.is_active = true AND p.country_code IS NOT NULL
   GROUP BY p.country_code
   ORDER BY user_count DESC
   LIMIT 10;
END;
$$;

COMMENT ON FUNCTION public.get_country_breakdown() IS
  'Lot B — Répartition pays des joueurs actifs (top 10).';

GRANT EXECUTE ON FUNCTION public.get_country_breakdown() TO authenticated;

-- ─── 4. Revenue breakdown sur période ───────────────────────────────
CREATE OR REPLACE FUNCTION public.get_revenue_breakdown(
  p_start timestamptz,
  p_end   timestamptz
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
  v_collected numeric;
  v_payouts   numeric;
  v_processor_fees numeric := 0;  -- V1 manuel P2P : 0
  v_margin    numeric;
BEGIN
  PERFORM _require_super_admin();

  SELECT COALESCE(sum(amount_local), 0) INTO v_collected
    FROM payments
   WHERE status = 'confirmed'
     AND COALESCE(validated_at, created_at) BETWEEN p_start AND p_end;

  SELECT COALESCE(sum(amount_local), 0) INTO v_payouts
    FROM payouts
   WHERE status = 'validated'
     AND COALESCE(validated_at, created_at) BETWEEN p_start AND p_end;

  v_margin := v_collected - v_payouts - v_processor_fees;

  RETURN jsonb_build_object(
    'period_start', p_start,
    'period_end', p_end,
    'collected_xaf', v_collected,
    'payouts_xaf', v_payouts,
    'processor_fees_xaf', v_processor_fees,
    'margin_xaf', v_margin,
    'margin_pct', CASE WHEN v_collected > 0
                       THEN ROUND(v_margin / v_collected * 100, 1)
                       ELSE 0 END
  );
END;
$$;

COMMENT ON FUNCTION public.get_revenue_breakdown(timestamptz, timestamptz) IS
  'Lot B — Décomposition revenu sur période pour SA4 super-admin revenue.';

GRANT EXECUTE ON FUNCTION public.get_revenue_breakdown(timestamptz, timestamptz) TO authenticated;

-- ─── 5. Revenue par compétition ─────────────────────────────────────
CREATE OR REPLACE FUNCTION public.get_revenue_per_competition(p_limit integer DEFAULT 20)
RETURNS TABLE (
  competition_id uuid,
  name text,
  game text,
  registered_count integer,
  revenue_xaf numeric,
  commission_xaf numeric
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
BEGIN
  PERFORM _require_super_admin();

  RETURN QUERY
  SELECT c.id AS competition_id,
         c.name,
         c.game::text,
         c.current_players AS registered_count,
         COALESCE((
           SELECT sum(amount_local) FROM payments
            WHERE payments.competition_id = c.id AND status = 'confirmed'
         ), 0) AS revenue_xaf,
         c.commission_xaf
    FROM competitions c
   WHERE c.status::text NOT IN ('draft', 'cancelled')
   ORDER BY c.created_at DESC
   LIMIT p_limit;
END;
$$;

COMMENT ON FUNCTION public.get_revenue_per_competition(integer) IS
  'Lot B — Revenu par compétition (payments + commission_xaf).';

GRANT EXECUTE ON FUNCTION public.get_revenue_per_competition(integer) TO authenticated;
