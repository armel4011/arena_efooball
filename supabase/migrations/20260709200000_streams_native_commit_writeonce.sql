-- =============================================================================
-- ARENA — Ré-audit 2026-07-09 (P3) : write-once DB du commitment anti-triche natif
-- =============================================================================
-- Le write-once du commitment natif ne reposait que sur le read-then-write de
-- l'EF anticheat-commit (l'index unique partiel existant ne couvre que
-- livekit_track_egress). Une course de deux commits concurrents du même joueur
-- pouvait théoriquement produire 2 lignes committées.
--
-- ⚠️ IMPORTANT — l'index NE peut PAS être `(match_id, player_id) where native` :
-- `match_stream_repository.openSession()` insère UNE ligne de session native PAR
-- enregistrement (is_active, sans preuve) → plusieurs lignes natives par
-- (match, joueur) sont LÉGITIMES (sessions multiples / reprises). Un index full
-- casserait le recorder au 2e enregistrement.
--
-- Le write-once porte sur le COMMITMENT : on contraint donc au plus UNE ligne
-- native COMMITTÉE (proof_committed_at not null) par (match, joueur). Cela ferme
-- la course sans entraver les sessions.
--
-- 1) Housekeeping : purge des lignes de session natives NON-committées redondantes
--    (artefacts de sessions E2E répétées) quand une ligne committée existe déjà
--    pour le même (match, joueur) — la ligne committée est la preuve de référence.
--    Idempotent (no-op si rien à purger, ex. CI fraîche).
-- 2) Index unique partiel scopé-commitment.
-- =============================================================================

delete from public.streams s
where s.provider = 'native_recorder'
  and s.proof_committed_at is null
  and exists (
    select 1 from public.streams s2
    where s2.provider = 'native_recorder'
      and s2.match_id = s.match_id
      and s2.player_id = s.player_id
      and s2.proof_committed_at is not null
  );

create unique index if not exists streams_one_native_commit_per_player
  on public.streams (match_id, player_id)
  where provider = 'native_recorder' and proof_committed_at is not null;

comment on index public.streams_one_native_commit_per_player is
  'Ré-audit 2026-07-09 : write-once DB du commitment natif — au plus une ligne '
  'native committée (proof_committed_at) par (match, joueur). Partiel sur '
  'proof_committed_at → n''entrave pas les multiples lignes de session (openSession).';
