-- =============================================================================
-- ARENA — PHASE 5 — Match Room RLS patch
-- =============================================================================
-- The original V1.0 design routed every match-room write through Edge
-- Functions (with the service_role key). Edge Functions are scheduled for
-- PHASE 12.5 — until they ship, the corresponding client flows are dead
-- because the locked-down RLS silently drops every UPDATE/INSERT.
--
-- This migration unblocks the four PHASE 5 client flows:
--   1. share-room-code     → UPDATE matches (room_code, home_player_id, status)
--   2. mark-in-progress    → UPDATE matches (status, started_at)
--   3. submit-score        → INSERT match_events (score_submitted)
--   4. commit / dispute    → UPDATE matches (score1, score2, winner_id, …)
--
-- Each policy restricts the right strictly to the two profiles seated on
-- the match (player1_id, player2_id). When the Edge Functions land in
-- PHASE 12.5, we'll either drop these policies or keep them — the
-- service_role bypasses RLS either way, so leaving them in place is
-- harmless but redundant.
-- =============================================================================

-- ─── matches: participants can UPDATE their own row ───────────────────────
create policy "matches_player_update"
  on public.matches for update
  using (
    auth.uid() = player1_id
    or auth.uid() = player2_id
  )
  with check (
    auth.uid() = player1_id
    or auth.uid() = player2_id
  );

comment on policy "matches_player_update" on public.matches is
  'PHASE 5 — Either seated player may update their match (room_code, status, score, winner_id). The narrower per-column intent is enforced by the Dart repository, not by RLS, until the PHASE 12.5 Edge Functions take over.';

-- ─── match_events: participants can INSERT events on their own match ──────
create policy "match_events_player_insert"
  on public.match_events for insert
  with check (
    auth.uid() = created_by
    and exists (
      select 1
      from public.matches m
      where m.id = match_id
        and (auth.uid() = m.player1_id or auth.uid() = m.player2_id)
    )
  );

comment on policy "match_events_player_insert" on public.match_events is
  'PHASE 5 — Either seated player may post `score_submitted` (and other) events on their own match. Same caveat: PHASE 12.5 Edge Functions will eventually own this write path.';

-- ─── Realtime publication ─────────────────────────────────────────────────
-- The migration that introduced `streams` + `competition_registrations`
-- forgot to add `matches` and `match_events` to the realtime publication.
-- Without this, `MatchRepository.watchById` and `watchScoreSubmissions`
-- only ever emit the initial snapshot — score validation across two
-- devices never converges because each client misses the other's INSERT.
do $$
begin
  alter publication supabase_realtime add table public.matches;
exception when duplicate_object then null;
end $$;

do $$
begin
  alter publication supabase_realtime add table public.match_events;
exception when duplicate_object then null;
end $$;
