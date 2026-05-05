-- =============================================================================
-- ARENA — Phase 0 — Migration 2/5
-- Core user (profiles) + Compétitions + tables globales (config, rates, codes,
-- banned_words)
-- =============================================================================
-- Dépend de : 20260505100001 (ENUMs user_role, competition_status, phase_type,
--                              tournament_format + fonction set_updated_at)
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 1. profiles (1ère table — pivot)
--    Aligné sur PARTIE 4 du master prompt + lib/data/models/profile.dart
-- -----------------------------------------------------------------------------
create table if not exists public.profiles (
  id uuid primary key references auth.users on delete cascade,
  username text unique not null check (length(username) between 3 and 20),
  email text unique not null,
  country_code text not null check (length(country_code) = 2),
  avatar_color text not null default '#4C7AFF',
  role public.user_role not null default 'player',
  is_active boolean not null default true,
  fcm_token text,
  stats jsonb not null default
    '{"wins":0,"losses":0,"goals_scored":0,"goals_conceded":0}'::jsonb,

  -- Authentification (méthode d'inscription)
  auth_provider text not null default 'email'
    check (auth_provider in ('email', 'google', 'apple')),
  auth_provider_id text,

  -- Internationalisation
  preferred_language text not null default 'fr',
  preferred_currency text not null default 'XAF',
  timezone text not null default 'Africa/Douala',

  -- Onboarding
  onboarding_completed boolean not null default false,
  onboarding_completed_at timestamptz,

  -- Auth admin (TOTP) — server-only, jamais lu côté client
  totp_secret text,
  totp_enabled boolean not null default false,
  backup_codes jsonb not null default '[]'::jsonb,

  -- Conformité légale
  cgu_accepted_at timestamptz,
  cgu_version_accepted text,
  privacy_policy_accepted_at timestamptz,
  marketing_consent boolean not null default false,

  -- RGPD : suppression de compte (soft-delete)
  account_deletion_requested_at timestamptz,
  account_deletion_reason text,
  deleted_at timestamptz,

  -- KYC (pour gros payouts)
  kyc_status text not null default 'none'
    check (kyc_status in ('none', 'pending', 'verified', 'rejected')),
  kyc_verified_at timestamptz,

  -- Timestamps
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create trigger trg_profiles_updated_at
  before update on public.profiles
  for each row execute function public.set_updated_at();

comment on table public.profiles is
  'Utilisateurs ARENA (joueurs + admins + super-admins). Lié à auth.users.';

-- -----------------------------------------------------------------------------
-- 2. competitions
--    Tournois e-sport — créés par admins
-- -----------------------------------------------------------------------------
create table if not exists public.competitions (
  id uuid primary key default uuid_generate_v4(),
  name text not null,
  game text not null check (game in ('efootball', 'fifa_mobile', 'ea_sports_fc')),
  description text,
  banner_url text,

  -- Format & statut
  format public.tournament_format not null,
  status public.competition_status not null default 'draft',

  -- Dates clés
  registration_opens_at timestamptz,
  registration_closes_at timestamptz,
  start_date timestamptz not null,
  end_date timestamptz,

  -- Capacité
  max_players int not null check (max_players >= 2),
  current_players int not null default 0,

  -- Inscription & commission
  registration_fee numeric(15, 2) not null default 0
    check (registration_fee >= 0),
  registration_currency text not null,
  commission_pct numeric(5, 2) not null default 10
    check (commission_pct between 0 and 100),

  -- Cagnotte (calculée + sponsoring)
  prize_pool_local numeric(15, 2) not null default 0,
  prize_pool_currency text,
  sponsor_bonus_local numeric(15, 2) not null default 0,

  -- Métadonnées
  created_by uuid references public.profiles on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create trigger trg_competitions_updated_at
  before update on public.competitions
  for each row execute function public.set_updated_at();

comment on table public.competitions is
  'Tournois e-sport — créés par les admins.';

-- -----------------------------------------------------------------------------
-- 3. phases
--    Une compétition = N phases (groupes, knockout, round_robin) ordonnées
-- -----------------------------------------------------------------------------
create table if not exists public.phases (
  id uuid primary key default uuid_generate_v4(),
  competition_id uuid not null
    references public.competitions on delete cascade,
  phase_order int not null check (phase_order >= 1),
  type public.phase_type not null,
  status text not null default 'pending'
    check (status in ('pending', 'ongoing', 'completed')),
  config jsonb not null default '{}'::jsonb,
  started_at timestamptz,
  finished_at timestamptz,
  created_at timestamptz not null default now(),
  unique (competition_id, phase_order)
);

comment on table public.phases is
  'Phases d''une compétition (groups, knockout, round_robin).';

-- -----------------------------------------------------------------------------
-- 4. groups
--    Groupes en phase de poules (8 joueurs → 2 groupes de 4 par ex.)
-- -----------------------------------------------------------------------------
create table if not exists public.groups (
  id uuid primary key default uuid_generate_v4(),
  competition_id uuid not null
    references public.competitions on delete cascade,
  phase_id uuid not null
    references public.phases on delete cascade,
  name text not null,
  group_number int not null check (group_number >= 1),
  created_at timestamptz not null default now(),
  unique (phase_id, group_number)
);

comment on table public.groups is
  'Groupes pour la phase de poules d''une compétition.';

-- -----------------------------------------------------------------------------
-- 5. group_memberships
--    Affectation joueur ↔ groupe + classement live (points, GF/GA/GD)
-- -----------------------------------------------------------------------------
create table if not exists public.group_memberships (
  id uuid primary key default uuid_generate_v4(),
  group_id uuid not null
    references public.groups on delete cascade,
  profile_id uuid not null
    references public.profiles on delete cascade,
  position int,
  points int not null default 0,
  played int not null default 0,
  wins int not null default 0,
  draws int not null default 0,
  losses int not null default 0,
  goals_for int not null default 0,
  goals_against int not null default 0,
  goal_diff int generated always as (goals_for - goals_against) stored,
  created_at timestamptz not null default now(),
  unique (group_id, profile_id)
);

comment on table public.group_memberships is
  'Joueurs dans un groupe + classement live (P/Pts/V/N/D/BP/BC/Diff).';

-- -----------------------------------------------------------------------------
-- 6. prizes
--    Top 4 récompensé — mode pourcentage OU montant fixe
--    Aligné verbatim sur le master prompt (PARTIE 4).
-- -----------------------------------------------------------------------------
create table if not exists public.prizes (
  id uuid primary key default uuid_generate_v4(),
  competition_id uuid not null
    references public.competitions on delete cascade,
  position int not null check (position between 1 and 4),

  -- Mode flexible
  prize_mode text not null check (prize_mode in ('percentage', 'fixed')),
  percentage_value numeric(5, 2),
  fixed_amount numeric(15, 2),
  fixed_currency text,

  -- Calculé au moment du paiement
  final_amount_usd numeric(15, 2),
  final_amount_local numeric(15, 2),
  final_currency text,

  -- Display
  display_name text,

  unique (competition_id, position),

  -- Garde-fou : un mode → ses champs requis, l'autre → null
  check (
    (prize_mode = 'percentage' and percentage_value is not null
       and fixed_amount is null and fixed_currency is null)
    or
    (prize_mode = 'fixed' and fixed_amount is not null
       and fixed_currency is not null and percentage_value is null)
  )
);

comment on table public.prizes is
  'Top 4 récompenses d''une compétition (mode % ou montant fixe).';

-- -----------------------------------------------------------------------------
-- 7. app_config
--    Feature flags + configuration globale (langues actives, devises, etc.)
-- -----------------------------------------------------------------------------
create table if not exists public.app_config (
  id uuid primary key default uuid_generate_v4(),
  key text unique not null,
  value jsonb not null,
  description text,
  updated_at timestamptz not null default now()
);

create trigger trg_app_config_updated_at
  before update on public.app_config
  for each row execute function public.set_updated_at();

comment on table public.app_config is
  'Feature flags + config globale (langues, devises, versions CGU…).';

-- -----------------------------------------------------------------------------
-- 8. exchange_rates
--    Cache des taux de change (USD pivot)
-- -----------------------------------------------------------------------------
create table if not exists public.exchange_rates (
  id uuid primary key default uuid_generate_v4(),
  base_currency text not null,
  quote_currency text not null,
  rate numeric(20, 8) not null check (rate > 0),
  source text,
  fetched_at timestamptz not null default now(),
  unique (base_currency, quote_currency)
);

comment on table public.exchange_rates is
  'Cache taux de change (rafraîchi par Edge Function).';

-- -----------------------------------------------------------------------------
-- 9. invitation_codes
--    Codes pour créer de nouveaux comptes admin / super-admin
-- -----------------------------------------------------------------------------
create table if not exists public.invitation_codes (
  id uuid primary key default uuid_generate_v4(),
  code text unique not null,
  role public.user_role not null default 'admin'
    check (role in ('admin', 'super_admin')),
  generated_by uuid references public.profiles on delete set null,
  expires_at timestamptz not null,
  used_at timestamptz,
  used_by uuid references public.profiles on delete set null,
  created_at timestamptz not null default now()
);

comment on table public.invitation_codes is
  'Codes d''invitation à usage unique pour créer admins/super-admins.';

-- -----------------------------------------------------------------------------
-- 10. banned_words
--     Liste de mots filtrés par l'Edge Function moderate_chat_message
-- -----------------------------------------------------------------------------
create table if not exists public.banned_words (
  id uuid primary key default uuid_generate_v4(),
  word text not null,
  language text not null default 'fr',
  severity int not null default 1 check (severity between 1 and 3),
  category text,
  created_at timestamptz not null default now(),
  unique (word, language)
);

comment on table public.banned_words is
  'Mots interdits pour la modération automatique du chat.';
