-- =============================================================================
-- ARENA — PHASE 8.7 — Auto-publish finals to Agora live streaming
-- =============================================================================
-- When a tournament reaches its grand final and the match starts, we
-- want it on `LiveStreamsPage` automatically — no admin action needed.
--
-- The seed config (PHASE 0 backend) already declares:
--   "streaming_finals_only": true
-- so the contract is: every grand final auto-publishes; non-final
-- matches stay private unless an admin manually flips the toggle
-- (`streaming_activation_type = 'manual_admin'`).
--
-- Mechanism: an AFTER UPDATE trigger on `public.matches` fires when
--   * status transitions to 'ongoing'
--   * AND the match is bound to a `bracket_nodes` row with
--     `is_grand_final = true`
-- It stamps the streaming columns on `matches` and flips
-- `streams.is_public = true` for the HOME's recording row (if one
-- exists at this point).
--
-- The trigger runs as SECURITY DEFINER so it bypasses the
-- `streams_player_update_own` RLS check that locks the public flag for
-- player-owned updates — the DB itself owns this transition.
-- =============================================================================

create or replace function public.auto_publish_final_match()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  is_final boolean;
  channel_name text;
begin
  -- Only react on the transition INTO 'ongoing'.
  if new.status is distinct from 'ongoing' then
    return new;
  end if;
  if old.status is not distinct from new.status then
    return new;
  end if;

  -- Is this match the grand final of its phase?
  select coalesce(bool_or(bn.is_grand_final), false)
    into is_final
    from public.bracket_nodes bn
   where bn.match_id = new.id;

  if not is_final then
    return new;
  end if;

  -- Stable Agora channel name `match_{uuid}` — must stay in sync with
  -- the Edge Function `get_agora_token` which derives the same value.
  channel_name := 'match_' || new.id::text;

  update public.matches m
     set is_streamed                    = true,
         streaming_activation_type      = 'auto_final',
         streaming_activated_at         = coalesce(m.streaming_activated_at, now()),
         agora_stream_channel           = coalesce(m.agora_stream_channel, channel_name),
         stream_status                  = case
                                            when m.stream_status = 'none' then 'pending'
                                            else m.stream_status
                                          end
   where m.id = new.id
     and m.is_streamed = false;

  -- Flip the HOME's recording row to public so it surfaces on
  -- `LiveStreamsPage` (driven by `streams.is_public = true and is_active = true`).
  -- If the HOME hasn't opened a stream session yet (recording starts
  -- after match-start in some flows), the trigger will still fire on
  -- the next `is_active` toggle via `auto_publish_late_stream` below.
  if new.home_player_id is not null then
    update public.streams s
       set is_public = true
     where s.match_id = new.id
       and s.player_id = new.home_player_id
       and s.is_active = true;
  end if;

  return new;
end;
$$;

drop trigger if exists trg_matches_auto_publish_final on public.matches;
create trigger trg_matches_auto_publish_final
  after update of status on public.matches
  for each row execute function public.auto_publish_final_match();

comment on function public.auto_publish_final_match() is
  'PHASE 8.7 — When a grand-final match starts (status -> ongoing), '
  'auto-flag is_streamed/auto_final on the match and publish the HOME''s '
  'recording row so it appears on LiveStreamsPage.';

-- ─── Late-stream catch-up ────────────────────────────────────────────────
-- If the HOME's recording session is opened AFTER the match starts
-- (the recording flow tolerates a few seconds of lag), we still need
-- the row to flip `is_public = true` so it shows up live. This trigger
-- handles that race by inspecting the linked match at INSERT time.

create or replace function public.auto_publish_late_stream()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  m_row public.matches;
begin
  select * into m_row from public.matches where id = new.match_id;
  if m_row.id is null then
    return new;
  end if;

  if m_row.is_streamed
     and m_row.streaming_activation_type = 'auto_final'
     and new.player_id = m_row.home_player_id
     and new.is_active = true
     and new.is_public = false then
    new.is_public := true;
  end if;

  return new;
end;
$$;

drop trigger if exists trg_streams_auto_publish_late on public.streams;
create trigger trg_streams_auto_publish_late
  before insert on public.streams
  for each row execute function public.auto_publish_late_stream();

comment on function public.auto_publish_late_stream() is
  'PHASE 8.7 — Catches the race where HOME opens its recording session '
  'after the grand-final match has been auto-flagged: forces is_public = true '
  'on insert.';
