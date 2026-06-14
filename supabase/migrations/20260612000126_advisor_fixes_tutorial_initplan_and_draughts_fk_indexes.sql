-- ─────────────────────────────────────────────────────────────────
-- Advisor fixes : initplan tutorial_video_views + index FK draughts
-- ─────────────────────────────────────────────────────────────────
-- RÉGÉNÉRÉE depuis la prod le 2026-06-14 (audit reproductibilité). Cette
-- migration avait été appliquée directement via MCP le 2026-06-12 mais son
-- fichier n'avait jamais été commité → un `db reset` / replay from-scratch
-- ne recréait pas ces objets. Le DDL ci-dessous reflète l'état prod réel.
-- Idempotente (DROP IF EXISTS / IF NOT EXISTS) : ré-jouable sans risque.

-- 1) Perf RLS (initplan) : `(select auth.uid())` est évalué UNE fois par
--    requête au lieu d'une fois par ligne (advisor auth_rls_initplan).
--    Les policies d'origine (20260606180000_tutorial_video_views.sql)
--    utilisaient `auth.uid()` nu.
drop policy if exists tutorial_video_views_self_select
  on public.tutorial_video_views;
create policy tutorial_video_views_self_select
  on public.tutorial_video_views for select
  to authenticated
  using (user_id = (select auth.uid()));

drop policy if exists tutorial_video_views_self_insert
  on public.tutorial_video_views;
create policy tutorial_video_views_self_insert
  on public.tutorial_video_views for insert
  to authenticated
  with check (user_id = (select auth.uid()));

-- 2) Index sur les FK draughts (advisor unused_index = FK non indexées) :
--    accélère jointures et cascades. Le pendant `match_id` existe déjà
--    (idx_draughts_games_match dans 20260608130000_draughts_tables.sql).
create index if not exists idx_draughts_games_white
  on public.draughts_games (white_id);
create index if not exists idx_draughts_games_black
  on public.draughts_games (black_id);
create index if not exists idx_draughts_moves_player
  on public.draughts_moves (player_id);
