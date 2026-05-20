-- Phase 3/4 du plan scaling 1M users — Realtime fan-out audit.
--
-- Deux tables sont publiées sur `supabase_realtime` mais aucun consumer
-- client ne les écoute via `.stream()`. Chaque write déclenche pourtant
-- un cycle WAL → Realtime broker → check RLS → discard. À 1M users le
-- coût CPU/RAM du broker devient mesurable.
--
-- 1. `profiles` — `ProfileRepository.watch(id)` existait depuis l'initial
--    commit mais n'a jamais été câblé. Tous les consommateurs lisent via
--    `currentProfileProvider` (FutureProvider) ou `getById()`. Le commit
--    `cd28b61` (2026-05-17) avait ajouté la table à la publication "à
--    monitorer côté Realtime si MAU explose" — confirmation : aucun
--    `.stream()` ne pointe sur `profiles`.
--
--    Volume écriture estimé à scale : fcm_token refresh + stats writes
--    après chaque match clos + edit profile (avatar/country/username) =
--    ~5-10 writes / user / mois → 5-10M events Realtime "for nothing"
--    par mois à 1M MAU.
--
-- 2. `chat_channels` — ajoutée en PHASE 6 (`20260506200002`) en
--    anticipation, mais `ChatRepository` n'utilise que des SELECT
--    (`openedMatchChannelIds`, `ensureMatchChannel`). Les notifications
--    "nouveau match chat" passent par la table `notifications` (déjà
--    streamée). Volume bas mais zéro consumer = zéro raison de publier.
--
-- Si un jour un `.stream()` est ajouté, ré-exécuter `ALTER PUBLICATION
-- supabase_realtime ADD TABLE …` dans la même migration que le code.

do $$
begin
  alter publication supabase_realtime drop table public.profiles;
exception when undefined_object then null;
end $$;

do $$
begin
  alter publication supabase_realtime drop table public.chat_channels;
exception when undefined_object then null;
end $$;
