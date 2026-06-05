-- ─────────────────────────────────────────────────────────────────────
-- Fix audit 2026-06-02 — rate-limit TOTP admin (brute-force 2FA).
-- ─────────────────────────────────────────────────────────────────────
-- Les EF `admin-verify-totp` / `admin-stepup-totp` acceptaient un nombre
-- illimité d'essais → un attaquant disposant du mot de passe admin (ou
-- d'une session volée pour le step-up) pouvait brute-forcer le code TOTP
-- 6 chiffres (10^6 combinaisons).
--
-- Comportement implémenté (aligné sur les messages UI existants de
-- `auth_failure_message.dart` : « Compte verrouillé après 3 tentatives.
-- Réessayez dans 30 minutes. ») :
--   • 3 échecs consécutifs → verrou 30 minutes (compteur partagé entre
--     verify-login et step-up : même surface d'attaque, même compteur).
--   • Verrou actif → l'EF renvoie 429 `admin_locked` sans même vérifier
--     le code (pas d'oracle).
--   • Succès → compteur remis à zéro.
--   • Lockout loggé dans `anti_cheat_events` (type `totp_lockout`,
--     severity 2) pour visibilité super-admin.
--
-- Accès : la table et les fonctions sont réservées au service_role (les
-- EF). Aucun client (anon/authenticated) ne peut lire ou appeler quoi
-- que ce soit — pas d'oracle sur l'état du verrou.
-- ─────────────────────────────────────────────────────────────────────

-- 1. Table de suivi des tentatives (une ligne par admin).
create table if not exists public.totp_attempts (
  user_id      uuid primary key references public.profiles (id) on delete cascade,
  failed_count integer not null default 0,
  locked_until timestamptz,
  updated_at   timestamptz not null default now()
);

comment on table public.totp_attempts is
  'Compteur d''échecs TOTP par admin (verify-login + step-up). '
  'Service role uniquement — RLS deny-all volontaire (aucune policy).';

-- RLS activée sans policy = deny-all pour anon/authenticated.
-- Le service_role (EF) bypasse la RLS.
alter table public.totp_attempts enable row level security;
revoke all on public.totp_attempts from anon, authenticated;

-- 2. `totp_lockout` ajouté aux types d'événements anti-cheat autorisés.
alter table public.anti_cheat_events
  drop constraint anti_cheat_events_type_check;
alter table public.anti_cheat_events
  add constraint anti_cheat_events_type_check check (
    type = any (array[
      'window_focus_lost'::text,
      'recording_interrupted'::text,
      'overlay_disabled'::text,
      'app_killed'::text,
      'screen_off'::text,
      'suspicious_input'::text,
      'duplicate_account_attempt'::text,
      'totp_lockout'::text
    ])
  );

-- 3. Échec atomique : incrémente, verrouille au 3e échec, log anti-cheat.
--    Retourne l'état pour que l'EF construise sa réponse (401 ou 429).
create or replace function public.totp_record_failure(p_user_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_count        integer;
  v_locked_until timestamptz;
begin
  insert into public.totp_attempts as ta (user_id, failed_count, updated_at)
  values (p_user_id, 1, now())
  on conflict (user_id) do update
    set failed_count = ta.failed_count + 1,
        updated_at   = now()
  returning ta.failed_count into v_count;

  if v_count >= 3 then
    v_locked_until := now() + interval '30 minutes';
    update public.totp_attempts
      set locked_until = v_locked_until,
          failed_count = 0,
          updated_at   = now()
      where user_id = p_user_id;

    -- Visibilité super-admin : un lockout TOTP est un signal d'attaque.
    insert into public.anti_cheat_events (profile_id, type, severity, data)
    values (
      p_user_id,
      'totp_lockout',
      2,
      jsonb_build_object(
        'failed_count', v_count,
        'locked_until', v_locked_until
      )
    );
  end if;

  return jsonb_build_object(
    'failed_count', v_count,
    'locked_until', v_locked_until,
    'attempts_remaining', greatest(0, 3 - v_count)
  );
end;
$$;

-- 4. Lecture du verrou (appelée AVANT de vérifier le code → pas d'oracle).
create or replace function public.totp_check_lock(p_user_id uuid)
returns jsonb
language sql
security definer
set search_path = public, pg_temp
stable
as $$
  select coalesce(
    (
      select jsonb_build_object(
        'locked', ta.locked_until is not null and ta.locked_until > now(),
        'locked_until', ta.locked_until,
        'retry_after_seconds',
          greatest(0, ceil(extract(epoch from (ta.locked_until - now())))::integer)
      )
      from public.totp_attempts ta
      where ta.user_id = p_user_id
    ),
    jsonb_build_object('locked', false)
  );
$$;

-- 5. Succès : remise à zéro du compteur et du verrou.
create or replace function public.totp_record_success(p_user_id uuid)
returns void
language sql
security definer
set search_path = public, pg_temp
as $$
  delete from public.totp_attempts where user_id = p_user_id;
$$;

-- 6. ACL : service_role uniquement. Aucun client ne peut sonder l'état
--    du verrou ni manipuler le compteur.
revoke execute on function public.totp_record_failure(uuid) from public, anon, authenticated;
revoke execute on function public.totp_check_lock(uuid) from public, anon, authenticated;
revoke execute on function public.totp_record_success(uuid) from public, anon, authenticated;
grant execute on function public.totp_record_failure(uuid) to service_role;
grant execute on function public.totp_check_lock(uuid) to service_role;
grant execute on function public.totp_record_success(uuid) to service_role;
