-- ════════════════════════════════════════════════════════════════════
-- ARENA — Fil de support user ↔ admin (écran « Contact / Aide »)
-- ════════════════════════════════════════════════════════════════════
-- On RÉUTILISE l'infrastructure de chat générique (chat_channels +
-- chat_messages) avec le type 'admin_user' déjà prévu d'origine, plutôt
-- que de créer une 3e messagerie. Bénéfices : modération auto, Realtime,
-- soft-delete, médias et état « non-lu » (chat_channel_user_state) déjà en
-- place et réutilisés tels quels.
--
-- Ce que cette migration ajoute :
--   1. chat_channels.support_user_id  — relie un canal 'admin_user' à SON
--      utilisateur (1 canal de support par user).
--   2. ensure_support_channel()       — RPC SECURITY DEFINER qui crée/retourne
--      le canal de support de l'appelant (un user ne peut pas créer de canal
--      'admin_user' via la RLS d'INSERT de chat_channels, d'où la RPC).
--   3. RLS étendue                     — SELECT chat_messages couvre désormais
--      le propriétaire d'un canal 'admin_user' ; garde RESTRICTIVE d'INSERT
--      qui cantonne chaque canal de support à son propriétaire (ou un admin).
--   4. _notify_support_message()       — trigger qui notifie l'autre partie
--      (push FCM via la table notifications) à chaque message.
-- ════════════════════════════════════════════════════════════════════

-- ─────────────────────────────────────────────────────────────────────
-- 1. Colonne de liaison canal de support → utilisateur
-- ─────────────────────────────────────────────────────────────────────
alter table public.chat_channels
  add column if not exists support_user_id uuid
    references public.profiles on delete cascade;

comment on column public.chat_channels.support_user_id is
  'Pour les canaux type=''admin_user'' : l''utilisateur propriétaire du fil de support. NULL pour les autres types.';

-- Un seul canal de support par utilisateur.
create unique index if not exists chat_channels_support_user_uniq
  on public.chat_channels (support_user_id)
  where type = 'admin_user';

