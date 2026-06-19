-- ─────────────────────────────────────────────────────────────────────
-- Expose avatar_url dans la vue publique public_profiles
-- ─────────────────────────────────────────────────────────────────────
-- ✅ APPLIQUÉE EN PROD le 2026-06-17 via MCP (version remote 20260617141456).
-- Fichier recréé dans le repo a posteriori pour la reproductibilité.
--
-- La photo d'avatar doit être visible cross-user (salle de match, chat,
-- bracket, classement, profil public…). Toute lecture cross-user passe par
-- cette vue (cf. fix C-1 résiduel) → il faut y ajouter avatar_url.
-- avatar_url n'est PAS de la PII (URL publique d'un bucket public).
--
-- security_invoker = false conservé VOLONTAIREMENT (cf. mémoire
-- public_profiles_security_definer) : la vue contourne la RLS self+admin de
-- profiles pour exposer ces colonnes publiques. NE PAS basculer en
-- security_invoker (casse recherche / profils / leaderboards).
create or replace view public.public_profiles
with (security_invoker = false) as
  select
    id, username, avatar_color, country_code, stats, role,
    is_active, permanent_ban, totp_enabled, last_seen_at,
    created_at, updated_at, avatar_url
  from public.profiles
  where deleted_at is null;

grant select on public.public_profiles to anon, authenticated;
