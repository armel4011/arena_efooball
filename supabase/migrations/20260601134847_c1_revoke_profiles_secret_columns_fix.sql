-- Fix audit C-1 (correctif) — verrouille les colonnes secretes de `profiles`.
--
-- Reconstitue a posteriori (regularisation historique 2026-06-05) : cette
-- migration avait ete appliquee en prod via MCP (version 20260601134847) sans
-- fichier local commite. Le SQL ci-dessous est recopie depuis
-- supabase_migrations.schema_migrations pour aligner local <-> distant.
--
-- Contexte : on revoque le SELECT global sur `profiles` puis on re-accorde le
-- SELECT colonne-par-colonne en EXCLUANT `totp_secret` et `backup_codes`. Ces
-- deux colonnes restent donc lisibles uniquement par le service role et les
-- fonctions SECURITY DEFINER (jamais par anon/authenticated). Complete par
-- 20260601184427_c1_residual_public_profiles_view (restriction des LIGNES).

revoke select on public.profiles from anon, authenticated;

grant select (
  id, username, email, country_code, avatar_color, role, is_active,
  fcm_token, stats, auth_provider, auth_provider_id, preferred_language,
  preferred_currency, timezone, onboarding_completed, onboarding_completed_at,
  totp_enabled, cgu_accepted_at, cgu_version_accepted, privacy_policy_accepted_at,
  marketing_consent, account_deletion_requested_at, account_deletion_reason,
  deleted_at, kyc_status, kyc_verified_at, created_at, updated_at,
  whatsapp_number, permanent_ban, referral_code, referred_by,
  last_seen_at, voip_token
) on public.profiles to anon, authenticated;

comment on column public.profiles.totp_secret is
  'Graine TOTP (secret serveur). SELECT NON accordé à anon/authenticated (fix audit C-1). Accès réservé au service role / fonctions DEFINER.';

comment on column public.profiles.backup_codes is
  'Codes de secours 2FA (HMAC). SELECT NON accordé à anon/authenticated (fix audit C-1). Accès réservé au service role / fonctions DEFINER.';
