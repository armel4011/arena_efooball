-- =============================================================================
-- ARENA — Anti-triche DUAL : provenance des enregistrements sur `streams`
-- =============================================================================
-- La table `streams` sert déjà de registre « 1 ligne par joueur / match » pour
-- l'anti-triche (recorder natif) et le live Agora. Le système DUAL ajoute le
-- provider LiveKit Track Egress : on enrichit `streams` plutôt que de créer une
-- table parallèle (réutilise MatchStreamRepository + le cron cleanup-streams).
--
-- LiveKit = 2 lignes par match (1 piste vidéo / joueur, 1 egress / ligne).
-- Additif et idempotent — aucune ligne existante n'est cassée (defaut natif).
-- =============================================================================

-- Provider ayant produit l'enregistrement. Les lignes historiques sont, par
-- définition, issues du recorder natif (filet de sécurité).
alter table public.streams
  add column if not exists provider text not null default 'native_recorder';

-- Identifiant d'egress LiveKit (null pour le natif). Sert au webhook pour
-- retrouver la ligne quand l'egress se termine.
alter table public.streams
  add column if not exists egress_id text;

-- Chemin de l'objet dans le bucket de stockage (clé S3 / Storage). La colonne
-- `url` reste pour une URL publique éventuelle ; `storage_path` porte la clé
-- privée résolue en URL signée à la demande côté admin (cf. disputes).
alter table public.streams
  add column if not exists storage_path text;

-- Échéance de rétention (purge par cleanup-streams). Null = pas d'échéance.
alter table public.streams
  add column if not exists expires_at timestamptz;

-- Garde-fou : provider parmi les valeurs connues. Drop + recreate pour rester
-- idempotent si la contrainte existe déjà.
alter table public.streams
  drop constraint if exists streams_provider_check;
alter table public.streams
  add constraint streams_provider_check
  check (provider in ('native_recorder', 'livekit_track_egress'));

-- Lookup du webhook egress_ended → ligne streams (egress_id unique quand posé).
create unique index if not exists streams_egress_id_key
  on public.streams (egress_id)
  where egress_id is not null;

comment on column public.streams.provider is
  'Provider anti-triche : native_recorder (filet de sécurité) | livekit_track_egress (défaut).';
comment on column public.streams.egress_id is
  'Identifiant LiveKit Track Egress (null pour le recorder natif).';
comment on column public.streams.storage_path is
  'Clé objet du fichier dans le bucket (résolue en URL signée à la demande).';
comment on column public.streams.expires_at is
  'Échéance de rétention pour la purge cleanup-streams (null = aucune).';
