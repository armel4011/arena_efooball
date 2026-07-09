-- =============================================================================
-- ARENA — Audit 2026-07-09 : correctifs sécurité P0 / P1 / P2
-- =============================================================================
-- Fil rouge (re)confirmé : durcissement super-admin des RPC contournable par une
-- voie d'écriture RLS DIRECTE laissée ouverte à l'admin simple.
--
-- P0 — Auto-promotion admin simple → super-admin
--   `guard_profiles_protected_columns` exemptait `is_admin()` (donc admin SIMPLE)
--   et `profiles_update` autorise la branche is_admin() sur toute ligne
--   → `UPDATE profiles SET role='super_admin' WHERE id=auth.uid()` réussissait.
--   Idem repoint de `admin_allowed_countries/sections` (un admin restreint
--   pouvait s'auto-élargir en mettant sa liste à NULL).
--   FIX : colonnes de PRIVILÈGE (role, admin_allowed_countries,
--   admin_allowed_sections) réservées au super-admin. Les colonnes de contrôle
--   de compte (is_active, permanent_ban, kyc_*, totp_*, stats) restent au tier
--   admin (flux ban/unban/overrideKyc légitimes du console admin, inchangés).
--
-- P1 — Forge du commitment/verdict anti-triche via `UPDATE streams`
--   Aucun guard de colonnes sur `streams` : le propriétaire (streams_update,
--   is_public=false) pouvait écrire proof_committed_at/proof_sha256/
--   proof_hash_verified/capture_status → contourner le soft-gate et forger le
--   verdict « vidéo conforme » sans vidéo. Le client ne touche JAMAIS ces
--   colonnes en direct (proof_claim_service = SELECT seul ; écritures = EF
--   service-role anticheat-commit/proof-verify).
--   FIX : trigger BEFORE UPDATE figeant proof_*/capture_*/storage_path/url/
--   egress_id/provider/match_id/player_id/started_at/ended_at côté client non-admin.
--
-- P2a — `generate_single_elim_bracket(uuid)` exécutable par tout authenticated
--   (régression ACL : le revoke de 20260519160000 ré-annulé par 20260626120000).
--   FIX : revoke (comme ses jumeaux round_robin / groups_then_knockout).
--
-- P2b — Redirection des frais : `set_competition_payment_options` gardé is_admin
--   seul → un admin réécrivait transfer_code (numéro MoMo de collecte) de
--   N'IMPORTE quelle compétition, hors de son pays.
--   FIX : garde admin_can_country sur le pays de la compétition.
-- =============================================================================
-- Depends on: 20260531141132 (guard profiles), 20260507100002 (streams player
--   rls), 20260629120000 (streams.proof_*), 20260706100400 (admin_can_country),
--   20260706100300 (set_competition_payment_options), 20260505100005 (is_admin/
--   is_super_admin), 20260605100000 (guard_matches modèle de trigger).
-- =============================================================================

-- ─── P0 : guard profiles à deux tiers (privilège = super-admin) ─────────────
create or replace function public.guard_profiles_protected_columns()
returns trigger
language plpgsql
security invoker
set search_path = public, pg_temp
as $$
begin
  -- service_role + fonctions SECURITY DEFINER (current_user = owner) restent
  -- libres. Seuls les clients PostgREST directs sont bridés.
  if current_user in ('authenticated', 'anon') then
    -- TIER PRIVILÈGE — réservé au SUPER-ADMIN. Ferme l'escalade : un admin
    -- simple ne peut ni se promouvoir (role) ni élargir son propre scope
    -- (admin_allowed_countries/sections). Aucun flux client légitime n'écrit
    -- ces colonnes (register-admin = EF DEFINER, three-strikes = trigger).
    if not public.is_super_admin() then
      if new.role                   is distinct from old.role
         or new.admin_allowed_countries is distinct from old.admin_allowed_countries
         or new.admin_allowed_sections  is distinct from old.admin_allowed_sections
      then
        raise exception 'Modification interdite : role et scope admin (pays/sections) reserves au super-admin'
          using errcode = '42501';
      end if;
    end if;

    -- TIER ADMIN — réservé aux admins (comportement historique préservé :
    -- ban/unban/overrideKyc du console admin passent toujours).
    if not public.is_admin() then
      if new.is_active        is distinct from old.is_active
         or new.permanent_ban    is distinct from old.permanent_ban
         or new.stats            is distinct from old.stats
         or new.kyc_status       is distinct from old.kyc_status
         or new.kyc_verified_at  is distinct from old.kyc_verified_at
         or new.totp_secret      is distinct from old.totp_secret
         or new.totp_enabled     is distinct from old.totp_enabled
         or new.backup_codes     is distinct from old.backup_codes
      then
        raise exception 'Modification interdite : colonnes protegees (is_active, permanent_ban, stats, kyc, totp) reservees au service ou aux admins'
          using errcode = '42501';
      end if;
    end if;
  end if;
  return new;
end;
$$;

comment on function public.guard_profiles_protected_columns() is
  'Audit 2026-07-09 P0 : role + admin_allowed_countries/sections figés sauf '
  'super-admin (ferme l''auto-promotion admin simple → super-admin) ; '
  'is_active/permanent_ban/stats/kyc/totp figés sauf admin. service_role/DEFINER libres.';

-- ─── P1 : guard des colonnes de preuve anti-triche sur `streams` ────────────
create or replace function public.guard_streams_protected_columns()
returns trigger
language plpgsql
security invoker
set search_path = public, pg_temp
as $$
begin
  -- Le client (joueur) ne doit jamais forger les colonnes de preuve : elles
  -- sont écrites uniquement par les EF service-role (anticheat-commit /
  -- proof-verify). On fige aussi les colonnes structurelles (repoint match_id/
  -- player_id, réécriture du chemin d'objet). is_public/is_active restent libres
  -- (aucun impact anti-triche). service_role/DEFINER et admins exemptés.
  if current_user in ('authenticated', 'anon') and not public.is_admin() then
    if new.proof_sha256           is distinct from old.proof_sha256
       or new.proof_bytes            is distinct from old.proof_bytes
       or new.proof_duration_seconds is distinct from old.proof_duration_seconds
       or new.proof_committed_at     is distinct from old.proof_committed_at
       or new.proof_claimed_at       is distinct from old.proof_claimed_at
       or new.proof_uploaded_at      is distinct from old.proof_uploaded_at
       or new.proof_hash_verified    is distinct from old.proof_hash_verified
       or new.capture_status         is distinct from old.capture_status
       or new.capture_note           is distinct from old.capture_note
       or new.storage_path           is distinct from old.storage_path
       or new.url                    is distinct from old.url
       or new.egress_id              is distinct from old.egress_id
       or new.provider               is distinct from old.provider
       or new.match_id               is distinct from old.match_id
       or new.player_id              is distinct from old.player_id
       or new.started_at             is distinct from old.started_at
       or new.ended_at               is distinct from old.ended_at
    then
      raise exception 'Modification interdite : colonnes de preuve/capture d''un enregistrement reservees au service anti-triche'
        using errcode = '42501';
    end if;
  end if;
  return new;
end;
$$;

comment on function public.guard_streams_protected_columns() is
  'Audit 2026-07-09 P1 : fige les colonnes proof_*/capture_*/storage/structure '
  'de streams cote client non-admin (empêche la forge de commitment/verdict). '
  'Ecritures légitimes = EF service-role anticheat-commit/proof-verify.';

drop trigger if exists trg_streams_guard_protected on public.streams;
create trigger trg_streams_guard_protected
  before update on public.streams
  for each row execute function public.guard_streams_protected_columns();

-- ─── P2a : re-verrouiller l'ACL de generate_single_elim_bracket ─────────────
revoke execute on function public.generate_single_elim_bracket(uuid)
  from authenticated, anon, public;

-- ─── P2b : cloisonner set_competition_payment_options par pays ──────────────
create or replace function public.set_competition_payment_options(
  p_competition_id uuid,
  p_options jsonb
)
returns integer
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_opt     jsonb;
  v_count   integer := 0;
  v_country text;
begin
  if not public.is_admin() then
    raise exception 'Reserve aux admins' using errcode = '42501';
  end if;

  select country_code into v_country
    from public.competitions where id = p_competition_id;
  if v_country is null then
    raise exception 'Competition introuvable' using errcode = 'P0002';
  end if;

  -- Cloisonnement pays (miroir payouts/recordings) : un admin restreint ne peut
  -- pas réécrire les codes de collecte (transfer_code) d'une compétition hors de
  -- son périmètre. super-admin (scope NULL) = autorisé partout.
  if not public.admin_can_country(auth.uid(), v_country) then
    raise exception 'Compétition hors de votre perimetre pays'
      using errcode = '42501';
  end if;

  -- Remplace-tout : on repart d'une table vierge pour cette compétition.
  delete from public.competition_payment_options
   where competition_id = p_competition_id;

  if p_options is null or jsonb_typeof(p_options) <> 'array' then
    return 0;
  end if;

  for v_opt in select * from jsonb_array_elements(p_options)
  loop
    insert into public.competition_payment_options
      (competition_id, country_code, operator_label, transfer_code, dial_code, sort_order)
    values (
      p_competition_id,
      upper(trim(v_opt->>'country_code')),
      trim(v_opt->>'operator_label'),
      trim(v_opt->>'transfer_code'),
      nullif(trim(coalesce(v_opt->>'dial_code', '')), ''),
      coalesce((v_opt->>'sort_order')::int, v_count)
    );
    v_count := v_count + 1;
  end loop;

  return v_count;
end;
$$;

revoke execute on function public.set_competition_payment_options(uuid, jsonb) from anon, public;
grant execute on function public.set_competition_payment_options(uuid, jsonb) to authenticated;

comment on function public.set_competition_payment_options(uuid, jsonb) is
  'Réécrit (remplace-tout) les options de paiement d''une compétition. '
  'Audit 2026-07-09 P2 : cloisonné par pays (admin_can_country) pour empêcher '
  'la redirection des transfer_code d''une compétition hors périmètre. DEFINER.';
