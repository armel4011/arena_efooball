-- =============================================================================
-- ARENA — Sécurité — m2 : un user ne peut modifier que `read_at` d'un message
-- =============================================================================
-- La policy `admin_chat_update_read_user`
-- (20260526120000_admin_user_chat.sql:56-60) annonce en commentaire qu'une
-- policy RESTRICTIVE empêchera le destinataire de réécrire `text`/`admin_id`,
-- mais elle est PERMISSIVE et son `WITH CHECK (recipient_id = auth.uid())`
-- n'empêche RIEN de tel : le destinataire peut altérer `text`, `admin_id`,
-- `sent_at` du message admin qui lui est adressé (atteinte à l'intégrité).
--
-- Une policy RLS ne peut pas comparer OLD/NEW colonne par colonne (le WITH
-- CHECK ne voit que la nouvelle ligne) — donc impossible de figer `text` tout
-- en laissant `read_at` modifiable par une policy seule. On utilise un trigger
-- BEFORE UPDATE (même pattern que la garde profiles C1) : un client
-- authenticated/anon non-admin ne peut modifier QUE `read_at`. Les admins et
-- le service_role conservent tous leurs droits.
-- =============================================================================
-- Depends on: 20260526120000_admin_user_chat.sql
-- =============================================================================

create or replace function public.guard_admin_chat_message_columns()
returns trigger
language plpgsql
security invoker
set search_path = public, pg_temp
as $$
begin
  if current_user in ('authenticated', 'anon') and not public.is_admin() then
    if new.admin_id     is distinct from old.admin_id
       or new.recipient_id is distinct from old.recipient_id
       or new.text         is distinct from old.text
       or new.sent_at      is distinct from old.sent_at
    then
      raise exception 'Modification interdite : seul read_at est modifiable cote destinataire'
        using errcode = '42501';
    end if;
  end if;
  return new;
end;
$$;

comment on function public.guard_admin_chat_message_columns() is
  'm2 : empeche le destinataire (authenticated non-admin) de reecrire admin_id/recipient_id/text/sent_at ; seul read_at reste modifiable. Admins et service_role non concernes.';

drop trigger if exists trg_admin_chat_guard_columns on public.admin_chat_messages;
create trigger trg_admin_chat_guard_columns
  before update on public.admin_chat_messages
  for each row execute function public.guard_admin_chat_message_columns();
