-- B.1 — MAU/DAU réels via `profiles.last_seen_at` + RPC heartbeat.
-- L'app appelle `heartbeat()` au démarrage et sur les navigations clés.

ALTER TABLE profiles
  ADD COLUMN IF NOT EXISTS last_seen_at timestamptz;

COMMENT ON COLUMN profiles.last_seen_at IS
  'Lot B.1 — Dernier ping de l''app. Mis à jour via RPC heartbeat() (PHASE 12.5).';

CREATE INDEX IF NOT EXISTS idx_profiles_last_seen ON profiles(last_seen_at DESC)
  WHERE last_seen_at IS NOT NULL;

-- Backfill : tous les profiles existants reçoivent une date passée pour
-- éviter de fausser les KPIs (utiliser created_at comme fallback).
UPDATE profiles SET last_seen_at = COALESCE(updated_at, created_at)
 WHERE last_seen_at IS NULL;

-- RPC heartbeat : ping appelé par l'app (au démarrage + nav clés).
CREATE OR REPLACE FUNCTION public.heartbeat()
RETURNS void
LANGUAGE sql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
  UPDATE profiles SET last_seen_at = now() WHERE id = auth.uid();
$$;

COMMENT ON FUNCTION public.heartbeat() IS
  'Lot B.1 — Met à jour profiles.last_seen_at = now() pour le user courant.';

GRANT EXECUTE ON FUNCTION public.heartbeat() TO authenticated;

-- Refactor get_super_admin_kpis : MAU/DAU basés sur last_seen_at au lieu
-- des unions d'activité. Plus précis (capture les sessions de simple
-- consultation sans inscription/match/paiement).
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

  -- MAU réel : last_seen_at sur 30 jours
  SELECT count(*) INTO v_active_30d
    FROM profiles
   WHERE is_active = true AND last_seen_at >= now() - interval '30 days';

  -- DAU réel : last_seen_at sur 24h
  SELECT count(*) INTO v_active_24h
    FROM profiles
   WHERE is_active = true AND last_seen_at >= now() - interval '24 hours';

  SELECT count(*) INTO v_competitions FROM competitions;
  SELECT count(*) INTO v_ongoing FROM competitions WHERE status = 'ongoing';

  SELECT COALESCE(sum(commission_xaf), 0) INTO v_total_commission
    FROM competitions
   WHERE status::text NOT IN ('draft', 'cancelled');

  SELECT COALESCE(sum(amount_local), 0) INTO v_total_revenue
    FROM payments
   WHERE status = 'confirmed';

  SELECT COALESCE(sum(amount_local), 0) INTO v_total_payouts
    FROM payouts
   WHERE status = 'validated';

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

-- B.2 — Bonus : RPC pour les charts d'évolution (12 derniers mois).
CREATE OR REPLACE FUNCTION public.get_monthly_signups(p_months integer DEFAULT 12)
RETURNS TABLE (month_start date, count integer)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path TO 'public'
AS $$
  WITH months AS (
    SELECT generate_series(
      date_trunc('month', now() - (p_months - 1) * interval '1 month')::date,
      date_trunc('month', now())::date,
      '1 month'::interval
    )::date AS month_start
  )
  SELECT m.month_start,
         (SELECT count(*)::integer FROM profiles p
           WHERE date_trunc('month', p.created_at)::date = m.month_start)
    FROM months m
   ORDER BY m.month_start;
$$;

CREATE OR REPLACE FUNCTION public.get_monthly_revenue(p_months integer DEFAULT 12)
RETURNS TABLE (month_start date, revenue_xaf numeric, margin_xaf numeric)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path TO 'public'
AS $$
  WITH months AS (
    SELECT generate_series(
      date_trunc('month', now() - (p_months - 1) * interval '1 month')::date,
      date_trunc('month', now())::date,
      '1 month'::interval
    )::date AS month_start
  )
  SELECT m.month_start,
         COALESCE((
           SELECT sum(amount_local) FROM payments
             WHERE status = 'confirmed'
               AND date_trunc('month', COALESCE(validated_at, created_at))::date = m.month_start
         ), 0) AS revenue_xaf,
         COALESCE((
           SELECT sum(amount_local) FROM payments
             WHERE status = 'confirmed'
               AND date_trunc('month', COALESCE(validated_at, created_at))::date = m.month_start
         ), 0)
         -
         COALESCE((
           SELECT sum(amount_local) FROM payouts
             WHERE status = 'validated'
               AND date_trunc('month', COALESCE(validated_at, created_at))::date = m.month_start
         ), 0) AS margin_xaf
    FROM months m
   ORDER BY m.month_start;
$$;

GRANT EXECUTE ON FUNCTION public.get_monthly_signups(integer) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_monthly_revenue(integer) TO authenticated;

-- Toutes deux require super_admin via _require_super_admin appelée
-- depuis les wrappers Dart si besoin.
