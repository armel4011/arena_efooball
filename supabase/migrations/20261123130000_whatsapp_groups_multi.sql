-- ════════════════════════════════════════════════════════════════════
-- Groupe WhatsApp obligatoire — PLUSIEURS groupes (5 max) + bascule auto
-- ════════════════════════════════════════════════════════════════════
-- Remplace le groupe unique (20261123120000) : le super-admin renseigne
-- jusqu'à 5 groupes (emplacements 1..5, ex. « Arena_Game 001 », « 002 »…).
-- Un nouveau joueur reçoit le lien du PREMIER groupe (par emplacement) qui
-- n'a pas atteint sa capacité (1020 par défaut, sous le plafond WhatsApp de
-- 1024 → marge pour les validations simultanées).
--
-- ⚠️ WhatsApp n'expose AUCUNE API de comptage des membres : la capacité est
-- comptée sur les joueurs ARENA ayant VALIDÉ chaque groupe
-- (profiles.whatsapp_group_position). C'est une estimation de remplissage.
--
-- Validation : le nom saisi est accepté s'il correspond à N'IMPORTE LEQUEL
-- des groupes configurés ; on enregistre lequel (alimente le compteur).
-- Tous les groupes pleins → l'étape ne bloque personne (l'écran admin
-- l'indique pour qu'un groupe soit ajouté).
-- ════════════════════════════════════════════════════════════════════

-- ─── 1. Table des groupes (NON lisible par les joueurs) ──────────────
create table if not exists public.whatsapp_groups (
  position    smallint primary key check (position between 1 and 5),
  invite_url  text not null
              check (invite_url ~* '^https://(chat\.whatsapp\.com|wa\.me)/\S+$'),
  group_name  text not null check (btrim(group_name) <> ''),
  capacity    integer not null default 1020 check (capacity > 0),
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

create index if not exists idx_whatsapp_groups_updated_by
  on public.whatsapp_groups(updated_by) where updated_by is not null;

-- Reprise de l'éventuel groupe unique (vide en prod au moment de l'écriture).
insert into public.whatsapp_groups (position, invite_url, group_name, updated_by)
select 1, btrim(c.invite_url), btrim(c.group_name), c.updated_by
  from public.whatsapp_group_config c
 where c.id = 1
   and coalesce(btrim(c.invite_url), '') <> ''
   and coalesce(btrim(c.group_name), '') <> ''
on conflict (position) do nothing;

-- ─── 2. Groupe rejoint par chaque joueur (alimente le compteur) ──────
alter table public.profiles
  add column if not exists whatsapp_group_position smallint
  references public.whatsapp_groups(position) on delete set null;

comment on column public.profiles.whatsapp_group_position is
  'Emplacement du groupe WhatsApp validé (posé UNIQUEMENT par confirm_whatsapp_group).';

create index if not exists idx_profiles_whatsapp_group_position
  on public.profiles(whatsapp_group_position)
  where whatsapp_group_position is not null;

-- ─── 3. Ancien modèle « groupe unique » retiré ───────────────────────
drop function if exists public.set_whatsapp_group_config(text, text);
drop table if exists public.whatsapp_group_config;

-- ─── 4. Statut du joueur courant (jamais aucun nom de groupe) ────────
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
             where m.whatsapp_group_position = g.position) < g.capacity
     order by g.position
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

-- ─── 5. Validation : nom de n'importe lequel des groupes ─────────────
create or replace function public.confirm_whatsapp_group(p_group_name text)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
declare
  v_uid   uuid := (select auth.uid());
  v_given text;
  v_pos   smallint;
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

  select g.position into v_pos
    from public.whatsapp_groups g
   where public._normalize_group_name(g.group_name) = v_given
   order by g.position
   limit 1;
  if v_pos is null then
    return false;
  end if;

  update public.profiles
     set whatsapp_group_joined_at = coalesce(whatsapp_group_joined_at, now()),
         whatsapp_group_position  = coalesce(whatsapp_group_position, v_pos)
   where id = v_uid;
  return true;
