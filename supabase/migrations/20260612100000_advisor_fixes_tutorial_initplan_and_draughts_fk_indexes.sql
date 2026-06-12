-- ============================================================================
-- Corrections advisors (audit 2026-06-12) — perf only, sémantique inchangée
-- ============================================================================
-- Deux lots issus du performance advisor Supabase :
--
--  1. auth_rls_initplan (WARN) sur tutorial_video_views : les 2 policies
--     réévaluent auth.uid() POUR CHAQUE ligne (fonction STABLE non cachée).
--     En wrappant dans un sous-SELECT, Postgres met le résultat en InitPlan
--     (1 appel/requête au lieu de N). DROP + CREATE car ALTER POLICY ne
--     permet pas de modifier l'expression. Sémantique strictement identique.
--
--  2. unindexed_foreign_keys (INFO) sur draughts_games(white_id, black_id)
--     et draughts_moves(player_id) : sans index couvrant, un DELETE/UPDATE
--     sur profiles(id) force un seq_scan des tables enfant pour vérifier les
--     références. Les 3 colonnes sont NOT NULL -> index complets.
--
-- NOTE volontairement NON traitée : l'advisor security_definer_view (ERROR)
-- sur public.public_profiles. La vue est DELIBEREMENT SECURITY DEFINER : elle
-- projette le sous-ensemble PUBLIC et sûr des colonnes de `profiles` (username,
-- avatar, stats, ...) alors que la seule policy SELECT de profiles est
-- (auth.uid() = id OR is_admin()). La basculer en security_invoker casserait
-- la recherche d'utilisateurs, les profils publics et les leaderboards (chaque
-- user ne verrait que sa propre ligne). La vue n'expose aucune colonne secrète
-- (ni email, ni whatsapp_number, ni voip_token) : exception assumée.
-- ----------------------------------------------------------------------------

-- 1. tutorial_video_views : initplan optimization (auth.uid() -> (select ...))
drop policy if exists tutorial_video_views_self_select on public.tutorial_video_views;
create policy tutorial_video_views_self_select
  on public.tutorial_video_views for select
  to authenticated
  using (user_id = (select auth.uid()));

drop policy if exists tutorial_video_views_self_insert on public.tutorial_video_views;
create policy tutorial_video_views_self_insert
  on public.tutorial_video_views for insert
  to authenticated
  with check (user_id = (select auth.uid()));

-- 2. draughts : index couvrants pour les FK vers profiles (colonnes NOT NULL)
create index if not exists idx_draughts_games_white
  on public.draughts_games (white_id);

create index if not exists idx_draughts_games_black
  on public.draughts_games (black_id);

create index if not exists idx_draughts_moves_player
  on public.draughts_moves (player_id);
