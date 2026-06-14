-- =============================================================================
-- ARENA — PHASE 8.1 — Match recordings storage bucket
-- =============================================================================
-- Creates the private `match-recordings` bucket used by:
--   1. Auto-recording uploads at end of match (PHASE 8.3, anti-cheat).
--   2. Manual uploads by players from their gallery (PHASE 8.3, dispute
--      evidence — kept always-on so we don't depend on Agora streaming
--      being enabled to gather proof).
--
-- Naming convention for objects inside the bucket:
--   {match_id}/{player_id}/{timestamp}.mp4
-- which makes the RLS policies trivial: the first path segment is the
-- match id, the second is the owner, so we can match `auth.uid()` against
-- the second segment to enforce per-player ownership without an extra
-- join.
-- =============================================================================

-- ─── Bucket ──────────────────────────────────────────────────────────────
-- 25 min @ 720p / 2 Mbps ≈ 375 MB. We cap at 500 MB to leave headroom
-- for slightly higher-quality recordings on better devices, while still
-- preventing accidental uploads of multi-GB files.
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'match-recordings',
  'match-recordings',
  false,
  524288000, -- 500 MB
  array['video/mp4', 'video/quicktime', 'video/webm']
)
on conflict (id) do update
  set public = excluded.public,
      file_size_limit = excluded.file_size_limit,
      allowed_mime_types = excluded.allowed_mime_types;

-- ─── RLS policies ────────────────────────────────────────────────────────
-- The bucket is private — only:
--   * the recording owner can read / write their own object,
--   * any admin / super-admin can read everything (for dispute review),
--   * no one can list bucket contents anonymously.
--
-- Path layout enforced by client: `{match_id}/{owner_uid}/{filename}`.

-- Owner can INSERT an object as long as the second path segment matches
-- their auth.uid() AND they are one of the two seated players of the
-- match referenced in the first segment.
create policy "match_recordings_owner_insert"
  on storage.objects for insert
  with check (
    bucket_id = 'match-recordings'
    and auth.uid()::text = (storage.foldername(name))[2]
    and exists (
      select 1
      from public.matches m
      where m.id::text = (storage.foldername(name))[1]
        and (auth.uid() = m.player1_id or auth.uid() = m.player2_id)
    )
  );

create policy "match_recordings_owner_select"
  on storage.objects for select
  using (
    bucket_id = 'match-recordings'
    and auth.uid()::text = (storage.foldername(name))[2]
  );

create policy "match_recordings_owner_update"
  on storage.objects for update
  using (
    bucket_id = 'match-recordings'
    and auth.uid()::text = (storage.foldername(name))[2]
  );

create policy "match_recordings_owner_delete"
  on storage.objects for delete
  using (
    bucket_id = 'match-recordings'
    and auth.uid()::text = (storage.foldername(name))[2]
  );

-- Admin / super-admin: read-only access to every recording for dispute
-- arbitration. Mirrors the convention used by other admin-grant policies
-- in `20260505100007_fix_profiles_rls_admin_grants.sql`.
create policy "match_recordings_admin_read"
  on storage.objects for select
  using (
    bucket_id = 'match-recordings'
    and exists (
      select 1
      from public.profiles p
      where p.id = auth.uid()
        and p.role in ('admin', 'super_admin')
    )
  );

-- `COMMENT ON POLICY ... ON storage.objects` requires ownership of the
-- `storage.objects` relation. The hosted project applies migrations as the
-- owner, but the local stack / CI (`supabase start`) runs as a less-privileged
-- role and raises `must be owner of relation objects` (SQLSTATE 42501), which
-- aborts the whole migration apply. The comments are purely documentary, so we
-- wrap them in a guarded block: applied where we own the table, gracefully
-- skipped (with a notice) where we don't.
do $$
begin
  comment on policy "match_recordings_owner_insert" on storage.objects is
    'PHASE 8.1 — Players may upload to their own match folder. Path: {match_id}/{owner_uid}/{file}.';
  comment on policy "match_recordings_admin_read" on storage.objects is
    'PHASE 8.1 — Admins read every recording during dispute review.';
exception
  when insufficient_privilege then
    raise notice 'Skipping COMMENT on storage.objects policies (not owner of storage.objects) — local/CI stack.';
end$$;
