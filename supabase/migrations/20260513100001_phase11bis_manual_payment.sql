-- =============================================================================
-- PHASE 11bis — Paiement manuel P2P (Orange Money / MTN MoMo)
-- =============================================================================
-- CinetPay + NowPayments reportés en V2. En V1, le joueur paie en P2P
-- directement sur le code marchand affiché par l'app, puis le super-admin
-- valide ou refuse manuellement la transaction depuis la console.
--
-- 1. competitions : 2 colonnes pour les codes marchands par tournoi
-- 2. payments : ajout du provider 'mobile_money_manual', 2 nouveaux
--    statuts ('awaiting_admin', 'rejected'), métadonnées payeur, audit
--    de validation admin, expiration 15 min
-- 3. RLS : self-insert pour le joueur, update super-admin pour valider
-- 4. Index sur la file d'attente admin
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 1. competitions : codes marchands par compétition
-- -----------------------------------------------------------------------------
alter table public.competitions
  add column if not exists orange_money_code text,
  add column if not exists mtn_momo_code text;

comment on column public.competitions.orange_money_code is
  'Code marchand Orange Money saisi par l''admin créateur — affiché sur P2 quand le joueur choisit Orange.';
comment on column public.competitions.mtn_momo_code is
  'Code marchand MTN MoMo saisi par l''admin créateur — affiché sur P2 quand le joueur choisit MTN.';

-- -----------------------------------------------------------------------------
-- 2. payments : extension provider / statut / métadonnées
-- -----------------------------------------------------------------------------
alter table public.payments
  drop constraint if exists payments_provider_check;

alter table public.payments
  add constraint payments_provider_check
    check (provider in ('cinetpay', 'nowpayments', 'mobile_money_manual'));

alter table public.payments
  drop constraint if exists payments_status_check;

alter table public.payments
  add constraint payments_status_check
    check (status in (
      'pending',
      'processing',
      'awaiting_admin',
      'succeeded',
      'failed',
      'rejected',
      'refunded',
      'expired'
    ));

alter table public.payments
  add column if not exists payer_phone text,
  add column if not exists payer_method text
    check (payer_method is null or payer_method in ('MTN_MOMO', 'ORANGE_MONEY')),
  add column if not exists validated_by_admin_id uuid
    references public.profiles on delete set null,
  add column if not exists validated_at timestamptz,
  add column if not exists rejection_reason text,
  add column if not exists expires_at timestamptz;

comment on column public.payments.payer_phone is
  'Numéro Mobile Money utilisé par le joueur pour payer (à afficher dans la console super-admin).';
comment on column public.payments.payer_method is
  '''MTN_MOMO'' ou ''ORANGE_MONEY'' — choix du joueur sur P1, persisté pour audit.';
comment on column public.payments.validated_by_admin_id is
  'Super-admin qui a validé ou refusé le paiement (audit trail).';
comment on column public.payments.expires_at is
  'created_at + 15 min — passé ce délai, le paiement bascule automatiquement en status=expired.';

-- -----------------------------------------------------------------------------
-- 3. RLS — self-insert joueur + update super-admin
-- -----------------------------------------------------------------------------
-- Le joueur insère son row de paiement avec status='awaiting_admin' juste
-- après avoir cliqué "J'AI PAYÉ" sur P2. La policy existing
-- "payments_self_select" couvre déjà la lecture.
drop policy if exists "payments_self_insert" on public.payments;
create policy "payments_self_insert"
  on public.payments for insert
  with check (
    auth.uid() = user_id
    and provider = 'mobile_money_manual'
    and status = 'awaiting_admin'
  );

-- Le super-admin met à jour le status (valider → succeeded, refuser → rejected)
-- ainsi que validated_by_admin_id, validated_at, rejection_reason.
drop policy if exists "payments_admin_update" on public.payments;
create policy "payments_admin_update"
  on public.payments for update
  using (public.is_super_admin())
  with check (public.is_super_admin());

-- -----------------------------------------------------------------------------
-- 4. Indexes — file d'attente admin triée par expiration croissante
-- -----------------------------------------------------------------------------
create index if not exists idx_payments_awaiting_admin
  on public.payments (expires_at)
  where status = 'awaiting_admin';

create index if not exists idx_payments_validated_at
  on public.payments (validated_at desc)
  where validated_at is not null;
