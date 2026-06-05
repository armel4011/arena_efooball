-- =============================================================================
-- ARENA — F-1 : pipeline de versement des gains (P2P manuel)
-- =============================================================================
-- Le cycle de vie s'arrêtait à `completed` : aucun producteur de lignes
-- `payouts`, `prize_distribution` jamais consommé → le gagnant n'était jamais
-- payé. On câble le versement, cohérent avec le P2P manuel (le staff verse via
-- Mobile Money ; le système calcule, matérialise et trace).
--
-- Décisions produit (2026-06-05) :
--   1. Le gagnant SAISIT son numéro de retrait au moment de réclamer (claim).
--   2. Génération MANUELLE par le super-admin (bouton), après vérif du classement.
--   3. `payouts` = gains uniquement (remboursements = mécanisme séparé, cf. C-2).
--   4. `prize_pool_local` est déjà NET ; `prize_distribution` est un tableau de
--      MONTANTS ABSOLUS par rang (index 0 = rang 1). Pas de commission à retenir.
--
-- Flux : generate_payouts (admin) → status `pending_admin_validation`
--   → claim_payout (gagnant saisit numéro) → mark_payout_paid (admin) `completed`.
-- =============================================================================

-- ─── 1. Adapter `payouts` au P2P manuel local ────────────────────────────────
-- La table était modelée pour le flux automatisé USD (CinetPay/NowPayments,
-- PHASE 12.5 dormante) : prize_id NOT NULL (table prizes inutilisée),
-- amount_usd NOT NULL, provider ∈ {cinetpay,nowpayments}. On assouplit pour le
-- versement local manuel. (payouts/prizes vides à ce jour → sans risque.)
alter table public.payouts alter column prize_id  drop not null;
alter table public.payouts alter column amount_usd drop not null;

alter table public.payouts drop constraint if exists payouts_payout_provider_check;
alter table public.payouts add constraint payouts_payout_provider_check
  check (payout_provider is null
         or payout_provider in ('cinetpay', 'nowpayments', 'mobile_money_manual'));

alter table public.payouts
  add column if not exists rank        integer,
  add column if not exists payee_phone text,
  add column if not exists payee_method text,
  add column if not exists claimed_at  timestamptz;

alter table public.payouts drop constraint if exists payouts_payee_method_check;
alter table public.payouts add constraint payouts_payee_method_check
  check (payee_method is null or payee_method in ('MTN_MOMO', 'ORANGE_MONEY'));

-- Un seul versement par (compétition, gagnant).
create unique index if not exists uniq_payouts_competition_user
  on public.payouts (competition_id, user_id);

-- ─── 2. Génération des versements (super-admin, manuel, idempotent) ───────────
create or replace function public.generate_payouts(p_competition_id uuid)
returns integer
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_status   public.competition_status;
  v_pool     numeric;
  v_dist     jsonb;
  v_currency text;
  v_name     text;
  v_n        integer;
  i          integer;
  v_amount   numeric;
  v_user     uuid;
  v_count    integer := 0;
begin
  if not public.is_super_admin() then
    raise exception 'Reserve au super-admin' using errcode = '42501';
  end if;

  select status, prize_pool_local, prize_distribution, registration_currency, name
    into v_status, v_pool, v_dist, v_currency, v_name
    from public.competitions
    where id = p_competition_id;
  if not found then
    raise exception 'Competition introuvable' using errcode = 'P0002';
  end if;
  if v_status <> 'completed' then
    raise exception 'Les versements ne se generent qu''une fois la competition terminee'
      using errcode = '42501';
  end if;

  -- Idempotence : ne pas regenerer si des payouts existent deja.
  if exists (select 1 from public.payouts where competition_id = p_competition_id) then
    return 0;
  end if;
  if v_dist is null or jsonb_typeof(v_dist) <> 'array' then
    return 0;
  end if;

  v_n := jsonb_array_length(v_dist);
  i := 1;
  while i <= v_n loop
    v_amount := coalesce((v_dist->>(i - 1))::numeric, 0);
    if v_amount > 0 then
      select player_id into v_user
        from public.competition_registrations
        where competition_id = p_competition_id and final_rank = i
        limit 1;
      if v_user is not null then
        insert into public.payouts
          (user_id, competition_id, amount_local, currency, status, rank, payout_provider)
        values
          (v_user, p_competition_id, v_amount, v_currency,
           'pending_admin_validation', i, 'mobile_money_manual');

        insert into public.notifications (user_id, type, title, body, data)
        values (v_user, 'payout_available', 'Tu as gagne !',
          'Felicitations ! Tu as remporte ' || v_amount::text || ' ' || v_currency
            || ' a « ' || v_name || ' ». Reclame tes gains dans l''app pour '
            || 'recevoir ton versement Mobile Money.',
          jsonb_build_object('competition_id', p_competition_id, 'rank', i,
                             'amount_local', v_amount));
        v_count := v_count + 1;
      end if;
    end if;
    i := i + 1;
  end loop;

  return v_count;
