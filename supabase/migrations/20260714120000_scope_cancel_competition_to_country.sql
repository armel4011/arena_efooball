-- ════════════════════════════════════════════════════════════════════
-- FIX P2 (audit 2026-07-14) — `cancel_competition` : cloisonnement pays
-- ════════════════════════════════════════════════════════════════════
-- `cancel_competition` est la SEULE action financière ouverte à un admin
-- simple (`is_admin()`) qui n'était PAS cloisonnée par pays : elle bascule les
-- paiements `succeeded → refund_pending` (déclenche la file de remboursement).
-- Ses sœurs financières — `generate_payouts`, `mark_payout_paid`,
-- `set_competition_payment_options` — vérifient toutes `admin_can_country`.
--
-- Trou : un admin restreint au pays CM pouvait annuler une compétition SN et
-- déclencher ses remboursements hors de son périmètre.
--
-- Correctif : après lecture verrouillée de la ligne, refuser si l'appelant
-- n'est pas autorisé sur `competitions.country_code`. Sémantique fail-closed
-- identique aux autres RPC argent : `admin_can_country` renvoie `true` pour un
-- admin sans restriction (allowed_countries NULL) et `false` si le pays de la
-- compétition est NULL pour un admin scopé.
--
-- On conserve intégralement les gardes d'état existantes (statut completed/
-- cancelled, présence de payouts, FOR UPDATE) : seule la garde pays est ajoutée.
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
  v_country  text;
  v_notified integer;
begin
  if not public.is_admin() then
    raise exception 'Reserve aux administrateurs' using errcode = '42501';
  end if;

  -- Verrouille la compétition et lit son statut courant AVANT toute mutation.
  select name, status::text, country_code
    into v_name, v_status, v_country
    from public.competitions
    where id = p_competition_id
    for update;

  if v_name is null then
    raise exception 'Competition introuvable' using errcode = 'P0002';
  end if;

  -- Cloisonnement pays : un admin scopé ne peut annuler que dans son périmètre.
  if not public.admin_can_country(auth.uid(), v_country) then
    raise exception 'Compte non autorise sur ce pays' using errcode = '42501';
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
  'remboursement) + awaiting_admin→rejected. Gate is_admin() + cloisonnement '
  'admin_can_country (fix audit 2026-07-14). Refuse si la competition est '
  'completed/cancelled ou si des payouts existent deja (fix audit 2026-06-26). '
  'Retourne le nombre de joueurs notifies.';
