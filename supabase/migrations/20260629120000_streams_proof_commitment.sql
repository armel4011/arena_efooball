-- =============================================================================
-- ARENA — Anti-triche Phase 3 : commitment hash (proxy 360p + upload on-demand)
-- =============================================================================
-- Reframe coût (cf. plan réduction coût anti-triche) : tout le monde enregistre
-- en natif, transcode un PROXY 360p à la fin du match, et n'envoie au serveur que
-- le SHA-256 de ce proxy (« commitment »). La soumission de score est débloquée
-- sur ce commit (quelques octets, marche en 2G), JAMAIS sur l'upload vidéo lourd.
--
-- La vidéo n'est uploadée que sur DEMANDE admin lors d'un litige (« réclamer la
-- vidéo »). À la réception, on compare le hash du fichier au commitment :
--   match    → preuve infalsifiable engageante ;
--   mismatch / non-livré après engagement → charge contre le joueur.
--
-- Additif + idempotent. Réutilise `streams` (1 ligne/joueur/match) et son
-- `storage_path` existant pour le fichier uploadé.
-- =============================================================================

-- Empreinte SHA-256 (hex, 64 chars) du proxy 360p engagé par le client.
alter table public.streams
  add column if not exists proof_sha256 text;

-- Taille en octets du proxy engagé (sert au sanity-check à l'upload).
alter table public.streams
  add column if not exists proof_bytes bigint;

-- Durée en secondes du proxy engagé (métadonnée litige).
alter table public.streams
  add column if not exists proof_duration_seconds integer;

-- Instant où le client a engagé le commitment (hash reçu par anticheat-commit).
alter table public.streams
  add column if not exists proof_committed_at timestamptz;

-- Instant où un admin a RÉCLAMÉ la vidéo (déclenche la commande FCM d'upload).
-- Non null = engagement d'upload attendu du joueur.
alter table public.streams
  add column if not exists proof_claimed_at timestamptz;

-- Instant où le client a effectivement livré le fichier (upload terminé).
alter table public.streams
  add column if not exists proof_uploaded_at timestamptz;

-- Verdict de vérification calculé à l'upload : le SHA-256 du fichier reçu
-- correspond-il au commitment ? null = pas encore uploadé/vérifié.
alter table public.streams
  add column if not exists proof_hash_verified boolean;

-- Garde-fou : un SHA-256 hex est 64 caractères [0-9a-f]. Drop+recreate idempotent.
alter table public.streams
  drop constraint if exists streams_proof_sha256_format;
alter table public.streams
  add constraint streams_proof_sha256_format
  check (proof_sha256 is null or proof_sha256 ~ '^[0-9a-f]{64}$');

-- Lookup admin : retrouver vite les preuves réclamées non encore livrées.
create index if not exists streams_proof_claimed_pending_idx
  on public.streams (proof_claimed_at)
  where proof_claimed_at is not null and proof_uploaded_at is null;

comment on column public.streams.proof_sha256 is
  'SHA-256 (hex) du proxy 360p engagé par le client (commitment). Vérifié à l''upload.';
comment on column public.streams.proof_bytes is
  'Taille en octets du proxy engagé.';
comment on column public.streams.proof_duration_seconds is
  'Durée (s) du proxy engagé.';
comment on column public.streams.proof_committed_at is
  'Instant de l''engagement du commitment (hash reçu).';
comment on column public.streams.proof_claimed_at is
  'Instant où un admin a réclamé la vidéo (déclenche l''upload on-demand). Non null = upload attendu.';
comment on column public.streams.proof_uploaded_at is
  'Instant de livraison effective du fichier par le client.';
comment on column public.streams.proof_hash_verified is
  'Le SHA-256 du fichier uploadé correspond-il au commitment ? null = pas encore vérifié.';
