-- ─────────────────────────────────────────────────────────────────────
-- Dames — état des règles de nulle FMJD fines (répétition + endgames).
-- ─────────────────────────────────────────────────────────────────────
-- Le compteur stérile (25 coups) existait déjà via la reconstruction depuis
-- board_fen ; on persiste en plus :
--   • endgame_plies   : demi-coups depuis l'entrée dans une config d'endgame
--                       à nulle accélérée (16 coups / 5 coups).
--   • position_counts : occurrences par position (clé FEN plateau+trait) pour
--                       la règle de répétition triple.
-- L'Edge Function (autorité) thread ces compteurs à chaque coup — pas besoin
-- de rejouer toute la partie.
-- ─────────────────────────────────────────────────────────────────────

alter table public.draughts_games
  add column if not exists endgame_plies   integer not null default 0,
  add column if not exists position_counts jsonb   not null default '{}'::jsonb;
