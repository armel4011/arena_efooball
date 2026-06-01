-- Phase 12.5 — Trigger DB qui invoque l'Edge Function `dispatch_notification`
-- à chaque insertion dans `public.notifications`.
--
-- L'EF lit le profile.fcm_token du destinataire et envoie une notification
-- FCM v1. On utilise `net.http_post` (extension pg_net) pour ne pas
-- bloquer la transaction INSERT — le HTTP call est queueé.
--
-- Le mime-type des `net.http_post` requiert d'envoyer un body texte ;
-- on builde le payload au format Supabase Database Webhook standard
-- (`{type, table, schema, record, old_record}`) pour que l'EF puisse
-- partager le même handler si on passe plus tard à des Webhooks
-- managés.

create or replace function public._dispatch_notification_to_edge()
returns trigger
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_webhook_secret text;
  v_function_url text := 'https://mamfuexzadeejtjrtzrq.supabase.co/functions/v1/dispatch_notification';
  v_payload jsonb;
begin
  -- Le secret est stocké dans pg_catalog.pg_db_role_setting via une
  -- option `app.settings.webhook_secret`. À défaut, on lit depuis vault
  -- ou on inline en clair ici (notre choix V1).
  v_webhook_secret := 'ROTATED-SEE-MIGRATION-20260522100000';

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

-- Permissions minimales : exécutable seulement par postgres (trigger context).
revoke all on function public._dispatch_notification_to_edge() from public, anon, authenticated;

drop trigger if exists trg_notifications_dispatch on public.notifications;
create trigger trg_notifications_dispatch
  after insert on public.notifications
  for each row
  execute function public._dispatch_notification_to_edge();

comment on function public._dispatch_notification_to_edge() is
  'Trigger handler — pousse chaque nouvelle notification vers l''Edge '
  'Function dispatch_notification (FCM HTTP v1). pg_net est asynchrone, '
  'l''INSERT n''est pas bloqué par le HTTP call.';
