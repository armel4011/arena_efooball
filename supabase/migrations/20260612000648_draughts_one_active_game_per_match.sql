-- ─────────────────────────────────────────────────────────────────
-- Draughts : une seule partie ACTIVE par match
-- ─────────────────────────────────────────────────────────────────
-- RÉGÉNÉRÉE depuis la prod le 2026-06-14 (audit reproductibilité). Appliquée
-- via MCP le 2026-06-12 mais jamais commitée → absente d'un replay
-- from-scratch. DDL conforme à l'état prod. Idempotente.
--
-- Invariant : `draughts-game` (EF autorité serveur) crée une partie en
-- statut `active`. Sans cette contrainte, une race / un double-appel pouvait
-- ouvrir 2 parties actives pour le même match → score ambigu. L'index unique
-- PARTIEL (WHERE status='active') autorise plusieurs parties terminées par
-- match (historique / best-of) mais une seule active à la fois.
create unique index if not exists draughts_games_one_active_per_match
  on public.draughts_games (match_id)
  where (status = 'active');
