-- ─────────────────────────────────────────────────────────────────────
-- Paiement multi-pays : options de paiement par pays / opérateur
-- ─────────────────────────────────────────────────────────────────────
-- Remplace les 2 colonnes figées competitions.orange_money_code /
-- mtn_momo_code (un seul jeu Cameroun) par une config souple : pour chaque
-- compétition PAYANTE, l'admin active des pays et, par pays, une LISTE
-- d'opérateurs (Orange Money, MTN MoMo, Wave, Moov, Free Money…), chacun avec
-- son code de transfert Mobile Money.
--
-- Le joueur, à l'inscription, choisit son pays (parmi les pays distincts
-- présents ici), puis un opérateur de ce pays, et paie sur le code affiché.
--
-- Les anciennes colonnes competitions.orange_money_code / mtn_momo_code sont
-- CONSERVÉES (dépréciées) le temps de la bascule complète du code Flutter ;
-- elles sont migrées en lignes ci-dessous.

-- -----------------------------------------------------------------------------
-- 1. Table
-- -----------------------------------------------------------------------------
create table if not exists public.competition_payment_options (
  id             uuid primary key default gen_random_uuid(),
  competition_id uuid not null references public.competitions (id) on delete cascade,
  country_code   text not null check (country_code ~ '^[A-Z]{2}$'),
  operator_label text not null check (char_length(trim(operator_label)) between 1 and 40),
  transfer_code  text not null check (char_length(trim(transfer_code)) between 1 and 60),
  -- Indicatif E.164 du pays (ex. '+237') — pré-remplit le champ numéro côté
  -- joueur (P2). Redondant avec supported_countries.dart mais persisté pour
  -- rester correct même si la liste applicative évolue.
  dial_code      text check (dial_code is null or dial_code ~ '^\+[0-9]{1,4}$'),
  sort_order     int not null default 0,
  created_at     timestamptz not null default now()
);

comment on table public.competition_payment_options is
  'Options de paiement P2P manuel par pays/opérateur pour une compétition payante. '
  'Les pays distincts = les pays dont les résidents peuvent s''inscrire.';
comment on column public.competition_payment_options.operator_label is
  'Nom affiché de l''opérateur (ex. « Orange Money », « Wave »).';
comment on column public.competition_payment_options.transfer_code is
  'Code de transfert Mobile Money / code marchand affiché au joueur (P2).';

-- Un même opérateur n'apparaît qu'une fois par (compétition, pays).
create unique index if not exists uq_comp_payment_options_operator
  on public.competition_payment_options (competition_id, country_code, lower(operator_label));

-- Lecture des options d'une compétition, triées.
create index if not exists idx_comp_payment_options_comp
  on public.competition_payment_options (competition_id, country_code, sort_order);

-- -----------------------------------------------------------------------------
-- 2. RLS — lecture publique (le joueur voit les codes pour payer),
--    écriture réservée aux admins (parité avec competitions_*_admin).
-- -----------------------------------------------------------------------------
alter table public.competition_payment_options enable row level security;

drop policy if exists "comp_payment_options_select" on public.competition_payment_options;
create policy "comp_payment_options_select"
  on public.competition_payment_options for select
  using (true);

drop policy if exists "comp_payment_options_admin_insert" on public.competition_payment_options;
create policy "comp_payment_options_admin_insert"
  on public.competition_payment_options for insert
  with check ((select public.is_admin()));

drop policy if exists "comp_payment_options_admin_update" on public.competition_payment_options;
create policy "comp_payment_options_admin_update"
  on public.competition_payment_options for update
  using ((select public.is_admin()))
  with check ((select public.is_admin()));

drop policy if exists "comp_payment_options_admin_delete" on public.competition_payment_options;
create policy "comp_payment_options_admin_delete"
  on public.competition_payment_options for delete
  using ((select public.is_admin()));

-- -----------------------------------------------------------------------------
-- 3. Migration de compatibilité : convertir les codes CM existants en lignes.
--    Idempotente (le unique index empêche les doublons ; on ne réinsère pas si
--    déjà présent). dial_code '+237' pour le Cameroun.
-- -----------------------------------------------------------------------------
insert into public.competition_payment_options
  (competition_id, country_code, operator_label, transfer_code, dial_code, sort_order)
select c.id, 'CM', 'Orange Money', c.orange_money_code, '+237', 0
from public.competitions c
where c.orange_money_code is not null
  and char_length(trim(c.orange_money_code)) > 0
on conflict (competition_id, country_code, lower(operator_label)) do nothing;

insert into public.competition_payment_options
  (competition_id, country_code, operator_label, transfer_code, dial_code, sort_order)
select c.id, 'CM', 'MTN MoMo', c.mtn_momo_code, '+237', 1
from public.competitions c
where c.mtn_momo_code is not null
  and char_length(trim(c.mtn_momo_code)) > 0
on conflict (competition_id, country_code, lower(operator_label)) do nothing;

-- -----------------------------------------------------------------------------
-- 4. Realtime — la page d'inscription doit refléter un ajout/retrait de code.
-- -----------------------------------------------------------------------------
do $$
begin
  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'competition_payment_options'
  ) then
    alter publication supabase_realtime add table public.competition_payment_options;
  end if;
end $$;
