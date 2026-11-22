-- ════════════════════════════════════════════════════════════════════
-- Groupes WhatsApp obligatoires — nombre ILLIMITÉ, identifiant stable
-- ════════════════════════════════════════════════════════════════════
-- Remplace les 5 emplacements fixes (20261123130000) : le super-admin ajoute
-- autant de groupes qu'il veut (« Nouveau groupe »), les retire ou les
-- réordonne. Chaque groupe a un IDENTIFIANT STABLE : son compteur de
-- validations le suit (supprimer/réordonner les autres ne le décale pas).
--
-- Inchangé : lien proposé = 1er groupe (ordre `sort_order`) sous sa capacité
-- (1020) ; nom de n'importe quel groupe accepté ; remplissage = joueurs ARENA
-- ayant validé (WhatsApp n'expose aucune API de comptage) ; tous pleins →
-- personne n'est bloqué.
--
-- Données : table vide et aucune validation en prod au moment de
-- l'écriture → restructuration sans reprise.
-- ════════════════════════════════════════════════════════════════════

-- ─── 1. Restructuration (position fixe → id + ordre) ─────────────────
alter table public.profiles drop column if exists whatsapp_group_position;
drop table if exists public.whatsapp_groups;

create table public.whatsapp_groups (
  id          bigint generated always as identity primary key,
  sort_order  integer not null,
  invite_url  text not null
              check (invite_url ~* '^https://(chat\.whatsapp\.com|wa\.me)/\S+$'),
  group_name  text not null check (btrim(group_name) <> ''),
  capacity    integer not null default 1020 check (capacity > 0),
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now(),
  updated_by  uuid references public.profiles(id) on delete set null
);

alter table public.whatsapp_groups enable row level security;

drop policy if exists whatsapp_groups_select_super on public.whatsapp_groups;
create policy whatsapp_groups_select_super
  on public.whatsapp_groups for select to authenticated
  using ((select public.is_super_admin()));

revoke all on public.whatsapp_groups from anon;
revoke insert, update, delete, truncate on public.whatsapp_groups from authenticated;
grant select on public.whatsapp_groups to authenticated;

create index if not exists idx_whatsapp_groups_order
  on public.whatsapp_groups(sort_order, id);
create index if not exists idx_whatsapp_groups_updated_by
  on public.whatsapp_groups(updated_by) where updated_by is not null;

-- Groupe validé par chaque joueur (alimente le compteur du groupe).
alter table public.profiles
  add column whatsapp_group_id bigint
  references public.whatsapp_groups(id) on delete set null;

comment on column public.profiles.whatsapp_group_id is
  'Groupe WhatsApp validé (posé UNIQUEMENT par confirm_whatsapp_group).';

create index if not exists idx_profiles_whatsapp_group_id
  on public.profiles(whatsapp_group_id)
  where whatsapp_group_id is not null;

-- ─── 2. Statut du joueur courant (jamais aucun nom de groupe) ────────
create or replace function public.my_whatsapp_group_status()
returns table (required boolean, joined boolean, invite_url text)
language sql
stable
security definer
set search_path = public
as $$
  with current_group as (
    select g.invite_url
      from public.whatsapp_groups g
     where (select count(*) from public.profiles m
             where m.whatsapp_group_id = g.id) < g.capacity
     order by g.sort_order, g.id
     limit 1
  )
  select
    exists (select 1 from current_group) as required,
    (p.whatsapp_group_joined_at is not null) as joined,
    (select cg.invite_url from current_group cg) as invite_url
  from public.profiles p
  where p.id = (select auth.uid());
$$;

revoke all on function public.my_whatsapp_group_status() from public, anon;
grant execute on function public.my_whatsapp_group_status() to authenticated;

-- ─── 3. Validation : nom de n'importe lequel des groupes ─────────────
create or replace function public.confirm_whatsapp_group(p_group_name text)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
declare
  v_uid   uuid := (select auth.uid());
  v_given text;
  v_id    bigint;
begin
  if v_uid is null then
    raise exception 'Non authentifié' using errcode = '42501';
  end if;

  if not exists (select 1 from public.whatsapp_groups) then
    return true;  -- aucun groupe configuré : étape inactive
  end if;

  v_given := public._normalize_group_name(p_group_name);
  if v_given = '' then
    return false;
  end if;

  select g.id into v_id
    from public.whatsapp_groups g
   where public._normalize_group_name(g.group_name) = v_given
   order by g.sort_order, g.id
   limit 1;
  if v_id is null then
    return false;
  end if;

  update public.profiles
     set whatsapp_group_joined_at = coalesce(whatsapp_group_joined_at, now()),
         whatsapp_group_id        = coalesce(whatsapp_group_id, v_id)
   where id = v_uid;
  return true;
end;
$$;

revoke all on function public.confirm_whatsapp_group(text) from public, anon;
grant execute on function public.confirm_whatsapp_group(text) to authenticated;

-- ─── 4. Lecture super-admin (ordre + remplissage + groupe en cours) ──
drop function if exists public.admin_list_whatsapp_groups();
create function public.admin_list_whatsapp_groups()
returns table (
  id          bigint,
  sort_order  integer,
  invite_url  text,
  group_name  text,
  capacity    integer,
  members     bigint,
  is_current  boolean
)
language plpgsql
stable
security definer
set search_path = public
as $$
#variable_conflict use_column
begin
  if not public.is_super_admin() then
    raise exception 'Réservé au super-admin' using errcode = '42501';
  end if;
  return query
  with g as (
    select wg.id, wg.sort_order, wg.invite_url, wg.group_name, wg.capacity,
           (select count(*) from public.profiles m
             where m.whatsapp_group_id = wg.id) as members
      from public.whatsapp_groups wg
  ),
  cur as (
    select g.id from g where g.members < g.capacity
     order by g.sort_order, g.id limit 1
  )
  select g.id, g.sort_order, g.invite_url, g.group_name, g.capacity, g.members,
         (g.id = (select cur.id from cur)) as is_current
    from g
   order by g.sort_order, g.id;
end;
$$;

revoke all on function public.admin_list_whatsapp_groups() from public, anon;
grant execute on function public.admin_list_whatsapp_groups() to authenticated;

-- ─── 5. Réglage super-admin : liste complète, dans l'ordre ───────────
-- p_groups = tableau JSON ordonné de {id?, invite_url, group_name}.
--   - avec `id` existant  → groupe mis à jour (son compteur est conservé) ;
--   - sans `id` (ou id inconnu) → nouveau groupe ;
--   - groupe existant ABSENT du tableau → supprimé (ses validations sont
--     détachées, les joueurs restent validés) ;
--   - entrée lien + nom vides → ignorée.
-- Tableau vide = étape désactivée.
drop function if exists public.set_whatsapp_groups(jsonb);
create function public.set_whatsapp_groups(p_groups jsonb)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_len   integer;
  v_i     integer;
  v_item  jsonb;
  v_id    bigint;
  v_url   text;
  v_name  text;
  v_norm  text;
  v_norms text[]   := '{}';
  v_keep  bigint[] := '{}';
  v_rank  integer  := 0;
begin
  if not public.is_super_admin() then
    raise exception 'Réservé au super-admin' using errcode = '42501';
  end if;
  if p_groups is null or jsonb_typeof(p_groups) <> 'array' then
    raise exception 'Format invalide (tableau attendu)' using errcode = '22023';
  end if;
  v_len := jsonb_array_length(p_groups);

  -- 1re passe : validation complète AVANT toute écriture.
  for v_i in 1..v_len loop
    v_item := p_groups -> (v_i - 1);
    v_url  := nullif(btrim(coalesce(v_item ->> 'invite_url', '')), '');
    v_name := nullif(btrim(coalesce(v_item ->> 'group_name', '')), '');
    if v_url is null and v_name is null then
      continue;
    end if;
    if (v_url is null) <> (v_name is null) then
      raise exception 'Groupe % : renseigne le lien ET le nom (ou vide les deux)', v_i
        using errcode = '22023';
    end if;
    if v_url !~* '^https://(chat\.whatsapp\.com|wa\.me)/\S+$' then
      raise exception 'Groupe % : lien d''invitation WhatsApp invalide (https://chat.whatsapp.com/…)', v_i
        using errcode = '22023';
    end if;
    v_norm := public._normalize_group_name(v_name);
    if v_norm = '' then
      raise exception 'Groupe % : le nom doit contenir au moins une lettre ou un chiffre', v_i
        using errcode = '22023';
    end if;
    if v_norm = any (v_norms) then
      raise exception 'Groupe % : ce nom est déjà utilisé par un autre groupe', v_i
        using errcode = '22023';
    end if;
    v_norms := v_norms || v_norm;
  end loop;

  -- Ids conservés = ceux fournis ET existants (les autres seront supprimés).
  for v_i in 1..v_len loop
    v_item := p_groups -> (v_i - 1);
    if nullif(btrim(coalesce(v_item ->> 'invite_url', '')), '') is null then
      continue;
    end if;
    v_id := nullif(v_item ->> 'id', '')::bigint;
    if v_id is not null
       and exists (select 1 from public.whatsapp_groups where id = v_id) then
      v_keep := v_keep || v_id;
    end if;
  end loop;

  delete from public.whatsapp_groups where not (id = any (v_keep));

  -- 2e passe : mise à jour / création dans l'ordre fourni.
  for v_i in 1..v_len loop
    v_item := p_groups -> (v_i - 1);
    v_url  := nullif(btrim(coalesce(v_item ->> 'invite_url', '')), '');
    v_name := nullif(btrim(coalesce(v_item ->> 'group_name', '')), '');
    if v_url is null then
      continue;
    end if;
    v_rank := v_rank + 1;
    v_id := nullif(v_item ->> 'id', '')::bigint;

    if v_id is not null and v_id = any (v_keep) then
      update public.whatsapp_groups
         set sort_order = v_rank,
             invite_url = v_url,
             group_name = v_name,
             updated_at = now(),
             updated_by = (select auth.uid())
       where id = v_id;
    else
      insert into public.whatsapp_groups (sort_order, invite_url, group_name, updated_by)
      values (v_rank, v_url, v_name, (select auth.uid()));
    end if;
  end loop;
end;
$$;

revoke all on function public.set_whatsapp_groups(jsonb) from public, anon;
grant execute on function public.set_whatsapp_groups(jsonb) to authenticated;

-- ─── 6. Le joueur ne peut pas cocher l'étape / choisir son groupe ────
create or replace function public.guard_profiles_protected_columns()
returns trigger
language plpgsql
set search_path to 'public', 'pg_temp'
as $function$
begin
  if current_user in ('authenticated', 'anon') then
    -- TIER PRIVILÈGE — réservé au SUPER-ADMIN (ferme l'auto-promotion).
    if not public.is_super_admin() then
      if new.role                   is distinct from old.role
         or new.admin_allowed_countries is distinct from old.admin_allowed_countries
         or new.admin_allowed_sections  is distinct from old.admin_allowed_sections
      then
        raise exception 'Modification interdite : role et scope admin (pays/sections) reserves au super-admin'
          using errcode = '42501';
      end if;
    end if;
    -- TIER ADMIN — réservé aux admins (comportement historique préservé).
    if not public.is_admin() then
      if new.is_active        is distinct from old.is_active
         or new.permanent_ban    is distinct from old.permanent_ban
         or new.stats            is distinct from old.stats
         or new.kyc_status       is distinct from old.kyc_status
         or new.kyc_verified_at  is distinct from old.kyc_verified_at
         or new.totp_secret      is distinct from old.totp_secret
         or new.totp_enabled     is distinct from old.totp_enabled
         or new.backup_codes     is distinct from old.backup_codes
         or new.whatsapp_group_joined_at is distinct from old.whatsapp_group_joined_at
         or new.whatsapp_group_id        is distinct from old.whatsapp_group_id
      then
        raise exception 'Modification interdite : colonnes protegees (is_active, permanent_ban, stats, kyc, totp, groupe WhatsApp) reservees au service ou aux admins'
          using errcode = '42501';
      end if;
    end if;
  end if;
  return new;
end;
$function$;

create or replace function public.guard_profiles_insert_whatsapp()
returns trigger
language plpgsql
set search_path to 'public', 'pg_temp'
as $$
begin
  if current_user in ('authenticated', 'anon') then
    new.whatsapp_group_joined_at := null;
    new.whatsapp_group_id        := null;
  end if;
  return new;
end;
$$;
