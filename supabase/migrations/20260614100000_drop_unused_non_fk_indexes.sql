-- ─────────────────────────────────────────────────────────────────
-- Nettoyage : suppression des index secondaires jamais scannés
-- (advisor performance Supabase, idx_scan = 0 au 2026-06-14).
--
-- Périmètre VOLONTAIREMENT restreint : on ne supprime QUE les index
-- secondaires non-uniques qui NE soutiennent PAS une clé étrangère.
--
-- Les index couvrant une FK sont CONSERVÉS même s'ils sont "inutilisés"
-- en lecture : ils évitent un scan séquentiel + une escalade de verrou
-- lors des DELETE/UPDATE sur la table parente. Beaucoup appartiennent
-- aussi à des features récentes (draughts, calls, tutorial) sans trafic.
--
-- Tous ces index sont triviaux (8-16 kB) et recréables si un plan de
-- requête régresse plus tard.
-- ─────────────────────────────────────────────────────────────────

DROP INDEX IF EXISTS public.idx_auto_actions_function;
DROP INDEX IF EXISTS public.idx_banned_words_language;
DROP INDEX IF EXISTS public.idx_competitions_dates;
DROP INDEX IF EXISTS public.idx_competitions_game;
DROP INDEX IF EXISTS public.idx_exchange_rates_pair;
DROP INDEX IF EXISTS public.invitation_codes_code_active_idx;
DROP INDEX IF EXISTS public.idx_matches_status;
DROP INDEX IF EXISTS public.idx_matches_status_scheduled_at;
DROP INDEX IF EXISTS public.idx_matches_streamed_live;
DROP INDEX IF EXISTS public.idx_webhook_log_provider;
DROP INDEX IF EXISTS public.idx_payments_provider_tx;
DROP INDEX IF EXISTS public.idx_payments_validated_at;
DROP INDEX IF EXISTS public.idx_profiles_country;
DROP INDEX IF EXISTS public.idx_profiles_deleted;
DROP INDEX IF EXISTS public.idx_profiles_last_seen;
DROP INDEX IF EXISTS public.idx_profiles_permanent_ban;
DROP INDEX IF EXISTS public.idx_reintegration_status_created;
DROP INDEX IF EXISTS public.idx_tutorial_video_active_page;
