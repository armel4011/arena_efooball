-- =============================================================================
-- ARENA — Optimisation RLS (auth_rls_initplan + multiple_permissive_policies)
-- =============================================================================
-- Stratégie :
--   1. Drop toutes les policies existantes du schema public.
--   2. Recreate avec :
--      - auth.uid()  → (select auth.uid())   [évalué une fois par requête]
--      - is_admin()  → (select public.is_admin())   [idem]
--      - 1 seule policy SELECT par table (fusion des permissives via OR)
--      - Policies INSERT/UPDATE/DELETE séparées au lieu de FOR ALL
--        (évite de doublonner le SELECT permissif)
-- =============================================================================

-- ---- 1. Drop toutes les policies du public schema --------------------------
do $$
declare r record;
begin
  for r in select policyname, tablename from pg_policies where schemaname = 'public'
  loop
    execute format('drop policy if exists %I on public.%I', r.policyname, r.tablename);
  end loop;
end $$;

-- ---- 2. profiles -----------------------------------------------------------
-- 1 SELECT (self ou admin ou non supprimé) ; UPDATE self ou admin ; INSERT/DELETE admin
create policy "profiles_select" on public.profiles for select
  using (deleted_at is null or (select auth.uid()) = id or (select public.is_admin()));
create policy "profiles_update" on public.profiles for update
  using ((select auth.uid()) = id or (select public.is_admin()))
  with check ((select auth.uid()) = id or (select public.is_admin()));
create policy "profiles_insert_admin" on public.profiles for insert
  with check ((select public.is_admin()));
create policy "profiles_delete_admin" on public.profiles for delete
  using ((select public.is_admin()));

-- ---- 3. competitions / phases / groups / group_memberships / prizes --------
-- Lecture publique, écriture admin (insert / update / delete séparés)
create policy "competitions_select" on public.competitions for select using (true);
create policy "competitions_insert_admin" on public.competitions for insert with check ((select public.is_admin()));
create policy "competitions_update_admin" on public.competitions for update using ((select public.is_admin())) with check ((select public.is_admin()));
create policy "competitions_delete_admin" on public.competitions for delete using ((select public.is_admin()));

create policy "phases_select" on public.phases for select using (true);
create policy "phases_insert_admin" on public.phases for insert with check ((select public.is_admin()));
create policy "phases_update_admin" on public.phases for update using ((select public.is_admin())) with check ((select public.is_admin()));
create policy "phases_delete_admin" on public.phases for delete using ((select public.is_admin()));

create policy "groups_select" on public.groups for select using (true);
create policy "groups_insert_admin" on public.groups for insert with check ((select public.is_admin()));
create policy "groups_update_admin" on public.groups for update using ((select public.is_admin())) with check ((select public.is_admin()));
create policy "groups_delete_admin" on public.groups for delete using ((select public.is_admin()));

create policy "memberships_select" on public.group_memberships for select using (true);
create policy "memberships_insert_admin" on public.group_memberships for insert with check ((select public.is_admin()));
create policy "memberships_update_admin" on public.group_memberships for update using ((select public.is_admin())) with check ((select public.is_admin()));
create policy "memberships_delete_admin" on public.group_memberships for delete using ((select public.is_admin()));

create policy "prizes_select" on public.prizes for select using (true);
create policy "prizes_insert_admin" on public.prizes for insert with check ((select public.is_admin()));
create policy "prizes_update_admin" on public.prizes for update using ((select public.is_admin())) with check ((select public.is_admin()));
create policy "prizes_delete_admin" on public.prizes for delete using ((select public.is_admin()));

-- ---- 4. app_config / exchange_rates / banned_words -------------------------
create policy "app_config_select" on public.app_config for select using (true);
create policy "app_config_insert_admin" on public.app_config for insert with check ((select public.is_admin()));
create policy "app_config_update_admin" on public.app_config for update using ((select public.is_admin())) with check ((select public.is_admin()));
create policy "app_config_delete_admin" on public.app_config for delete using ((select public.is_admin()));

