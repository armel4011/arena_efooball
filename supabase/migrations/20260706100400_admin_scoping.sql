-- ─────────────────────────────────────────────────────────────────────
-- Volet 3 — Restriction des actions admin par PAYS et par SECTION
-- ─────────────────────────────────────────────────────────────────────
-- Le super-admin, en créant un code d'invitation admin, peut restreindre le
-- futur admin/super-admin :
--   • allowed_country_codes : pays qu'il peut gérer (NULL = tous)
--   • allowed_sections      : sections auxquelles il a accès, ex. {'payouts'}
--                             (NULL = toutes)
-- Ces restrictions sont portées par le code d'invitation, propagées au profil
-- créé (EF register-admin, 20260706100500 côté Deno), puis APPLIQUÉES :
--   • DB : lecture des versements (payouts) + RPC generate/mark_payout_paid,
--          filtrées par pays organisateur de la compétition (payouts.country_code).
--   • UI : masquage des sections non autorisées (côté Flutter, tâche #10).
--
-- « Pays cible » = competitions.country_code (pays organisateur), copié sur
-- chaque payout à la génération (voir 20260706100200). Un admin restreint à
-- {'CM'} ne voit/valide QUE les versements des compétitions country_code='CM'.
-- Idempotente.

-- -----------------------------------------------------------------------------
-- 1. Colonnes de scope
-- -----------------------------------------------------------------------------
alter table public.invitation_codes
  add column if not exists allowed_country_codes text[],
  add column if not exists allowed_sections      text[];

comment on column public.invitation_codes.allowed_country_codes is
  'Pays (ISO alpha-2) que le futur admin pourra gérer. NULL = aucun scope (tous).';
comment on column public.invitation_codes.allowed_sections is
  'Sections admin autorisées (ex. {payouts}). NULL = accès complet.';

alter table public.profiles
  add column if not exists admin_allowed_countries text[],
  add column if not exists admin_allowed_sections  text[];

comment on column public.profiles.admin_allowed_countries is
  'Scoping admin : pays gérables (ISO alpha-2). NULL = pas de restriction.';
comment on column public.profiles.admin_allowed_sections is
  'Scoping admin : sections autorisées. NULL = pas de restriction.';

-- Piège C-1 : le SELECT sur profiles est accordé colonne par colonne. Toute
-- nouvelle colonne lue par le client admin doit être GRANT explicitement,
-- sinon 42501 côté app. Ces colonnes pilotent la nav admin → lecture requise.
grant select (admin_allowed_countries, admin_allowed_sections)
  on public.profiles to authenticated;

-- -----------------------------------------------------------------------------
-- 2. Helpers de scope (SECURITY DEFINER → lisent profiles hors RLS)
-- -----------------------------------------------------------------------------
create or replace function public.admin_allowed_countries(p_uid uuid)
returns text[]
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select admin_allowed_countries from public.profiles where id = p_uid;
$$;

create or replace function public.admin_allowed_sections(p_uid uuid)
returns text[]
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select admin_allowed_sections from public.profiles where id = p_uid;
$$;

-- NULL scope = pas de restriction → autorisé. Sinon, appartenance à la liste.
create or replace function public.admin_can_country(p_uid uuid, p_country text)
returns boolean
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select case
    when public.admin_allowed_countries(p_uid) is null then true
    when p_country is null then false
    else p_country = any (public.admin_allowed_countries(p_uid))
  end;
$$;

create or replace function public.admin_can_section(p_uid uuid, p_section text)
returns boolean
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select case
    when public.admin_allowed_sections(p_uid) is null then true
    else p_section = any (public.admin_allowed_sections(p_uid))
  end;
$$;

-- Réservé aux comptes connectés (RLS/RPC). On ne revoke PAS is_admin/is_super_admin
-- ici (utilisés par 30+ RLS) ; ces helpers-ci sont nouveaux.
revoke execute on function public.admin_allowed_countries(uuid) from anon, public;
revoke execute on function public.admin_allowed_sections(uuid)  from anon, public;
revoke execute on function public.admin_can_country(uuid, text)  from anon, public;
revoke execute on function public.admin_can_section(uuid, text)  from anon, public;
grant execute on function public.admin_allowed_countries(uuid) to authenticated;
grant execute on function public.admin_allowed_sections(uuid)  to authenticated;
grant execute on function public.admin_can_country(uuid, text)  to authenticated;
grant execute on function public.admin_can_section(uuid, text)  to authenticated;

-- -----------------------------------------------------------------------------
-- 3. RLS payouts : un admin restreint ne LIT que les versements de ses pays.
--    On remplace l'unique policy SELECT canonique (payouts_select de
--    20260505185438) — pas d'ajout permissif (sinon OR annulerait le scope).
--    ⚠️ `admin_allowed_countries(...)` est appelée DIRECTEMENT (pas via un
--    `(select ...)`) : wrapper la fonction dans un scalar-subquery casse la
--    forme tableau de `= ANY` (Postgres l'interprète comme `= ANY (sous-requête)`
--    → `text = text[]`). La fonction est STABLE + `(select auth.uid())` est
--    hoisté, donc l'évaluation reste bornée.
-- -----------------------------------------------------------------------------
drop policy if exists "payouts_select" on public.payouts;
create policy "payouts_select"
  on public.payouts for select
  using (
    user_id = (select auth.uid())
    or (
      (select public.is_admin())
      and (
        public.admin_allowed_countries((select auth.uid())) is null
        or country_code = any (public.admin_allowed_countries((select auth.uid())))
      )
    )
  );

