-- ============================================================================
-- admin_filter_users : ajouter le filtre « intéressé par le(s) jeu(x) »
-- ============================================================================
-- Nouveau paramètre `p_games text[]` : ne garde que les users dont
-- game_interests recoupe au moins un des jeux demandés (opérateur &&).
-- Ajouter un paramètre = nouvelle signature → on DROP explicitement l'ancienne
-- surcharge avant de recréer (cf. 20260523110000_drop_admin_filter_users_legacy_overload).
-- Le reste du corps est identique à 20260714130000 (dernière def, scope pays).
-- ----------------------------------------------------------------------------

drop function if exists public.admin_filter_users(
  text, text, text, boolean, boolean, boolean, boolean, integer, uuid[], integer
);

create or replace function public.admin_filter_users(
  p_country_code    text    default null,
  p_status          text    default null,
  p_search          text    default null,
  p_won             boolean default null,
  p_paid            boolean default null,
  p_rewarded        boolean default null,
  p_disputed        boolean default null,
  p_guilty_min      integer default null,
  p_competition_ids uuid[]  default null,
  p_games           text[]  default null,
  p_limit           integer default 100
)
returns setof public.profiles
language sql
stable security definer
set search_path to 'public'
as $function$
  SELECT p.*
    FROM public.profiles p
   WHERE public.is_admin()
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
     AND (p_games IS NULL
          OR array_length(p_games, 1) IS NULL
          OR p.game_interests && p_games)
   ORDER BY p.created_at DESC
   LIMIT GREATEST(p_limit, 1);
$function$;

revoke all on function public.admin_filter_users(
  text, text, text, boolean, boolean, boolean, boolean, integer, uuid[], text[], integer
) from public, anon;
grant execute on function public.admin_filter_users(
  text, text, text, boolean, boolean, boolean, boolean, integer, uuid[], text[], integer
) to authenticated, service_role;
