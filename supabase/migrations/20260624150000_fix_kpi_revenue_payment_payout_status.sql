-- =============================================================================
-- ARENA — Correction des KPI financiers (statuts payments/payouts erronés)
-- =============================================================================
-- Les fonctions de reporting financier filtraient sur des valeurs de statut
-- qui N'EXISTENT PAS dans les CHECK des tables → tous les montants à 0 :
--   * payments.status = 'confirmed'  → INVALIDE. CHECK = pending/processing/
--     awaiting_admin/succeeded/refund_pending/failed/rejected/refunded/expired.
--     Le statut « encaissé » réel est 'succeeded' (posé à la validation
--     super-admin du paiement P2P manuel). → revenus affichés à 0.
--   * payouts.status = 'validated'   → valeur VALIDE du CHECK mais JAMAIS écrite
--     par aucune fonction : le cycle réel est pending_admin_validation →
--     'completed' (via mark_payout_paid). → versements/marge jamais soustraits
--     (marge surévaluée = revenus).
--
-- Correctif : payments → 'succeeded', payouts → 'completed' dans les 4 fonctions
-- de reporting. Aucune autre logique modifiée (corps recréés à l'identique).
-- =============================================================================

-- ─── 1. get_super_admin_kpis ─────────────────────────────────────────────────
create or replace function public.get_super_admin_kpis()
returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $function$
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
   WHERE status = 'succeeded';

  SELECT COALESCE(sum(amount_local), 0) INTO v_total_payouts
    FROM payouts
   WHERE status = 'completed';

  SELECT COALESCE(
    (SELECT sum(amount_local) FROM payments
       WHERE status = 'succeeded' AND validated_at >= now() - interval '30 days')
    -
    COALESCE(
      (SELECT sum(amount_local) FROM payouts
         WHERE status = 'completed' AND validated_at >= now() - interval '30 days'),
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
$function$;

-- ─── 2. get_monthly_revenue ──────────────────────────────────────────────────
create or replace function public.get_monthly_revenue(p_months integer default 12)
returns table(month_start date, revenue_xaf numeric, margin_xaf numeric)
language plpgsql
stable security definer
set search_path to 'public'
as $function$
BEGIN
  PERFORM _require_super_admin();
  RETURN QUERY
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
             WHERE status = 'succeeded'
               AND date_trunc('month', COALESCE(validated_at, created_at))::date = m.month_start
         ), 0) AS revenue_xaf,
         COALESCE((
           SELECT sum(amount_local) FROM payments
             WHERE status = 'succeeded'
               AND date_trunc('month', COALESCE(validated_at, created_at))::date = m.month_start
         ), 0)
         -
         COALESCE((
           SELECT sum(amount_local) FROM payouts
             WHERE status = 'completed'
               AND date_trunc('month', COALESCE(validated_at, created_at))::date = m.month_start
         ), 0) AS margin_xaf
    FROM months m
   ORDER BY m.month_start;
END;
$function$;

-- ─── 3. get_revenue_breakdown ────────────────────────────────────────────────
create or replace function public.get_revenue_breakdown(p_start timestamp with time zone, p_end timestamp with time zone)
returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $function$
DECLARE
  v_collected numeric;
  v_payouts   numeric;
  v_processor_fees numeric := 0;  -- V1 manuel P2P : 0
  v_margin    numeric;
BEGIN
  PERFORM _require_super_admin();

  SELECT COALESCE(sum(amount_local), 0) INTO v_collected
    FROM payments
   WHERE status = 'succeeded'
     AND COALESCE(validated_at, created_at) BETWEEN p_start AND p_end;

  SELECT COALESCE(sum(amount_local), 0) INTO v_payouts
    FROM payouts
   WHERE status = 'completed'
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
$function$;

-- ─── 4. get_revenue_per_competition ──────────────────────────────────────────
create or replace function public.get_revenue_per_competition(p_limit integer default 20)
returns table(competition_id uuid, name text, game text, registered_count integer, revenue_xaf numeric, commission_xaf numeric)
language plpgsql
security definer
set search_path to 'public'
as $function$
BEGIN
  PERFORM _require_super_admin();

  RETURN QUERY
  SELECT c.id AS competition_id,
         c.name,
         c.game::text,
         c.current_players AS registered_count,
         COALESCE((
           SELECT sum(amount_local) FROM payments
            WHERE payments.competition_id = c.id AND status = 'succeeded'
         ), 0) AS revenue_xaf,
         c.commission_xaf
    FROM competitions c
   WHERE c.status::text NOT IN ('draft', 'cancelled')
   ORDER BY c.created_at DESC
   LIMIT p_limit;
END;
$function$;
