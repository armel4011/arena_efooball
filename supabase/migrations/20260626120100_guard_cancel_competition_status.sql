-- ════════════════════════════════════════════════════════════════════
-- FIX P2 — `cancel_competition` : garde de statut (anti double sortie d'argent)
-- ════════════════════════════════════════════════════════════════════
-- Bug (audit 2026-06-26) : `cancel_competition` passait la compétition à
-- `cancelled` et les paiements `succeeded` → `refund_pending` SANS vérifier le
-- statut courant. Elle pouvait donc être appelée sur une compétition `completed`
-- dont les `payouts` (prix) ont déjà été générés/payés.
--
-- Scénario : compétition terminée, gains versés via `mark_payout_paid`. Un admin
-- clique « ANNULER (refund all) » → tous les frais d'inscription `succeeded`
-- repassent `refund_pending` → le staff rembourse les inscriptions EN PLUS des
-- prix déjà payés. La plateforme paie deux fois.
--
-- Correctif : refuser l'annulation si la compétition est déjà `completed` ou
-- `cancelled`, ou si des payouts existent déjà pour cette compétition
-- (ceinture-bretelles, couvre le cas où le statut serait `ongoing` mais des
-- prix déjà générés). On verrouille la ligne `FOR UPDATE` pour éviter une course
-- avec un passage concurrent en `completed`.
-- ════════════════════════════════════════════════════════════════════

create or replace function public.cancel_competition(p_competition_id uuid)
returns integer
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_name     text;
  v_status   text;
  v_notified integer;
begin
  if not public.is_admin() then
    raise exception 'Reserve aux administrateurs' using errcode = '42501';
  end if;

  -- Verrouille la compétition et lit son statut courant AVANT toute mutation.
  select name, status::text
    into v_name, v_status
    from public.competitions
    where id = p_competition_id
    for update;

  if v_name is null then
    raise exception 'Competition introuvable' using errcode = 'P0002';
  end if;

  -- Garde : ne jamais annuler une compétition déjà terminée ou déjà annulée.
  if v_status in ('completed', 'cancelled') then
    raise exception
      'Impossible d''annuler une competition au statut % (annulation reservee aux competitions non terminees)',
      v_status
      using errcode = '42501';
  end if;

  -- Ceinture-bretelles : si des prix ont déjà été générés/versés, refuser
  -- l'annulation (sinon double remboursement inscriptions + prix).
  if exists (select 1 from public.payouts where competition_id = p_competition_id) then
    raise exception
      'Impossible d''annuler : des gains ont deja ete generes pour cette competition'
      using errcode = '42501';
  end if;

  update public.competitions
     set status = 'cancelled'
   where id = p_competition_id;

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
  'remboursement) + awaiting_admin→rejected. Gate is_admin(). Refuse si la '
  'competition est completed/cancelled ou si des payouts existent deja '
  '(fix audit 2026-06-26). Retourne le nombre de joueurs notifies.';
