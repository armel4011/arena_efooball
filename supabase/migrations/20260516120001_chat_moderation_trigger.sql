-- Phase 12.5 — Trigger qui pousse les nouveaux `chat_messages` vers
-- l'Edge Function `moderate-chat-message`. Pattern identique au trigger
-- FCM (cf. 20260515120001_dispatch_notification_trigger.sql) :
--   - net.http_post async pour ne pas bloquer l'INSERT
--   - payload format Database Webhook standard
--   - bearer secret partagé avec l'EF
--
-- Seed minimal de `banned_words` (vocabulaire e-sport courant) — le
-- super-admin peut compléter via la console.

create or replace function public._moderate_chat_message_to_edge()
returns trigger
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_webhook_secret text := '8877a4a699baf715b90661172e80a353d229b7b65792caa1931af3a7a3909acd';
  v_function_url text := 'https://mamfuexzadeejtjrtzrq.supabase.co/functions/v1/moderate-chat-message';
  v_payload jsonb;
begin
  -- On ne déclenche que sur INSERT initial (is_moderated=false). Si
  -- l'EF update le row, la condition WHEN du trigger filtre.
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

drop trigger if exists trg_chat_messages_moderate on public.chat_messages;
create trigger trg_chat_messages_moderate
  after insert on public.chat_messages
  for each row
  -- Seul le texte est modéré ; les messages 'system' (résultats, etc.)
  -- viennent du backend de toute façon et 'image' n'a pas de contenu
  -- textuel à filtrer. is_moderated=false filtre l'UPDATE de l'EF
  -- (évite la boucle infinie même si on changeait AFTER UPDATE plus tard).
  when (new.type = 'text' and new.is_moderated = false)
  execute function public._moderate_chat_message_to_edge();

comment on function public._moderate_chat_message_to_edge() is
  'Trigger handler — pousse chaque chat_message texte vers l''Edge '
  'Function moderate-chat-message (filtre banned_words + log abuse).';

-- ─────────────────────────────────────────────────────────────────────
-- Seed initial : vocabulaire e-sport courant. Le super-admin enrichit
-- via la console (banned_words est super_admin-writable, cf. phase 11).
-- ─────────────────────────────────────────────────────────────────────
insert into public.banned_words (word, language, severity, category) values
  ('noob',     'en', 1, 'esport'),
  ('hack',     'en', 1, 'esport'),
  ('cheater',  'en', 2, 'accusation'),
  ('scammer',  'en', 2, 'accusation'),
  ('tricheur', 'fr', 2, 'accusation'),
  ('arnaqueur','fr', 2, 'accusation')
on conflict (word, language) do nothing;
