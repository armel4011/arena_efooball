-- =============================================================================
-- ARENA — Phase 0 — Migration 1/5
-- Extensions, ENUMs, fonction utilitaire updated_at
-- =============================================================================
-- Idempotent : peut être rejouée sans erreur (create ... if not exists).
-- =============================================================================

-- -----------------------------------------------------------------------------
-- Extensions (uuid-ossp, pgcrypto, pg_cron, pg_net)
-- -----------------------------------------------------------------------------
create extension if not exists "uuid-ossp";
create extension if not exists pgcrypto;

-- pg_cron / pg_net sont préinstallés sur le projet hébergé Supabase, mais PAS
-- créés sur le stack local / CI (`supabase start`) — d'où l'échec historique du
-- job "DB tests (pgTAP RLS)" : `relation "cron.job" does not exist`, qui avorte
-- toute la séquence avant d'atteindre les tests. On les crée ici de façon
-- idempotente et tolérante : no-op en prod (déjà présents), créés sur le stack
-- local (l'image supabase/postgres les précharge via shared_preload_libraries).
-- Si une image ne les supporte pas, on skip avec un NOTICE plutôt que d'avorter.
do $$
begin
  create extension if not exists pg_cron;
exception when others then
  raise notice 'pg_cron indisponible (% — %), création ignorée.', sqlstate, sqlerrm;
end $$;

do $$
begin
  create extension if not exists pg_net;
exception when others then
  raise notice 'pg_net indisponible (% — %), création ignorée.', sqlstate, sqlerrm;
end $$;

-- -----------------------------------------------------------------------------
-- ENUM : user_role
--   Aligné sur lib/data/models/user_role.dart
-- -----------------------------------------------------------------------------
do $$ begin
  create type public.user_role as enum ('player', 'admin', 'super_admin');
exception
  when duplicate_object then null;
end $$;

-- -----------------------------------------------------------------------------
-- ENUM : competition_status
-- -----------------------------------------------------------------------------
do $$ begin
  create type public.competition_status as enum (
    'draft',
    'registration_open',
    'registration_closed',
    'ongoing',
    'completed',
    'cancelled'
  );
exception
  when duplicate_object then null;
end $$;

-- -----------------------------------------------------------------------------
-- ENUM : match_status
-- -----------------------------------------------------------------------------
do $$ begin
  create type public.match_status as enum (
    'pending',
    'scheduled',
    'ready',
    'in_progress',
    'score_pending',
    'awaiting_validation',
    'disputed',
    'completed',
    'cancelled',
    'forfeited'
  );
exception
  when duplicate_object then null;
end $$;

-- -----------------------------------------------------------------------------
-- ENUM : phase_type
-- -----------------------------------------------------------------------------
do $$ begin
  create type public.phase_type as enum ('groups', 'knockout', 'round_robin');
exception
  when duplicate_object then null;
end $$;

-- -----------------------------------------------------------------------------
-- ENUM : tournament_format
-- -----------------------------------------------------------------------------
do $$ begin
  create type public.tournament_format as enum (
    'single_elimination',
    'groups_then_knockout',
    'round_robin'
  );
exception
  when duplicate_object then null;
end $$;

-- -----------------------------------------------------------------------------
-- Fonction trigger : timestamp updated_at automatique
--   À utiliser via : create trigger ... before update on <table>
--                   for each row execute function public.set_updated_at();
-- -----------------------------------------------------------------------------
create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

comment on function public.set_updated_at is
  'Trigger function: stamps updated_at with now() on row update.';
