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

-- Idempotent par table : `match_events` est déjà ajouté (de façon guardée) par
-- 20260506200001. Un `ALTER PUBLICATION ... ADD TABLE a, b, c` est atomique et
-- échoue en entier dès qu'UNE table est déjà membre — ce qui cassait toute la
-- séquence sur un stack à neuf (CI) : `relation "match_events" is already member
-- of publication "supabase_realtime"`. On ajoute donc chaque table dans son
-- propre bloc tolérant au doublon. No-op en prod (déjà appliqué).
do $$
declare
  v_tbl text;
begin
  foreach v_tbl in array array[
    'match_events', 'competitions', 'profiles', 'disputes', 'payouts', 'notifications'
  ]
  loop
    begin
      execute format('alter publication supabase_realtime add table public.%I', v_tbl);
    exception when duplicate_object then null;
    end;
  end loop;
end $$;
