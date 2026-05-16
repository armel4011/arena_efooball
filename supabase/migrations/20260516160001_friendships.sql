-- =============================================================================
-- ARENA — Phase 13 — Système d'amitiés (friend requests + blocking)
-- =============================================================================
-- Modèle :
--   - 1 row par paire (unique sur least/greatest(requester_id, addressee_id))
--   - status = pending → accepted → … (peut être supprimé via remove_friend)
--   - status = blocked : qui que ce soit dans la paire peut bloquer ;
--     `blocked_by` désigne le bloqueur (seul lui peut débloquer).
--
-- Pourquoi des RPCs au lieu de policies INSERT/UPDATE narrow ?
--   Les transitions (accept, block, unblock) demandent de vérifier l'état
--   ancien + le rôle (requester vs addressee), ce qui est lourd à exprimer
--   en WITH CHECK seul. Une poignée de SQL functions `security definer`
--   garde la logique atomique et auditable. Ce ne sont PAS des Edge
--   Functions (cf. phase-strategy 12.5) — c'est du SQL natif.
-- =============================================================================
-- Dépend de : 20260505100002 (profiles), 20260505100004 (chat_messages),
--             20260505100005 (RLS + is_admin)
-- =============================================================================

-- ─────────────────────────────────────────────────────────────────────────────
-- 1. ENUM friendship_status
-- ─────────────────────────────────────────────────────────────────────────────
do $$ begin
  create type public.friendship_status as enum (
    'pending',
    'accepted',
    'blocked'
  );
exception
  when duplicate_object then null;
end $$;

-- ─────────────────────────────────────────────────────────────────────────────
-- 2. Table friendships
-- ─────────────────────────────────────────────────────────────────────────────
create table if not exists public.friendships (
  id uuid primary key default uuid_generate_v4(),
  requester_id uuid not null references public.profiles(id) on delete cascade,
  addressee_id uuid not null references public.profiles(id) on delete cascade,
  status public.friendship_status not null default 'pending',
  -- Si status = blocked, qui a bloqué (seul lui peut unblock).
  blocked_by uuid references public.profiles(id) on delete cascade,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint friendships_distinct_users
    check (requester_id <> addressee_id),
  constraint friendships_blocked_by_required
    check (
      (status = 'blocked' and blocked_by is not null)
      or (status <> 'blocked' and blocked_by is null)
    ),
  constraint friendships_blocked_by_in_pair
    check (
      blocked_by is null
      or blocked_by = requester_id
      or blocked_by = addressee_id
    )
);

-- Unicité de la paire indépendamment de l'ordre requester/addressee.
create unique index if not exists uq_friendships_pair
  on public.friendships (
    least(requester_id, addressee_id),
    greatest(requester_id, addressee_id)
  );

-- Index pour la lookup "demandes entrantes" (badge count) et listes amis.
create index if not exists idx_friendships_addressee_status
  on public.friendships (addressee_id, status);

create index if not exists idx_friendships_requester_status
  on public.friendships (requester_id, status);

create trigger trg_friendships_updated_at
  before update on public.friendships
  for each row execute function public.set_updated_at();

comment on table public.friendships is
  'Phase 13 — Liens d''amitié entre joueurs (pending/accepted/blocked). 1 row par paire.';

-- ─────────────────────────────────────────────────────────────────────────────
-- 3. RLS — SELECT pour les membres de la paire + admins. Aucun write direct.
-- ─────────────────────────────────────────────────────────────────────────────
alter table public.friendships enable row level security;

create policy "friendships_self_select"
  on public.friendships for select
  to authenticated
  using (
    auth.uid() = requester_id or auth.uid() = addressee_id
  );

create policy "friendships_admin_all"
  on public.friendships for all
  to authenticated
  using ((select public.is_admin()))
  with check ((select public.is_admin()));

-- Pas de policy INSERT/UPDATE/DELETE pour authenticated → seuls les RPCs
-- security definer ci-dessous peuvent muter la table.

-- ─────────────────────────────────────────────────────────────────────────────
-- 4. Helper : is_blocked_pair(a, b) — utilisé par les autres policies (chat).
-- ─────────────────────────────────────────────────────────────────────────────
create or replace function public.is_blocked_pair(p_user_a uuid, p_user_b uuid)
returns boolean
language sql
security definer
set search_path = public
stable
as $$
  select exists (
    select 1
    from public.friendships
    where status = 'blocked'
      and (
        (requester_id = p_user_a and addressee_id = p_user_b)
        or (requester_id = p_user_b and addressee_id = p_user_a)
      )
  );
$$;

revoke all on function public.is_blocked_pair(uuid, uuid) from public, anon;
grant execute on function public.is_blocked_pair(uuid, uuid) to authenticated;

