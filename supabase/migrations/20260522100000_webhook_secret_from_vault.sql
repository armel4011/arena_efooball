-- ─────────────────────────────────────────────────────────────────────
-- Sécurité — Sort le webhook secret partagé du code des migrations.
-- ─────────────────────────────────────────────────────────────────────
-- Jusqu'ici, le bearer secret partagé entre les triggers/crons DB et les
-- Edge Functions (dispatch_notification, moderate-chat-message, cleanup-*,
-- send-transactional-email) était inliné EN CLAIR dans 5 migrations :
--   20260515120001, 20260516110001, 20260516120001, 20260516130001,
--   20260516140001
-- → visible dans l'historique Git, donc compromis.
--
-- Cette migration centralise la lecture du secret via Supabase Vault.
-- Plus aucune valeur de secret n'apparaît dans le code versionné.
--
-- ┌─ PRÉREQUIS AVANT D'APPLIQUER CETTE MIGRATION ────────────────────┐
-- │ 1. Générer un NOUVEAU secret (l'ancien est brûlé) :              │
-- │      openssl rand -hex 32                                        │
-- │                                                                  │
-- │ 2. L'enregistrer dans le Vault (SQL editor, hors-repo) :         │
-- │      select vault.create_secret(                                 │
-- │        '<nouveau-secret>', 'webhook_secret',                      │
-- │        'Bearer partagé triggers/crons DB <-> Edge Functions');    │
-- │    (si 'webhook_secret' existe déjà : vault.update_secret(...))   │
-- │                                                                  │
-- │ 3. Mettre la MÊME valeur dans les secrets Edge Functions :       │
-- │      supabase secrets set WEBHOOK_SECRET=<nouveau-secret>         │
-- │                                                                  │
-- │ Si le secret n'est pas dans le Vault au moment où un trigger se   │
-- │ déclenche, le webhook part avec un bearer vide → l'EF répond 401  │
-- │ et l'événement est perdu (échec propre, aucun INSERT bloqué).     │
-- └──────────────────────────────────────────────────────────────────┘

-- ─────────────────────────────────────────────────────────────────────
-- 1. Helper : lit le secret depuis le Vault.
-- ─────────────────────────────────────────────────────────────────────
-- SECURITY DEFINER + owned by postgres → seul l'owner (donc les fonctions
-- trigger/RPC, elles-mêmes SECURITY DEFINER) peut le résoudre. Aucun rôle
-- applicatif (anon, authenticated) ne peut lire le secret.
create or replace function public._webhook_secret()
returns text
language sql
security definer
set search_path = ''
stable
as $$
  select decrypted_secret
  from vault.decrypted_secrets
  where name = 'webhook_secret'
  limit 1;
$$;

revoke all on function public._webhook_secret() from public, anon, authenticated;

comment on function public._webhook_secret() is
  'Résout le bearer secret partagé DB <-> Edge Functions depuis le Vault '
  '(secret nommé ''webhook_secret''). Ne jamais GRANT à un rôle applicatif.';

-- ─────────────────────────────────────────────────────────────────────
-- 2. dispatch_notification — trigger FCM (cf. 20260515120001).
-- ─────────────────────────────────────────────────────────────────────
create or replace function public._dispatch_notification_to_edge()
returns trigger
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_webhook_secret text := coalesce(public._webhook_secret(), '');
  v_function_url text := 'https://mamfuexzadeejtjrtzrq.supabase.co/functions/v1/dispatch_notification';
  v_payload jsonb;
begin
  v_payload := jsonb_build_object(
    'type',      'INSERT',
    'table',     'notifications',
    'schema',    'public',
    'record',    row_to_json(new)::jsonb,
    'old_record', null
  );

  perform net.http_post(
    url := v_function_url,
    body := v_payload,
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'Authorization', 'Bearer ' || v_webhook_secret
    ),
    timeout_milliseconds := 5000
  );

  return new;
end;
$$;

revoke all on function public._dispatch_notification_to_edge() from public, anon, authenticated;

-- ─────────────────────────────────────────────────────────────────────
-- 3. moderate-chat-message — trigger modération (cf. 20260516120001).
-- ─────────────────────────────────────────────────────────────────────
create or replace function public._moderate_chat_message_to_edge()
returns trigger
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_webhook_secret text := coalesce(public._webhook_secret(), '');
  v_function_url text := 'https://mamfuexzadeejtjrtzrq.supabase.co/functions/v1/moderate-chat-message';
  v_payload jsonb;
begin
  v_payload := jsonb_build_object(
    'type',      'INSERT',
    'table',     'chat_messages',
    'schema',    'public',
    'record',    row_to_json(new)::jsonb,
    'old_record', null
  );

  perform net.http_post(
    url := v_function_url,
    body := v_payload,
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'Authorization', 'Bearer ' || v_webhook_secret
    ),
    timeout_milliseconds := 5000
  );
  return new;
end;
$$;

revoke all on function public._moderate_chat_message_to_edge() from public, anon, authenticated;

-- ─────────────────────────────────────────────────────────────────────
-- 4. send-transactional-email — triggers email (cf. 20260516140001).
-- ─────────────────────────────────────────────────────────────────────
create or replace function public._send_email_admin_invitation()
returns trigger
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_webhook_secret text := coalesce(public._webhook_secret(), '');
  v_function_url text := 'https://mamfuexzadeejtjrtzrq.supabase.co/functions/v1/send-transactional-email';
  v_payload jsonb;
