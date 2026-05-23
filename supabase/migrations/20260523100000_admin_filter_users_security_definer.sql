-- Audit sécu 2026-05-23 — Item #3
--
-- admin_filter_users était SECURITY INVOKER. La protection venait
-- uniquement de la RLS profiles_admin_all (using is_admin()). Si cette
-- policy dérive un jour (rename, suppression accidentelle, scope qui
-- élargit le set authorisé), le RPC fuite la liste de tous les
-- utilisateurs filtrables — y compris email.
--
-- Hardening : on passe en SECURITY DEFINER et on déplace le gate dans
-- le corps du RPC via `WHERE public.is_admin()`. Avec DEFINER, RLS est
-- bypassée par le owner (postgres), donc on remplit ce trou à la main.
-- Si l'appelant n'est pas admin, la clause WHERE court-circuite et le
-- RPC renvoie 0 ligne — exactement le comportement précédent côté
-- client (la RLS répondait pareil), donc pas de breaking côté Dart.
--
-- Le `set search_path = public` reste explicite : sans lui, DEFINER
-- est exploitable via search_path hijacking (ex: un user crée
-- public.is_admin() dans son schéma temporaire et la fonction
-- l'appellerait sous son propre privilège).
--
-- CREATE OR REPLACE conserve owner + GRANTs existants → pas besoin de
-- ré-appliquer le revoke/grant déjà posé en 20260515130001.

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
  'Liste profils filtrés (admin/super-admin). SECURITY DEFINER + '
  'gate is_admin() dans le corps (audit 2026-05-23). Renvoie [] si '
  'appelant non-admin — même comportement que l''ancien INVOKER+RLS.';