create policy "exchange_rates_select" on public.exchange_rates for select using (true);
-- Pas d'INSERT/UPDATE/DELETE : Edge Function (service_role) seulement.

create policy "banned_words_select_admin" on public.banned_words for select using ((select public.is_admin()));
create policy "banned_words_insert_admin" on public.banned_words for insert with check ((select public.is_admin()));
create policy "banned_words_update_admin" on public.banned_words for update using ((select public.is_admin())) with check ((select public.is_admin()));
create policy "banned_words_delete_admin" on public.banned_words for delete using ((select public.is_admin()));

-- ---- 5. invitation_codes (super_admin only) --------------------------------
create policy "invitation_codes_select_su" on public.invitation_codes for select using ((select public.is_super_admin()));
create policy "invitation_codes_insert_su" on public.invitation_codes for insert with check ((select public.is_super_admin()));
create policy "invitation_codes_update_su" on public.invitation_codes for update using ((select public.is_super_admin())) with check ((select public.is_super_admin()));
create policy "invitation_codes_delete_su" on public.invitation_codes for delete using ((select public.is_super_admin()));

-- ---- 6. matches / bracket_nodes --------------------------------------------
create policy "matches_select" on public.matches for select using (true);
create policy "matches_insert_admin" on public.matches for insert with check ((select public.is_admin()));
create policy "matches_update_admin" on public.matches for update using ((select public.is_admin())) with check ((select public.is_admin()));
create policy "matches_delete_admin" on public.matches for delete using ((select public.is_admin()));

create policy "bracket_nodes_select" on public.bracket_nodes for select using (true);
create policy "bracket_nodes_insert_admin" on public.bracket_nodes for insert with check ((select public.is_admin()));
create policy "bracket_nodes_update_admin" on public.bracket_nodes for update using ((select public.is_admin())) with check ((select public.is_admin()));
create policy "bracket_nodes_delete_admin" on public.bracket_nodes for delete using ((select public.is_admin()));

-- ---- 7. match_events (lecture participants OR admin ; écriture admin) ------
create policy "match_events_select" on public.match_events for select using (
  (select public.is_admin())
  or exists (
    select 1 from public.matches m
    where m.id = match_id
      and ((select auth.uid()) in (m.player1_id, m.player2_id))
  )
);
create policy "match_events_insert_admin" on public.match_events for insert with check ((select public.is_admin()));
create policy "match_events_update_admin" on public.match_events for update using ((select public.is_admin())) with check ((select public.is_admin()));
create policy "match_events_delete_admin" on public.match_events for delete using ((select public.is_admin()));

-- ---- 8. anti_cheat_events (admin only) -------------------------------------
create policy "anti_cheat_select_admin" on public.anti_cheat_events for select using ((select public.is_admin()));
create policy "anti_cheat_insert_admin" on public.anti_cheat_events for insert with check ((select public.is_admin()));
create policy "anti_cheat_update_admin" on public.anti_cheat_events for update using ((select public.is_admin())) with check ((select public.is_admin()));
create policy "anti_cheat_delete_admin" on public.anti_cheat_events for delete using ((select public.is_admin()));

-- ---- 9. chat_channels ------------------------------------------------------
create policy "chat_channels_select" on public.chat_channels for select using (true);
create policy "chat_channels_insert_admin" on public.chat_channels for insert with check ((select public.is_admin()));
create policy "chat_channels_update_admin" on public.chat_channels for update using ((select public.is_admin())) with check ((select public.is_admin()));
create policy "chat_channels_delete_admin" on public.chat_channels for delete using ((select public.is_admin()));

