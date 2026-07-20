-- ─────────────────────────────────────────────────────────────────────
-- Audit 2026-07-20 (perf) — index des 2 seules clés étrangères non couvertes.
-- ─────────────────────────────────────────────────────────────────────
-- L'advisor `unindexed_foreign_keys` signale 2 FK sans index couvrant :
--   • app_release_config.updated_by          (→ profiles)
--   • match_anticheat_plans.recorded_player_id (→ profiles)
-- Une FK sans index rend lents les jointures et surtout les vérifications
-- ON DELETE / ON UPDATE côté table parente (scan séquentiel de l'enfant).
-- Tables minuscules aujourd'hui, mais ces deux index sont légitimes (à la
-- différence des ~40 index « inutilisés » anticipatoires qu'on NE touche PAS :
-- idx_scan=0 seulement parce que le volume prod est faible).
--
-- IF NOT EXISTS → idempotent. Pas de CONCURRENTLY : tables minuscules,
-- verrou négligeable, et CONCURRENTLY est interdit dans une transaction de
-- migration.

create index if not exists idx_app_release_config_updated_by
  on public.app_release_config (updated_by);

create index if not exists idx_match_anticheat_plans_recorded_player_id
  on public.match_anticheat_plans (recorded_player_id);