-- -----------------------------------------------------------------------------
-- 4. RPC generate_payouts : gate section 'payouts' + pays de la compétition.
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

  -- Scope admin : section « versements » + pays de la compétition.
  if not public.admin_can_section(auth.uid(), 'payouts') then
    raise exception 'Compte non autorise sur les versements' using errcode = '42501';
  end if;
  if not public.admin_can_country(auth.uid(), v_country) then
    raise exception 'Compte non autorise sur ce pays' using errcode = '42501';
  end if;

  if v_status <> 'completed' then
    raise exception 'Les versements ne se generent qu''une fois la competition terminee'
      using errcode = '42501';
  end if;

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

-- -----------------------------------------------------------------------------
-- 5. RPC mark_payout_paid : gate section 'payouts' + pays du versement.
-- -----------------------------------------------------------------------------
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
  v_country  text;
begin
  if not public.is_super_admin() then
    raise exception 'Reserve au super-admin' using errcode = '42501';
  end if;

  select p.user_id, p.status, p.payee_phone, p.amount_local, p.currency, c.name, p.country_code
    into v_user, v_status, v_phone, v_amount, v_currency, v_name, v_country
    from public.payouts p
    join public.competitions c on c.id = p.competition_id
    where p.id = p_payout_id for update;
  if not found then
    raise exception 'Versement introuvable' using errcode = 'P0002';
  end if;

  -- Scope admin : section « versements » + pays du versement.
  if not public.admin_can_section(auth.uid(), 'payouts') then
    raise exception 'Compte non autorise sur les versements' using errcode = '42501';
  end if;
  if not public.admin_can_country(auth.uid(), v_country) then
    raise exception 'Compte non autorise sur ce pays' using errcode = '42501';
  end if;

  if v_status = 'completed' then
    raise exception 'Versement deja paye' using errcode = '42501';
  end if;
  if coalesce(trim(v_phone), '') = '' then
    raise exception 'Le gagnant n''a pas encore reclame (numero de retrait manquant)'
      using errcode = '42501';
  end if;

  update public.payouts
     set status                = 'completed',
         validated_by_admin_id = auth.uid(),
         validated_at          = now(),
         completed_at          = now()
   where id = p_payout_id;

  insert into public.notifications (user_id, type, title, body, data)
  values (v_user, 'payout_paid', 'Versement effectue',
    'Ton gain de ' || v_amount::text || ' ' || v_currency || ' pour « ' || v_name
      || ' » a ete verse sur ton numero Mobile Money.',
    jsonb_build_object('payout_id', p_payout_id));
end;
$$;

revoke execute on function public.mark_payout_paid(uuid) from anon, public;
grant execute on function public.mark_payout_paid(uuid) to authenticated;
