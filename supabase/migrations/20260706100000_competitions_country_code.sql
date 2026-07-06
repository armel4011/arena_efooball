-- ─────────────────────────────────────────────────────────────────────
-- Pays organisateur de la compétition (dimension pays — volet 3 scoping)
-- ─────────────────────────────────────────────────────────────────────
-- Chaque compétition appartient à un pays « organisateur » (country_code ISO
-- alpha-2, ex. 'CM'). C'est cette valeur qui sert au scoping des admins :
-- un super-admin restreint à un pays ne gère que les compétitions / versements
-- de CE pays (voir 20260706100400_admin_scoping.sql).
--
-- ⚠️ NE PAS confondre avec les pays d'INSCRIPTION autorisés (les résidents de
-- quels pays peuvent s'inscrire) : ceux-là vivent dans
-- competition_payment_options (20260706100100). Le country_code ici = le pays
-- « propriétaire » de la compétition, pas la liste des pays payeurs.
--
-- Default 'CM' : rétro-compatible (toutes les compétitions existantes étaient
-- 100 % Cameroun). NOT NULL après backfill. Idempotente.
--
-- Sécurité : l'écriture est déjà couverte par `competitions_update_admin` /
-- `competitions_insert_admin` (is_admin()). Lecture publique via
-- `competitions_select`. Aucune nouvelle policy nécessaire.

alter table public.competitions
  add column if not exists country_code text not null default 'CM';

-- Normalisation : toujours 2 lettres majuscules (parité avec profiles.country_code).
alter table public.competitions
  drop constraint if exists competitions_country_code_check;
alter table public.competitions
  add constraint competitions_country_code_check
    check (country_code ~ '^[A-Z]{2}$');

comment on column public.competitions.country_code is
  'Pays organisateur (ISO alpha-2). Sert au scoping admin par pays. '
  'DIFFÉRENT des pays d''inscription autorisés (competition_payment_options).';

-- Index : filtrage des compétitions par pays (admin restreint).
create index if not exists idx_competitions_country_code
  on public.competitions (country_code);
