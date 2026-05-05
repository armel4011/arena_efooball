-- =============================================================================
-- ARENA — Phase 0 — Migration 5/5
-- Tables d'audit (admin_audit_log, auto_actions_log)
--   + activation RLS sur les 24 tables
--   + helpers (is_admin / is_super_admin)
--   + policies sécurité
--   + indexes critiques
--   + seed minimal app_config (V1.0)
-- =============================================================================
-- Dépend de : 20260505100002, 20260505100003, 20260505100004
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 1. admin_audit_log
--    Trace de toutes les actions admin (forçage statut, validation payout, etc.)
-- -----------------------------------------------------------------------------
create table if not exists public.admin_audit_log (
  id uuid primary key default uuid_generate_v4(),
  admin_id uuid not null
    references public.profiles on delete restrict,
  action text not null,
  target_type text,
  target_id uuid,
  before_state jsonb,
  after_state jsonb,
  ip_address text,
  user_agent text,
  created_at timestamptz not null default now()
);

comment on table public.admin_audit_log is
  'Audit trail des actions admin — RGPD + responsabilité.';

-- -----------------------------------------------------------------------------
-- 2. auto_actions_log
--    Trace des actions automatiques exécutées par les Edge Functions.
-- -----------------------------------------------------------------------------
create table if not exists public.auto_actions_log (
  id uuid primary key default uuid_generate_v4(),
  edge_function text not null,
  action text not null,
  target_type text,
  target_id uuid,
  status text not null check (status in ('success', 'partial', 'failed')),
  payload jsonb not null default '{}'::jsonb,
  error text,
  executed_at timestamptz not null default now()
);

comment on table public.auto_actions_log is
  'Logs des actions automatiques (Edge Functions + crons).';

-- =============================================================================
-- HELPERS DE SECURITE
-- =============================================================================

-- Renvoie true si l'utilisateur courant a le rôle admin ou super_admin.
-- security definer + search_path verrouillé pour résister à l'injection.
create or replace function public.is_admin()
returns boolean
language sql
security definer
set search_path = public
stable
as $$
  select exists (
    select 1
    from public.profiles
    where id = auth.uid()
      and role in ('admin', 'super_admin')
      and is_active = true
      and deleted_at is null
  );
$$;

create or replace function public.is_super_admin()
returns boolean
language sql
security definer
set search_path = public
stable
as $$
  select exists (
    select 1
    from public.profiles
    where id = auth.uid()
      and role = 'super_admin'
      and is_active = true
      and deleted_at is null
  );
$$;

comment on function public.is_admin is 'true si auth.uid() est admin ou super_admin actif.';
comment on function public.is_super_admin is 'true si auth.uid() est super_admin actif.';

-- =============================================================================
-- ACTIVATION RLS — 24 tables
-- =============================================================================
alter table public.profiles               enable row level security;
alter table public.competitions           enable row level security;
alter table public.phases     enable row level security;
alter table public.groups                 enable row level security;
alter table public.group_memberships      enable row level security;
alter table public.prizes                 enable row level security;
alter table public.app_config             enable row level security;
alter table public.exchange_rates         enable row level security;
alter table public.invitation_codes       enable row level security;
alter table public.banned_words           enable row level security;
alter table public.matches                enable row level security;
alter table public.bracket_nodes          enable row level security;
alter table public.match_events           enable row level security;
alter table public.anti_cheat_events      enable row level security;
alter table public.chat_channels          enable row level security;
alter table public.chat_messages          enable row level security;
alter table public.payments               enable row level security;
alter table public.payouts                enable row level security;
alter table public.platform_revenue       enable row level security;
alter table public.payment_webhook_log    enable row level security;
alter table public.disputes               enable row level security;
alter table public.notifications          enable row level security;
alter table public.admin_audit_log        enable row level security;
alter table public.auto_actions_log       enable row level security;

-- =============================================================================
-- POLICIES — Principe : DENY by default, ouvrir au strict nécessaire.
-- Note : les Edge Functions utilisent service_role qui bypass RLS.
-- =============================================================================

-- ---------- profiles ---------------------------------------------------------
create policy "profiles_self_select"
  on public.profiles for select
  using (auth.uid() = id);

create policy "profiles_public_read_limited"
  on public.profiles for select
  using (deleted_at is null);

