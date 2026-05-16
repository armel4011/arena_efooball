-- Phase 12.5 — Cron horaire : ferme les streams "stale" + purge le
-- storage des matchs finished depuis > 30j.
--
-- Schedule : minute 17 de chaque heure (décalé du purge RGPD 03:15
-- pour ne pas surcharger le scheduler).
-- Action   : net.http_post vers `cleanup-streams` avec le webhook
-- secret partagé.

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
        'Authorization', 'Bearer 8877a4a699baf715b90661172e80a353d229b7b65792caa1931af3a7a3909acd'
      ),
      timeout_milliseconds := 30000
    );
  $cron$
);

-- RPC pour déclenchement manuel super-admin (utile en debug, ou si on
-- soupçonne qu'un broadcaster est resté connecté après un crash).
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
      'Authorization', 'Bearer 8877a4a699baf715b90661172e80a353d229b7b65792caa1931af3a7a3909acd'
    ),
    timeout_milliseconds := 30000
  );
end;
$$;

revoke all on function public.admin_run_cleanup_streams() from public, anon;
grant execute on function public.admin_run_cleanup_streams() to authenticated;

comment on function public.admin_run_cleanup_streams() is
  'Déclenche manuellement le cleanup des streams stale + storage > 30j. '
  'Réservé super_admin (gate sur role).';
