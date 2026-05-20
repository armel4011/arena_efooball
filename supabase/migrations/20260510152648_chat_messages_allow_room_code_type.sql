alter table public.chat_messages drop constraint chat_messages_type_check;
alter table public.chat_messages add constraint chat_messages_type_check
  check (type = any (array['text'::text, 'system'::text, 'image'::text, 'room_code'::text]));
