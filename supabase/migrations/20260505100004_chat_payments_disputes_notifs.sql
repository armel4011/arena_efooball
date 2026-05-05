-- =============================================================================
-- ARENA — Phase 0 — Migration 4/5
-- Chat (channels + messages) + Paiements (payments, payouts, revenue,
-- webhook log) + Litiges (disputes) + Notifications
-- =============================================================================
-- Dépend de : 20260505100002 (profiles, competitions), 20260505100003 (matches)
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 1. chat_channels
--    Canaux de chat (1-on-1 match, broadcast compétition, support admin)
-- -----------------------------------------------------------------------------
create table if not exists public.chat_channels (
  id uuid primary key default uuid_generate_v4(),
  type text not null check (type in (
    'match',
    'competition_broadcast',
    'admin_user',
    'global'
  )),
  match_id uuid references public.matches on delete cascade,
  competition_id uuid references public.competitions on delete cascade,
  name text,
  is_archived boolean not null default false,
  created_at timestamptz not null default now(),

  -- Cohérence : un channel 'match' DOIT être lié à un match, etc.
  check (
    (type = 'match' and match_id is not null)
    or (type = 'competition_broadcast' and competition_id is not null)
    or (type in ('admin_user', 'global'))
  )
);

comment on table public.chat_channels is
  'Canaux de chat (match 1-on-1, broadcast, support admin, global).';

-- -----------------------------------------------------------------------------
-- 2. chat_messages
--    Messages persistants (Supabase Realtime). Présence/typing = Agora RTM.
-- -----------------------------------------------------------------------------
create table if not exists public.chat_messages (
  id uuid primary key default uuid_generate_v4(),
  channel_id uuid not null
    references public.chat_channels on delete cascade,
  sender_id uuid references public.profiles on delete set null,
  content text not null check (length(content) between 1 and 2000),
  type text not null default 'text'
    check (type in ('text', 'system', 'image')),

  -- Modération automatique (Edge Function moderate_chat_message)
  is_moderated boolean not null default false,
  moderated_at timestamptz,
  moderated_reason text,

  created_at timestamptz not null default now()
);

comment on table public.chat_messages is
  'Messages persistants (texte/image/système). Présence = Agora RTM séparé.';

