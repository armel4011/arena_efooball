-- ─────────────────────────────────────────────────────────────────────
-- Perf 2026-06-02 — advisors Supabase : auth_rls_initplan +
-- multiple_permissive_policies + unindexed_foreign_keys.
-- ─────────────────────────────────────────────────────────────────────
-- 1. `auth.uid()` nu dans une policy est ré-évalué PAR LIGNE ; encapsulé
--    en `(select auth.uid())` il devient un InitPlan évalué une fois.
--    Tables concernées : admin_chat_messages (3 policies), stream_comments (1).
-- 2. admin_chat_messages avait 2 policies SELECT permissives (admin + user)
--    → chaque SELECT évaluait les deux. Fusionnées en une seule (OR).
-- 3. 2 FK sans index couvrant : match_reminders_sent.player_id,
--    stream_comments.author_id.
--
-- Aucun changement de sémantique d'accès : mêmes règles, mêmes rôles.
-- ─────────────────────────────────────────────────────────────────────

-- 1. admin_chat_messages — fusion des 2 policies SELECT + initplan.
drop policy if exists "admin_chat_select_admin" on public.admin_chat_messages;
drop policy if exists "admin_chat_select_user" on public.admin_chat_messages;
create policy "admin_chat_select" on public.admin_chat_messages
  for select to authenticated
  using (
    (select public.is_admin())
    or recipient_id = (select auth.uid())
  );

-- 2. admin_chat_messages — INSERT admin only (initplan).
drop policy if exists "admin_chat_insert_admin_only" on public.admin_chat_messages;
create policy "admin_chat_insert_admin_only" on public.admin_chat_messages
  for insert to authenticated
  with check (
    (select public.is_admin())
    and admin_id = (select auth.uid())
  );

-- 3. admin_chat_messages — UPDATE read receipt par le destinataire (initplan).
drop policy if exists "admin_chat_update_read_user" on public.admin_chat_messages;
create policy "admin_chat_update_read_user" on public.admin_chat_messages
  for update to authenticated
  using (recipient_id = (select auth.uid()))
  with check (recipient_id = (select auth.uid()));

-- 4. stream_comments — INSERT par l'auteur sur un stream public actif (initplan).
drop policy if exists "stream_comments_insert_authenticated" on public.stream_comments;
create policy "stream_comments_insert_authenticated" on public.stream_comments
  for insert to authenticated
  with check (
    author_id = (select auth.uid())
    and exists (
      select 1 from public.streams s
      where s.match_id = stream_comments.match_id
        and s.is_public = true
        and s.is_active = true
    )
  );

-- 5. Index couvrants sur les FK flaggées par l'advisor.
create index if not exists idx_match_reminders_sent_player
  on public.match_reminders_sent (player_id);
create index if not exists idx_stream_comments_author
  on public.stream_comments (author_id);