end;
$$;

revoke all on function public.confirm_whatsapp_group(text) from public, anon;
grant execute on function public.confirm_whatsapp_group(text) to authenticated;

-- ─── 6. Lecture super-admin (avec remplissage) ───────────────────────
create or replace function public.admin_list_whatsapp_groups()
returns table (
  "position"  smallint,
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
    select wg.position, wg.invite_url, wg.group_name, wg.capacity,
           (select count(*) from public.profiles m
             where m.whatsapp_group_position = wg.position) as members
      from public.whatsapp_groups wg
  ),
  cur as (
    select g.position from g where g.members < g.capacity
     order by g.position limit 1
  )
  select g.position, g.invite_url, g.group_name, g.capacity, g.members,
         (g.position = (select cur.position from cur)) as is_current
    from g
   order by g.position;
end;
$$;

revoke all on function public.admin_list_whatsapp_groups() from public, anon;
grant execute on function public.admin_list_whatsapp_groups() to authenticated;

-- ─── 7. Réglage super-admin : 5 emplacements d'un coup ───────────────
-- p_groups = tableau JSON de 5 objets max {invite_url, group_name}, dans
-- l'ordre des emplacements. Lien ET nom vides = emplacement libéré (ses
-- validations sont détachées → compteur remis à zéro). Modifier le seul lien
-- d'un emplacement conserve son compteur.
create or replace function public.set_whatsapp_groups(p_groups jsonb)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_len   integer;
  v_i     integer;
  v_item  jsonb;
  v_url   text;
  v_name  text;
  v_norms text[] := '{}';
  v_norm  text;
begin
  if not public.is_super_admin() then
    raise exception 'Réservé au super-admin' using errcode = '42501';
  end if;
  if p_groups is null or jsonb_typeof(p_groups) <> 'array' then
    raise exception 'Format invalide (tableau attendu)' using errcode = '22023';
  end if;
  v_len := jsonb_array_length(p_groups);
  if v_len > 5 then
    raise exception '5 groupes maximum' using errcode = '22023';
  end if;

  -- 1re passe : validation complète AVANT toute écriture.
  for v_i in 1..v_len loop
    v_item := p_groups -> (v_i - 1);
    v_url  := nullif(btrim(coalesce(v_item ->> 'invite_url', '')), '');
    v_name := nullif(btrim(coalesce(v_item ->> 'group_name', '')), '');
    if (v_url is null) <> (v_name is null) then
      raise exception 'Groupe % : renseigne le lien ET le nom (ou vide les deux)', v_i
        using errcode = '22023';
    end if;
    if v_url is null then
      continue;
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

  -- 2e passe : écriture emplacement par emplacement (1..5).
  for v_i in 1..5 loop
    if v_i <= v_len then
      v_item := p_groups -> (v_i - 1);
      v_url  := nullif(btrim(coalesce(v_item ->> 'invite_url', '')), '');
      v_name := nullif(btrim(coalesce(v_item ->> 'group_name', '')), '');
    else
      v_url := null;
      v_name := null;
    end if;

    if v_url is null then
      delete from public.whatsapp_groups where position = v_i;
    else
      insert into public.whatsapp_groups (position, invite_url, group_name, updated_by)
      values (v_i, v_url, v_name, (select auth.uid()))
      on conflict (position) do update
        set invite_url = excluded.invite_url,
            group_name = excluded.group_name,
            updated_at = now(),
            updated_by = excluded.updated_by;
    end if;
  end loop;
end;
$$;

revoke all on function public.set_whatsapp_groups(jsonb) from public, anon;
grant execute on function public.set_whatsapp_groups(jsonb) to authenticated;

-- ─── 8. Le joueur ne peut pas choisir/cocher son groupe lui-même ─────
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
         or new.whatsapp_group_position  is distinct from old.whatsapp_group_position
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
    new.whatsapp_group_position  := null;
  end if;
  return new;
end;
$$;
