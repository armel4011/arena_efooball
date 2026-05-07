-- =============================================================================
-- ARENA — PHASE 8.3 — Streams player-write RLS (anti-cheat recordings)
-- =============================================================================
-- Same V1.0 caveat as PHASE 5/6: the original RLS routed every write
-- through Edge Functions / admin (`streams_admin_all` only). The Edge
-- Functions that own recording lifecycle (`stream_started`,
-- `stream_ended`, `attach_recording_url`) are deferred to PHASE 12.5.
-- Until they ship, the in-app anti-cheat layer needs a narrow client
-- write policy so a seated player can:
--   1. INSERT a `streams` row tied to their own match when recording
--      starts (PHASE 8.3),
--   2. UPDATE that row when the recording stops or the upload finishes
--      (set `ended_at`, `is_active = false`, `url`).
--
-- Manual uploads (gallery picker) reuse the same INSERT path — the
-- file is just sourced from the user's library instead of from the
-- screen recorder.
-- =============================================================================

-- ─── streams: seated players may insert their own session ────────────────
create policy "streams_player_insert_self"
  on public.streams for insert
  with check (
    auth.uid() = player_id
    and exists (
      select 1
      from public.matches m
      where m.id = match_id
        and (auth.uid() = m.player1_id or auth.uid() = m.player2_id)
    )
  );

comment on policy "streams_player_insert_self" on public.streams is
  'PHASE 8.3 — Either seated player may open a recording session for their own match. PHASE 12.5 Edge Functions will eventually own the lifecycle.';

-- ─── streams: owners may update their own session row ────────────────────
-- Used to flip `is_active = false`, stamp `ended_at`, and attach the
-- final Storage URL. We do NOT let a player toggle `is_public` — that
-- decision is reserved to admins (Agora streaming activation).
create policy "streams_player_update_own"
  on public.streams for update
  using (auth.uid() = player_id)
  with check (
    auth.uid() = player_id
    -- Lock the public flag down: only admins can flip it on, via
    -- `streams_admin_all` which uses the higher-priority `for all`.
    and is_public = false
  );

comment on policy "streams_player_update_own" on public.streams is
  'PHASE 8.3 — Owner may close their own recording session and set its URL. Cannot publish (is_public = false enforced).';
