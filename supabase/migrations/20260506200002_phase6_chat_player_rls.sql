-- =============================================================================
-- ARENA — PHASE 6 — Chat hybride RLS patch
-- =============================================================================
-- Same V1.0 caveat as PHASE 5: the original RLS routed every chat write
-- through Edge Functions / admin (`chat_channels_admin_write`), but the
-- moderation / channel-bootstrap Edge Functions are deferred to PHASE 12.5.
-- Until they ship, the in-app chat needs a narrow client-write policy so
-- the two seated players of a match can auto-create the `type = 'match'`
-- channel when they first open the chat screen.
--
-- `chat_messages` already has the right policies upstream:
--   - `chat_messages_select`        — participants of the match read OK
--   - `chat_messages_insert_self`   — author posts as themselves OK
-- so this migration only needs to:
--   1. allow seated players to INSERT a `chat_channels` row tied to their
--      match,
--   2. add `chat_channels` and `chat_messages` to `supabase_realtime` so
--      the stream subscriptions actually receive INSERT events.
-- =============================================================================

-- ─── chat_channels: seated players can INSERT their match channel ─────────
create policy "chat_channels_player_insert_match"
  on public.chat_channels for insert
  with check (
    type = 'match'
    and match_id is not null
    and exists (
      select 1
      from public.matches m
      where m.id = match_id
        and (auth.uid() = m.player1_id or auth.uid() = m.player2_id)
    )
  );

comment on policy "chat_channels_player_insert_match" on public.chat_channels is
  'PHASE 6 — Either seated player may bootstrap the `type = match` channel for their own match. PHASE 12.5 Edge Functions will eventually own channel creation.';

-- ─── Realtime publication ─────────────────────────────────────────────────
-- Without these, the chat stream only ever emits the initial snapshot —
-- new messages from the other player never reach the client.
do $$
begin
  alter publication supabase_realtime add table public.chat_channels;
exception when duplicate_object then null;
end $$;

do $$
begin
  alter publication supabase_realtime add table public.chat_messages;
exception when duplicate_object then null;
end $$;
