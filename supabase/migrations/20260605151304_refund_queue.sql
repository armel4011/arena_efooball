-- =============================================================================
-- ARENA — File de remboursement traçable (audit complétude, C-2 option 2)
-- =============================================================================
-- L'annulation d'une compétition notifiait les payeurs mais le remboursement
-- restait un geste Mobile Money 100% manuel SANS trace (ni file, ni statut, ni
-- SLA). On rend le remboursement traçable :
--   • nouveau statut payments `refund_pending` (paiement validé à rembourser) ;
--   • `cancel_competition` passe les paiements `succeeded` → `refund_pending`
--     (en plus de notifier et de rejeter les `awaiting_admin`) ;
--   • RPC `mark_payment_refunded` (super-admin) : le staff effectue le virement
--     Mobile Money réel puis marque `refunded` + notifie le joueur.
-- Cohérent avec le P2P manuel : le système ne verse pas, il calcule/trace.
-- =============================================================================

-- ─── 1. Nouveau statut + colonne d'horodatage du remboursement ───────────────
alter table public.payments drop constraint if exists payments_status_check;
alter table public.payments add constraint payments_status_check
  check (status in (
    'pending', 'processing', 'awaiting_admin', 'succeeded',
    'refund_pending', 'failed', 'rejected', 'refunded', 'expired'
  ));

alter table public.payments
  add column if not exists refunded_at timestamptz;

comment on column public.payments.refunded_at is
  'Horodatage du remboursement effectif (P2P manuel) par le super-admin.';

-- ─── 2. cancel_competition : succeeded → refund_pending ──────────────────────
create or replace function public.cancel_competition(p_competition_id uuid)
returns integer
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_name     text;
  v_notified integer;
begin
  if not public.is_admin() then
    raise exception 'Reserve aux administrateurs' using errcode = '42501';
  end if;

  update public.competitions
     set status = 'cancelled'
   where id = p_competition_id
   returning name into v_name;

  if v_name is null then
    raise exception 'Competition introuvable' using errcode = 'P0002';
  end if;

  -- Notifie d'abord (lit succeeded + awaiting_admin avant de muter).
  with notified as (
    insert into public.notifications (user_id, type, title, body, data)
    select distinct
      p.user_id,
      'competition_cancelled',
      'Competition annulee',
      'La competition « ' || v_name || ' » a ete annulee. Si tu as paye ton '
        || 'inscription, un remboursement Mobile Money te sera adresse par le '
        || 'staff.',
      jsonb_build_object('competition_id', p_competition_id,
                         'route', '/payments/history')
    from public.payments p
    where p.competition_id = p_competition_id
      and p.status in ('succeeded', 'awaiting_admin')
    returning 1
  )
  select count(*) into v_notified from notified;

  -- Paiements validés (encaissés) → file de remboursement traçable.
  update public.payments
     set status = 'refund_pending'
   where competition_id = p_competition_id
     and status = 'succeeded';

  -- Paiements non encore validés → rejetés (anti-validation post-annulation).
  update public.payments
     set status = 'rejected',
         rejection_reason = 'Competition annulee'
   where competition_id = p_competition_id
     and status = 'awaiting_admin';

  return v_notified;
end;
$$;

comment on function public.cancel_competition(uuid) is
  'C-2 : annule + notifie les payeurs + succeeded→refund_pending (file de '
  'remboursement) + awaiting_admin→rejected. Gate is_admin(). Retourne le '
  'nombre de joueurs notifies.';

-- ─── 3. mark_payment_refunded : le super-admin clot un remboursement ─────────
create or replace function public.mark_payment_refunded(p_payment_id uuid)
returns void
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_user     uuid;
  v_status   text;
  v_amount   numeric;
  v_currency text;
begin
  if not public.is_super_admin() then
    raise exception 'Reserve au super-admin' using errcode = '42501';
  end if;

  select user_id, status, amount_local, currency
    into v_user, v_status, v_amount, v_currency
    from public.payments
    where id = p_payment_id for update;
  if not found then
    raise exception 'Paiement introuvable' using errcode = 'P0002';
  end if;
  if v_status <> 'refund_pending' then
    raise exception 'Ce paiement n''est pas en attente de remboursement (statut %)', v_status
      using errcode = '42501';
  end if;

  update public.payments
     set status                = 'refunded',
         refunded_at           = now(),
         validated_by_admin_id = auth.uid()
   where id = p_payment_id;

  insert into public.notifications (user_id, type, title, body, data)
  values (v_user, 'payment_refunded', 'Remboursement effectue',
    'Ton inscription de ' || v_amount::text || ' ' || v_currency
      || ' a ete remboursee sur ton numero Mobile Money.',
    jsonb_build_object('payment_id', p_payment_id, 'route', '/payments/history'));
end;
$$;

comment on function public.mark_payment_refunded(uuid) is
  'C-2 : le super-admin marque un paiement refund_pending comme refunded '
  '(apres virement reel) + notifie le joueur. Gate super-admin.';

revoke execute on function public.mark_payment_refunded(uuid) from anon, public;
grant execute on function public.mark_payment_refunded(uuid) to authenticated;
