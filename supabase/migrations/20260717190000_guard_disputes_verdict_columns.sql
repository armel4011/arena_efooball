-- =============================================================================
-- ARENA — Audit 2026-07-17 : P0 bannissement arbitraire via `disputes`
-- =============================================================================
-- Même fil rouge que 20260709150000 : une RPC durcie (`resolve_dispute`) est
-- contournée par une voie d'écriture RLS DIRECTE laissée ouverte. `disputes`
-- est la table oubliée du durcissement — ses policies datent du 2026-05-05 et
-- n'ont jamais été rouvertes, alors que profiles/payments/payouts/streams/
-- matches ont chacune reçu leur trigger de garde colonne.
--
-- P0 — BANNISSEMENT À VIE DE N'IMPORTE QUEL COMPTE PAR N'IMPORTE QUEL JOUEUR
--   `disputes_insert` (20260505185438) ne contraint que `opened_by` et
--   `match_id` ; `guilty_party_id` n'est contraint par RIEN (ni policy, ni
--   grant colonne, ni trigger). Or `trg_three_strikes_ban` se déclenche
--   `after insert or update of guilty_party_id` et compte SANS filtre :
--       select count(*) from disputes where guilty_party_id = new.guilty_party_id
--   Tout joueur inscrit possède un match où il est player1/player2. Il poste
--   3× un litige sur SON match en désignant une victime ARBITRAIRE (le
--   guilty_party_id n'est pas relié au match) : au 3e, la victime passe
--   `is_active=false, permanent_ban=true`. Cible possible : n'importe qui, y
--   compris un super-admin — soit le gel des validations de paiement et des
--   payouts. Coût : 3 requêtes REST. La victime est ensuite confinée sur
--   /banned (user_router) et doit passer par une réintégration sous 48 h.
--
-- P1 — ADMIN SIMPLE CONTOURNANT `resolve_dispute`
--   `disputes_update_admin` autorise TOUT is_admin() à écrire n'importe quelle
--   colonne en PATCH direct. `resolve_dispute` (20260714140000) est pourtant
--   gardée super-admin-si-cagnotte + admin_can_country + audit log. Un admin
--   simple écrivait donc le verdict d'un litige d'un autre pays, sur une
--   compétition à cagnotte, sans trace dans `admin_audit_log`.
--
-- FIX : trigger de garde figeant les colonnes de VERDICT côté client
-- PostgREST direct, sur le modèle exact de `guard_profiles_protected_columns`.
-- Les RPC légitimes (`flag_score_dispute`, `resolve_dispute`, `replay_match`)
-- sont SECURITY DEFINER owner=postgres → `current_user` = owner → exemptées.
--
-- Vérifié avant écriture : AUCUN chemin légitime n'écrit ces colonnes.
-- `guilty_party_id` n'apparaît dans AUCUNE fonction en écriture ni dans une
-- seule ligne de Dart ; le seul accès client à `disputes` est un SELECT de KPI
-- (admin_kpis_repository). En prod : 6 litiges, 0 guilty_party_id renseigné,
-- 0 profil banni. Ce guard ne retire donc aucune capacité réelle.
--
-- ⚠️ COROLLAIRE PRODUIT : la feature « 3 strikes » est DORMANTE — aucun chemin
-- ne désigne de coupable, donc le ban à vie ne s'est jamais déclenché
-- légitimement. Le câblage (paramètre p_guilty_party_id sur resolve_dispute +
-- UI admin) est un chantier séparé ; ce guard le prépare en réservant la
-- colonne au serveur.
-- =============================================================================
-- Depends on: 20260505185438 (policies disputes), 20260515130002 (three
--   strikes), 20260709150000 (modèle de guard), 20260505100005 (is_admin).
-- =============================================================================

-- ─── P0 + P1 : garde des colonnes de verdict ────────────────────────────────
create or replace function public.guard_disputes_verdict_columns()
returns trigger
language plpgsql
security invoker
set search_path = public, pg_temp
as $$
begin
  -- service_role + fonctions SECURITY DEFINER (current_user = owner) restent
  -- libres. Seuls les clients PostgREST directs sont bridés.
  if current_user not in ('authenticated', 'anon') then
    return new;
  end if;

  if tg_op = 'INSERT' then
    -- Ouvrir un litige = déclarer un différend, JAMAIS le trancher. Le verdict
    -- (et donc le strike) est l'affaire exclusive du serveur.
    if new.guilty_party_id is not null
       or new.resolved_by is not null
       or new.resolved_at is not null
       or new.resolution  is not null
    then
      raise exception 'Ouverture de litige : le verdict (guilty_party_id, resolved_*, resolution) est reserve au serveur'
        using errcode = '42501';
    end if;
    -- `status` a pour défaut 'open' ; un client ne pré-tranche pas.
    if new.status is distinct from 'open' then
      raise exception 'Ouverture de litige : statut initial impose (open)'
        using errcode = '42501';
    end if;
    return new;
  end if;

  -- UPDATE — ferme aussi le P1 : même un admin simple ne trafique plus le
  -- verdict en direct ; il doit passer par resolve_dispute / replay_match, qui
  -- portent les gardes pays/cagnotte et écrivent l'audit log.
  if new.guilty_party_id is distinct from old.guilty_party_id
     or new.resolved_by is distinct from old.resolved_by
     or new.resolved_at is distinct from old.resolved_at
     or new.resolution  is distinct from old.resolution
     or new.status      is distinct from old.status
  then
    raise exception 'Verdict de litige : passer par resolve_dispute / replay_match (RPC gardees + auditees)'
      using errcode = '42501';
  end if;

  return new;
end;
$$;

comment on function public.guard_disputes_verdict_columns() is
  'Fige les colonnes de verdict de `disputes` (guilty_party_id, resolved_by, '
  'resolved_at, resolution, status) face aux clients PostgREST directs. Ferme '
  'le P0 « 3 INSERT REST = ban a vie de n''importe qui » et le P1 « admin '
  'simple contournant resolve_dispute ». Les RPC SECURITY DEFINER passent.';

drop trigger if exists trg_guard_disputes_verdict on public.disputes;
create trigger trg_guard_disputes_verdict
  before insert or update on public.disputes
  for each row
  execute function public.guard_disputes_verdict_columns();

-- ─── Défense en profondeur : un strike = un VERDICT, pas une accusation ─────
-- Même si une écriture de `guilty_party_id` venait à repasser, une ligne
-- simplement OUVERTE ne doit jamais compter comme un strike : seul un litige
-- réellement tranché par un admin (`resolved` + `resolved_by`) est un verdict.
-- L'ancien `count(*)` sans filtre comptait une accusation brute.
create or replace function public.enforce_three_strikes_ban()
returns trigger
language plpgsql
security definer
set search_path to 'public'
as $function$
declare
  v_guilty_count int;
  v_username text;
begin
  if new.guilty_party_id is null then
    return new;
  end if;

  if tg_op = 'UPDATE'
     and old.guilty_party_id is not distinct from new.guilty_party_id then
    return new;
  end if;

  select count(*) into v_guilty_count
  from public.disputes
  where guilty_party_id = new.guilty_party_id
    and status = 'resolved'
    and resolved_by is not null;

  if v_guilty_count < 3 then
    return new;
  end if;

  update public.profiles
     set is_active = false,
         permanent_ban = true
   where id = new.guilty_party_id
     and permanent_ban = false
  returning username into v_username;

  if v_username is null then
    return new;
  end if;

  insert into public.notifications(user_id, type, title, body, data)
  values (
    new.guilty_party_id,
    'permanent_ban',
    'Compte définitivement banni',
    'Vous avez été reconnu coupable d''un litige à 3 reprises. Votre '
    'compte est définitivement banni. Vous pouvez soumettre une requête '
    'de réintégration à l''équipe Arena Requête depuis l''écran de '
    'connexion (analyse sous 48h).',
    jsonb_build_object('route', '/banned', 'guilty_count', v_guilty_count)
  );

  return new;
end;
$function$;

comment on function public.enforce_three_strikes_ban() is
  'Ban a vie au 3e VERDICT de culpabilite (litige resolved + resolved_by). '
  'Le filtre de statut est essentiel : sans lui, 3 accusations brutes '
  'suffisaient a bannir (cf. P0 du 2026-07-17).';
