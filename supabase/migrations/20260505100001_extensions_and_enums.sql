-- =============================================================================
-- ARENA — Phase 0 — Migration 1/5
-- Extensions, ENUMs, fonction utilitaire updated_at
-- =============================================================================
-- Idempotent : peut être rejouée sans erreur (create ... if not exists).
-- =============================================================================

-- -----------------------------------------------------------------------------
-- Extensions (uuid-ossp, pgcrypto, pg_cron déjà activés par Supabase)
-- -----------------------------------------------------------------------------
create extension if not exists "uuid-ossp";
create extension if not exists pgcrypto;

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
