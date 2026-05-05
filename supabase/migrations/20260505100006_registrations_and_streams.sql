-- =============================================================================
-- ARENA — Phase 0 — Migration 6/X
-- Tables manquantes (cf. ARENA_FLUTTER_PROMPT.md L1324 + L1442) :
--   * competition_registrations  (inscriptions joueurs aux compétitions)
--   * streams                    (sessions de recording / streaming live)
-- + RLS, indexes, et inclusion dans la publication realtime.
-- =============================================================================
-- Dépend de : 20260505100002 (profiles, competitions),
--             20260505100003 (matches),
--             20260505100005 (helpers is_admin / is_super_admin)
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 1. competition_registrations
--    Lien N-N entre joueurs et compétitions auxquelles ils sont inscrits.
--    PK composite : un joueur ne peut s'inscrire qu'une seule fois par comp.
--    L'INSERT réel se fait via Edge Function (service_role) après confirmation
--    du paiement CinetPay/NowPayments. Côté client : SELECT seulement.
-- -----------------------------------------------------------------------------
create table if not exists public.competition_registrations (
  competition_id uuid not null
    references public.competitions on delete cascade,
  player_id      uuid not null
    references public.profiles on delete cascade,
  registered_at  timestamptz not null default now(),
  -- Statut de l'inscription (pending = paiement en cours, confirmed = payé,
  -- refunded = remboursé, withdrawn = retrait volontaire avant début comp).
  status         text not null default 'confirmed'
    check (status in ('pending', 'confirmed', 'refunded', 'withdrawn')),
  -- Optionnel : référence vers le paiement qui a déclenché l'inscription.
  payment_id     uuid references public.payments on delete set null,
  primary key (competition_id, player_id)
);

comment on table public.competition_registrations is
  'Inscriptions joueurs aux compétitions (lien N-N + statut + payment).';

-- -----------------------------------------------------------------------------
-- 2. streams
--    Sessions de recording / streaming live (anti-cheat + diffusion finales).
--    Une ligne par session (un même match peut avoir 2 streams si les 2
--    joueurs enregistrent leur écran indépendamment).
-- -----------------------------------------------------------------------------
create table if not exists public.streams (
  id          uuid primary key default uuid_generate_v4(),
  match_id    uuid not null
    references public.matches on delete cascade,
  player_id   uuid not null
    references public.profiles on delete cascade,
  -- URL du recording (Supabase Storage) ou channel Agora pour streaming live.
  url         text,
  -- Stream public (visible LiveStreamsPage) ou privé (anti-cheat admin only).
  is_public   boolean not null default false,
  -- Stream actuellement en cours (live ou recording in progress).
  is_active   boolean not null default true,
  started_at  timestamptz not null default now(),
  ended_at    timestamptz
);

comment on table public.streams is
  'Sessions de recording (anti-cheat) ou streaming Agora (finales / sélection admin).';

-- =============================================================================
-- INDEXES
-- =============================================================================

-- competition_registrations : recherche par compétition (liste inscrits) et
-- par joueur (mes inscriptions sur HomePage / profile).
create index if not exists idx_registrations_competition
  on public.competition_registrations(competition_id);
create index if not exists idx_registrations_player
  on public.competition_registrations(player_id, registered_at desc);
create index if not exists idx_registrations_status
  on public.competition_registrations(status)
  where status in ('pending', 'confirmed');

-- streams : LiveStreamsPage = streams publics actifs.
create index if not exists idx_streams_match
  on public.streams(match_id);
create index if not exists idx_streams_active_public
  on public.streams(is_public, is_active)
  where is_public = true and is_active = true;
create index if not exists idx_streams_player
  on public.streams(player_id, started_at desc);

-- =============================================================================
-- ROW LEVEL SECURITY
-- =============================================================================

alter table public.competition_registrations enable row level security;
alter table public.streams                   enable row level security;

-- ---------- competition_registrations ----------------------------------------
-- Lecture publique : la liste des inscrits est visible (transparence des
-- compétitions, comme un bracket public).
create policy "registrations_public_read"
  on public.competition_registrations for select
  using (true);

-- INSERT/DELETE : seules les Edge Functions (service_role bypass) ou
-- l'admin peuvent inscrire/désinscrire un joueur. Côté joueur, le flow
-- passe par le paiement → Edge Function → INSERT.
create policy "registrations_admin_all"
  on public.competition_registrations for all
  using (public.is_admin())
  with check (public.is_admin());

-- ---------- streams ----------------------------------------------------------
-- Le streamer voit ses propres streams, l'admin voit tout, et tout le monde
-- peut voir les streams publics actifs (LiveStreamsPage / WatchStreamPage).
create policy "streams_public_read"
  on public.streams for select
  using (is_public = true);

create policy "streams_owner_select"
  on public.streams for select
  using (player_id = auth.uid());

create policy "streams_admin_all"
  on public.streams for all
  using (public.is_admin())
  with check (public.is_admin());

-- L'INSERT/UPDATE par les joueurs (lancement recording, fin de stream) passe
-- par l'Edge Function get_agora_token + update via service_role. Pas de
-- policy d'écriture côté client (sensible : preuve anti-cheat).

-- =============================================================================
-- REALTIME
-- =============================================================================
-- streams : nécessaire pour LiveStreamsPage (apparition / disparition live)
-- competition_registrations : nécessaire pour CompetitionDetailPage
--   (compteur d'inscrits qui se met à jour en temps réel)
alter publication supabase_realtime add table public.streams;
alter publication supabase_realtime add table public.competition_registrations;
