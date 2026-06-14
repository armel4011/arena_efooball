-- ─────────────────────────────────────────────────────────────────
-- Durcissement post-audit (2026-06-14) — surface anon & intention RLS
-- ─────────────────────────────────────────────────────────────────

-- 1) tutorial_record_and_get_view : SECURITY DEFINER exécutable par `anon`
--    (advisor 0028). La fonction s'auto-protège déjà (`if auth.uid() is null
--    then return null`), donc l'appel anon est un no-op — mais on retire la
--    surface inutile en révoquant l'accès public/anon. Seuls les utilisateurs
--    authentifiés enregistrent une vue de tutoriel.
revoke execute on function public.tutorial_record_and_get_view(uuid) from public, anon;
grant execute on function public.tutorial_record_and_get_view(uuid) to authenticated;

-- 2) Documente l'intention « deny-by-default » des 3 tables RLS-sans-policy
--    (advisor 0008, INFO). Ce ne sont PAS des oublis : elles sont écrites/lues
--    exclusivement par le service_role (Edge Functions), qui bypasse la RLS.
--    Aucun grant anon/authenticated → aucun accès client possible, ce qui est
--    le comportement voulu. Le commentaire fige cette intention pour les audits
--    futurs.
comment on table public.admin_register_attempts is
  'RLS activée sans policy = deny-by-default VOULU. Écrite/lue uniquement par '
  'l''Edge Function register-admin (service_role, bypass RLS) pour le rate-limit. '
  'Aucun accès client attendu.';
comment on table public.totp_attempts is
  'RLS activée sans policy = deny-by-default VOULU. Écrite/lue uniquement par les '
  'Edge Functions TOTP (service_role, bypass RLS) pour le rate-limit. Aucun accès '
  'client attendu.';
comment on table public.match_reminders_sent is
  'RLS activée sans policy = deny-by-default VOULU. Écrite/lue uniquement par le '
  'cron de rappels de match (service_role, bypass RLS). Aucun accès client attendu.';
