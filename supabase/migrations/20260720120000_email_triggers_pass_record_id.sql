-- ─────────────────────────────────────────────────────────────────────
-- Audit 2026-07-20 — durcissement send-transactional-email.
-- ─────────────────────────────────────────────────────────────────────
-- L'Edge Function `send-transactional-email` faisait confiance au
-- `recipient`/`data` du payload webhook. Un `WEBHOOK_SECRET` qui fuiterait
-- permettait donc d'envoyer un email Arena-brandé (faux code d'invitation
-- admin, faux « gain validé ») à une adresse arbitraire — vecteur de
-- phishing via le domaine d'envoi vérifié.
--
-- L'EF relit désormais destinataire + variables sensibles depuis la ligne
-- source (invitation_codes / payouts), keyée par `record_id`. L'appelant ne
-- choisit plus que QUELLE ligne, jamais le contenu — même durcissement que
-- `moderate-chat-message` (audit 2026-07-18) et `dispatch_notification`.
--
-- Cette migration ajoute `record_id = new.id` aux deux payloads. On CONSERVE
-- `recipient`/`data` : l'ancienne EF (avant redéploiement) continue de
-- fonctionner, donc l'ordre de déploiement migration/fonction est
-- indifférent. Une fois l'EF déployée, ces champs sont ignorés pour les
-- emails sensibles.
--
-- ┌─ DÉPLOIEMENT ────────────────────────────────────────────────────┐
-- │ Appliquer cette migration PUIS redéployer send-transactional-email.│
-- │ (l'ordre inverse marche aussi grâce au fallback ci-dessus.)        │
-- └────────────────────────────────────────────────────────────────────┘

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
    'record_id', new.id,
    -- recipient/data conservés pour compat rétro (EF durcie les ignore).
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
  -- soft-deleted entre temps — auquel cas on no-op). Conservé pour la
  -- compat rétro du payload ; l'EF durcie relit depuis la DB par record_id.
  select email into v_recipient
    from public.profiles where id = new.user_id;
  if v_recipient is null then
    return new;
  end if;

  select name into v_competition_name
    from public.competitions where id = new.competition_id;

  v_payload := jsonb_build_object(
    'kind',      'payout_validated',
    'record_id', new.id,
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

comment on function public._send_email_admin_invitation() is
  'Trigger handler — POST send-transactional-email (kind=admin_invitation) '
  'avec record_id=invitation_codes.id ; l''EF relit le contenu depuis la DB.';
comment on function public._send_email_payout_validated() is
  'Trigger handler — POST send-transactional-email (kind=payout_validated) '
  'avec record_id=payouts.id ; l''EF relit destinataire+montant depuis la DB.';
