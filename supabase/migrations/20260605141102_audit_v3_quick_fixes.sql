-- =============================================================================
-- ARENA — Lot rapide audit v3 : F-2, F-3, séparation des pouvoirs payouts
-- =============================================================================

-- ─── F-2 : cancel_competition neutralise les paiements en attente ────────────
-- L'annulation notifiait les payeurs mais laissait les paiements
-- `awaiting_admin` dans la file admin → validables APRÈS annulation
-- (encaissement d'une compétition annulée + registration créée). On les passe
-- en `rejected` dans la même transaction, APRÈS avoir capturé la liste des
-- notifiés (succeeded + awaiting_admin). Les `succeeded` restent (déjà payés →
-- remboursement P2P manuel à suivre, file traçable = chantier ultérieur).
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
        || 'inscription, un remboursement manuel (Mobile Money) te sera '
        || 'adresse par le staff.',
      jsonb_build_object('competition_id', p_competition_id)
    from public.payments p
    where p.competition_id = p_competition_id
      and p.status in ('succeeded', 'awaiting_admin')
    returning 1
  )
  select count(*) into v_notified from notified;

  -- Neutralise les paiements non encore validés : ils ne doivent plus pouvoir
  -- être validés par l'admin pour une compétition annulée.
  update public.payments
     set status = 'rejected',
         rejection_reason = 'Competition annulee'
   where competition_id = p_competition_id
     and status = 'awaiting_admin';

  return v_notified;
end;
$$;

comment on function public.cancel_competition(uuid) is
  'C-2 : annule une competition + notifie les payeurs (succeeded/awaiting_admin) '
  '+ passe les awaiting_admin en rejected (anti-validation post-annulation). '
  'Gate is_admin() interne. Retourne le nombre de joueurs notifies.';

-- ─── F-3 : complète le scrub d'anonymisation RGPD ────────────────────────────
-- Le scrub oubliait des PII/secrets : backup_codes (codes 2FA HMAC),
-- referred_by, et le numero Mobile Money du payeur (payments.payer_phone).
create or replace function public.anonymize_deleted_account(p_user_id uuid)
returns void
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_tag text := left(replace(p_user_id::text, '-', ''), 16);
begin
  update public.profiles set
    username                = 'del_' || v_tag,
    email                   = p_user_id::text || '@deleted.invalid',
    whatsapp_number         = null,
    fcm_token               = null,
    voip_token              = null,
    auth_provider_id        = null,
    referral_code           = 'DEL' || upper(v_tag),
    referred_by             = null,
    account_deletion_reason = null,
    totp_secret             = null,
    totp_enabled            = false,
    backup_codes            = '[]'::jsonb,
    last_seen_at            = null,
    anonymized_at           = now()
  where id = p_user_id
    and anonymized_at is null;

  -- PII résiduelle dans les pièces comptables conservées : on masque le
  -- numéro Mobile Money du payeur (les montants/dates restent pour la compta).
  update public.payments
     set payer_phone = null
   where user_id = p_user_id
     and payer_phone is not null;
end;
$$;

comment on function public.anonymize_deleted_account(uuid) is
  'RGPD C-1 (complété F-3) : scrub PII de profiles (username/email/whatsapp/'
  'tokens/totp/backup_codes/referral/referred_by) + payments.payer_phone. '
  'Conserve les lignes compta anonymisées. Service_role only.';

-- ─── Séparation des pouvoirs : validation des payouts réservée au super-admin ─
-- `payments_admin_update` exige is_super_admin(), mais `payouts_admin_update`
-- restait sur is_admin() → un admin simple pouvait valider le payout d'autrui
-- (sortie d'argent). On aligne sur les paiements.
drop policy if exists "payouts_admin_update" on public.payouts;
create policy "payouts_admin_update"
  on public.payouts for update
  using (public.is_super_admin())
  with check (public.is_super_admin());
