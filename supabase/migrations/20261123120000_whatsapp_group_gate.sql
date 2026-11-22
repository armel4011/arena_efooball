-- ════════════════════════════════════════════════════════════════════
-- Étape obligatoire « Rejoindre le groupe WhatsApp » (tous les utilisateurs)
-- ════════════════════════════════════════════════════════════════════
-- Le super-admin configure UN groupe (lien d'invitation + nom exact). Tant
-- qu'un joueur n'a pas validé, l'app user l'arrête sur un dialogue bloquant :
-- il rejoint le groupe puis saisit son nom. La comparaison est faite CÔTÉ
-- SERVEUR (le nom attendu n'est jamais exposé au client, sinon on pourrait le
-- lire sans rejoindre). Tant qu'aucun groupe n'est configuré, l'étape est
-- inactive (personne n'est bloqué).
-- ════════════════════════════════════════════════════════════════════

-- ─── 1. Validation par joueur ────────────────────────────────────────
alter table public.profiles
  add column if not exists whatsapp_group_joined_at timestamptz;

comment on column public.profiles.whatsapp_group_joined_at is
  'Horodatage de validation de l''étape « groupe WhatsApp » (posé UNIQUEMENT par confirm_whatsapp_group).';

-- ─── 2. Config du groupe (ligne unique, NON lisible par les joueurs) ──
create table if not exists public.whatsapp_group_config (
  id          smallint primary key default 1 check (id = 1),
  invite_url  text,
  group_name  text,
  updated_at  timestamptz not null default now(),
  updated_by  uuid references public.profiles(id) on delete set null
);

alter table public.whatsapp_group_config enable row level security;

-- Seul le super-admin lit la config (écran de réglage). AUCUNE policy pour les
-- joueurs : le nom attendu reste secret. Écriture uniquement via la RPC.
drop policy if exists whatsapp_group_config_select_super on public.whatsapp_group_config;
create policy whatsapp_group_config_select_super
  on public.whatsapp_group_config for select to authenticated
  using ((select public.is_super_admin()));

revoke all on public.whatsapp_group_config from anon;
revoke insert, update, delete, truncate on public.whatsapp_group_config from authenticated;
grant select on public.whatsapp_group_config to authenticated;

insert into public.whatsapp_group_config (id) values (1) on conflict (id) do nothing;

create index if not exists idx_whatsapp_group_config_updated_by
  on public.whatsapp_group_config(updated_by) where updated_by is not null;

-- ─── 3. Normalisation des noms ────────────────────────────────────────
-- Minuscules, accents retirés, puis on ne garde que [a-z0-9] : espaces,
-- emojis et ponctuation sont ignorés (« Arena Communauté 🏆 » = « arena
-- communaute »). 42 caractères accentués ↔ 42 lettres de base.
create or replace function public._normalize_group_name(p text)
returns text
language sql
immutable
set search_path = public
as $$
  select regexp_replace(
    translate(
      lower(coalesce(p, '')),
      'àáâãäåāçćčèéêëēėęìíîïīįñńòóôõöøōùúûüūÿýžźż',
      'aaaaaaaccceeeeeeeiiiiiinnooooooouuuuuyyzzz'
    ),
    '[^a-z0-9]', '', 'g'
  );
$$;

revoke all on function public._normalize_group_name(text) from public, anon, authenticated;

-- ─── 4. Statut du joueur courant (sans jamais renvoyer le nom attendu) ─
create or replace function public.my_whatsapp_group_status()
returns table (required boolean, joined boolean, invite_url text)
language sql
stable
security definer
set search_path = public
as $$
  select
    (coalesce(btrim(c.invite_url), '') <> '' and coalesce(btrim(c.group_name), '') <> '') as required,
    (p.whatsapp_group_joined_at is not null) as joined,
    c.invite_url
  from public.profiles p
  left join public.whatsapp_group_config c on c.id = 1
  where p.id = (select auth.uid());
$$;

revoke all on function public.my_whatsapp_group_status() from public, anon;
grant execute on function public.my_whatsapp_group_status() to authenticated;

-- ─── 5. Validation : le joueur saisit le nom du groupe ────────────────
-- Renvoie true si le nom correspond (ou si aucun groupe n'est configuré),
-- false sinon. Idempotent : une validation déjà posée est conservée.
create or replace function public.confirm_whatsapp_group(p_group_name text)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
declare
  v_uid      uuid := (select auth.uid());
  v_expected text;
  v_given    text;
begin
  if v_uid is null then
    raise exception 'Non authentifié' using errcode = '42501';
  end if;

  select group_name into v_expected from public.whatsapp_group_config where id = 1;
  if coalesce(btrim(v_expected), '') = '' then
    return true;  -- aucun groupe configuré : étape inactive
  end if;

  v_given := public._normalize_group_name(p_group_name);
  if v_given = '' or v_given <> public._normalize_group_name(v_expected) then
    return false;
  end if;

  update public.profiles
     set whatsapp_group_joined_at = coalesce(whatsapp_group_joined_at, now())
   where id = v_uid;
  return true;
end;
$$;

revoke all on function public.confirm_whatsapp_group(text) from public, anon;
grant execute on function public.confirm_whatsapp_group(text) to authenticated;

-- ─── 6. Réglage par le super-admin ────────────────────────────────────
-- Les deux champs renseignés = étape active ; les deux vides = désactivée.
create or replace function public.set_whatsapp_group_config(
  p_invite_url text,
  p_group_name text
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_url  text := nullif(btrim(coalesce(p_invite_url, '')), '');
  v_name text := nullif(btrim(coalesce(p_group_name, '')), '');
begin
  if not public.is_super_admin() then
    raise exception 'Réservé au super-admin' using errcode = '42501';
  end if;
  if (v_url is null) <> (v_name is null) then
    raise exception 'Renseigne le lien ET le nom du groupe (ou vide les deux pour désactiver)'
      using errcode = '22023';
  end if;
  if v_url is not null and v_url !~* '^https://(chat\.whatsapp\.com|wa\.me)/\S+$' then
    raise exception 'Lien d''invitation WhatsApp invalide (attendu : https://chat.whatsapp.com/…)'
      using errcode = '22023';
  end if;
  if v_name is not null and public._normalize_group_name(v_name) = '' then
    raise exception 'Nom de groupe invalide : il doit contenir au moins une lettre ou un chiffre'
      using errcode = '22023';
  end if;

  update public.whatsapp_group_config
     set invite_url = v_url,
         group_name = v_name,
         updated_at = now(),
         updated_by = (select auth.uid())
   where id = 1;
end;
$$;

revoke all on function public.set_whatsapp_group_config(text, text) from public, anon;
grant execute on function public.set_whatsapp_group_config(text, text) to authenticated;

-- ─── 7. Le joueur ne peut PAS cocher l'étape lui-même ─────────────────
-- 7a. UPDATE : `whatsapp_group_joined_at` rejoint le tier ADMIN du garde
--     existant (corps repris à l'identique + 1 colonne). Les RPC SECURITY
--     DEFINER tournent sous le propriétaire → non concernées.
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
      then
        raise exception 'Modification interdite : colonnes protegees (is_active, permanent_ban, stats, kyc, totp, groupe WhatsApp) reservees au service ou aux admins'
          using errcode = '42501';
      end if;
    end if;
  end if;
  return new;
end;
$function$;

-- 7b. INSERT : le garde existant est BEFORE UPDATE uniquement → à
--     l'inscription (INSERT client du profil), on neutralise la colonne.
create or replace function public.guard_profiles_insert_whatsapp()
returns trigger
language plpgsql
set search_path to 'public', 'pg_temp'
as $$
begin
  if current_user in ('authenticated', 'anon') then
    new.whatsapp_group_joined_at := null;
  end if;
  return new;
end;
$$;

revoke all on function public.guard_profiles_insert_whatsapp() from public, anon, authenticated;

drop trigger if exists trg_guard_profiles_insert_whatsapp on public.profiles;
create trigger trg_guard_profiles_insert_whatsapp
  before insert on public.profiles
  for each row execute function public.guard_profiles_insert_whatsapp();
