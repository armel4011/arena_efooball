-- ════════════════════════════════════════════════════════════════════
-- Photos d'avatar : colonne profiles.avatar_url + bucket Storage `avatars`
-- ════════════════════════════════════════════════════════════════════
-- ✅ APPLIQUÉE EN PROD le 2026-06-17 via MCP (version remote 20260617131921).
-- Fichier recréé dans le repo a posteriori pour la reproductibilité (le DDL
-- avait été appliqué directement en prod sans fichier local). Idempotent.
--
-- Convention de chemin : `<uid>/avatar_<ts>.<ext>` — le 1er segment = uid
-- impose la RLS owner-only (storage.foldername(name)[1] = auth.uid()). Bucket
-- PUBLIC (lecture CDN libre) → pas de policy SELECT ; getPublicUrl côté client.

-- 1. Colonne avatar_url (NULL → repli cercle coloré + initiale via avatar_color)
alter table public.profiles
  add column if not exists avatar_url text;

comment on column public.profiles.avatar_url is
  'URL publique de la photo d''avatar (bucket Storage `avatars`). '
  'NULL → repli cercle dégradé + initiale via avatar_color.';

-- 2. Bucket public `avatars` (5 Mo, images uniquement)
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'avatars',
  'avatars',
  true,
  5242880,
  array['image/jpeg','image/png','image/webp']
)
on conflict (id) do nothing;

-- 3. RLS owner-only sur les écritures. Path : <uid>/... → folder[1] = uid.
--    Lecture publique assurée par bucket.public = true (aucune policy SELECT).
drop policy if exists avatars_insert_own on storage.objects;
create policy avatars_insert_own on storage.objects
for insert to authenticated
with check (
  bucket_id = 'avatars'
  and (storage.foldername(name))[1] = (select auth.uid())::text
);

drop policy if exists avatars_update_own on storage.objects;
create policy avatars_update_own on storage.objects
for update to authenticated
using (
  bucket_id = 'avatars'
  and (storage.foldername(name))[1] = (select auth.uid())::text
)
with check (
  bucket_id = 'avatars'
  and (storage.foldername(name))[1] = (select auth.uid())::text
);

drop policy if exists avatars_delete_own on storage.objects;
create policy avatars_delete_own on storage.objects
for delete to authenticated
using (
  bucket_id = 'avatars'
  and (storage.foldername(name))[1] = (select auth.uid())::text
);
