-- ════════════════════════════════════════════════════════════════════
-- ARENA — Config de release pour la MAJ in-app (hors Play Store)
-- ════════════════════════════════════════════════════════════════════
-- L'app (distribuée en APK direct depuis arena237.com) lit cette table au
-- démarrage, compare la dernière version publiée à sa version installée
-- (package_info, comparaison sémantique du nom de version) et propose une
-- mise à jour. Édité par un super-admin via /super/app-update.
-- ════════════════════════════════════════════════════════════════════

create table if not exists public.app_release_config (
  id uuid primary key default gen_random_uuid(),
  platform text not null default 'android' check (platform in ('android')),
  latest_version text not null,                 -- nom semver, ex "1.0.9"
  latest_build int not null default 0,          -- informatif (versionCode)
  min_supported_version text,                   -- pour un futur force-update
  apk_url text not null,                         -- URL de l'APK universel
  changelog text,                               -- notes de version
  mandatory boolean not null default false,     -- bloquant si true (V1 = false)
  is_active boolean not null default true,
  updated_at timestamptz not null default now(),
  updated_by uuid references public.profiles on delete set null
);

comment on table public.app_release_config is
  'Config de release lue par l''app pour proposer une MAJ in-app (distribution APK directe).';

-- Une seule config active par plateforme.
create unique index if not exists app_release_config_active_platform_uniq
  on public.app_release_config (platform) where is_active;

alter table public.app_release_config enable row level security;

-- Lecture par tous (info publique ; l'app doit pouvoir vérifier tôt).
drop policy if exists app_release_config_select on public.app_release_config;
create policy app_release_config_select on public.app_release_config
  for select using (true);

-- Écriture réservée aux admins (l'UI est gatée super-admin).
drop policy if exists app_release_config_write_admin on public.app_release_config;
create policy app_release_config_write_admin on public.app_release_config
  for all to public
  using ((select public.is_admin()))
  with check ((select public.is_admin()));

drop trigger if exists trg_app_release_config_updated_at on public.app_release_config;
create trigger trg_app_release_config_updated_at
  before update on public.app_release_config
  for each row execute function public.set_updated_at();

-- Seed : version courante 1.0.9.
insert into public.app_release_config
  (platform, latest_version, latest_build, apk_url, changelog, is_active)
values (
  'android', '1.0.9', 10,
  'https://arena237.com/downloads/arena-android-universel.apk',
  'Nouveau fil de support « Contact / Aide », page À propos mise à jour, et améliorations diverses.',
  true
)
on conflict do nothing;
