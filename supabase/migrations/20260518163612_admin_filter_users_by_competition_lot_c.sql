-- ════════════════════════════════════════════════════════════════════
-- LOT C — Étend admin_filter_users avec un filtre par compétition (item 2)
-- ════════════════════════════════════════════════════════════════════
-- Permet au super-admin de cibler uniquement les inscrits à une
-- compétition donnée (pour la page Users SA3 et pour Broadcast SA2bis).
-- Le filtre est combinable avec tous les critères existants.

CREATE OR REPLACE FUNCTION public.admin_filter_users(
  p_country_code  text   DEFAULT NULL,
  p_status        text   DEFAULT NULL,
  p_search        text   DEFAULT NULL,
  p_won           boolean DEFAULT NULL,
  p_paid          boolean DEFAULT NULL,
  p_rewarded      boolean DEFAULT NULL,
  p_disputed      boolean DEFAULT NULL,
  p_guilty_min    integer DEFAULT NULL,
  p_competition_id uuid   DEFAULT NULL,
  p_limit         integer DEFAULT 100
)
RETURNS SETOF profiles
LANGUAGE sql
STABLE
SET search_path TO 'public'
AS $$
  SELECT p.*
    FROM public.profiles p
   WHERE (p_country_code IS NULL OR p.country_code = p_country_code)
     AND (p_status IS NULL
          OR (p_status = 'active'      AND p.is_active = true)
          OR (p_status = 'banned'      AND p.is_active = false)
          OR (p_status = 'kyc_pending' AND p.kyc_status = 'pending'))
     AND (p_search IS NULL
          OR p.username ILIKE '%' || p_search || '%'
          OR p.email    ILIKE '%' || p_search || '%')
     AND (COALESCE(p_won, false) = false
          OR EXISTS (
            SELECT 1 FROM public.competition_registrations cr
             WHERE cr.player_id = p.id AND cr.final_rank = 1))
     AND (COALESCE(p_paid, false) = false
          OR EXISTS (
            SELECT 1 FROM public.payments pay
             WHERE pay.user_id = p.id
               AND pay.status IN ('succeeded', 'validated')))
     AND (COALESCE(p_rewarded, false) = false
          OR EXISTS (
            SELECT 1 FROM public.payouts po
             WHERE po.user_id = p.id AND po.status = 'completed'))
     AND (COALESCE(p_disputed, false) = false
          OR EXISTS (
            SELECT 1 FROM public.disputes d
              JOIN public.matches m ON m.id = d.match_id
             WHERE p.id IN (m.player1_id, m.player2_id)))
     AND (p_guilty_min IS NULL
          OR (SELECT count(*) FROM public.disputes d
               WHERE d.guilty_party_id = p.id) >= p_guilty_min)
     -- NEW : Filtre par compétition (Lot C, item 2)
     AND (p_competition_id IS NULL
          OR EXISTS (
            SELECT 1 FROM public.competition_registrations cr
             WHERE cr.player_id = p.id
               AND cr.competition_id = p_competition_id))
   ORDER BY p.created_at DESC
   LIMIT GREATEST(p_limit, 1);
$$;

COMMENT ON FUNCTION public.admin_filter_users(text, text, text, boolean, boolean, boolean, boolean, integer, uuid, integer) IS
  'Lot C — Étend admin_filter_users avec p_competition_id : ne renvoie que les utilisateurs inscrits à la compétition. Combinable avec tous les autres critères.';

-- ─── Helper : liste des compétitions activables pour le filtre ──────
-- (UI dropdown) — pas de status draft/cancelled, ordre récent.
CREATE OR REPLACE FUNCTION public.list_filterable_competitions(p_limit integer DEFAULT 50)
RETURNS TABLE (
  id uuid,
  name text,
  status text,
  game text,
  current_players integer,
  max_players integer,
  start_date timestamptz
)
LANGUAGE sql
STABLE
SET search_path TO 'public'
AS $$
  SELECT c.id,
         c.name,
         c.status::text,
         c.game::text,
         c.current_players,
         c.max_players,
         c.start_date
    FROM public.competitions c
   WHERE c.status::text NOT IN ('draft', 'cancelled')
   ORDER BY c.created_at DESC
   LIMIT GREATEST(p_limit, 1);
$$;

COMMENT ON FUNCTION public.list_filterable_competitions(integer) IS
  'Lot C — Liste légère des compétitions pour le dropdown filter (super-admin users + broadcast).';

GRANT EXECUTE ON FUNCTION public.list_filterable_competitions(integer) TO authenticated;
