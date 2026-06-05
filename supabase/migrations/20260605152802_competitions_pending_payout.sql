-- =============================================================================
-- ARENA — Génération payout rétroactive : liste des compétitions à régler
-- =============================================================================
-- `generate_payouts` est par-compétition (bouton onglet ACTIONS) et idempotent.
-- Trou : aucune VUE d'ensemble des compétitions `completed` qui ont des gains à
-- distribuer mais dont les versements n'ont jamais été générés (oubli admin, ou
-- compétitions terminées avant F-1). → un gagnant peut ne jamais être payé sans
-- que personne ne le remarque.
--
-- Cette RPC alimente un onglet « À GÉNÉRER » dans /super/payouts : le
-- super-admin voit la liste et clique « Générer » par compétition.
-- =============================================================================

create or replace function public.competitions_pending_payout()
returns table (
  id               uuid,
  name             text,
  prize_pool_local numeric,
  currency         text,
  completed_at     timestamptz
)
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
  if not public.is_super_admin() then
    raise exception 'Reserve au super-admin' using errcode = '42501';
  end if;

  return query
    select c.id, c.name, c.prize_pool_local, c.registration_currency, c.updated_at
      from public.competitions c
     where c.status = 'completed'
       and c.prize_pool_local > 0
       and not exists (
         select 1 from public.payouts p where p.competition_id = c.id
       )
     order by c.updated_at desc;
end;
$$;

comment on function public.competitions_pending_payout() is
  'F-1 (rétro) : compétitions completed avec gains (prize_pool>0) mais sans '
  'payouts générés → file « à générer » pour le super-admin. Gate super-admin.';

revoke execute on function public.competitions_pending_payout() from anon, public;
grant execute on function public.competitions_pending_payout() to authenticated;