create policy "profiles_self_update"
  on public.profiles for update
  using (auth.uid() = id)
  with check (auth.uid() = id);

create policy "profiles_admin_all"
  on public.profiles for all
  using (public.is_admin())
  with check (public.is_admin());

-- L'INSERT est fait par l'Edge Function de signup (service_role),
-- pas via RLS côté client. Aucune policy INSERT ouverte.

-- ---------- competitions -----------------------------------------------------
create policy "competitions_public_read"
  on public.competitions for select
  using (true);

create policy "competitions_admin_write"
  on public.competitions for all
  using (public.is_admin())
  with check (public.is_admin());

-- ---------- phases / groups / group_memberships ------------------
create policy "phases_public_read"
  on public.phases for select using (true);
create policy "phases_admin_write"
  on public.phases for all
  using (public.is_admin()) with check (public.is_admin());

create policy "groups_public_read"
  on public.groups for select using (true);
create policy "groups_admin_write"
  on public.groups for all
  using (public.is_admin()) with check (public.is_admin());

create policy "memberships_public_read"
  on public.group_memberships for select using (true);
create policy "memberships_admin_write"
  on public.group_memberships for all
  using (public.is_admin()) with check (public.is_admin());

-- ---------- prizes -----------------------------------------------------------
create policy "prizes_public_read"
  on public.prizes for select using (true);
create policy "prizes_admin_write"
  on public.prizes for all
  using (public.is_admin()) with check (public.is_admin());

-- ---------- app_config / exchange_rates / banned_words -----------------------
create policy "app_config_public_read"
  on public.app_config for select using (true);
create policy "app_config_admin_write"
  on public.app_config for all
  using (public.is_admin()) with check (public.is_admin());

create policy "exchange_rates_public_read"
  on public.exchange_rates for select using (true);
-- L'écriture des taux passe par Edge Function (service_role) — pas de policy.

create policy "banned_words_admin_select"
  on public.banned_words for select using (public.is_admin());
create policy "banned_words_admin_write"
  on public.banned_words for all
  using (public.is_admin()) with check (public.is_admin());

-- ---------- invitation_codes -------------------------------------------------
create policy "invitation_codes_super_admin"
  on public.invitation_codes for all
  using (public.is_super_admin())
  with check (public.is_super_admin());

-- ---------- matches ----------------------------------------------------------
create policy "matches_public_read"
  on public.matches for select using (true);

-- Les joueurs participants peuvent updater des champs précis (room_code, score
-- via Edge Function). Pour V1.0 on bloque l'UPDATE direct côté client : tout
-- passe par les Edge Functions submit_score_collaborative, etc.
create policy "matches_admin_write"
  on public.matches for all
  using (public.is_admin()) with check (public.is_admin());

-- ---------- bracket_nodes ----------------------------------------------------
create policy "bracket_nodes_public_read"
  on public.bracket_nodes for select using (true);
create policy "bracket_nodes_admin_write"
  on public.bracket_nodes for all
  using (public.is_admin()) with check (public.is_admin());

-- ---------- match_events -----------------------------------------------------
-- Lecture : participants au match + admin
create policy "match_events_select"
  on public.match_events for select
  using (
    public.is_admin()
    or exists (
      select 1 from public.matches m
      where m.id = match_id
        and (m.player1_id = auth.uid() or m.player2_id = auth.uid())
    )
  );
-- Écriture : Edge Functions (service_role) seulement.
create policy "match_events_admin_write"
  on public.match_events for all
  using (public.is_admin()) with check (public.is_admin());

-- ---------- anti_cheat_events ------------------------------------------------
-- Strictement admin (sensible).
create policy "anti_cheat_admin_only"
  on public.anti_cheat_events for all
  using (public.is_admin()) with check (public.is_admin());

-- ---------- chat_channels ----------------------------------------------------
-- Lecture libre des canaux match/broadcast (membership filtrée par chat_messages).
create policy "chat_channels_public_read"
  on public.chat_channels for select using (true);
create policy "chat_channels_admin_write"
  on public.chat_channels for all
  using (public.is_admin()) with check (public.is_admin());

