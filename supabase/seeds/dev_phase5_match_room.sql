-- =============================================================================
-- ARENA — PHASE 5 dev seed — Match Room test fixtures
-- =============================================================================
-- WHAT IT DOES
--   1. Ensures a 2nd test user (`opponent@arena.dev` / `TestPass123!`) exists.
--   2. Ensures the matching `profiles` row exists (idempotent).
--   3. Creates a single-elimination competition `__phase5_dev` with one
--      knockout phase and seven `matches` rows covering every match-room
--      screen we ship in PHASE 5:
--        #1 pending                  → 5.C share-code form
--        #2 ready (cladiator HOME)   → 5.C ready view, you are HOME
--        #3 ready (opponent HOME)    → 5.C ready view, you are AWAY
--        #4 in_progress, no events   → 5.D submit form
--        #5 in_progress, opp posted  → 5.D submit form (opponent already in)
--        #6 completed 3-1            → completed view (cladiator wins)
--        #7 disputed                 → 12.5 placeholder
--
-- HOW TO RUN
--   Paste into Supabase SQL editor with the **service_role** session
--   (default for the dashboard). Re-runnable: drops the test competition
--   first via the cleanup block at the top.
--
-- ASSUMPTIONS
--   - Email confirmation is disabled in dev (matches our project memory).
--   - You are running this in the Supabase SQL editor (service_role) so
--     RLS does not block the inserts.
--
-- LOGIN CREDENTIALS
--   Both seeded accounts use the password `TestPass123!`. Sign in with
--   either one in the app to test the match-room flows.
-- =============================================================================

-- ─── Cleanup any prior run of this seed ───────────────────────────────────
delete from public.competitions where name = '__phase5_dev';

-- ─── 1. Ensure both test users exist in auth.users ────────────────────────
do $$
declare
  v_pair record;
begin
  for v_pair in
    select * from (values
      ('cladiator4011@gmail.com', 'cladiator'),
      ('opponent@arena.dev', 'opponent')
    ) as t(email, username)
  loop
    if not exists (select 1 from auth.users where auth.users.email = v_pair.email) then
      insert into auth.users (
        instance_id,
        id,
        aud,
        role,
        email,
        encrypted_password,
        email_confirmed_at,
        raw_app_meta_data,
        raw_user_meta_data,
        created_at,
        updated_at,
        confirmation_token,
        email_change,
        email_change_token_new,
        recovery_token
      ) values (
        '00000000-0000-0000-0000-000000000000',
        gen_random_uuid(),
        'authenticated',
        'authenticated',
        v_pair.email,
        crypt('TestPass123!', gen_salt('bf')),
        now(),
        '{"provider":"email","providers":["email"]}'::jsonb,
        jsonb_build_object('username', v_pair.username),
        now(),
        now(),
        '',
        '',
        '',
        ''
      );
    end if;
  end loop;
end $$;

-- ─── 2. Ensure matching profiles for both users ───────────────────────────
insert into public.profiles (
  id,
  username,
  email,
  country_code,
  cgu_accepted_at,
  cgu_version_accepted,
  privacy_policy_accepted_at
)
select
  u.id,
  case u.email
    when 'cladiator4011@gmail.com' then 'cladiator'
    when 'opponent@arena.dev' then 'opponent'
  end,
  u.email,
  'CM',
  now(),
  'v1.0',
  now()
from auth.users u
where u.email in ('cladiator4011@gmail.com', 'opponent@arena.dev')
on conflict (id) do nothing;

-- ─── 3. Build the test fixtures ───────────────────────────────────────────
do $$
declare
  v_p1 uuid;
  v_p2 uuid;
  v_comp uuid;
  v_phase uuid;
  v_match_pending uuid;
  v_match_ready_home uuid;
  v_match_ready_away uuid;
  v_match_inprogress uuid;
  v_match_inprogress_opp_posted uuid;
  v_match_completed uuid;
  v_match_disputed uuid;
