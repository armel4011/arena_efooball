-- Phase 13.2 — Optimisation des policies RLS : auth.uid() → (select auth.uid()).
--
-- Audit performance flag : 8 policies réévaluent auth.uid() POUR CHAQUE
-- ligne. Postgres ne peut pas cacher le résultat à cause de la sémantique
-- STABLE de la fonction. En wrappant l'appel dans un sous-SELECT,
-- Postgres met le résultat en cache d'InitPlan (1 appel par requête au
-- lieu de N appels par ligne). Gain proportionnel au volume scanné.
--
-- DROP + CREATE, pas d'ALTER POLICY (Postgres ne supporte pas).

-- 1. matches.matches_player_update
drop policy if exists matches_player_update on public.matches;
create policy matches_player_update on public.matches
  for update
  using (((select auth.uid()) = player1_id) or ((select auth.uid()) = player2_id))
  with check (((select auth.uid()) = player1_id) or ((select auth.uid()) = player2_id));

-- 2. match_events.match_events_player_insert
drop policy if exists match_events_player_insert on public.match_events;
create policy match_events_player_insert on public.match_events
  for insert
  with check (
    ((select auth.uid()) = created_by)
    and exists (
      select 1 from public.matches m
      where m.id = match_events.match_id
        and ((select auth.uid()) = m.player1_id or (select auth.uid()) = m.player2_id)
    )
  );

-- 3. chat_channels.chat_channels_player_insert_match
drop policy if exists chat_channels_player_insert_match on public.chat_channels;
create policy chat_channels_player_insert_match on public.chat_channels
  for insert
  with check (
    type = 'match'
    and match_id is not null
    and exists (
      select 1 from public.matches m
      where m.id = chat_channels.match_id
        and ((select auth.uid()) = m.player1_id or (select auth.uid()) = m.player2_id)
    )
  );

-- 4. streams.streams_player_insert_self
drop policy if exists streams_player_insert_self on public.streams;
create policy streams_player_insert_self on public.streams
  for insert
  with check (
    ((select auth.uid()) = player_id)
    and exists (
      select 1 from public.matches m
      where m.id = streams.match_id
        and ((select auth.uid()) = m.player1_id or (select auth.uid()) = m.player2_id)
    )
  );

-- 5. streams.streams_player_update_own
drop policy if exists streams_player_update_own on public.streams;
create policy streams_player_update_own on public.streams
  for update
  using ((select auth.uid()) = player_id)
  with check (((select auth.uid()) = player_id) and is_public = false);

-- 6. payments.payments_self_insert
drop policy if exists payments_self_insert on public.payments;
create policy payments_self_insert on public.payments
  for insert
  with check (
    ((select auth.uid()) = user_id)
    and provider = 'mobile_money_manual'
    and status = 'awaiting_admin'
  );

-- 7. competition_registrations.registrations_free_self_insert
drop policy if exists registrations_free_self_insert on public.competition_registrations;
create policy registrations_free_self_insert on public.competition_registrations
  for insert
  with check (
    ((select auth.uid()) = player_id)
    and status = 'confirmed'
    and payment_id is null
    and exists (
      select 1 from public.competitions c
      where c.id = competition_registrations.competition_id
        and c.registration_fee = 0::numeric
    )
  );

-- 8. admin_audit_log.admin_audit_log_admin_insert
drop policy if exists admin_audit_log_admin_insert on public.admin_audit_log;
create policy admin_audit_log_admin_insert on public.admin_audit_log
  for insert
  with check (public.is_admin() and admin_id = (select auth.uid()));
