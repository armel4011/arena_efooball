-- Ajoute toutes les tables encore manquantes dans la publication
-- `supabase_realtime`. Chacune est consommée par un `.stream()` côté
-- Flutter (cf. audit du 2026-05-17) :
--
-- match_events  → MatchRoomPage timeline + replay
-- competitions  → home filter chips + admin competitions list
-- profiles      → watchById (live update du compte courant + autres)
-- disputes      → admin disputes list + détail
-- payouts       → admin payouts dashboard (status auto-update)
-- notifications → inbox notif live
--
-- RLS reste appliquée côté serveur — chaque subscriber ne reçoit que
-- les events visibles selon sa policy (notifications.user_id, etc.).
-- profiles : volume écriture modéré en V1 (mostly fcm_token + stats),
-- à monitorer côté Realtime pricing si MAU explose.

ALTER PUBLICATION supabase_realtime ADD TABLE
  public.match_events,
  public.competitions,
  public.profiles,
  public.disputes,
  public.payouts,
  public.notifications;
