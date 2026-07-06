-- ─────────────────────────────────────────────────────────────────────
-- Paiement multi-pays : généralisation payments / payouts
-- ─────────────────────────────────────────────────────────────────────
-- 1. payments : le joueur peut payer depuis n'importe quel pays activé, via
--    un opérateur LIBRE (plus seulement MTN_MOMO / ORANGE_MONEY). On ajoute
--    country_code + operator_label et on relâche la contrainte figée.
-- 2. payouts : chaque versement porte le pays (organisateur) de sa compétition
--    → base du scoping admin par pays (20260706100400). payee_method relâché
--    aussi (le gagnant peut retirer via un opérateur libre).
-- Idempotente.

-- -----------------------------------------------------------------------------
-- 1. payments — pays + opérateur libre
-- -----------------------------------------------------------------------------
alter table public.payments
  add column if not exists country_code   text,
  add column if not exists operator_label text;

alter table public.payments
  drop constraint if exists payments_country_code_check;
alter table public.payments
  add constraint payments_country_code_check
    check (country_code is null or country_code ~ '^[A-Z]{2}$');

-- Historiquement payer_method ∈ {MTN_MOMO, ORANGE_MONEY}. Désormais il peut
-- porter le code d'un opérateur libre (ou rester l'un des 2 anciens pour
-- rétro-compat). On RELÂCHE : plus de liste blanche figée.
alter table public.payments
  drop constraint if exists payments_payer_method_check;

comment on column public.payments.country_code is
  'Pays choisi par le joueur à l''inscription (ISO alpha-2). NULL = ancien paiement CM.';
comment on column public.payments.operator_label is
  'Nom de l''opérateur choisi (ex. « Wave »). payer_method peut porter son code technique.';

-- Backfill : les paiements manuels existants étaient tous Cameroun.
update public.payments
   set country_code = 'CM'
 where country_code is null
   and provider = 'mobile_money_manual';

-- -----------------------------------------------------------------------------
-- 2. payouts — pays (dérivé de la compétition) + méthode de retrait libre
-- -----------------------------------------------------------------------------
alter table public.payouts
  add column if not exists country_code text;

alter table public.payouts
  drop constraint if exists payouts_country_code_check;
alter table public.payouts
  add constraint payouts_country_code_check
    check (country_code is null or country_code ~ '^[A-Z]{2}$');

-- Le gagnant retire via son propre opérateur — peut être libre.
alter table public.payouts
  drop constraint if exists payouts_payee_method_check;

comment on column public.payouts.country_code is
  'Pays organisateur de la compétition (copié à la génération). Base du scoping '
  'admin par pays : un admin restreint ne gère que les versements de son pays.';

-- Backfill depuis competitions.country_code (colonne ajoutée en 20260706100000).
update public.payouts p
   set country_code = c.country_code
  from public.competitions c
 where c.id = p.competition_id
   and p.country_code is null;

create index if not exists idx_payouts_country_code
  on public.payouts (country_code);

-- -----------------------------------------------------------------------------
-- 3. generate_payouts : le remplissage de country_code sur les nouvelles lignes
--    ET le gate de scoping sont faits ENSEMBLE dans 20260706100400, en repartant
--    du corps AUTORITAIRE durci (cap cagnotte + garde classement + alerte
--    subvention). On NE redéfinit PAS la fonction ici pour ne pas écraser ces
--    durcissements avec une version périmée.
-- -----------------------------------------------------------------------------
