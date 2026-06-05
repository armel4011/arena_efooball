-- =============================================================================
-- ARENA — RGPD C-1 : anonymisation des comptes supprimés (conservation compta)
-- =============================================================================
-- La cron `cleanup-deleted-accounts` appelait `auth.admin.deleteUser`, mais
-- `payments`/`payouts`/`competition_registrations` sont `ON DELETE RESTRICT`
-- → la suppression du `profiles` (cascade depuis auth.users) ÉCHOUE pour tout
-- utilisateur ayant transigé. Les comptes restaient en limbe soft-deleted et
-- la promesse « supprimé sous 30 j » n'était pas tenue.
--
-- Décision (audit v2, choix produit) : ANONYMISER en place et CONSERVER les
-- pièces comptables (obligation légale de conservation). On scrub les PII du
-- `profiles` ; la cron scrub en plus l'email auth + bannit le login. Les lignes
-- payments/payouts survivent, rattachées à un profil anonymisé non identifiant.
--
-- `anonymized_at` sert de marqueur d'idempotence : la cron ne retraite que les
-- profils `anonymized_at is null`.
-- =============================================================================

alter table public.profiles
  add column if not exists anonymized_at timestamptz;

comment on column public.profiles.anonymized_at is
  'Horodatage de l''anonymisation RGPD (C-1). NULL = pas encore anonymisé. '
  'Posé par anonymize_deleted_account() via la cron cleanup-deleted-accounts.';

-- Scrub des PII du profil. Garde les colonnes non identifiantes (avatar_color,
-- country_code, stats, role…) et toutes les lignes filles compta intactes.
-- Valeurs dérivées de l'id (16 hex) pour respecter les contraintes UNIQUE
-- (username/email/referral_code) et le CHECK length(username) 3..20.
create or replace function public.anonymize_deleted_account(p_user_id uuid)
returns void
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_tag text := left(replace(p_user_id::text, '-', ''), 16); -- 16 hex
begin
  update public.profiles set
    username                = 'del_' || v_tag,                 -- 20 chars, unique
    email                   = p_user_id::text || '@deleted.invalid',
    whatsapp_number         = null,
    fcm_token               = null,
    voip_token              = null,
    auth_provider_id        = null,
    referral_code           = 'DEL' || upper(v_tag),
    account_deletion_reason = null,
    totp_secret             = null,
    totp_enabled            = false,
    last_seen_at            = null,
    anonymized_at           = now()
  where id = p_user_id
    and anonymized_at is null;
end;
$$;

comment on function public.anonymize_deleted_account(uuid) is
  'RGPD C-1 : scrub les PII de profiles (username/email/whatsapp/tokens/totp/'
  'referral) et pose anonymized_at. Conserve les lignes compta (payments/'
  'payouts). Appelée par la cron service_role uniquement.';

-- Réservé au service_role (cron). Aucun rôle applicatif ne doit l'appeler.
revoke all on function public.anonymize_deleted_account(uuid) from public, anon, authenticated;
grant execute on function public.anonymize_deleted_account(uuid) to service_role;
