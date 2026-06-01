-- ─────────────────────────────────────────────────────────────────────
-- Fix audit C-1 (résiduel) — stoppe la fuite de PII inter-utilisateurs.
-- ─────────────────────────────────────────────────────────────────────
-- ⚠️ NE PAS APPLIQUER EN PROD AVANT VÉRIFICATION SUR DEVICE.
-- Ce changement restreint les LIGNES lisibles de `profiles` à self+admin.
-- Toute lecture cross-user (adversaire, pair de chat, joueur de bracket,
-- classement, recherche d'amis, profil public, usernameOf) doit passer par
-- la vue `public_profiles`. Les sites Dart ont été reroutés dans le même
-- lot, mais un site oublié = écran vide (RLS refuse la ligne) → tester :
--   • Salle de match (pseudo + avatar adversaire)
--   • Chat direct + chat ami (pseudo du pair, bouton appel)
--   • Inbox messages (pseudos)
--   • Bracket + classement par poules (pseudos)
--   • Classement final d'une compétition (getRanking)
--   • Recherche d'utilisateurs + page profil public
--   • Appels entrants ("X vous appelle")
--   • Inscription : vérification username déjà pris
--   • Écrans admin (listes users, paiements, chat) — admins lisent la table
--
-- Contexte : la policy `profiles_select` autorisait la lecture de toute
-- ligne active → un compte authentifié pouvait lire email / whatsapp_number
-- / kyc_* de n'importe qui via `select=email`. Les colonnes secrètes
-- (totp_secret/backup_codes) étaient déjà verrouillées (20260601120000) ;
-- ici on ferme la PII restante en restreignant les LIGNES + vue publique.
-- ─────────────────────────────────────────────────────────────────────

-- 1. Vue publique : uniquement les colonnes non-PII. `security_invoker = false`
--    (vue exécutée avec les droits de l'owner) → elle contourne volontairement
--    la RLS restreinte de la table pour exposer ces colonnes publiques à tous
--    les utilisateurs. C'est l'intention ; l'advisor `security_definer_view`
--    le signalera (WARN assumé). AUCUNE colonne PII n'est projetée.
create or replace view public.public_profiles
with (security_invoker = false) as
  select
    id, username, avatar_color, country_code, stats, role,
    is_active, permanent_ban, totp_enabled, last_seen_at,
    created_at, updated_at
  from public.profiles
  where deleted_at is null;

comment on view public.public_profiles is
  'Projection publique de profiles (sans PII : ni email/whatsapp/fcm/voip/'
  'kyc/auth_provider/referral/totp). security_invoker=false volontaire pour '
  'exposer ces colonnes cross-user malgré la RLS self+admin de la table. '
  'Fix audit C-1 résiduel.';

grant select on public.public_profiles to anon, authenticated;

-- 2. Restreint les LIGNES lisibles de la table à self + admin. La lecture
--    cross-user passe désormais exclusivement par la vue ci-dessus.
drop policy if exists "profiles_select" on public.profiles;
create policy "profiles_select" on public.profiles for select
  using ((select auth.uid()) = id or (select public.is_admin()));
