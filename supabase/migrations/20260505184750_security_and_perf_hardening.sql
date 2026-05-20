-- =============================================================================
-- ARENA — Hardening sécurité + performance (issu des advisors)
-- =============================================================================

-- ---- 1. Fonctions trigger : verrouille search_path ---------------------------
alter function public.set_updated_at()      set search_path = public, pg_temp;
alter function public.cascade_match_winner() set search_path = public, pg_temp;

-- ---- 2. Révoque EXECUTE des helpers SECURITY DEFINER -------------------------
-- Elles ne doivent être invoquées que par les policies RLS (côté serveur),
-- jamais via /rest/v1/rpc.
revoke execute on function public.is_admin()       from anon, authenticated, public;
revoke execute on function public.is_super_admin() from anon, authenticated, public;

-- ---- 3. Indexes pour FK manquants (24 FK détectées) --------------------------
-- bracket_nodes
create index if not exists idx_bracket_nodes_bye_player on public.bracket_nodes(bye_player_id) where bye_player_id is not null;
create index if not exists idx_bracket_nodes_competition on public.bracket_nodes(competition_id);
create index if not exists idx_bracket_nodes_next_node on public.bracket_nodes(next_node_id) where next_node_id is not null;

-- chat
create index if not exists idx_chat_channels_competition on public.chat_channels(competition_id) where competition_id is not null;
create index if not exists idx_chat_messages_sender on public.chat_messages(sender_id) where sender_id is not null;

-- competition_registrations / competitions
create index if not exists idx_registrations_payment on public.competition_registrations(payment_id) where payment_id is not null;
create index if not exists idx_competitions_created_by on public.competitions(created_by) where created_by is not null;

-- disputes
create index if not exists idx_disputes_opened_by on public.disputes(opened_by);
create index if not exists idx_disputes_resolved_by on public.disputes(resolved_by) where resolved_by is not null;

-- groups
create index if not exists idx_groups_competition on public.groups(competition_id);

-- invitation_codes
create index if not exists idx_invitation_codes_generated_by on public.invitation_codes(generated_by) where generated_by is not null;
create index if not exists idx_invitation_codes_used_by on public.invitation_codes(used_by) where used_by is not null;

-- match_events
create index if not exists idx_match_events_created_by on public.match_events(created_by) where created_by is not null;

-- matches (5 FK)
create index if not exists idx_matches_group on public.matches(group_id) where group_id is not null;
create index if not exists idx_matches_home_player on public.matches(home_player_id) where home_player_id is not null;
create index if not exists idx_matches_player2 on public.matches(player2_id) where player2_id is not null;
create index if not exists idx_matches_streaming_admin on public.matches(streaming_activated_by_admin_id) where streaming_activated_by_admin_id is not null;
create index if not exists idx_matches_winner on public.matches(winner_id) where winner_id is not null;

-- payment_webhook_log
create index if not exists idx_webhook_log_payout on public.payment_webhook_log(related_payout_id) where related_payout_id is not null;

-- payouts (3 FK)
create index if not exists idx_payouts_competition on public.payouts(competition_id);
create index if not exists idx_payouts_prize on public.payouts(prize_id);
create index if not exists idx_payouts_validated_by_admin on public.payouts(validated_by_admin_id) where validated_by_admin_id is not null;

-- platform_revenue (2 FK)
create index if not exists idx_platform_revenue_competition on public.platform_revenue(competition_id) where competition_id is not null;
create index if not exists idx_platform_revenue_payment on public.platform_revenue(payment_id) where payment_id is not null;