-- -----------------------------------------------------------------------------
-- 3. payments
--    Paiements ENTRANTS (frais d'inscription compétition).
-- -----------------------------------------------------------------------------
create table if not exists public.payments (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid not null
    references public.profiles on delete restrict,
  competition_id uuid not null
    references public.competitions on delete restrict,

  -- Montants
  amount_local numeric(15, 2) not null check (amount_local > 0),
  amount_usd numeric(15, 2),
  currency text not null,
  exchange_rate numeric(20, 8),

  -- Provider
  provider text not null check (provider in ('cinetpay', 'nowpayments')),
  provider_method text,
  provider_transaction_id text,
  provider_response jsonb not null default '{}'::jsonb,

  -- Statut
  status text not null default 'pending' check (status in (
    'pending',
    'processing',
    'succeeded',
    'failed',
    'refunded',
    'expired'
  )),

  -- Idempotence (anti-double-paiement sur webhooks rejoués)
  idempotency_key text unique,

  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create trigger trg_payments_updated_at
  before update on public.payments
  for each row execute function public.set_updated_at();

comment on table public.payments is
  'Paiements entrants (frais d''inscription) — CinetPay / NowPayments.';

-- -----------------------------------------------------------------------------
-- 4. payouts
--    Versements SORTANTS (gains aux joueurs Top 4).
--    Aligné verbatim sur PARTIE 4 du master prompt.
-- -----------------------------------------------------------------------------
create table if not exists public.payouts (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid not null
    references public.profiles on delete restrict,
  competition_id uuid not null
    references public.competitions on delete restrict,
  prize_id uuid not null
    references public.prizes on delete restrict,

  -- Montants
  amount_usd numeric(15, 2) not null check (amount_usd > 0),
  amount_local numeric(15, 2) not null,
  currency text not null,
  exchange_rate numeric(20, 8),

  -- Statut (workflow strict)
  status text not null default 'pending_admin_validation' check (status in (
    'pending_admin_validation',
    'validated',
    'processing',
    'completed',
    'failed',
    'refunded',
    'cancelled'
  )),

  -- Validation admin (audit trail)
  validated_by_admin_id uuid references public.profiles on delete set null,
  validated_at timestamptz,
  validation_justification text,

  -- 5 contrôles auto (KYC, no dispute, no anti-cheat alert, not banned, data ok)
  auto_checks jsonb not null default '{}'::jsonb,

  -- Provider
  payout_provider text check (payout_provider in ('cinetpay', 'nowpayments')),
  payout_method text,
  payout_destination jsonb,
  provider_transaction_id text,
  provider_response jsonb not null default '{}'::jsonb,

  -- Timestamps
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  scheduled_for timestamptz,
  completed_at timestamptz,

  unique (user_id, prize_id)
);

create trigger trg_payouts_updated_at
  before update on public.payouts
  for each row execute function public.set_updated_at();

comment on table public.payouts is
  'Versements sortants (gains Top 4) — validation admin manuelle obligatoire.';

-- -----------------------------------------------------------------------------
-- 5. platform_revenue
--    Commissions ARENA (10-15%) + sponsoring éventuel.
-- -----------------------------------------------------------------------------
create table if not exists public.platform_revenue (
  id uuid primary key default uuid_generate_v4(),
  competition_id uuid references public.competitions on delete restrict,
  payment_id uuid references public.payments on delete restrict,
  kind text not null check (kind in ('commission', 'sponsorship', 'other')),
  amount_local numeric(15, 2) not null,
  amount_usd numeric(15, 2),
  currency text not null,
  recorded_at timestamptz not null default now()
);

comment on table public.platform_revenue is
  'Revenus ARENA (commissions + sponsoring). Source de vérité comptable.';

-- -----------------------------------------------------------------------------
-- 6. payment_webhook_log
--    Logs bruts des webhooks providers (CinetPay, NowPayments).
--    Idempotence + débogage + replay.
-- -----------------------------------------------------------------------------
create table if not exists public.payment_webhook_log (
  id uuid primary key default uuid_generate_v4(),
  provider text not null,
  event_type text,
  signature_valid boolean,
  payload jsonb not null,
  related_payment_id uuid references public.payments on delete set null,
  related_payout_id uuid references public.payouts on delete set null,
  processed_at timestamptz,
  error text,
  created_at timestamptz not null default now()
);

comment on table public.payment_webhook_log is
  'Logs des webhooks providers paiement — idempotence + débogage.';

-- -----------------------------------------------------------------------------
-- 7. disputes
--    Litiges sur match (score contesté). Workflow : open → bot_review →
--    admin_review → resolved/closed.
-- -----------------------------------------------------------------------------
create table if not exists public.disputes (
  id uuid primary key default uuid_generate_v4(),
  match_id uuid not null
    references public.matches on delete cascade,
  opened_by uuid not null
    references public.profiles on delete restrict,

  status text not null default 'open' check (status in (
    'open',
    'bot_review',
    'admin_review',
    'resolved',
    'closed'
  )),
  reason text,
  evidence jsonb not null default '{}'::jsonb,

  -- Escalation : 0 = bot, 1 = admin junior, 2 = admin senior, 3 = super-admin
  escalation_level int not null default 0
    check (escalation_level between 0 and 3),
  bot_attempted_at timestamptz,
  escalated_at timestamptz,

  resolved_at timestamptz,
  resolved_by uuid references public.profiles on delete set null,
  resolution text,

  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create trigger trg_disputes_updated_at
  before update on public.disputes
  for each row execute function public.set_updated_at();

comment on table public.disputes is
  'Litiges sur scores (bot d''arbitrage → admin si échec).';

-- -----------------------------------------------------------------------------
-- 8. notifications
--    Notifications push + in-app (FCM côté user + insert ici).
-- -----------------------------------------------------------------------------
create table if not exists public.notifications (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid not null
    references public.profiles on delete cascade,
  type text not null,
  title text not null,
  body text,
  data jsonb not null default '{}'::jsonb,
  read_at timestamptz,
  sent_at timestamptz,
  created_at timestamptz not null default now()
);

comment on table public.notifications is
  'Notifications utilisateur (push FCM + in-app).';
