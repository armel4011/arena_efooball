-- ─────────────────────────────────────────────────────────────────────
-- Fix audit C-1 — Verrou des colonnes secrètes de `profiles`.
-- ─────────────────────────────────────────────────────────────────────
-- La policy `profiles_select` (20260505185438) autorise tout utilisateur
-- (et `anon`, qui a EXECUTE sur is_admin) à lire CHAQUE ligne active via
-- `GET /rest/v1/profiles?select=*`. Or `profiles` contient des secrets
-- purement serveur :
--   - `totp_secret`  → graine TOTP (compromission directe du 2FA admin)
--   - `backup_codes` → HMAC des codes de secours 2FA
-- Aucun code client n'en a besoin (le modèle Dart `Profile` les strippe ;
-- les Edge Functions TOTP les lisent via le service role qui ignore les
-- grants colonne).
--
-- ⚠️ Piège PostgreSQL : un `REVOKE SELECT (colonne)` est INOPÉRANT tant
-- qu'un GRANT SELECT *table-level* existe (Supabase l'accorde par défaut
-- à anon/authenticated). Il faut donc retirer le SELECT table-level puis
-- re-grant la liste explicite des colonnes NON-secrètes.
--
-- Conséquence côté client : `select=*` (ou `.select()` implicite) doit
-- disparaître — `ProfileRepository` a été migré vers une liste de colonnes
-- explicite dans le même lot. Tout NOUVEL ajout de colonne devra être
-- explicitement GRANT'é ici (privé par défaut = posture plus sûre).
--
-- NB : les fonctions SECURITY DEFINER (admin_filter_users, triggers,
-- crons) tournent en tant qu'owner et conservent l'accès. Le service role
-- (Edge Functions) bypasse également les grants colonne.
-- ─────────────────────────────────────────────────────────────────────

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
  'Graine TOTP (secret serveur). SELECT NON accordé à anon/authenticated '
  '(fix audit C-1). Accès réservé au service role / fonctions DEFINER.';

comment on column public.profiles.backup_codes is
  'Codes de secours 2FA (HMAC). SELECT NON accordé à anon/authenticated '
  '(fix audit C-1). Accès réservé au service role / fonctions DEFINER.';