-- ---- 10. chat_messages -----------------------------------------------------
create policy "chat_messages_select" on public.chat_messages for select using (
  (select public.is_admin())
  or exists (
    select 1 from public.chat_channels c
    left join public.matches m on m.id = c.match_id
    where c.id = channel_id and (
      c.type in ('competition_broadcast','global')
      or (c.type = 'match' and (select auth.uid()) in (m.player1_id, m.player2_id))
    )
  )
);
create policy "chat_messages_insert" on public.chat_messages for insert
  with check (sender_id = (select auth.uid()) or (select public.is_admin()));
create policy "chat_messages_update_admin" on public.chat_messages for update
  using ((select public.is_admin())) with check ((select public.is_admin()));
create policy "chat_messages_delete_admin" on public.chat_messages for delete
  using ((select public.is_admin()));

-- ---- 11. payments / payouts (lecture self OR admin) ------------------------
create policy "payments_select" on public.payments for select
  using (user_id = (select auth.uid()) or (select public.is_admin()));
-- Pas d'INSERT/UPDATE/DELETE : Edge Functions service_role.

create policy "payouts_select" on public.payouts for select
  using (user_id = (select auth.uid()) or (select public.is_admin()));

-- ---- 12. platform_revenue / payment_webhook_log (admin only) ---------------
create policy "platform_revenue_select_admin" on public.platform_revenue for select
  using ((select public.is_admin()));

create policy "payment_webhook_log_select_admin" on public.payment_webhook_log for select
  using ((select public.is_admin()));

-- ---- 13. disputes ----------------------------------------------------------
create policy "disputes_select" on public.disputes for select using (
  opened_by = (select auth.uid())
  or (select public.is_admin())
  or exists (
    select 1 from public.matches m
    where m.id = match_id
      and ((select auth.uid()) in (m.player1_id, m.player2_id))
  )
);
create policy "disputes_insert" on public.disputes for insert with check (
  (select public.is_admin())
  or (
    opened_by = (select auth.uid())
    and exists (
      select 1 from public.matches m
      where m.id = match_id
        and ((select auth.uid()) in (m.player1_id, m.player2_id))
    )
  )
);
create policy "disputes_update_admin" on public.disputes for update
  using ((select public.is_admin())) with check ((select public.is_admin()));
create policy "disputes_delete_admin" on public.disputes for delete
  using ((select public.is_admin()));

-- ---- 14. notifications -----------------------------------------------------
create policy "notifications_select" on public.notifications for select
  using (user_id = (select auth.uid()) or (select public.is_admin()));
create policy "notifications_update" on public.notifications for update
  using (user_id = (select auth.uid()) or (select public.is_admin()))
  with check (user_id = (select auth.uid()) or (select public.is_admin()));
create policy "notifications_insert_admin" on public.notifications for insert
  with check ((select public.is_admin()));
create policy "notifications_delete_admin" on public.notifications for delete
  using ((select public.is_admin()));

-- ---- 15. admin_audit_log / auto_actions_log (admin only) -------------------
create policy "admin_audit_log_select_admin" on public.admin_audit_log for select
  using ((select public.is_admin()));

create policy "auto_actions_log_select_admin" on public.auto_actions_log for select
  using ((select public.is_admin()));

-- ---- 16. competition_registrations -----------------------------------------
create policy "registrations_select" on public.competition_registrations for select using (true);
create policy "registrations_insert_admin" on public.competition_registrations for insert with check ((select public.is_admin()));
create policy "registrations_update_admin" on public.competition_registrations for update using ((select public.is_admin())) with check ((select public.is_admin()));
create policy "registrations_delete_admin" on public.competition_registrations for delete using ((select public.is_admin()));

-- ---- 17. streams -----------------------------------------------------------
create policy "streams_select" on public.streams for select using (
  is_public = true
  or player_id = (select auth.uid())
  or (select public.is_admin())
);
create policy "streams_insert_admin" on public.streams for insert with check ((select public.is_admin()));
create policy "streams_update_admin" on public.streams for update using ((select public.is_admin())) with check ((select public.is_admin()));
create policy "streams_delete_admin" on public.streams for delete using ((select public.is_admin()));
