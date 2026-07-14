-- ════════════════════════════════════════════════════════════════════
-- FIX P2 (audit 2026-07-14) — `admin_filter_users` : cloisonnement pays
-- ════════════════════════════════════════════════════════════════════
-- `admin_filter_users` (SECURITY DEFINER, gate `is_admin()`) renvoie
-- `SETOF profiles` — dont l'email. `p_country_code` n'était qu'un FILTRE
-- optionnel, pas une CONTRAINTE : un admin simple scopé à un pays pouvait
-- lister username + email de TOUS les pays, contournant le cloisonnement
-- appliqué partout ailleurs (generate_payouts, mark_payout_paid, admin_scoping).
--
-- Correctif : borner les lignes au périmètre pays de l'appelant.
--   • super-admin → aucune restriction (accès global) ;
--   • admin sans scope (admin_allowed_countries NULL) → aucune restriction ;
--   • admin scopé {CM,…} → uniquement les profils dont country_code ∈ scope.
-- `p_country_code` reste un filtre additionnel (l'UI l'utilise), mais ne peut
-- plus élargir au-delà du périmètre. `(select auth.uid())` pour l'initplan.
--
-- CREATE OR REPLACE conserve owner + GRANTs → pas de revoke/grant à ré-appliquer.
-- ════════════════════════════════════════════════════════════════════

CREATE OR REPLACE FUNCTION public.admin_filter_users(
  p_country_code    text     DEFAULT NULL,
  p_status          text     DEFAULT NULL,
  p_search          text     DEFAULT NULL,
  p_won             boolean  DEFAULT NULL,
  p_paid            boolean  DEFAULT NULL,
  p_rewarded        boolean  DEFAULT NULL,
  p_disputed        boolean  DEFAULT NULL,
  p_guilty_min      integer  DEFAULT NULL,
  p_competition_ids uuid[]   DEFAULT NULL,
  p_limit           integer  DEFAULT 100
)
RETURNS SETOF public.profiles
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT p.*
    FROM public.profiles p
   WHERE public.is_admin()  -- gate explicite : équivalent à l'ex-RLS
     -- Cloisonnement pays : super-admin ou admin global (scope NULL) = tout ;
     -- admin scopé = uniquement les profils de ses pays autorisés.
     AND (public.is_super_admin()
          OR public.admin_allowed_countries((select auth.uid())) IS NULL
          OR p.country_code = ANY (public.admin_allowed_countries((select auth.uid()))))
     AND (p_country_code IS NULL OR p.country_code = p_country_code)
     AND (p_status IS NULL
          OR (p_status = 'active'      AND p.is_active = true)
          OR (p_status = 'banned'      AND p.is_active = false)
          OR (p_status = 'kyc_pending' AND p.kyc_status = 'pending'))
     AND (p_search IS NULL
          OR p.username ILIKE '%' || p_search || '%'
          OR p.email    ILIKE '%' || p_search || '%')
     AND (COALESCE(p_won, false) = false
          OR EXISTS (SELECT 1 FROM public.competition_registrations cr
             WHERE cr.player_id = p.id AND cr.final_rank = 1))
     AND (COALESCE(p_paid, false) = false
          OR EXISTS (SELECT 1 FROM public.payments pay
             WHERE pay.user_id = p.id
               AND pay.status IN ('succeeded', 'validated')))
     AND (COALESCE(p_rewarded, false) = false
          OR EXISTS (SELECT 1 FROM public.payouts po
             WHERE po.user_id = p.id AND po.status = 'completed'))
     AND (COALESCE(p_disputed, false) = false
          OR EXISTS (SELECT 1 FROM public.disputes d
              JOIN public.matches m ON m.id = d.match_id
             WHERE p.id IN (m.player1_id, m.player2_id)))
     AND (p_guilty_min IS NULL
          OR (SELECT count(*) FROM public.disputes d
               WHERE d.guilty_party_id = p.id) >= p_guilty_min)
     AND (p_competition_ids IS NULL
          OR array_length(p_competition_ids, 1) IS NULL
          OR EXISTS (
            SELECT 1 FROM public.competition_registrations cr
             WHERE cr.player_id = p.id
               AND cr.competition_id = ANY (p_competition_ids)))
   ORDER BY p.created_at DESC
   LIMIT GREATEST(p_limit, 1);
$$;

COMMENT ON FUNCTION public.admin_filter_users(
  text, text, text, boolean, boolean, boolean, boolean, integer, uuid[], integer
) IS
  'Liste profils filtrés (admin/super-admin). SECURITY DEFINER + gate '
  'is_admin() dans le corps (audit 2026-05-23) + cloisonnement pays : un admin '
  'scopé ne voit que ses pays autorisés (audit 2026-07-14). Renvoie [] si '
  'appelant non-admin.';
