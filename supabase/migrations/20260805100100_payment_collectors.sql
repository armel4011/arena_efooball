-- Lot 1b — Collecteurs de paiement par pays, quota, blocage, versements.
--
-- Modèle (multi-collecteurs par pays) :
--   * Un COLLECTEUR = un profil `role='collector'` rattaché à un pays, avec un
--     quota de collecte et un encours (outstanding).
--   * Chaque OPTION de paiement d'une compétition (numéro marchand) peut être
--     rattachée à un collecteur (competition_payment_options.collector_id).
--   * À la VALIDATION d'un paiement par le collecteur, son encours augmente du
--     montant. Dès que l'encours atteint le quota → le collecteur est BLOQUÉ :
--     son/ses numéros ne peuvent plus recevoir de paiement (garde à l'INSERT).
--   * Le collecteur DÉCLARE un versement ; le super-admin le VALIDE → l'encours
--     est REMIS À ZÉRO et le collecteur RÉACTIVÉ.
--   * Rétro-compatible : une option sans collector_id (Cameroun actuel) n'est
--     soumise à aucun quota ni blocage.

-- ─────────────────────────────────────────────────────────────────────────
-- 0. Gardes de rôle
-- ─────────────────────────────────────────────────────────────────────────

create or replace function public.is_collector()
  returns boolean
  language sql
  stable
  security definer
  set search_path = public
as $$
  select exists (
    select 1 from public.profiles
    where id = (select auth.uid())
      and role = 'collector'
      and is_active
      and deleted_at is null
  );
$$;

-- ─────────────────────────────────────────────────────────────────────────
-- 1. Table des collecteurs (plusieurs par pays)
-- ─────────────────────────────────────────────────────────────────────────

create table if not exists public.payment_collectors (
  id                uuid primary key default gen_random_uuid(),
  profile_id        uuid not null references public.profiles(id) on delete cascade,
  country_code      text not null check (country_code ~ '^[A-Z]{2}$'),
  quota_local       numeric(15,2) not null check (quota_local > 0),
  outstanding_local numeric(15,2) not null default 0 check (outstanding_local >= 0),
  is_blocked        boolean not null default false,
  is_active         boolean not null default true,
  created_by        uuid references public.profiles(id),
  created_at        timestamptz not null default now(),
  updated_at        timestamptz not null default now()
);

-- Un profil ne porte qu'UN compte collecteur par pays.
create unique index if not exists payment_collectors_profile_country_uq
  on public.payment_collectors(profile_id, country_code);
create index if not exists payment_collectors_country_idx
  on public.payment_collectors(country_code);

alter table public.payment_collectors enable row level security;

-- Lecture : super-admin (cloisonné pays) ; le collecteur voit SES comptes.
create policy payment_collectors_select on public.payment_collectors
  for select to authenticated
  using (
    (public.is_super_admin() and public.admin_can_country((select auth.uid()), country_code))
    or profile_id = (select auth.uid())
  );
-- Écriture uniquement via RPC (SECURITY DEFINER) — aucune policy write directe.

-- ─────────────────────────────────────────────────────────────────────────
-- 2. Rattachement d'une option de paiement à un collecteur + du paiement soumis
-- ─────────────────────────────────────────────────────────────────────────

alter table public.competition_payment_options
  add column if not exists collector_id uuid
    references public.payment_collectors(id) on delete restrict;
create index if not exists competition_payment_options_collector_idx
  on public.competition_payment_options(collector_id);

alter table public.payments
  add column if not exists collector_id uuid
    references public.payment_collectors(id) on delete set null;
create index if not exists payments_collector_idx
  on public.payments(collector_id);

-- ─────────────────────────────────────────────────────────────────────────
-- 3. Versements du collecteur
-- ─────────────────────────────────────────────────────────────────────────

create table if not exists public.collector_remittances (
  id               uuid primary key default gen_random_uuid(),
  collector_id     uuid not null references public.payment_collectors(id) on delete cascade,
  amount_local     numeric(15,2) not null check (amount_local >= 0),
  status           text not null default 'declared'
                     check (status in ('declared','validated','rejected')),
  note             text,
  declared_at      timestamptz not null default now(),
  validated_by     uuid references public.profiles(id),
  validated_at     timestamptz,
  rejection_reason text
);
create index if not exists collector_remittances_collector_idx
  on public.collector_remittances(collector_id, status);

alter table public.collector_remittances enable row level security;

create policy collector_remittances_select on public.collector_remittances
  for select to authenticated
  using (
    exists (
      select 1 from public.payment_collectors c
      where c.id = collector_remittances.collector_id
        and (
          c.profile_id = (select auth.uid())
          or (public.is_super_admin()
              and public.admin_can_country((select auth.uid()), c.country_code))
        )
    )
  );
-- Écriture via RPC uniquement.

-- ─────────────────────────────────────────────────────────────────────────
-- 4. Garde de BLOCAGE à l'INSERT d'un paiement (côté joueur)
--    Restrictive → s'AJOUTE (AND) aux policies d'insert existantes sans les
--    réécrire. collector_id NULL (flux libre) → toujours autorisé.
-- ─────────────────────────────────────────────────────────────────────────

create or replace function public.collector_accepts_payments(p_collector_id uuid)
  returns boolean
  language sql
  stable
  security definer
  set search_path = public
as $$
  select case
    when p_collector_id is null then true
    else exists (
      select 1 from public.payment_collectors c
      where c.id = p_collector_id and c.is_active and not c.is_blocked
    )
  end;
$$;

drop policy if exists payments_insert_collector_open on public.payments;
create policy payments_insert_collector_open on public.payments
  as restrictive
  for insert to authenticated
  with check (public.collector_accepts_payments(collector_id));

-- ─────────────────────────────────────────────────────────────────────────
-- 5. Lecture des paiements par le collecteur (SES paiements uniquement)
--    Permissive → s'ajoute (OR) à payments_select existante.
-- ─────────────────────────────────────────────────────────────────────────

drop policy if exists payments_collector_select on public.payments;
create policy payments_collector_select on public.payments
  for select to authenticated
  using (
    public.is_collector()
    and collector_id in (
      select id from public.payment_collectors where profile_id = (select auth.uid())
    )
  );

-- ─────────────────────────────────────────────────────────────────────────
-- 6. RPC — VALIDATION d'un paiement par le collecteur (quota + blocage)
-- ─────────────────────────────────────────────────────────────────────────

create or replace function public.collector_validate_payment(p_payment_id uuid)
  returns void
  language plpgsql
  security definer
  set search_path = public
as $$
declare
  v_payment   public.payments;
  v_collector public.payment_collectors;
  v_new_total numeric(15,2);
begin
  if not public.is_collector() then
    raise exception 'Réservé aux collecteurs' using errcode = '42501';
  end if;

  select * into v_payment from public.payments where id = p_payment_id for update;
  if not found then
    raise exception 'Paiement introuvable' using errcode = 'P0002';
  end if;
  if v_payment.status <> 'awaiting_admin' then
    raise exception 'Ce paiement n''est plus en attente de validation' using errcode = '42501';
  end if;
  if v_payment.collector_id is null then
    raise exception 'Ce paiement n''est rattaché à aucun collecteur' using errcode = '42501';
  end if;

  select * into v_collector
    from public.payment_collectors where id = v_payment.collector_id for update;
  if not found or v_collector.profile_id <> (select auth.uid()) then
    raise exception 'Ce paiement ne relève pas de votre compte' using errcode = '42501';
  end if;
  if not v_collector.is_active then
    raise exception 'Votre compte collecteur est inactif' using errcode = '42501';
  end if;
  if v_collector.is_blocked then
    raise exception 'Quota atteint : effectuez un versement avant de valider de nouveaux paiements'
      using errcode = '42501';
  end if;

  -- Valider le paiement → le trigger on_payment_validated crée l'inscription.
  update public.payments
    set status = 'succeeded',
        validated_by_admin_id = (select auth.uid()),
        validated_at = now()
    where id = v_payment.id;

  -- Incrémenter l'encours ; bloquer dès que le quota est atteint.
  v_new_total := v_collector.outstanding_local + v_payment.amount_local;
  update public.payment_collectors
    set outstanding_local = v_new_total,
        is_blocked = (v_new_total >= quota_local),
        updated_at = now()
    where id = v_collector.id;
end;
$$;

-- ─────────────────────────────────────────────────────────────────────────
-- 7. RPC — REFUS d'un paiement par le collecteur (n'affecte pas l'encours)
-- ─────────────────────────────────────────────────────────────────────────

create or replace function public.collector_reject_payment(
  p_payment_id uuid,
  p_reason     text
) returns void
  language plpgsql
  security definer
  set search_path = public
as $$
declare
  v_payment   public.payments;
  v_collector public.payment_collectors;
begin
  if not public.is_collector() then
    raise exception 'Réservé aux collecteurs' using errcode = '42501';
  end if;
  if coalesce(btrim(p_reason), '') = '' then
    raise exception 'Motif de refus requis' using errcode = '22023';
  end if;

  select * into v_payment from public.payments where id = p_payment_id for update;
  if not found or v_payment.status <> 'awaiting_admin' then
    raise exception 'Paiement introuvable ou déjà traité' using errcode = '42501';
  end if;
  select * into v_collector
    from public.payment_collectors where id = v_payment.collector_id;
  if not found or v_collector.profile_id <> (select auth.uid()) then
    raise exception 'Ce paiement ne relève pas de votre compte' using errcode = '42501';
  end if;

  update public.payments
    set status = 'rejected',
        rejection_reason = p_reason,
        validated_by_admin_id = (select auth.uid()),
        validated_at = now()
    where id = v_payment.id;
end;
$$;

-- ─────────────────────────────────────────────────────────────────────────
-- 8. RPC — Le collecteur DÉCLARE un versement (snapshot de l'encours courant)
-- ─────────────────────────────────────────────────────────────────────────

create or replace function public.declare_collector_remittance(
  p_collector_id uuid,
  p_note         text default null
) returns uuid
  language plpgsql
  security definer
  set search_path = public
as $$
declare
  v_collector public.payment_collectors;
  v_id        uuid;
begin
  if not public.is_collector() then
    raise exception 'Réservé aux collecteurs' using errcode = '42501';
  end if;
  select * into v_collector from public.payment_collectors where id = p_collector_id;
  if not found or v_collector.profile_id <> (select auth.uid()) then
    raise exception 'Compte collecteur invalide' using errcode = '42501';
  end if;
  if v_collector.outstanding_local <= 0 then
    raise exception 'Aucun encours à reverser' using errcode = '42501';
  end if;
  -- Un seul versement en attente à la fois.
  if exists (
    select 1 from public.collector_remittances
    where collector_id = p_collector_id and status = 'declared'
  ) then
    raise exception 'Un versement est déjà en attente de validation' using errcode = '42501';
  end if;

  insert into public.collector_remittances (collector_id, amount_local, note)
    values (p_collector_id, v_collector.outstanding_local, p_note)
    returning id into v_id;
  return v_id;
end;
$$;

-- ─────────────────────────────────────────────────────────────────────────
-- 9. RPC — Le super-admin VALIDE un versement → reset encours + réactivation
-- ─────────────────────────────────────────────────────────────────────────

create or replace function public.validate_collector_remittance(p_remittance_id uuid)
  returns void
  language plpgsql
  security definer
  set search_path = public
as $$
declare
  v_rem       public.collector_remittances;
  v_collector public.payment_collectors;
begin
  select * into v_rem from public.collector_remittances where id = p_remittance_id for update;
  if not found then
    raise exception 'Versement introuvable' using errcode = 'P0002';
  end if;
  if v_rem.status <> 'declared' then
    raise exception 'Versement déjà traité' using errcode = '42501';
  end if;

  select * into v_collector from public.payment_collectors where id = v_rem.collector_id for update;
  if not public.is_super_admin()
     or not public.admin_can_country((select auth.uid()), v_collector.country_code) then
    raise exception 'Réservé au super-admin habilité sur ce pays' using errcode = '42501';
  end if;

  update public.collector_remittances
    set status = 'validated', validated_by = (select auth.uid()), validated_at = now()
    where id = v_rem.id;

  -- Remise à ZÉRO de l'encours + réactivation du collecteur.
  update public.payment_collectors
    set outstanding_local = 0, is_blocked = false, updated_at = now()
    where id = v_collector.id;
end;
$$;

-- Refus d'un versement (super-admin) — n'altère pas l'encours.
create or replace function public.reject_collector_remittance(
  p_remittance_id uuid,
  p_reason        text
) returns void
  language plpgsql
  security definer
  set search_path = public
as $$
declare
  v_rem       public.collector_remittances;
  v_collector public.payment_collectors;
begin
  select * into v_rem from public.collector_remittances where id = p_remittance_id for update;
  if not found or v_rem.status <> 'declared' then
    raise exception 'Versement introuvable ou déjà traité' using errcode = '42501';
  end if;
  select * into v_collector from public.payment_collectors where id = v_rem.collector_id;
  if not public.is_super_admin()
     or not public.admin_can_country((select auth.uid()), v_collector.country_code) then
    raise exception 'Réservé au super-admin habilité sur ce pays' using errcode = '42501';
  end if;
  update public.collector_remittances
    set status = 'rejected', rejection_reason = p_reason,
        validated_by = (select auth.uid()), validated_at = now()
    where id = v_rem.id;
end;
$$;

-- ─────────────────────────────────────────────────────────────────────────
-- 10. RPC — Super-admin : créer / mettre à jour un collecteur (pays + quota)
-- ─────────────────────────────────────────────────────────────────────────

create or replace function public.upsert_payment_collector(
  p_profile_id uuid,
  p_country    text,
  p_quota      numeric
) returns uuid
  language plpgsql
  security definer
  set search_path = public
as $$
declare
  v_id   uuid;
  v_role public.user_role;
begin
  if not public.is_super_admin()
     or not public.admin_can_country((select auth.uid()), p_country) then
    raise exception 'Réservé au super-admin habilité sur ce pays' using errcode = '42501';
  end if;
  if p_quota is null or p_quota <= 0 then
    raise exception 'Quota invalide' using errcode = '22023';
  end if;
  select role into v_role from public.profiles where id = p_profile_id;
  if v_role is distinct from 'collector' then
    raise exception 'Le profil ciblé n''a pas le rôle collecteur' using errcode = '42501';
  end if;

  insert into public.payment_collectors (profile_id, country_code, quota_local, created_by)
    values (p_profile_id, p_country, p_quota, (select auth.uid()))
    on conflict (profile_id, country_code)
      do update set quota_local = excluded.quota_local, is_active = true, updated_at = now()
    returning id into v_id;
  return v_id;
end;
$$;

-- Activer / désactiver un collecteur (super-admin habilité pays).
create or replace function public.set_payment_collector_active(
  p_collector_id uuid,
  p_active       boolean
) returns void
  language plpgsql
  security definer
  set search_path = public
as $$
declare v_collector public.payment_collectors;
begin
  select * into v_collector from public.payment_collectors where id = p_collector_id;
  if not found then raise exception 'Collecteur introuvable' using errcode = 'P0002'; end if;
  if not public.is_super_admin()
     or not public.admin_can_country((select auth.uid()), v_collector.country_code) then
    raise exception 'Réservé au super-admin habilité sur ce pays' using errcode = '42501';
  end if;
  update public.payment_collectors
    set is_active = p_active, updated_at = now() where id = p_collector_id;
end;
$$;

-- ─────────────────────────────────────────────────────────────────────────
-- 11. Grants — RPC d'action réservées aux utilisateurs authentifiés
-- ─────────────────────────────────────────────────────────────────────────

revoke execute on function public.collector_validate_payment(uuid)       from public, anon;
revoke execute on function public.collector_reject_payment(uuid, text)    from public, anon;
revoke execute on function public.declare_collector_remittance(uuid, text) from public, anon;
revoke execute on function public.validate_collector_remittance(uuid)     from public, anon;
revoke execute on function public.reject_collector_remittance(uuid, text) from public, anon;
revoke execute on function public.upsert_payment_collector(uuid, text, numeric) from public, anon;
revoke execute on function public.set_payment_collector_active(uuid, boolean)   from public, anon;

grant execute on function public.collector_validate_payment(uuid)       to authenticated;
grant execute on function public.collector_reject_payment(uuid, text)    to authenticated;
grant execute on function public.declare_collector_remittance(uuid, text) to authenticated;
grant execute on function public.validate_collector_remittance(uuid)     to authenticated;
grant execute on function public.reject_collector_remittance(uuid, text) to authenticated;
grant execute on function public.upsert_payment_collector(uuid, text, numeric) to authenticated;
grant execute on function public.set_payment_collector_active(uuid, boolean)   to authenticated;

-- ─────────────────────────────────────────────────────────────────────────
-- 12. Codes d'invitation : autoriser le rôle 'collector'
--     (la contrainte CHECK est anonyme/inline → on la retrouve dynamiquement)
-- ─────────────────────────────────────────────────────────────────────────

do $$
declare c_name text;
begin
  select conname into c_name
  from pg_constraint
  where conrelid = 'public.invitation_codes'::regclass
    and contype = 'c'
    and pg_get_constraintdef(oid) ilike '%role%';
  if c_name is not null then
    execute format('alter table public.invitation_codes drop constraint %I', c_name);
  end if;
end$$;

alter table public.invitation_codes
  add constraint invitation_codes_role_check
  check (role in ('admin', 'super_admin', 'collector'));
