-- C.2 — Filtre compétition multi-sélection : p_competition_ids uuid[]
-- remplace p_competition_id uuid. Le user doit être inscrit à AU MOINS
-- une des compétitions listées (OR).
--
-- Comme Postgres ne permet pas de garder 2 signatures avec arity
-- équivalente côté Dart (le client passerait l'array même si seul un
-- élément), on remplace l'ancienne signature. Le client Dart adapte
-- son repository.

CREATE OR REPLACE FUNCTION public.admin_filter_users(
  p_country_code   text     DEFAULT NULL,
  p_status         text     DEFAULT NULL,
  p_search         text     DEFAULT NULL,
  p_won            boolean  DEFAULT NULL,
  p_paid           boolean  DEFAULT NULL,
  p_rewarded       boolean  DEFAULT NULL,
  p_disputed       boolean  DEFAULT NULL,
  p_guilty_min     integer  DEFAULT NULL,
  p_competition_ids uuid[]  DEFAULT NULL,
  p_limit          integer  DEFAULT 100
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
     -- C.2 : Filtre multi-compétition. NULL ou tableau vide = pas de filtre.
     AND (p_competition_ids IS NULL
          OR array_length(p_competition_ids, 1) IS NULL
          OR EXISTS (
            SELECT 1 FROM public.competition_registrations cr
             WHERE cr.player_id = p.id
               AND cr.competition_id = ANY (p_competition_ids)))
   ORDER BY p.created_at DESC
   LIMIT GREATEST(p_limit, 1);
$$;

-- Drop l'ancienne signature mono uuid (devenue duplicate)
DROP FUNCTION IF EXISTS public.admin_filter_users(text, text, text, boolean, boolean, boolean, boolean, integer, uuid, integer);

COMMENT ON FUNCTION public.admin_filter_users(text, text, text, boolean, boolean, boolean, boolean, integer, uuid[], integer) IS
  'Lot C.2 — Filtre users avec multi-sélection de compétitions (OR). Combinable avec tous les autres critères.';
