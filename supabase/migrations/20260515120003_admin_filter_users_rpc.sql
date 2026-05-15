-- Phase 12.5 — RPC admin_filter_users : filtre profiles selon les
-- critères classiques (pays, statut, recherche) + 5 critères avancés
-- qui requièrent des EXISTS cross-tables. SECURITY INVOKER → RLS de
-- profiles_admin_all gate les non-admins (ne verront que leur propre
-- ligne, qui ne matchera quasi-jamais les filtres avancés).

create or replace function public.admin_filter_users(
  p_country_code text default null,
  p_status text default null,        -- 'active' | 'banned' | 'kyc_pending'
  p_search text default null,
  p_won boolean default null,        -- true → a remporté ≥ 1 compétition (final_rank=1)
  p_paid boolean default null,       -- true → a payé ≥ 1 inscription (succeeded/validated)
  p_rewarded boolean default null,   -- true → a reçu ≥ 1 payout complété
  p_disputed boolean default null,   -- true → impliqué dans ≥ 1 dispute (match)
  p_guilty boolean default null,     -- true → désigné coupable d'≥ 1 dispute
  p_limit int default 100
)
returns setof public.profiles
language sql
stable
security invoker
set search_path = public
as $$
  select p.*
  from public.profiles p
  where (p_country_code is null or p.country_code = p_country_code)
    and (p_status is null
         or (p_status = 'active'      and p.is_active = true)
         or (p_status = 'banned'      and p.is_active = false)
         or (p_status = 'kyc_pending' and p.kyc_status = 'pending'))
    and (p_search is null
         or p.username ilike '%' || p_search || '%'
         or p.email    ilike '%' || p_search || '%')
    and (coalesce(p_won, false) = false
         or exists (
           select 1 from public.competition_registrations cr
           where cr.player_id = p.id and cr.final_rank = 1))
    and (coalesce(p_paid, false) = false
         or exists (
           select 1 from public.payments pay
           where pay.user_id = p.id
             and pay.status in ('succeeded', 'validated')))
    and (coalesce(p_rewarded, false) = false
         or exists (
           select 1 from public.payouts po
           where po.user_id = p.id and po.status = 'completed'))
    and (coalesce(p_disputed, false) = false
         or exists (
           select 1 from public.disputes d
           join public.matches m on m.id = d.match_id
           where p.id in (m.player1_id, m.player2_id)))
    and (coalesce(p_guilty, false) = false
         or exists (
           select 1 from public.disputes d
           where d.guilty_party_id = p.id))
  order by p.created_at desc
  limit greatest(p_limit, 1);
$$;

revoke all on function public.admin_filter_users(
  text, text, text, boolean, boolean, boolean, boolean, boolean, int
) from public, anon;
grant execute on function public.admin_filter_users(
  text, text, text, boolean, boolean, boolean, boolean, boolean, int
) to authenticated;

comment on function public.admin_filter_users(
  text, text, text, boolean, boolean, boolean, boolean, boolean, int
) is
  'Liste des profils filtrés (super-admin). SECURITY INVOKER → RLS '
  'profiles_admin_all gate l''accès aux non-admins. Utilisé par '
  'super_admin_users + super_admin_broadcast pour cibler les notifs.';