begin
  v_payload := jsonb_build_object(
    'kind',      'admin_invitation',
    'recipient', new.target_email,
    'data',      jsonb_build_object(
      'code',       new.code,
      'role',       new.role,
      'expires_at', new.expires_at
    )
  );
  perform net.http_post(
    url := v_function_url,
    body := v_payload,
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'Authorization', 'Bearer ' || v_webhook_secret
    ),
    timeout_milliseconds := 5000
  );
  return new;
end;
$$;

revoke all on function public._send_email_admin_invitation() from public, anon, authenticated;

create or replace function public._send_email_payout_validated()
returns trigger
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_webhook_secret text := coalesce(public._webhook_secret(), '');
  v_function_url text := 'https://mamfuexzadeejtjrtzrq.supabase.co/functions/v1/send-transactional-email';
  v_recipient text;
  v_competition_name text;
  v_payload jsonb;
begin
  -- Email du bénéficiaire (via profile, qui peut être NULL si compte
  -- soft-deleted entre temps — auquel cas on no-op).
  select email into v_recipient
    from public.profiles where id = new.user_id;
  if v_recipient is null then
    return new;
  end if;

  -- Nom de la compétition (libellé humain dans le mail).
  select name into v_competition_name
    from public.competitions where id = new.competition_id;

  v_payload := jsonb_build_object(
    'kind',      'payout_validated',
    'recipient', v_recipient,
    'data',      jsonb_build_object(
      'amount_usd',       new.amount_usd,
      'amount_local',     new.amount_local,
      'currency',         new.currency,
      'payout_method',    new.payout_method,
      'competition_name', v_competition_name
    )
  );
  perform net.http_post(
    url := v_function_url,
    body := v_payload,
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'Authorization', 'Bearer ' || v_webhook_secret
    ),
    timeout_milliseconds := 5000
  );
  return new;
end;
$$;

revoke all on function public._send_email_payout_validated() from public, anon, authenticated;

-- ─────────────────────────────────────────────────────────────────────
-- 5. cleanup-deleted-accounts — RPC manuelle (cf. 20260516110001).
-- ─────────────────────────────────────────────────────────────────────
create or replace function public.admin_run_cleanup_deleted_accounts()
returns void
language plpgsql
security definer
set search_path = public, extensions
as $$
begin
  if not exists (
    select 1 from public.profiles
    where id = auth.uid() and role = 'super_admin'
  ) then
    raise exception 'forbidden_role';
  end if;
  perform net.http_post(
    url := 'https://mamfuexzadeejtjrtzrq.supabase.co/functions/v1/cleanup-deleted-accounts',
    body := '{}'::jsonb,
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'Authorization', 'Bearer ' || coalesce(public._webhook_secret(), '')
    ),
    timeout_milliseconds := 30000
  );
end;
$$;

revoke all on function public.admin_run_cleanup_deleted_accounts() from public, anon;
grant execute on function public.admin_run_cleanup_deleted_accounts() to authenticated;

-- ─────────────────────────────────────────────────────────────────────
-- 6. cleanup-streams — RPC manuelle (cf. 20260516130001).
-- ─────────────────────────────────────────────────────────────────────
create or replace function public.admin_run_cleanup_streams()
returns void
language plpgsql
security definer
set search_path = public, extensions
as $$
begin
  if not exists (
    select 1 from public.profiles
    where id = auth.uid() and role = 'super_admin'
  ) then
    raise exception 'forbidden_role';
  end if;
  perform net.http_post(
    url := 'https://mamfuexzadeejtjrtzrq.supabase.co/functions/v1/cleanup-streams',
    body := '{}'::jsonb,
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'Authorization', 'Bearer ' || coalesce(public._webhook_secret(), '')
    ),
    timeout_milliseconds := 30000
  );
end;
$$;

revoke all on function public.admin_run_cleanup_streams() from public, anon;
grant execute on function public.admin_run_cleanup_streams() to authenticated;

-- ─────────────────────────────────────────────────────────────────────
-- 7. Cron jobs — réécrits pour résoudre le secret au runtime.
-- ─────────────────────────────────────────────────────────────────────
-- pg_cron exécute le corps en tant que `postgres`, owner de
-- `_webhook_secret()` → l'appel est autorisé malgré le revoke.

do $$
declare
  v_job_id bigint;
begin
  select jobid into v_job_id from cron.job where jobname = 'cleanup_deleted_accounts_daily';
  if v_job_id is not null then
    perform cron.unschedule(v_job_id);
  end if;
end $$;

select cron.schedule(
  'cleanup_deleted_accounts_daily',
  '15 3 * * *',
  $cron$
    select net.http_post(
      url := 'https://mamfuexzadeejtjrtzrq.supabase.co/functions/v1/cleanup-deleted-accounts',
      body := '{}'::jsonb,
      headers := jsonb_build_object(
        'Content-Type', 'application/json',
        'Authorization', 'Bearer ' || coalesce(public._webhook_secret(), '')
      ),
      timeout_milliseconds := 30000
    );
  $cron$
);

do $$
declare
  v_job_id bigint;
begin
  select jobid into v_job_id from cron.job where jobname = 'cleanup_streams_hourly';
  if v_job_id is not null then
    perform cron.unschedule(v_job_id);
  end if;
end $$;

select cron.schedule(
  'cleanup_streams_hourly',
  '17 * * * *',
  $cron$
    select net.http_post(
      url := 'https://mamfuexzadeejtjrtzrq.supabase.co/functions/v1/cleanup-streams',
      body := '{}'::jsonb,
      headers := jsonb_build_object(
        'Content-Type', 'application/json',
        'Authorization', 'Bearer ' || coalesce(public._webhook_secret(), '')
      ),
      timeout_milliseconds := 30000
    );
  $cron$
);
