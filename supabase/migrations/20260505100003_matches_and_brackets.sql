-- =============================================================================
-- ARENA — Phase 0 — Migration 3/5
-- Matches + Brackets + Match events + Anti-cheat events
-- =============================================================================
-- Dépend de : 20260505100002 (profiles, competitions, phases, groups)
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 1. matches
--    Match entre 2 joueurs — avec configuration streaming Agora sélectif.
--    Aligné verbatim sur PARTIE 4 du master prompt.
-- -----------------------------------------------------------------------------
create table if not exists public.matches (
  id uuid primary key default uuid_generate_v4(),
  competition_id uuid not null
    references public.competitions on delete cascade,
  phase_id uuid
    references public.phases on delete cascade,
  group_id uuid
    references public.groups on delete cascade,
  round int,
  match_number int,

  -- Joueurs (peuvent être null tant que bracket pas finalisé)
  player1_id uuid references public.profiles on delete set null,
  player2_id uuid references public.profiles on delete set null,
  score1 int,
  score2 int,
  winner_id uuid references public.profiles on delete set null,

  -- Statut & meta match-room
  status public.match_status not null default 'pending',
  home_player_id uuid references public.profiles on delete set null,
  room_code text,

  -- STREAMING (Agora RTC sélectif)
  is_streamed boolean not null default false,
  streaming_activation_type text
    check (streaming_activation_type in ('auto_final', 'manual_admin', 'auto_premium')),
  streaming_activated_by_admin_id uuid
    references public.profiles on delete set null,
  streaming_activated_at timestamptz,
  agora_stream_channel text,
  stream_status text not null default 'none'
    check (stream_status in ('none', 'pending', 'live', 'ended')),
  stream_started_at timestamptz,
  stream_ended_at timestamptz,
  current_viewers_count int not null default 0,
  peak_viewers_count int not null default 0,

  -- Timing & avancée bracket
  scheduled_at timestamptz,
  started_at timestamptz,
  finished_at timestamptz,
  next_match_id uuid references public.matches on delete set null,

  -- Configuration spécifique (ex: phase de groupes)
  match_config jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),

  -- Garde-fous logiques
  check (player1_id is null or player2_id is null or player1_id <> player2_id),
  check (winner_id is null or winner_id = player1_id or winner_id = player2_id)
);

create trigger trg_matches_updated_at
  before update on public.matches
  for each row execute function public.set_updated_at();

comment on table public.matches is
  'Match entre 2 joueurs (incluant config streaming Agora sélectif).';

-- -----------------------------------------------------------------------------
-- 2. bracket_nodes
--    Arbre du bracket (single elimination ou knockout phase)
--    Aligné sur la spec ARENA_FLUTTER_PROMPT.md L1356-1380 :
--      phase_id + round_number/position_in_round/total_rounds
--      + parent_node_id + is_grand_final + is_third_place_match.
--    Extensions locales conservées : is_bye / bye_player_id (gestion des
--    tableaux à 12/24/48 joueurs) et next_position (utilisé par le
--    trigger cascade_match_winner).
-- -----------------------------------------------------------------------------
create table if not exists public.bracket_nodes (
  id uuid primary key default uuid_generate_v4(),
  phase_id uuid not null
    references public.phases on delete cascade,
  competition_id uuid not null
    references public.competitions on delete cascade,

  -- Position dans l'arbre
  round_number int not null check (round_number >= 1),
  position_in_round int not null check (position_in_round >= 0),
  total_rounds int not null check (total_rounds >= 1),

  -- Match associé (peut rester null tant que pas instancié)
  match_id uuid
    references public.matches on delete set null,

  -- Liens dans l'arbre
  next_node_id uuid references public.bracket_nodes on delete set null,
  parent_node_id uuid references public.bracket_nodes on delete set null,
  next_position text check (next_position in ('player1', 'player2')),

  -- Spéciaux
  is_grand_final boolean not null default false,
  is_third_place_match boolean not null default false,

  -- Bye (joueur passe directement au tour suivant)
  is_bye boolean not null default false,
  bye_player_id uuid references public.profiles on delete set null,

  created_at timestamptz not null default now(),
  unique (phase_id, round_number, position_in_round)
);

comment on table public.bracket_nodes is
  'Nœuds de l''arbre du bracket — un par emplacement de match dans une phase.';

-- -----------------------------------------------------------------------------
-- 3. match_events
--    Timeline des événements d'un match (validation collaborative scores,
--    contestations, ajustements admin, etc.)
-- -----------------------------------------------------------------------------
create table if not exists public.match_events (
  id uuid primary key default uuid_generate_v4(),
  match_id uuid not null
    references public.matches on delete cascade,
  type text not null check (type in (
    'match_started',
    'goal',
    'score_submitted',
    'score_validated',
    'score_disputed',
    'forfeit',
    'admin_adjustment',
    'match_finished'
  )),
  payload jsonb not null default '{}'::jsonb,
  created_by uuid references public.profiles on delete set null,
  created_at timestamptz not null default now()
);

comment on table public.match_events is
  'Timeline des événements d''un match — utilisé par le bot d''arbitrage.';

-- -----------------------------------------------------------------------------
-- 4. anti_cheat_events
--    Alertes anomalies recording (focus perdu, recording stoppé, etc.)
-- -----------------------------------------------------------------------------
create table if not exists public.anti_cheat_events (
  id uuid primary key default uuid_generate_v4(),
  match_id uuid references public.matches on delete cascade,
  profile_id uuid not null
    references public.profiles on delete cascade,
  type text not null check (type in (
    'window_focus_lost',
    'recording_interrupted',
    'overlay_disabled',
    'app_killed',
    'screen_off',
    'suspicious_input',
    'duplicate_account_attempt'
  )),
  severity int not null default 1 check (severity between 1 and 3),
  data jsonb not null default '{}'::jsonb,
  recording_url text,
  created_at timestamptz not null default now()
);

comment on table public.anti_cheat_events is
  'Anomalies détectées par l''anti-cheat (recording, overlay, app focus).';

-- -----------------------------------------------------------------------------
-- TRIGGER : cascade_match_winner
--   Quand un match passe à 'completed' avec un winner_id, on fait avancer
--   automatiquement le gagnant dans le next_match (via next_match_id +
--   bracket_nodes.next_position si renseigné).
--
--   Logique simplifiée pour V1.0 :
--   - on lit le bracket_node du match courant pour connaître next_position
--   - on remplit player1_id ou player2_id du match suivant
-- -----------------------------------------------------------------------------
create or replace function public.cascade_match_winner()
returns trigger
language plpgsql
as $$
declare
  v_next_position text;
begin
  -- Ne réagit qu'au passage à completed avec un winner défini
  if (new.status = 'completed' and new.winner_id is not null
      and new.next_match_id is not null
      and (old.status is distinct from new.status
           or old.winner_id is distinct from new.winner_id)) then

    -- Récupère la position de destination (player1 / player2)
    select bn.next_position into v_next_position
    from public.bracket_nodes bn
    where bn.match_id = new.id
    limit 1;

    if v_next_position = 'player1' then
      update public.matches
        set player1_id = new.winner_id
        where id = new.next_match_id and player1_id is null;
    elsif v_next_position = 'player2' then
      update public.matches
        set player2_id = new.winner_id
        where id = new.next_match_id and player2_id is null;
    end if;
  end if;
  return new;
end;
$$;

create trigger trg_matches_cascade_winner
  after update on public.matches
  for each row execute function public.cascade_match_winner();

comment on function public.cascade_match_winner is
  'Avance automatiquement le winner dans le next match selon bracket_nodes.';
