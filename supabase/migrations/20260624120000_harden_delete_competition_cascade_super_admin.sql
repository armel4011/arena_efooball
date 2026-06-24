-- =============================================================================
-- 2026-06-24 — Durcissement audit : delete_competition_cascade en super-admin.
--
-- Problème (audit 2026-06-24, finding ÉLEVÉ) : la fonction
-- `delete_competition_cascade` est `SECURITY DEFINER` et fait un HARD DELETE
-- des pièces comptables (`payouts`, `platform_revenue`, `payments`) d'une
-- compétition. Sa garde était `is_admin()`, qui accepte un admin SIMPLE.
-- Or tout le reste du flux argent (generate_payouts, mark_payout_paid,
-- mark_payment_refunded, payouts_admin_update) exige `is_super_admin()`.
-- Asymétrie : un admin simple ne peut pas valider un seul payout mais
-- pourrait effacer toute la comptabilité d'une compétition.
--
-- Correctif : aligner la garde sur `is_super_admin()`.
-- =============================================================================

create or replace function public.delete_competition_cascade(p_competition_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if not public.is_super_admin() then
    raise exception 'forbidden: super-admin only';
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
  'Atomique. Les registrations/matches/brackets cascadent via leur propre FK. '
  'Garde durcie is_admin -> is_super_admin (audit 2026-06-24).';
