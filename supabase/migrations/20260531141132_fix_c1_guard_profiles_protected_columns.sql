-- =============================================================================
-- ARENA — Sécurité — C1 : verrou des colonnes sensibles de `profiles`
-- =============================================================================
-- La policy `profiles_update` (20260505185438_rls_policies_optimization.sql:28)
-- autorise un utilisateur à mettre à jour SA PROPRE ligne, mais SANS aucune
-- garde de colonne, et aucun trigger ne protégeait les colonnes sensibles.
-- Un joueur authentifié pouvait donc s'auto-promouvoir :
--
--   UPDATE profiles SET role='super_admin', is_active=true, permanent_ban=false
--   WHERE id = auth.uid();
--
-- → prise de contrôle totale (validation paiements/payouts, broadcast, déban).
--
-- Correctif : un trigger BEFORE UPDATE qui rejette toute modification des
-- colonnes protégées (role, is_active, permanent_ban, stats, kyc_*, totp_*,
-- backup_codes) dès lors que l'appel provient d'un client PostgREST direct
-- (`authenticated` / `anon`) qui n'est pas admin.
--
-- Les écritures LÉGITIMES sur ces colonnes passent toutes par des fonctions
-- SECURITY DEFINER (recalculate_player_stats, _recalc_stats_on_match_completed,
-- enforce_three_strikes_ban, apply_reintegration_decision) ou par le
-- service_role. Dans ces contextes, `current_user` vaut le rôle owner
-- (postgres) ou `service_role`, jamais `authenticated`/`anon` — la garde ne
-- s'applique donc pas et ces flux continuent de fonctionner.
--
-- IMPORTANT : la fonction trigger est volontairement SECURITY INVOKER pour que
-- `current_user` reflète le contexte réel d'exécution. La passer en DEFINER
-- ferait toujours valoir `current_user = postgres` et désactiverait la garde.
-- =============================================================================
-- Depends on: 20260505185438_rls_policies_optimization.sql,
--             20260515130002_three_strikes_permanent_ban.sql
-- =============================================================================

create or replace function public.guard_profiles_protected_columns()
returns trigger
language plpgsql
security invoker
set search_path = public, pg_temp
as $$
begin
  -- Seuls les clients PostgREST directs (authenticated/anon) non-admin sont
  -- bridés. service_role + fonctions SECURITY DEFINER conservent leurs droits.
  if current_user in ('authenticated', 'anon') and not public.is_admin() then
    if new.role            is distinct from old.role
       or new.is_active        is distinct from old.is_active
       or new.permanent_ban    is distinct from old.permanent_ban
       or new.stats            is distinct from old.stats
       or new.kyc_status       is distinct from old.kyc_status
       or new.kyc_verified_at  is distinct from old.kyc_verified_at
       or new.totp_secret      is distinct from old.totp_secret
       or new.totp_enabled     is distinct from old.totp_enabled
       or new.backup_codes     is distinct from old.backup_codes
    then
      raise exception 'Modification interdite : colonnes protegees (role, is_active, permanent_ban, stats, kyc, totp) reservees au service ou aux admins'
        using errcode = '42501';
    end if;
  end if;
  return new;
end;
$$;

comment on function public.guard_profiles_protected_columns() is
  'C1 : empeche un client authenticated/anon non-admin de modifier les colonnes sensibles de profiles (escalade de privileges). Les fonctions SECURITY DEFINER et le service_role ne sont pas concernes.';

drop trigger if exists trg_profiles_guard_protected on public.profiles;
create trigger trg_profiles_guard_protected
  before update on public.profiles
  for each row execute function public.guard_profiles_protected_columns();
