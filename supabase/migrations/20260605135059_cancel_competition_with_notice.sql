-- =============================================================================
-- ARENA — C-2 : annulation de compétition avec notification des payeurs
-- =============================================================================
-- Le bouton admin « ANNULER (refund all) » ne faisait qu'un flip de statut :
-- aucun remboursement, AUCUNE notification aux joueurs ayant déjà payé en P2P.
-- Argent réel encaissé, joueur laissé sans info.
--
-- V1 (cohérent avec le P2P manuel) : on annule la compétition ET on notifie
-- chaque joueur ayant un paiement `succeeded`/`awaiting_admin` qu'un
-- remboursement manuel (Mobile Money) lui sera adressé. L'insertion dans
-- `notifications` déclenche le dispatch push existant (trigger pg_net → FCM) +
-- l'inbox in-app. Le traitement effectif du remboursement reste manuel côté
-- super-admin (file de remboursement traçable = chantier ultérieur).
--
-- SECURITY DEFINER + gate is_admin() interne (la RLS competitions n'autorise
-- pas un joueur à écrire dans notifications d'autrui ; on passe DEFINER).
-- =============================================================================

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

  -- Notifie chaque joueur ayant un paiement actif/validé pour cette compétition.
  with notified as (
    insert into public.notifications (user_id, type, title, body, data)
    select distinct
      p.user_id,
      'competition_cancelled',
      'Competition annulee',
      'La competition « ' || v_name || ' » a ete annulee. Si tu as paye ton '
        || 'inscription, un remboursement manuel (Mobile Money) te sera '
        || 'adresse par le staff.',
      jsonb_build_object('competition_id', p_competition_id)
    from public.payments p
    where p.competition_id = p_competition_id
      and p.status in ('succeeded', 'awaiting_admin')
    returning 1
  )
  select count(*) into v_notified from notified;

  return v_notified;
end;
$$;

comment on function public.cancel_competition(uuid) is
  'C-2 : annule une competition (status=cancelled) et notifie les joueurs ayant '
  'un paiement succeeded/awaiting_admin (remboursement P2P manuel a suivre). '
  'Gate is_admin() interne. Retourne le nombre de joueurs notifies.';

revoke execute on function public.cancel_competition(uuid) from anon, public;
grant execute on function public.cancel_competition(uuid) to authenticated;