-- Cohérence : un canal de support DOIT cibler un utilisateur.
-- (0 canal 'admin_user' n'existe à ce jour → contrainte posée sans backfill.)
do $$
begin
  if not exists (
    select 1 from pg_constraint
    where conname = 'chat_channels_admin_user_has_user'
      and conrelid = 'public.chat_channels'::regclass
  ) then
    alter table public.chat_channels
      add constraint chat_channels_admin_user_has_user
      check (type <> 'admin_user' or support_user_id is not null);
  end if;
end $$;

-- ─────────────────────────────────────────────────────────────────────
-- 2. RPC : ouvre (ou retourne) le canal de support de l'appelant
-- ─────────────────────────────────────────────────────────────────────
create or replace function public.ensure_support_channel()
returns uuid
language plpgsql
security definer
set search_path to 'public', 'pg_temp'
as $$
declare
  v_uid uuid := auth.uid();
  v_id  uuid;
begin
  if v_uid is null then
    raise exception 'not_authenticated';
  end if;

  select id into v_id
  from public.chat_channels
  where type = 'admin_user' and support_user_id = v_uid;

  if v_id is null then
    insert into public.chat_channels (type, support_user_id, name)
    values ('admin_user', v_uid, 'Support')
    returning id into v_id;
  end if;

  return v_id;
end;
$$;

revoke all on function public.ensure_support_channel() from public, anon;
grant execute on function public.ensure_support_channel() to authenticated;

comment on function public.ensure_support_channel() is
  'Crée (idempotent) et retourne l''id du canal de support (type=admin_user) de l''appelant.';

-- ─────────────────────────────────────────────────────────────────────
-- 3. RLS
-- ─────────────────────────────────────────────────────────────────────
-- 3a. SELECT chat_messages : ajoute le cas « propriétaire d'un canal de
--     support ». On réécrit la policy en conservant à l'identique les
--     branches existantes (broadcast/global, match, friend) + admin.
drop policy if exists chat_messages_select on public.chat_messages;
create policy chat_messages_select on public.chat_messages
  for select
  using (
    (select public.is_admin())
    or exists (
      select 1
      from public.chat_channels c
        left join public.matches m on m.id = c.match_id
        left join public.friendships f on f.id = c.friendship_id
      where c.id = chat_messages.channel_id
        and (
          c.type = any (array['competition_broadcast'::text, 'global'::text])
          or (c.type = 'match'
              and ((select auth.uid()) = m.player1_id
                   or (select auth.uid()) = m.player2_id))
          or (c.type = 'friend'
              and f.status = 'accepted'::friendship_status
              and ((select auth.uid()) = f.requester_id
                   or (select auth.uid()) = f.addressee_id))
          or (c.type = 'admin_user'
              and c.support_user_id = (select auth.uid()))
        )
    )
  );

-- 3b. INSERT chat_messages : garde RESTRICTIVE qui ne contraint QUE les
--     canaux 'admin_user'. Pour les autres types, le premier terme est vrai
--     → la garde laisse passer (la policy PERMISSIVE existante reste seule
--     juge). Pour un canal de support : seul son propriétaire ou un admin
--     peut écrire. RESTRICTIVE = ET avec les policies PERMISSIVES (cf. leçon
--     RLS : une garde « NOT EXISTS » doit être RESTRICTIVE, sinon inactive).
drop policy if exists chat_messages_support_insert_guard on public.chat_messages;
create policy chat_messages_support_insert_guard on public.chat_messages
  as restrictive
  for insert
  with check (
    not exists (
      select 1 from public.chat_channels cc
      where cc.id = chat_messages.channel_id and cc.type = 'admin_user'
    )
    or (select public.is_admin())
    or exists (
      select 1 from public.chat_channels cc
      where cc.id = chat_messages.channel_id
        and cc.type = 'admin_user'
        and cc.support_user_id = (select auth.uid())
    )
  );

-- ─────────────────────────────────────────────────────────────────────
-- 4. Notification (push FCM via table notifications)
-- ─────────────────────────────────────────────────────────────────────
create or replace function public._notify_support_message()
returns trigger
language plpgsql
security definer
set search_path to 'public', 'pg_temp'
as $$
declare
  v_support_user_id uuid;
  v_sender_is_admin boolean;
  v_sender_name     text;
  v_preview         text;
begin
  -- Ne concerne que les canaux de support.
  select support_user_id into v_support_user_id
  from public.chat_channels
  where id = NEW.channel_id and type = 'admin_user';
  if v_support_user_id is null then
    return NEW;
  end if;

  -- Aperçu (texte tronqué, sinon « pièce jointe »).
  if NEW.content is not null and length(NEW.content) > 0 then
    v_preview := substring(NEW.content from 1 for 120);
  elsif NEW.media_url is not null then
    v_preview := 'Pièce jointe';
  else
    v_preview := '';
  end if;

  select (role in ('admin', 'super_admin'))
    into v_sender_is_admin
  from public.profiles where id = NEW.sender_id;

  if coalesce(v_sender_is_admin, false) then
    -- Admin → user : notifie le propriétaire du fil.
    select username into v_sender_name from public.profiles where id = NEW.sender_id;
    insert into public.notifications (user_id, type, title, body, data)
    values (
      v_support_user_id,
      'admin_message',
      coalesce(v_sender_name, 'Support ARENA'),
      v_preview,
      jsonb_build_object('route', '/support-chat', 'channel_id', NEW.channel_id::text)
    );
  else
    -- User → admins : notifie les SUPER-admins (propriétaires de la boîte
    -- de support `/super/support`).
    insert into public.notifications (user_id, type, title, body, data)
    select p.id,
           'support_request',
           'Nouveau message support',
           v_preview,
           jsonb_build_object(
             'route', '/super/support',
             'channel_id', NEW.channel_id::text,
             'from_user_id', NEW.sender_id::text
           )
    from public.profiles p
    where p.role = 'super_admin'
      and p.is_active = true
      and p.deleted_at is null;
  end if;

  return NEW;
end;
$$;

drop trigger if exists trg_chat_messages_support_notify on public.chat_messages;
create trigger trg_chat_messages_support_notify
  after insert on public.chat_messages
  for each row
  execute function public._notify_support_message();

-- ─────────────────────────────────────────────────────────────────────
-- 5. Storage : étend les policies du bucket chat-media aux canaux de
--    support. Le propriétaire du fil (ou un admin) peut uploader/lire
--    les médias rangés sous `<channelId>/...` (mêmes branches match/friend
--    qu'avant, + nouvelle branche admin_user).
-- ─────────────────────────────────────────────────────────────────────
drop policy if exists chat_media_insert_member on storage.objects;
create policy chat_media_insert_member on storage.objects
  for insert to public
  with check (
    bucket_id = 'chat-media'
    and (
      exists (select 1 from public.chat_channels cc join public.matches m on m.id = cc.match_id
              where cc.id::text = (storage.foldername(objects.name))[1] and cc.type = 'match'
                and (auth.uid() = m.player1_id or auth.uid() = m.player2_id))
      or exists (select 1 from public.chat_channels cc join public.friendships f on f.id = cc.friendship_id
              where cc.id::text = (storage.foldername(objects.name))[1] and cc.type = 'friend'
                and f.status = 'accepted'::friendship_status
                and (auth.uid() = f.requester_id or auth.uid() = f.addressee_id))
      or exists (select 1 from public.chat_channels cc
              where cc.id::text = (storage.foldername(objects.name))[1] and cc.type = 'admin_user'
                and (auth.uid() = cc.support_user_id or public.is_admin()))
    )
  );

drop policy if exists chat_media_select_member on storage.objects;
create policy chat_media_select_member on storage.objects
  for select to public
  using (
    bucket_id = 'chat-media'
    and (
      exists (select 1 from public.chat_channels cc join public.matches m on m.id = cc.match_id
              where cc.id::text = (storage.foldername(objects.name))[1] and cc.type = 'match'
                and (auth.uid() = m.player1_id or auth.uid() = m.player2_id))
      or exists (select 1 from public.chat_channels cc join public.friendships f on f.id = cc.friendship_id
              where cc.id::text = (storage.foldername(objects.name))[1] and cc.type = 'friend'
                and f.status = 'accepted'::friendship_status
                and (auth.uid() = f.requester_id or auth.uid() = f.addressee_id))
      or exists (select 1 from public.chat_channels cc
              where cc.id::text = (storage.foldername(objects.name))[1] and cc.type = 'admin_user'
                and (auth.uid() = cc.support_user_id or public.is_admin()))
    )
  );
