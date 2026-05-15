-- Phase 12.6 — Filtre coupable multi-seuil (≥1 / ≥2 / ≥3 litiges).
--
-- Le précédent admin_filter_users acceptait juste p_guilty boolean :
-- "a au moins 1 verdict coupable". Pour permettre au super-admin de
-- repérer les récidivistes (et de cibler les bannis à vie via la règle
-- 3-strikes), on remplace ce paramètre par p_guilty_min int (1/2/3 —
-- NULL = pas de filtre).

drop function if exists public.admin_filter_users(
  text, text, text, boolean, boolean, boolean, boolean, boolean, int
);

create or replace function public.admin_filter_users(
  p_country_code text default null,
  p_status text default null,        -- 'active' | 'banned' | 'kyc_pending'
  p_search text default null,
  p_won boolean default null,        -- true → a remporté ≥ 1 compétition (final_rank=1)
  p_paid boolean default null,       -- true → a payé ≥ 1 inscription (succeeded/validated)
  p_rewarded boolean default null,   -- true → a reçu ≥ 1 payout complété
  p_disputed boolean default null,   -- true → impliqué dans ≥ 1 dispute (match)
  p_guilty_min int default null,     -- 1/2/3 → coupable dans ≥ N disputes (NULL = ignoré)
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
    and (p_guilty_min is null
         or (
           select count(*) from public.disputes d
           where d.guilty_party_id = p.id
         ) >= p_guilty_min)
  order by p.created_at desc
  limit greatest(p_limit, 1);
$$;

revoke all on function public.admin_filter_users(
  text, text, text, boolean, boolean, boolean, boolean, int, int
) from public, anon;
grant execute on function public.admin_filter_users(
  text, text, text, boolean, boolean, boolean, boolean, int, int
) to authenticated;

comment on function public.admin_filter_users(
  text, text, text, boolean, boolean, boolean, boolean, int, int
) is
  'Liste des profils filtrés (super-admin). SECURITY INVOKER → RLS '
  'profiles_admin_all gate l''accès aux non-admins. '
  'p_guilty_min : seuil min de verdicts coupables (1/2/3 — null=ignore).';
