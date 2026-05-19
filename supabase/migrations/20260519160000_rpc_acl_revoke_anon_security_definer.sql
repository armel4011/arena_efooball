-- ════════════════════════════════════════════════════════════════════
-- Audit 2026-05-19 — Verrouillage RPC ACL sur 20 SECURITY DEFINER
-- ════════════════════════════════════════════════════════════════════
-- Suite à 20260515110001_security_hardening_rpc_acl + audit complet
-- 2026-05-19. L'advisor `anon_security_definer_function_executable`
-- flagge encore 20 fonctions SECURITY DEFINER appelables par anon via
-- /rest/v1/rpc/.
--
-- Re-revoke défensif (le grant peut s'être perdu après un DROP/CREATE
-- ultérieur de la fn) + extension à 18 nouvelles cibles.
--
-- Vérifications préalables (cf. audit) :
--   - `generate_*_bracket` & `try_schedule_next_round` ne sont JAMAIS
--     appelées depuis Flutter (grep `lib/`). Seul le trigger
--     `trigger_auto_generate_bracket` les invoque.
--   - `get_monthly_revenue` & `get_monthly_signups` n'avaient PAS de
--     gate `_require_super_admin()` interne — corrigé ici.

-- ─── 1. Triggers internes : retirés de tous les rôles REST ──────────

revoke all on function public.enforce_referral_quota_on_registration() from public, anon, authenticated;
revoke all on function public.trigger_auto_generate_bracket() from public, anon, authenticated;
revoke all on function public.trigger_try_schedule_next_round() from public, anon, authenticated;

comment on function public.enforce_referral_quota_on_registration() is
  '[SECURITY DEFINER intentional] Trigger interne — pas appelable via RPC. Bloque INSERT competition_registrations si quota referral non atteint.';
comment on function public.trigger_auto_generate_bracket() is
  '[SECURITY DEFINER intentional] Trigger interne — pas appelable via RPC. Génère le bracket auto quand max_players atteint.';
comment on function public.trigger_try_schedule_next_round() is
  '[SECURITY DEFINER intentional] Trigger interne — pas appelable via RPC. Avance le bracket dès qu''un match passe completed/forfeited.';

-- ─── 2. Bracket generators : trigger-only, jamais via Flutter ───────

revoke all on function public.generate_single_elim_bracket(uuid) from public, anon, authenticated;
revoke all on function public.generate_round_robin_bracket(uuid) from public, anon, authenticated;
revoke all on function public.generate_groups_then_knockout_bracket(uuid) from public, anon, authenticated;
revoke all on function public.try_schedule_next_round(uuid) from public, anon, authenticated;

comment on function public.generate_single_elim_bracket(uuid) is
  '[SECURITY DEFINER intentional] Appelée uniquement par trigger_auto_generate_bracket. EXECUTE révoqué de anon/authenticated.';
comment on function public.generate_round_robin_bracket(uuid) is
  '[SECURITY DEFINER intentional] Appelée uniquement par trigger_auto_generate_bracket. EXECUTE révoqué de anon/authenticated.';
comment on function public.generate_groups_then_knockout_bracket(uuid) is
  '[SECURITY DEFINER intentional] Appelée uniquement par trigger_auto_generate_bracket. EXECUTE révoqué de anon/authenticated.';
comment on function public.try_schedule_next_round(uuid) is
  '[SECURITY DEFINER intentional] Appelée uniquement par trigger_try_schedule_next_round. EXECUTE révoqué de anon/authenticated.';

-- ─── 3. _require_super_admin : helper interne, zéro accès REST ──────

revoke all on function public._require_super_admin() from public, anon, authenticated;

comment on function public._require_super_admin() is
  '[SECURITY DEFINER intentional] Helper interne. Appelée par PERFORM dans les RPC super-admin. EXECUTE révoqué de anon/authenticated — le chain SECURITY DEFINER suffit.';

-- ─── 4. Ajoute gate _require_super_admin() à get_monthly_revenue ───
-- L'audit a découvert que ces 2 fonctions SQL n'avaient pas le PERFORM
-- _require_super_admin() de leurs cousines. Réécrites en plpgsql.

CREATE OR REPLACE FUNCTION public.get_monthly_revenue(p_months integer DEFAULT 12)
RETURNS TABLE(month_start date, revenue_xaf numeric, margin_xaf numeric)
LANGUAGE plpgsql
STABLE SECURITY DEFINER
SET search_path TO 'public'
AS $function$
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
END;
$function$;

-- ─── 5. Ajoute gate _require_super_admin() à get_monthly_signups ───

CREATE OR REPLACE FUNCTION public.get_monthly_signups(p_months integer DEFAULT 12)
RETURNS TABLE(month_start date, count integer)
LANGUAGE plpgsql
STABLE SECURITY DEFINER
SET search_path TO 'public'
AS $function$
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
         (SELECT count(*)::integer FROM profiles p
           WHERE date_trunc('month', p.created_at)::date = m.month_start)
    FROM months m
   ORDER BY m.month_start;
END;
$function$;

-- ─── 6. Super-admin RPC : revoke anon, gate interne déjà présent ────

revoke all on function public.get_super_admin_kpis() from public, anon;
grant execute on function public.get_super_admin_kpis() to authenticated;

revoke all on function public.get_revenue_breakdown(timestamptz, timestamptz) from public, anon;
grant execute on function public.get_revenue_breakdown(timestamptz, timestamptz) to authenticated;

revoke all on function public.get_revenue_per_competition(integer) from public, anon;
grant execute on function public.get_revenue_per_competition(integer) to authenticated;

revoke all on function public.get_country_breakdown() from public, anon;
grant execute on function public.get_country_breakdown() to authenticated;

revoke all on function public.get_top_players_by_wins(integer) from public, anon;
grant execute on function public.get_top_players_by_wins(integer) to authenticated;

revoke all on function public.get_monthly_revenue(integer) from public, anon;
grant execute on function public.get_monthly_revenue(integer) to authenticated;

revoke all on function public.get_monthly_signups(integer) from public, anon;
grant execute on function public.get_monthly_signups(integer) to authenticated;

-- ─── 7. User helpers : re-revoke anon (perdu après DROP/CREATE) ─────

revoke all on function public.is_admin() from public, anon;
grant execute on function public.is_admin() to authenticated;

revoke all on function public.is_super_admin() from public, anon;
grant execute on function public.is_super_admin() to authenticated;

revoke all on function public.is_blocked_pair(uuid, uuid) from public, anon;
grant execute on function public.is_blocked_pair(uuid, uuid) to authenticated;

revoke all on function public.can_register_via_referral(uuid, uuid) from public, anon;
grant execute on function public.can_register_via_referral(uuid, uuid) to authenticated;

revoke all on function public.heartbeat() from public, anon;
grant execute on function public.heartbeat() to authenticated;

comment on function public.heartbeat() is
  '[SECURITY DEFINER intentional] User RPC. UPDATE profiles.last_seen_at = now() WHERE id = auth.uid(). EXECUTE révoqué de anon.';
