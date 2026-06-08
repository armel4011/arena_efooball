-- ─────────────────────────────────────────────────────────────────────
-- Dames internationales in-app — Phase 2 : schéma de persistance.
-- ─────────────────────────────────────────────────────────────────────
-- Une compétition `draughts` se joue désormais DANS l'app (plateau 10×10),
-- au lieu du système déclaratif (score saisi à la main). L'état et l'historique
-- des coups sont persistés ici ; l'AUTORITÉ (validation de chaque coup, horloge,
-- fin de partie) est tenue par l'Edge Function `draughts-apply-move` (service_role)
-- — décision d'audit « validation serveur dure ».
--
-- Mort subite : en élimination directe, une partie nulle est rejouée jusqu'à
-- décision → PLUSIEURS parties possibles par match (d'où game_number, et
-- match_id NON unique). En poule, la nulle est acceptée (1 seule partie).
--
-- Accès : les 2 joueurs (et les admins) LISENT leur partie ; PERSONNE n'écrit
-- en direct (aucune policy insert/update pour authenticated) → tout passe par
-- l'Edge Function en service_role, qui bypasse la RLS.
-- ─────────────────────────────────────────────────────────────────────

-- 1. Une partie de dames (1+ par match en cas de mort subite).
create table public.draughts_games (
  id             uuid primary key default gen_random_uuid(),
  match_id       uuid not null references public.matches(id) on delete cascade,
  game_number    int  not null default 1,
  white_id       uuid not null references public.profiles(id) on delete cascade,
  black_id       uuid not null references public.profiles(id) on delete cascade,
  current_turn   text not null default 'white'
                   check (current_turn in ('white', 'black')),
  board_fen      text not null,            -- état courant (FEN-like, moteur)
  ply            int  not null default 0,  -- nb de demi-coups joués
  sterile_plies  int  not null default 0,  -- demi-coups sans prise/mvt pion (nulle)
  status         text not null default 'active'
                   check (status in
                     ('active', 'white_won', 'black_won', 'draw', 'aborted')),
  white_clock_ms bigint,                   -- temps restant (null = sans horloge)
  black_clock_ms bigint,
  last_move_at   timestamptz not null default now(),
  created_at     timestamptz not null default now(),
  updated_at     timestamptz not null default now(),
  unique (match_id, game_number)
);

create index idx_draughts_games_match on public.draughts_games (match_id);

comment on table public.draughts_games is
  'Partie de dames 10×10 in-app liée à un match. Plusieurs lignes par match '
  'possibles (mort subite). Écriture réservée à l''Edge Function (service_role).';

-- 2. Historique des coups (replay + autorité + anti-rejeu).
create table public.draughts_moves (
  id              uuid primary key default gen_random_uuid(),
  game_id         uuid not null references public.draughts_games(id)
                    on delete cascade,
  ply             int  not null,            -- séquentiel (anti-rejeu)
  player_id       uuid not null references public.profiles(id) on delete cascade,
  move_json       jsonb not null,           -- {from,to,captured[],path[]}
  board_after_fen text not null,            -- état résultant (autorité)
  parent_fen_hash text not null,            -- hash de l'état parent (continuité)
  created_at      timestamptz not null default now(),
  unique (game_id, ply)
);

create index idx_draughts_moves_game_ply on public.draughts_moves (game_id, ply);

comment on table public.draughts_moves is
  'Coups d''une partie de dames (replay/arbitrage). Écriture service_role only.';

-- 3. RLS — lecture par les 2 joueurs + admins ; aucune écriture directe.
alter table public.draughts_games enable row level security;
alter table public.draughts_moves enable row level security;

create policy draughts_games_player_select on public.draughts_games
  for select using (
    (select auth.uid()) = white_id
    or (select auth.uid()) = black_id
    or public.is_admin()
  );

create policy draughts_moves_player_select on public.draughts_moves
  for select using (
    exists (
      select 1 from public.draughts_games g
      where g.id = draughts_moves.game_id
        and (
          (select auth.uid()) = g.white_id
          or (select auth.uid()) = g.black_id
          or public.is_admin()
        )
    )
  );

-- Pas de policy insert/update/delete pour authenticated : l'Edge Function
-- (service_role) bypasse la RLS et reste la seule voie d'écriture.

-- 4. Realtime — sans ça, la synchro temps réel des coups ne fonctionne pas.
alter publication supabase_realtime add table public.draughts_games;
alter publication supabase_realtime add table public.draughts_moves;