end;
$$;

comment on function public.generate_payouts(uuid) is
  'F-1 : genere les lignes payouts (gains) d''une competition completed depuis '
  'prize_distribution (montants absolus par rang) + final_rank des inscriptions. '
  'Notifie chaque gagnant. Idempotent. Gate is_super_admin().';

revoke execute on function public.generate_payouts(uuid) from anon, public;
grant execute on function public.generate_payouts(uuid) to authenticated;

-- ─── 3. Réclamation par le gagnant (saisie du numéro de retrait) ──────────────
create or replace function public.claim_payout(
  p_payout_id uuid, p_phone text, p_method text)
returns void
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_user   uuid;
  v_status text;
begin
  select user_id, status into v_user, v_status
    from public.payouts where id = p_payout_id for update;
  if not found then
    raise exception 'Versement introuvable' using errcode = 'P0002';
  end if;
  if v_user is distinct from auth.uid() then
    raise exception 'Tu ne peux reclamer que tes propres gains' using errcode = '42501';
  end if;
  if v_status <> 'pending_admin_validation' then
    raise exception 'Ce versement n''est plus reclamable' using errcode = '42501';
  end if;
  if p_method not in ('MTN_MOMO', 'ORANGE_MONEY') then
    raise exception 'Methode de retrait invalide' using errcode = '22023';
  end if;
  if coalesce(trim(p_phone), '') = '' then
    raise exception 'Numero de retrait requis' using errcode = '22023';
  end if;

  update public.payouts
     set payee_phone  = trim(p_phone),
         payee_method = p_method,
         claimed_at   = now()
   where id = p_payout_id;
end;
$$;

comment on function public.claim_payout(uuid, text, text) is
  'F-1 : le gagnant (auth.uid) saisit son numero/methode Mobile Money de retrait '
  'sur SON payout pending. SECURITY DEFINER → contourne le guard de colonnes.';

revoke execute on function public.claim_payout(uuid, text, text) from anon, public;
grant execute on function public.claim_payout(uuid, text, text) to authenticated;

-- ─── 4. Validation du versement par le super-admin (apres virement reel) ──────
create or replace function public.mark_payout_paid(p_payout_id uuid)
returns void
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_user     uuid;
  v_status   text;
  v_phone    text;
  v_amount   numeric;
  v_currency text;
  v_name     text;
begin
  if not public.is_super_admin() then
    raise exception 'Reserve au super-admin' using errcode = '42501';
  end if;

  select p.user_id, p.status, p.payee_phone, p.amount_local, p.currency, c.name
    into v_user, v_status, v_phone, v_amount, v_currency, v_name
    from public.payouts p
    join public.competitions c on c.id = p.competition_id
    where p.id = p_payout_id for update;
  if not found then
    raise exception 'Versement introuvable' using errcode = 'P0002';
  end if;
  if v_status = 'completed' then
    raise exception 'Versement deja paye' using errcode = '42501';
  end if;
  if coalesce(trim(v_phone), '') = '' then
    raise exception 'Le gagnant n''a pas encore reclame (numero de retrait manquant)'
      using errcode = '42501';
  end if;

  update public.payouts
     set status               = 'completed',
         validated_by_admin_id = auth.uid(),
         validated_at         = now(),
         completed_at         = now()
   where id = p_payout_id;

  insert into public.notifications (user_id, type, title, body, data)
  values (v_user, 'payout_paid', 'Versement effectue',
    'Ton gain de ' || v_amount::text || ' ' || v_currency || ' pour « ' || v_name
      || ' » a ete verse sur ton numero Mobile Money.',
    jsonb_build_object('payout_id', p_payout_id));
end;
$$;

comment on function public.mark_payout_paid(uuid) is
  'F-1 : le super-admin marque un payout comme paye (apres virement Mobile Money '
  'reel). Exige un numero de retrait reclame. Notifie le gagnant. Gate super-admin.';

revoke execute on function public.mark_payout_paid(uuid) from anon, public;
grant execute on function public.mark_payout_paid(uuid) to authenticated;
