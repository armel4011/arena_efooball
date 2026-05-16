-- Phase 12.5 — Triggers DB qui poussent les emails transactionnels vers
-- l'Edge Function `send-transactional-email` :
--   1. AFTER INSERT invitation_codes (si target_email renseigné)
--      → email "admin_invitation" avec le code à 12 caractères
--   2. AFTER UPDATE payouts WHEN status passe à 'validated'
--      → email "payout_validated" au bénéficiaire avec montant +
--        nom de compétition
--
-- Pattern identique à `_dispatch_notification_to_edge` (cf. FCM trigger) :
-- net.http_post async, bearer secret partagé, payload JSON.

create or replace function public._send_email_admin_invitation()
returns trigger
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_webhook_secret text := '8877a4a699baf715b90661172e80a353d229b7b65792caa1931af3a7a3909acd';
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

drop trigger if exists trg_invitation_codes_email on public.invitation_codes;
create trigger trg_invitation_codes_email
  after insert on public.invitation_codes
  for each row
  when (new.target_email is not null)
  execute function public._send_email_admin_invitation();

comment on function public._send_email_admin_invitation() is
  'Trigger handler — POST send-transactional-email avec kind=admin_invitation '
  'quand un super-admin émet un code nominatif (target_email renseigné).';

-- ─────────────────────────────────────────────────────────────────────

create or replace function public._send_email_payout_validated()
returns trigger
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_webhook_secret text := '8877a4a699baf715b90661172e80a353d229b7b65792caa1931af3a7a3909acd';
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

drop trigger if exists trg_payouts_validated_email on public.payouts;
create trigger trg_payouts_validated_email
  after update of status on public.payouts
  for each row
  when (new.status = 'validated' and old.status is distinct from 'validated')
  execute function public._send_email_payout_validated();

comment on function public._send_email_payout_validated() is
  'Trigger handler — POST send-transactional-email avec kind=payout_validated '
  'quand un payout transitionne vers status=''validated''.';
