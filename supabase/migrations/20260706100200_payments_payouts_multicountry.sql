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
-- 3. generate_payouts : renseigner country_code sur les nouvelles lignes.
--    (Le gate de scoping est ajouté en 20260706100400 ; ici on ne touche qu'au
--    remplissage du pays.)
-- -----------------------------------------------------------------------------
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
  v_country  text;
  v_n        integer;
  i          integer;
  v_amount   numeric;
  v_user     uuid;
  v_count    integer := 0;
begin
  if not public.is_super_admin() then
    raise exception 'Reserve au super-admin' using errcode = '42501';
  end if;

  select status, prize_pool_local, prize_distribution, registration_currency, name, country_code
    into v_status, v_pool, v_dist, v_currency, v_name, v_country
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
          (user_id, competition_id, amount_local, currency, status, rank,
           payout_provider, country_code)
        values
          (v_user, p_competition_id, v_amount, v_currency,
           'pending_admin_validation', i, 'mobile_money_manual', v_country);

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

revoke execute on function public.generate_payouts(uuid) from anon, public;
grant execute on function public.generate_payouts(uuid) to authenticated;