comment on function public.is_blocked_pair(uuid, uuid) is
  'True si l''un des deux joueurs a bloqué l''autre. Utilisé par les RLS chat.';

-- ─────────────────────────────────────────────────────────────────────────────
-- 5. RPC : send_friend_request(target) → uuid friendship_id
-- ─────────────────────────────────────────────────────────────────────────────
create or replace function public.send_friend_request(p_target uuid)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_me uuid := auth.uid();
  v_friendship_id uuid;
  v_existing record;
begin
  if v_me is null then
    raise exception 'not_authenticated';
  end if;
  if p_target is null or p_target = v_me then
    raise exception 'invalid_target';
  end if;

  -- Cible doit exister et ne pas être supprimée.
  if not exists (
    select 1 from public.profiles
    where id = p_target
      and deleted_at is null
      and is_active = true
  ) then
    raise exception 'target_not_found';
  end if;

  -- Cherche une amitié existante dans la paire.
  select id, status, requester_id, addressee_id, blocked_by
    into v_existing
    from public.friendships
   where least(requester_id, addressee_id)    = least(v_me, p_target)
     and greatest(requester_id, addressee_id) = greatest(v_me, p_target);

  if v_existing.id is not null then
    -- Déjà accepted ou pending → no-op idempotent.
    if v_existing.status in ('accepted', 'pending') then
      return v_existing.id;
    end if;
    -- Bloqué → refuse même si tu n'es pas le bloqueur (info-leak prevention).
    if v_existing.status = 'blocked' then
      raise exception 'blocked_pair';
    end if;
  end if;

  insert into public.friendships (requester_id, addressee_id, status)
       values (v_me, p_target, 'pending')
    returning id into v_friendship_id;

  return v_friendship_id;
end;
$$;

revoke all on function public.send_friend_request(uuid) from public, anon;
grant execute on function public.send_friend_request(uuid) to authenticated;

