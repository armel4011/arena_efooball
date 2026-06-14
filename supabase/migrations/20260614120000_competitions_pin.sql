-- ─────────────────────────────────────────────────────────────────
-- Épinglage de compétitions « à la une »
-- ─────────────────────────────────────────────────────────────────
-- L'admin peut épingler des compétitions importantes : elles remontent en
-- tête des listes côté utilisateur (home + page compétitions) avec un badge.
-- `is_pinned` = état ; `pinned_at` = horodatage (tri des épinglées entre
-- elles, plus récent en premier + trace d'audit). Idempotente.
--
-- Sécurité : l'UPDATE de ces colonnes est déjà couvert par la policy
-- existante `competitions_admin_write` (is_admin()). Lecture publique via
-- `competitions_public_read`. Aucune nouvelle policy nécessaire.

alter table public.competitions
  add column if not exists is_pinned boolean not null default false,
  add column if not exists pinned_at timestamptz;

comment on column public.competitions.is_pinned is
  'Compétition mise en avant côté utilisateur (remonte en tête des listes).';
comment on column public.competitions.pinned_at is
  'Horodatage de l''épinglage : tri des épinglées entre elles + audit.';

-- Index partiel : seules les épinglées sont indexées (tri pinned_at desc).
create index if not exists idx_competitions_pinned
  on public.competitions (pinned_at desc)
  where is_pinned;