-- ---------- chat_messages ----------------------------------------------------
-- Lecture : participants du match du channel + admin
create policy "chat_messages_select"
  on public.chat_messages for select
  using (
    public.is_admin()
    or exists (
      select 1
      from public.chat_channels c
      left join public.matches m on m.id = c.match_id
      where c.id = channel_id
        and (
          c.type in ('competition_broadcast', 'global')
          or (c.type = 'match'
              and (m.player1_id = auth.uid() or m.player2_id = auth.uid()))
        )
    )
  );

-- Écriture : un user n'envoie qu'un message dont il est l'auteur.
create policy "chat_messages_insert_self"
  on public.chat_messages for insert
  with check (sender_id = auth.uid());

create policy "chat_messages_admin_all"
  on public.chat_messages for all
  using (public.is_admin()) with check (public.is_admin());

-- ---------- payments ---------------------------------------------------------
-- L'utilisateur voit ses propres paiements ; admin voit tout.
create policy "payments_self_select"
  on public.payments for select
  using (user_id = auth.uid());
create policy "payments_admin_select"
  on public.payments for select
  using (public.is_admin());
-- Pas d'INSERT/UPDATE direct côté client : seules les Edge Functions
-- (service_role) écrivent les paiements après confirmation provider.

-- ---------- payouts ----------------------------------------------------------
create policy "payouts_self_select"
  on public.payouts for select
  using (user_id = auth.uid());
create policy "payouts_admin_select"
  on public.payouts for select
  using (public.is_admin());
-- Validation manuelle admin via Edge Function, pas d'écriture directe.

-- ---------- platform_revenue (admin only) ------------------------------------
create policy "platform_revenue_admin"
  on public.platform_revenue for select using (public.is_admin());

-- ---------- payment_webhook_log (admin only) ---------------------------------
create policy "payment_webhook_log_admin"
  on public.payment_webhook_log for select using (public.is_admin());

-- ---------- disputes ---------------------------------------------------------
-- Le user peut voir un dispute auquel il est partie + ouvrir un dispute.
create policy "disputes_party_select"
  on public.disputes for select
  using (
    opened_by = auth.uid()
    or public.is_admin()
    or exists (
      select 1 from public.matches m
      where m.id = match_id
        and (m.player1_id = auth.uid() or m.player2_id = auth.uid())
    )
  );

create policy "disputes_party_insert"
  on public.disputes for insert
  with check (
    opened_by = auth.uid()
    and exists (
      select 1 from public.matches m
      where m.id = match_id
        and (m.player1_id = auth.uid() or m.player2_id = auth.uid())
    )
  );

create policy "disputes_admin_all"
  on public.disputes for all
  using (public.is_admin()) with check (public.is_admin());

-- ---------- notifications ----------------------------------------------------
create policy "notifications_self_select"
  on public.notifications for select
  using (user_id = auth.uid());
create policy "notifications_self_update"
  on public.notifications for update
  using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy "notifications_admin_all"
  on public.notifications for all
  using (public.is_admin()) with check (public.is_admin());

-- ---------- admin_audit_log / auto_actions_log (admin only read) -------------
create policy "admin_audit_log_admin"
  on public.admin_audit_log for select using (public.is_admin());

create policy "auto_actions_log_admin"
  on public.auto_actions_log for select using (public.is_admin());

-- =============================================================================
-- INDEXES CRITIQUES (cf. PARTIE 4 du master)
-- =============================================================================

-- Profiles
create index if not exists idx_profiles_role
  on public.profiles(role);
create index if not exists idx_profiles_country
  on public.profiles(country_code);
create index if not exists idx_profiles_deleted
  on public.profiles(deleted_at) where deleted_at is not null;

-- Compétitions
create index if not exists idx_competitions_status
  on public.competitions(status);
create index if not exists idx_competitions_dates
  on public.competitions(start_date, end_date);
create index if not exists idx_competitions_game
  on public.competitions(game);

-- Compétition phases & groupes
create index if not exists idx_phases_competition
  on public.phases(competition_id, phase_order);
create index if not exists idx_groups_phase
  on public.groups(phase_id);
create index if not exists idx_memberships_group
  on public.group_memberships(group_id);
create index if not exists idx_memberships_profile
  on public.group_memberships(profile_id);

-- Prizes
create index if not exists idx_prizes_competition
  on public.prizes(competition_id);

-- Matches
create index if not exists idx_matches_status
  on public.matches(status);
create index if not exists idx_matches_competition
  on public.matches(competition_id);
create index if not exists idx_matches_phase
  on public.matches(phase_id);
