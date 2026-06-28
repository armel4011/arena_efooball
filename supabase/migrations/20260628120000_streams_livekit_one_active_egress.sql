-- =============================================================================
-- ARENA — Anti-triche LiveKit : une seule capture active par joueur / match
-- =============================================================================
-- Course observée en test : deux `track_published` quasi simultanés passent
-- tous les deux le garde applicatif (`maybeSingle` puis `insert`, non atomique)
-- → deux Track Egress lancés pour le même joueur → double enregistrement et
-- double stockage. Cet index partiel rend la garantie atomique côté DB : au
-- plus UNE ligne LiveKit `is_active` par (match_id, player_id). Le webhook
-- attrape la violation 23505 et arrête l'egress dupliqué.
--
-- Portée : provider LiveKit uniquement (le recorder natif n'est pas concerné),
-- lignes actives uniquement (les enregistrements clôturés ne conflictent pas).
-- Idempotent.
-- =============================================================================

create unique index if not exists streams_one_active_livekit_per_player
  on public.streams (match_id, player_id)
  where provider = 'livekit_track_egress' and is_active = true;
