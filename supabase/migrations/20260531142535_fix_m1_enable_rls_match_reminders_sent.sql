-- =============================================================================
-- ARENA — Sécurité — m1 : RLS deny-all sur `match_reminders_sent`
-- =============================================================================
-- `match_reminders_sent` (20260526110000_match_reminders.sql:23-29) est la
-- seule table publique sans RLS (advisor Supabase niveau ERROR
-- `rls_disabled_in_public`). Elle n'est écrite que par la fonction
-- `_dispatch_match_reminders()` (SECURITY DEFINER, EXECUTE révoqué à
-- public/authenticated/anon), appelée par pg_cron.
--
-- On active RLS SANS aucune policy → deny-all par défaut pour les rôles
-- authenticated/anon via PostgREST. La fonction DEFINER (owner = propriétaire
-- de la table) continue d'insérer car le propriétaire bypasse RLS. Aucune
-- lecture client n'est nécessaire (ledger d'idempotence interne).
-- =============================================================================
-- Depends on: 20260526110000_match_reminders.sql
-- =============================================================================

alter table public.match_reminders_sent enable row level security;

comment on table public.match_reminders_sent is
  'Ledger idempotence rappels match auto (T-60/30/10/5). RLS deny-all : ecrit '
  'uniquement par _dispatch_match_reminders() (SECURITY DEFINER / pg_cron), '
  'aucun acces client.';