begin
  -- Look up cladiator (must already exist).
  select id into v_p1 from public.profiles where email = 'cladiator4011@gmail.com';
  if v_p1 is null then
    raise exception 'profile cladiator4011@gmail.com not found — sign up via the app first.';
  end if;

  select id into v_p2 from public.profiles where email = 'opponent@arena.dev';
  if v_p2 is null then
    raise exception 'profile opponent@arena.dev not found — step 2 above must have run.';
  end if;

  -- Competition.
  insert into public.competitions (
    name,
    game,
    description,
    format,
    status,
    registration_opens_at,
    registration_closes_at,
    start_date,
    max_players,
    current_players,
    registration_fee,
    registration_currency,
    commission_pct,
    prize_pool_local,
    prize_pool_currency,
    created_by
  ) values (
    '__phase5_dev',
    'efootball',
    'Seed compétition — sert à valider la match-room (PHASE 5).',
    'single_elimination',
    'ongoing',
    now() - interval '7 days',
    now() - interval '1 day',
    now() - interval '1 hour',
    8,
    2,
    0,
    'XAF',
    10,
    0,
    'XAF',
    v_p1
  ) returning id into v_comp;

  -- One knockout phase.
  insert into public.phases (competition_id, phase_order, type, status, started_at)
  values (v_comp, 1, 'knockout', 'ongoing', now() - interval '30 minutes')
  returning id into v_phase;

  -- Match #1 — pending (no code shared yet) → 5.C share-code form.
  insert into public.matches (
    competition_id, phase_id, round, match_number,
    player1_id, player2_id, status
  ) values (
    v_comp, v_phase, 1, 1,
    v_p1, v_p2, 'pending'
  ) returning id into v_match_pending;

  -- Match #2 — ready, cladiator is HOME → 5.C ready view, "you are HOME".
  insert into public.matches (
    competition_id, phase_id, round, match_number,
    player1_id, player2_id, status,
    home_player_id, room_code
  ) values (
    v_comp, v_phase, 1, 2,
    v_p1, v_p2, 'ready',
    v_p1, 'ABC123'
  ) returning id into v_match_ready_home;

  -- Match #3 — ready, opponent is HOME → 5.C ready view, "you are AWAY".
  insert into public.matches (
    competition_id, phase_id, round, match_number,
    player1_id, player2_id, status,
    home_player_id, room_code
  ) values (
    v_comp, v_phase, 1, 3,
    v_p1, v_p2, 'ready',
    v_p2, 'XYZ789'
  ) returning id into v_match_ready_away;

  -- Match #4 — in_progress, no submissions yet → 5.D entry form.
  insert into public.matches (
    competition_id, phase_id, round, match_number,
    player1_id, player2_id, status,
    home_player_id, room_code, started_at
  ) values (
    v_comp, v_phase, 1, 4,
    v_p1, v_p2, 'in_progress',
    v_p1, 'PLAY01', now() - interval '20 minutes'
  ) returning id into v_match_inprogress;

  -- Match #5 — in_progress, opponent already posted a score → 5.D form
  -- still shows for cladiator (mySubmission is null), and submitting a
  -- matching score should commit the match in real time.
  insert into public.matches (
    competition_id, phase_id, round, match_number,
    player1_id, player2_id, status,
    home_player_id, room_code, started_at
  ) values (
    v_comp, v_phase, 1, 5,
    v_p1, v_p2, 'in_progress',
    v_p2, 'PLAY02', now() - interval '15 minutes'
  ) returning id into v_match_inprogress_opp_posted;

  insert into public.match_events (match_id, type, payload, created_by)
  values (
    v_match_inprogress_opp_posted,
    'score_submitted',
    '{"score1": 2, "score2": 3}'::jsonb,
    v_p2
  );

  -- Match #6 — completed, cladiator wins 3-1 → completed view.
  insert into public.matches (
    competition_id, phase_id, round, match_number,
    player1_id, player2_id, status,
    home_player_id, room_code,
    score1, score2, winner_id,
    started_at, finished_at
  ) values (
    v_comp, v_phase, 1, 6,
    v_p1, v_p2, 'completed',
    v_p1, 'DONE01',
    3, 1, v_p1,
    now() - interval '2 hours', now() - interval '90 minutes'
  ) returning id into v_match_completed;

  -- Match #7 — disputed → 12.5 placeholder.
  insert into public.matches (
    competition_id, phase_id, round, match_number,
    player1_id, player2_id, status,
    home_player_id, room_code, started_at
  ) values (
    v_comp, v_phase, 1, 7,
    v_p1, v_p2, 'disputed',
    v_p1, 'WTF001', now() - interval '40 minutes'
  ) returning id into v_match_disputed;

  -- Two divergent submissions on the disputed match (for posterity).
  insert into public.match_events (match_id, type, payload, created_by) values
    (v_match_disputed, 'score_submitted', '{"score1": 2, "score2": 1}'::jsonb, v_p1),
    (v_match_disputed, 'score_submitted', '{"score1": 1, "score2": 2}'::jsonb, v_p2);

  raise notice 'phase5 seed OK: competition %, 7 matches', v_comp;
end $$;
