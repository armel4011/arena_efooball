-- Phase 12.5 — Cron quotidien : purge RGPD des comptes soft-deleted > 30j.
--
-- Schedule : tous les jours à 03:15 UTC (heure creuse côté Yaoundé/Douala).
-- Action   : `net.http_post` vers `cleanup-deleted-accounts` avec le
--            shared webhook secret (réutilisé de dispatch_notification).
--
-- Pourquoi pg_cron + pg_net plutôt qu'un Database Webhook : un cron n'a
-- pas de "table trigger" — il faut un scheduler. pg_cron est managé par
-- Supabase, robuste et observable via `cron.job_run_details`.

-- Garde-fou : ne pas créer 2 fois la même job (idempotent à chaque
-- redéploiement). pg_cron.unschedule prend un nom — on déduplique
-- en cherchant par jobname.
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
        'Authorization', 'Bearer 8877a4a699baf715b90661172e80a353d229b7b65792caa1931af3a7a3909acd'
      ),
      timeout_milliseconds := 30000
    );
  $cron$
);

-- Petit confort d'admin : un wrapper SQL exposé en RPC permet à un
-- super-admin de déclencher le purge à la demande depuis le dashboard
-- (utile en cas de demande RGPD urgente "je veux que mon compte
-- disparaisse maintenant"). Gate sur is_super_admin().
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
      'Authorization', 'Bearer 8877a4a699baf715b90661172e80a353d229b7b65792caa1931af3a7a3909acd'
    ),
    timeout_milliseconds := 30000
  );
end;
$$;

revoke all on function public.admin_run_cleanup_deleted_accounts() from public, anon;
grant execute on function public.admin_run_cleanup_deleted_accounts() to authenticated;

comment on function public.admin_run_cleanup_deleted_accounts() is
  'Déclenche manuellement le purge RGPD. Réservé super_admin (gate sur role) ; '
  'utilisé depuis le dashboard d''admin pour les requêtes urgentes.';