-- ─────────────────────────────────────────────────────────────────────────────
-- 6. RPC : accept_friend_request(friendship_id)
-- ─────────────────────────────────────────────────────────────────────────────
create or replace function public.accept_friend_request(p_friendship_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_me uuid := auth.uid();
  v_addressee uuid;
  v_status public.friendship_status;
begin
  if v_me is null then
    raise exception 'not_authenticated';
  end if;

  select addressee_id, status
    into v_addressee, v_status
    from public.friendships
   where id = p_friendship_id;

  if v_addressee is null then
    raise exception 'not_found';
  end if;
  if v_addressee <> v_me then
    raise exception 'not_addressee';
  end if;
  if v_status <> 'pending' then
    raise exception 'invalid_status';
  end if;

  update public.friendships
     set status = 'accepted'
   where id = p_friendship_id;
end;
$$;

revoke all on function public.accept_friend_request(uuid) from public, anon;
grant execute on function public.accept_friend_request(uuid) to authenticated;

-- ─────────────────────────────────────────────────────────────────────────────
-- 7. RPC : decline_friend_request(friendship_id) — supprime la row pending.
-- ─────────────────────────────────────────────────────────────────────────────
create or replace function public.decline_friend_request(p_friendship_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_me uuid := auth.uid();
  v_requester uuid;
  v_addressee uuid;
  v_status public.friendship_status;
begin
  if v_me is null then
    raise exception 'not_authenticated';
  end if;

  select requester_id, addressee_id, status
    into v_requester, v_addressee, v_status
    from public.friendships
   where id = p_friendship_id;

  if v_requester is null then
    raise exception 'not_found';
  end if;
  -- L'addressee peut refuser ; le requester peut aussi annuler son envoi.
  if v_me not in (v_requester, v_addressee) then
    raise exception 'forbidden';
  end if;
  if v_status <> 'pending' then
    raise exception 'invalid_status';
  end if;

  delete from public.friendships where id = p_friendship_id;
end;
$$;

revoke all on function public.decline_friend_request(uuid) from public, anon;
grant execute on function public.decline_friend_request(uuid) to authenticated;

-- ─────────────────────────────────────────────────────────────────────────────
-- 8. RPC : remove_friend(target) — supprime l'amitié accepted entre nous.
-- ─────────────────────────────────────────────────────────────────────────────
create or replace function public.remove_friend(p_target uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_me uuid := auth.uid();
begin
  if v_me is null then
    raise exception 'not_authenticated';
  end if;
  if p_target is null or p_target = v_me then
    raise exception 'invalid_target';
  end if;

  delete from public.friendships
   where status = 'accepted'
     and least(requester_id, addressee_id)    = least(v_me, p_target)
     and greatest(requester_id, addressee_id) = greatest(v_me, p_target);
end;
$$;

revoke all on function public.remove_friend(uuid) from public, anon;
grant execute on function public.remove_friend(uuid) to authenticated;

-- ─────────────────────────────────────────────────────────────────────────────
-- 9. RPC : block_user(target) — bloque, indépendamment de l'état existant.
--    Si pas de row → crée. Sinon UPDATE status=blocked, blocked_by=me.
-- ─────────────────────────────────────────────────────────────────────────────
create or replace function public.block_user(p_target uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_me uuid := auth.uid();
  v_existing_id uuid;
begin
  if v_me is null then
    raise exception 'not_authenticated';
  end if;
  if p_target is null or p_target = v_me then
    raise exception 'invalid_target';
  end if;

  if not exists (
    select 1 from public.profiles
    where id = p_target and deleted_at is null
  ) then
    raise exception 'target_not_found';
  end if;

  select id into v_existing_id
    from public.friendships
   where least(requester_id, addressee_id)    = least(v_me, p_target)
     and greatest(requester_id, addressee_id) = greatest(v_me, p_target);

  if v_existing_id is null then
    insert into public.friendships (requester_id, addressee_id, status, blocked_by)
         values (v_me, p_target, 'blocked', v_me);
  else
    update public.friendships
       set status = 'blocked',
           blocked_by = v_me
     where id = v_existing_id;
  end if;
end;
$$;

revoke all on function public.block_user(uuid) from public, anon;
grant execute on function public.block_user(uuid) to authenticated;

-- ─────────────────────────────────────────────────────────────────────────────
-- 10. RPC : unblock_user(target) — seul le bloqueur peut débloquer.
--     Supprime la row (retour à "pas d'amitié").
-- ─────────────────────────────────────────────────────────────────────────────
create or replace function public.unblock_user(p_target uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_me uuid := auth.uid();
  v_existing_id uuid;
  v_blocked_by uuid;
begin
  if v_me is null then
    raise exception 'not_authenticated';
  end if;
  if p_target is null or p_target = v_me then
    raise exception 'invalid_target';
  end if;

  select id, blocked_by
    into v_existing_id, v_blocked_by
    from public.friendships
   where status = 'blocked'
     and least(requester_id, addressee_id)    = least(v_me, p_target)
     and greatest(requester_id, addressee_id) = greatest(v_me, p_target);

  if v_existing_id is null then
    -- Idempotent : pas d'erreur si rien à débloquer.
    return;
  end if;
  if v_blocked_by <> v_me then
    raise exception 'not_blocker';
  end if;

  delete from public.friendships where id = v_existing_id;
end;
$$;

revoke all on function public.unblock_user(uuid) from public, anon;
grant execute on function public.unblock_user(uuid) to authenticated;

-- ─────────────────────────────────────────────────────────────────────────────
-- 11. RPC : friend_pending_count() — utilisé par le badge dans le tab profil.
-- ─────────────────────────────────────────────────────────────────────────────
create or replace function public.friend_pending_count()
returns int
language sql
security definer
set search_path = public
stable
as $$
  select count(*)::int
    from public.friendships
   where addressee_id = auth.uid()
     and status = 'pending';
$$;

revoke all on function public.friend_pending_count() from public, anon;
grant execute on function public.friend_pending_count() to authenticated;

-- ─────────────────────────────────────────────────────────────────────────────
-- 12. Chat : ajouter une policy RESTRICTIVE qui bloque les INSERT entre paire
--     bloquée. Restrictive = ANDed avec les policies permissives existantes.
-- ─────────────────────────────────────────────────────────────────────────────
drop policy if exists "chat_messages_no_blocked_pair" on public.chat_messages;

create policy "chat_messages_no_blocked_pair"
  on public.chat_messages
  as restrictive
  for insert
  to authenticated
  with check (
    not exists (
      select 1
      from public.chat_channels cc
      join public.matches m on m.id = cc.match_id
      where cc.id = chat_messages.channel_id
        and cc.type = 'match'
        and (
          public.is_blocked_pair(
            auth.uid(),
            case
              when m.player1_id = auth.uid() then m.player2_id
              else m.player1_id
            end
          )
        )
    )
  );

comment on policy "chat_messages_no_blocked_pair" on public.chat_messages is
  'Phase 13 — Empêche d''envoyer un message dans un chat 1v1 match dont l''un des deux joueurs a bloqué l''autre.';

-- ─────────────────────────────────────────────────────────────────────────────
-- 13. Realtime : la table friendships doit pousser updates pour rafraîchir
--     le badge "demandes pending" et la liste amis en temps réel.
-- ─────────────────────────────────────────────────────────────────────────────
do $$
begin
  alter publication supabase_realtime add table public.friendships;
exception when duplicate_object then null;
end $$;
