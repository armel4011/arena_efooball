-- =============================================================================
-- ARENA — Audit 2026-07-17 : P3 d'hygiène
-- =============================================================================
-- Trois écarts de convention, tous à impact réel faible ou nul, mais qui
-- entretiennent des angles morts que le prochain durcissement paierait cher.
-- =============================================================================

-- ─── P3.1 — `payments_admin_update` : cloisonner l'écriture par pays ────────
-- La LECTURE des paiements est cloisonnée (`payments_select`, 20260710170000,
-- filtre sur admin_allowed_countries) mais l'ÉCRITURE ne l'était pas. Un
-- super-admin scopé {'CM'} qui obtient l'UUID d'un paiement `awaiting_admin`
-- d'un tournoi SN par un autre canal (notification, capture d'écran, log)
-- pouvait le valider → `on_payment_validated` crée une inscription confirmée
-- hors de son périmètre.
--
-- Sévérité basse (il ne peut pas ÉNUMÉRER ces lignes, la policy SELECT le
-- bloque ; et le rôle est déjà très privilégié) mais c'est une incohérence avec
-- le miroir `payouts` (20260706100400) et avec `mark_payout_paid` /
-- `generate_payouts`, toutes deux admin_can_country-gardées.
drop policy if exists payments_admin_update on public.payments;
create policy payments_admin_update on public.payments
  for update to public
  using (
    public.is_super_admin()
    and status = 'awaiting_admin'
    and public.admin_can_country((select auth.uid()), country_code)
  )
  with check (
    public.is_super_admin()
    and status in ('succeeded', 'rejected')
    and public.admin_can_country((select auth.uid()), country_code)
  );

-- ─── P3.2 — trigger DEFINER sans revoke (régression de convention) ──────────
-- 20260710180000 a établi la convention pour ses jumelles (`notify_room_code_
-- shared`, `_notify_support_message`) ; `purge_match_reminders_on_reschedule`
-- (20260716120000) l'a manquée et garde le GRANT EXECUTE TO PUBLIC par défaut.
-- Impact réel NUL — une fonction `returns trigger` ne peut pas être appelée
-- hors contexte trigger — mais elle ressort aux advisors 0028/0029.
revoke execute on function public.purge_match_reminders_on_reschedule()
  from public, anon, authenticated;

-- ─── P3.3 — `revoke ... from anon` NE SUFFIT PAS ────────────────────────────
-- 20260717160000 (#347) fait bien `REVOKE EXECUTE ... FROM anon`, et pourtant
-- l'advisor prouve qu'anon peut TOUJOURS exécuter la fonction : le droit est
-- hérité de PUBLIC, que le revoke sur `anon` ne retire pas. C'est le symétrique
-- exact du piège déjà connu pour `authenticated` (cf. 20260615200000).
--
-- Impact réel nul ici (la fonction rend `false` si auth.uid() is null, donc un
-- anon n'obtient rien), mais le réflexe est faux : appliqué un jour à une
-- fonction sensible, il laisserait la porte grande ouverte en donnant
-- l'illusion du contraire. On corrige la fonction ET le pattern.
revoke execute on function public.onboarding_mark_seen_once(text) from public, anon;
grant execute on function public.onboarding_mark_seen_once(text) to authenticated;
