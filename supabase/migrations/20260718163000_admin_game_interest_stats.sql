-- ============================================================================
-- RPC admin_game_interest_stats — résultats agrégés du sondage (côté admin)
-- ============================================================================
-- Renvoie un objet JSON : le nombre de répondants et, par jeu, combien
-- d'utilisateurs sont intéressés. Gardé comme admin_filter_users :
--   • is_admin() requis (sinon ensemble vide → respondents 0, counts {}) ;
--   • cloisonnement pays (un admin scopé ne voit que ses pays).
-- Ne compte que les répondants réels (game_interests non NULL et non vide).
-- Forme : { "respondents": 123, "counts": { "efootball": 40, "dream_league": 12 } }
-- ----------------------------------------------------------------------------

create or replace function public.admin_game_interest_stats()
returns jsonb
language sql
stable security definer
set search_path = public
as $$
  with scoped as (
    select p.game_interests
      from public.profiles p
     WHERE public.is_admin()
       AND (public.is_super_admin()
            OR public.admin_allowed_countries((select auth.uid())) IS NULL
            OR p.country_code = ANY (public.admin_allowed_countries((select auth.uid()))))
       AND p.game_interests IS NOT NULL
       AND array_length(p.game_interests, 1) IS NOT NULL
  )
  select jsonb_build_object(
    'respondents', (select count(*) from scoped),
    'counts', coalesce((
      select jsonb_object_agg(g, c)
        from (
          select g, count(*)::int as c
            from scoped s, unnest(s.game_interests) as g
           group by g
        ) t
    ), '{}'::jsonb)
  );
$$;

revoke all on function public.admin_game_interest_stats() from public, anon;
grant execute on function public.admin_game_interest_stats() to authenticated;