create index if not exists idx_matches_players
  on public.matches(player1_id, player2_id);
create index if not exists idx_matches_streamed_live
  on public.matches(is_streamed, stream_status)
  where stream_status = 'live';
create index if not exists idx_matches_next
  on public.matches(next_match_id);

-- Bracket nodes (cf. spec L1379)
create index if not exists idx_bracket_nodes_phase
  on public.bracket_nodes(phase_id, round_number, position_in_round);
create index if not exists idx_bracket_nodes_match
  on public.bracket_nodes(match_id);
create index if not exists idx_bracket_nodes_parent
  on public.bracket_nodes(parent_node_id) where parent_node_id is not null;

-- Match events & anti-cheat
create index if not exists idx_match_events_match
  on public.match_events(match_id, created_at desc);
create index if not exists idx_anti_cheat_match
  on public.anti_cheat_events(match_id, created_at desc);
create index if not exists idx_anti_cheat_profile
  on public.anti_cheat_events(profile_id, created_at desc);

-- Chat
create index if not exists idx_chat_messages_channel
  on public.chat_messages(channel_id, created_at desc);
create index if not exists idx_chat_channels_match
  on public.chat_channels(match_id) where match_id is not null;

-- Paiements
create index if not exists idx_payments_user
  on public.payments(user_id, created_at desc);
create index if not exists idx_payments_competition
  on public.payments(competition_id);
create index if not exists idx_payments_status
  on public.payments(status);
create index if not exists idx_payments_provider_tx
  on public.payments(provider, provider_transaction_id);

-- Payouts
create index if not exists idx_payouts_status
  on public.payouts(status);
create index if not exists idx_payouts_user
  on public.payouts(user_id);
create index if not exists idx_payouts_admin_validation
  on public.payouts(status) where status = 'pending_admin_validation';

-- Webhooks logs
create index if not exists idx_webhook_log_provider
  on public.payment_webhook_log(provider, created_at desc);
create index if not exists idx_webhook_log_payment
  on public.payment_webhook_log(related_payment_id);

-- Disputes
create index if not exists idx_disputes_status
  on public.disputes(status);
create index if not exists idx_disputes_match
  on public.disputes(match_id);

-- Notifications
create index if not exists idx_notifications_user
  on public.notifications(user_id, created_at desc);
create index if not exists idx_notifications_unread
  on public.notifications(user_id) where read_at is null;

-- Audit & auto-actions
create index if not exists idx_admin_audit_admin
  on public.admin_audit_log(admin_id, created_at desc);
create index if not exists idx_auto_actions_function
  on public.auto_actions_log(edge_function, executed_at desc);

-- Invitation codes
create index if not exists idx_invitation_codes_unused
  on public.invitation_codes(code) where used_at is null;

-- Banned words (lookup rapide par lang)
create index if not exists idx_banned_words_language
  on public.banned_words(language);

-- Exchange rates
create index if not exists idx_exchange_rates_pair
  on public.exchange_rates(base_currency, quote_currency, fetched_at desc);

-- =============================================================================
-- SEED — Feature flags V1.0 (Afrique francophone)
-- =============================================================================
insert into public.app_config(key, value, description) values
  (
    'supported_languages',
    '["fr"]'::jsonb,
    'Langues actives en V1.0 (V1.1 ajoutera "en", V1.2 ajoutera "ar").'
  ),
  (
    'supported_currencies',
    '["XAF","XOF","USD"]'::jsonb,
    'Devises actives en V1.0.'
  ),
  (
    'supported_countries',
    '["CM","SN","CI","GA","BJ","TG","BF","ML","NE","TD","GN","CD","MG"]'::jsonb,
    '13 pays Afrique francophone V1.0.'
  ),
  (
    'cgu_version',
    '"1.0.0"'::jsonb,
    'Version actuelle des CGU.'
  ),
  (
    'commission_default_pct',
    '12'::jsonb,
    'Commission ARENA par défaut (modifiable par admin par compétition).'
  ),
  (
    'feature_flags',
    '{
      "social_login_google": false,
      "social_login_apple": false,
      "streaming_finals_only": true,
      "anti_cheat_recording": true,
      "crypto_payouts": false
    }'::jsonb,
    'Feature flags pour activation progressive (V1.0 démarre conservateur).'
  )
on conflict (key) do nothing;
