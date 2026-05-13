-- =============================================================================
-- 2026-05-14 — Suppression cascade d'une compétition (super-admin only).
--
-- Problème : `payments.competition_id`, `payouts.competition_id` et
-- `platform_revenue.competition_id` ont `ON DELETE RESTRICT`, et aucune
-- policy DELETE n'existe pour admin sur ces 3 tables. Du coup, la
-- suppression d'une compétition échoue toujours avec une FK violation.
--
-- Solution : une fonction SECURITY DEFINER qui :
--   1. vérifie que le caller est admin
--   2. supprime payouts, platform_revenue, payments liés
--   3. supprime la compétition (registrations/matches/brackets cascadent
--      déjà via leurs FK existantes en `on delete cascade`)
-- Le tout dans une transaction atomique côté Postgres.
-- =============================================================================

create or replace function public.delete_competition_cascade(p_competition_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if not public.is_admin() then
    raise exception 'forbidden: admin only';
  end if;

  delete from public.payouts          where competition_id = p_competition_id;
  delete from public.platform_revenue where competition_id = p_competition_id;
  delete from public.payments         where competition_id = p_competition_id;
  delete from public.competitions     where id             = p_competition_id;
end;
$$;

revoke all on function public.delete_competition_cascade(uuid) from public;
grant execute on function public.delete_competition_cascade(uuid) to authenticated;

comment on function public.delete_competition_cascade(uuid) is
  'Super-admin only: supprime une compétition + payouts/revenue/payments liés. '
  'Atomique. Les registrations/matches/brackets cascadent via leur propre FK.';
