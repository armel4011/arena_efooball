-- =============================================================================
-- ARENA — Audit 2026-07-07 (P2) : delete_competition_cascade refuse si refunds dus
-- =============================================================================
-- `delete_competition_cascade` (super-admin) hard-DELETE les payments d'une
-- compétition, Y COMPRIS les lignes `refund_pending` (compétition annulée,
-- remboursement pas encore effectué) → l'obligation de remboursement disparaît
-- SANS TRACE.
--
-- CORRECTIF : on refuse la suppression tant qu'il reste des remboursements DUS
-- (`payments.status = 'refund_pending'`). Le super-admin doit d'abord les
-- traiter (mark_payment_refunded) avant de pouvoir supprimer la compétition.
-- Le reste (gate super-admin, cascade payouts/platform_revenue/payments) est
-- conservé à l'identique.
-- =============================================================================

create or replace function public.delete_competition_cascade(p_competition_id uuid)
returns void
language plpgsql
security definer
set search_path to 'public'
as $function$
declare
  v_pending int;
begin
  if not public.is_super_admin() then
    raise exception 'forbidden: super-admin only';
  end if;

  -- Garde (audit 2026-07-07) : ne pas effacer une compétition qui doit encore
  -- des remboursements — sinon l'obligation disparaît sans trace.
  select count(*) into v_pending
    from public.payments
   where competition_id = p_competition_id
     and status = 'refund_pending';
  if v_pending > 0 then
    raise exception
      'Suppression bloquee : % remboursement(s) en attente (refund_pending) a traiter d''abord',
      v_pending
      using errcode = '42501';
  end if;

  delete from public.payouts          where competition_id = p_competition_id;
  delete from public.platform_revenue where competition_id = p_competition_id;
  delete from public.payments         where competition_id = p_competition_id;
  delete from public.competitions     where id             = p_competition_id;
end;
$function$;

comment on function public.delete_competition_cascade(uuid) is
  'Super-admin : hard-delete cascade d''une compétition (payouts, platform_revenue, '
  'payments). P2 audit 2026-07-07 : REFUSE si des payments refund_pending '
  'subsistent (remboursements dus à traiter d''abord).';
