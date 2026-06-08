-- ─────────────────────────────────────────────────────────────────────
-- Fix audit 2026-06-08 — rate-limit register-admin (énumération / brute-force).
-- ─────────────────────────────────────────────────────────────────────
-- L'EF `register-admin` est volontairement publique (`verify_jwt=false`) :
-- l'auth repose uniquement sur un code d'invitation `XXXX-XXXX-XXXX`. Sans
-- throttling, l'endpoint était un oracle d'énumération de codes (les réponses
-- distinguent invalid / already_used / expired / mismatch) brute-forçable à
-- volonté. On borne donc les tentatives PAR IP.
--
-- Comportement (aligné sur le pattern TOTP, cf. 20260602184952) :
--   • Une « tentative » = un code refusé (introuvable / consommé / expiré /
--     email mismatch). Une inscription réussie remet le compteur à zéro.
--   • 5 échecs dans une fenêtre de 15 min → verrou 30 min.
--   • Verrou actif → l'EF renvoie 429 sans même consulter `invitation_codes`
--     (pas d'oracle).
--
-- Accès : table + fonctions réservées au service_role (l'EF). Aucun client
-- (anon/authenticated) ne peut lire l'état du verrou ni manipuler le compteur.
-- ─────────────────────────────────────────────────────────────────────

-- 1. Suivi des tentatives par IP.
create table if not exists public.admin_register_attempts (
  ip                text primary key,
  failed_count      integer not null default 0,
  window_started_at timestamptz not null default now(),
  locked_until      timestamptz,
  updated_at        timestamptz not null default now()
);

comment on table public.admin_register_attempts is
  'Compteur d''échecs register-admin par IP (anti-énumération de codes '
  'd''invitation). Service role uniquement — RLS deny-all volontaire.';

-- RLS activée sans policy = deny-all pour anon/authenticated.
-- Le service_role (EF) bypasse la RLS.
alter table public.admin_register_attempts enable row level security;
revoke all on public.admin_register_attempts from anon, authenticated;

-- 2. Lecture du verrou (appelée AVANT de consulter le code → pas d'oracle).
create or replace function public.register_admin_check_lock(p_ip text)
returns jsonb
language sql
security definer
set search_path = public, pg_temp
stable
as $$
  select coalesce(
    (
      select jsonb_build_object(
        'locked', ra.locked_until is not null and ra.locked_until > now(),
        'retry_after_seconds',
          greatest(0, ceil(extract(epoch from (ra.locked_until - now())))::integer)
      )
      from public.admin_register_attempts ra
      where ra.ip = p_ip
    ),
    jsonb_build_object('locked', false, 'retry_after_seconds', 0)
  );
$$;

-- 3. Échec atomique : incrémente dans la fenêtre courante, verrouille au 5e.
--    La fenêtre glisse : si le dernier échec date de > 15 min, on repart à 1.
create or replace function public.register_admin_record_failure(p_ip text)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_count        integer;
  v_window       timestamptz;
  v_locked_until timestamptz;
begin
  insert into public.admin_register_attempts as ra
    (ip, failed_count, window_started_at, updated_at)
  values (p_ip, 1, now(), now())
  on conflict (ip) do update
    set failed_count = case
          when ra.window_started_at < now() - interval '15 minutes' then 1
          else ra.failed_count + 1
        end,
        window_started_at = case
          when ra.window_started_at < now() - interval '15 minutes' then now()
          else ra.window_started_at
        end,
        updated_at = now()
  returning ra.failed_count, ra.window_started_at
    into v_count, v_window;

  if v_count >= 5 then
    v_locked_until := now() + interval '30 minutes';
    update public.admin_register_attempts
      set locked_until      = v_locked_until,
          failed_count      = 0,
          window_started_at = now(),
          updated_at        = now()
      where ip = p_ip;
  end if;

  return jsonb_build_object(
    'failed_count', v_count,
    'locked', v_locked_until is not null,
    'retry_after_seconds', case when v_locked_until is not null then 30 * 60 else 0 end
  );
end;
$$;

-- 4. Succès : remise à zéro (une inscription valide nettoie l'IP).
create or replace function public.register_admin_record_success(p_ip text)
returns void
language sql
security definer
set search_path = public, pg_temp
as $$
  delete from public.admin_register_attempts where ip = p_ip;
$$;

-- 5. ACL : service_role uniquement.
revoke execute on function public.register_admin_check_lock(text) from public, anon, authenticated;
revoke execute on function public.register_admin_record_failure(text) from public, anon, authenticated;
revoke execute on function public.register_admin_record_success(text) from public, anon, authenticated;
grant execute on function public.register_admin_check_lock(text) to service_role;
grant execute on function public.register_admin_record_failure(text) to service_role;
grant execute on function public.register_admin_record_success(text) to service_role;
