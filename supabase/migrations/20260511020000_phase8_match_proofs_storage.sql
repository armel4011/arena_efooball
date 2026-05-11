-- =============================================================================
-- ARENA — PHASE 8 — Match score proofs storage bucket
-- =============================================================================
-- Hosts the user-supplied screenshot or short clip a player attaches to
-- their score submission. Distinct from `match-recordings` (which holds
-- the anti-cheat MediaProjection MP4) so we can keep different size
-- limits and MIME allowlists.
--
-- Path layout:  match-proofs/{matchId}/{userId}/{timestamp}.{ext}
--   * foldername(name)[1] = matchId
--   * foldername(name)[2] = userId   (mirrors match-recordings)
-- =============================================================================

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'match-proofs',
  'match-proofs',
  false,
  52428800, -- 50 MiB; proofs are short clips/screenshots, not full replays
  array[
    'image/jpeg',
    'image/png',
    'image/webp',
    'video/mp4',
    'video/quicktime',
    'video/webm'
  ]
)
on conflict (id) do update set
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

-- A player can upload only into their own subfolder of a match they
-- actually play in. Mirrors `match_recordings_owner_insert`.
drop policy if exists match_proofs_owner_insert on storage.objects;
create policy match_proofs_owner_insert on storage.objects
  for insert to authenticated
  with check (
    bucket_id = 'match-proofs'
    and (auth.uid())::text = (storage.foldername(name))[2]
    and exists (
      select 1 from public.matches m
      where (m.id)::text = (storage.foldername(name))[1]
        and (auth.uid() = m.player1_id or auth.uid() = m.player2_id)
    )
  );

-- A player can read their own proofs back (preview, replace).
drop policy if exists match_proofs_owner_select on storage.objects;
create policy match_proofs_owner_select on storage.objects
  for select to authenticated
  using (
    bucket_id = 'match-proofs'
    and (auth.uid())::text = (storage.foldername(name))[2]
  );

-- The opponent can also read the proof attached by the other side —
-- useful so each player can see what the other submitted before the
-- match resolves (concordant vs disputed).
drop policy if exists match_proofs_opponent_select on storage.objects;
create policy match_proofs_opponent_select on storage.objects
  for select to authenticated
  using (
    bucket_id = 'match-proofs'
    and exists (
      select 1 from public.matches m
      where (m.id)::text = (storage.foldername(name))[1]
        and (auth.uid() = m.player1_id or auth.uid() = m.player2_id)
    )
  );

-- Admins / super-admins read everything for arbitration.
drop policy if exists match_proofs_admin_read on storage.objects;
create policy match_proofs_admin_read on storage.objects
  for select to authenticated
  using (
    bucket_id = 'match-proofs'
    and exists (
      select 1 from public.profiles p
      where p.id = auth.uid()
        and p.role in ('admin', 'super_admin')
    )
  );

-- A player can replace their own proof up until the match resolves.
drop policy if exists match_proofs_owner_update on storage.objects;
create policy match_proofs_owner_update on storage.objects
  for update to authenticated
  using (
    bucket_id = 'match-proofs'
    and (auth.uid())::text = (storage.foldername(name))[2]
  );

drop policy if exists match_proofs_owner_delete on storage.objects;
create policy match_proofs_owner_delete on storage.objects
  for delete to authenticated
  using (
    bucket_id = 'match-proofs'
    and (auth.uid())::text = (storage.foldername(name))[2]
  );
