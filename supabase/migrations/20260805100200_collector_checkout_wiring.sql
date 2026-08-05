-- Lot 4 — câblage checkout du collecteur.
--   1) Les ADMINS (pas seulement super-admin) peuvent LIRE les collecteurs de
--      leur pays, pour les rattacher aux options de paiement d'une compétition.
--   2) set_competition_payment_options stocke désormais collector_id (avec garde
--      : le collecteur doit appartenir au pays de l'option).
--   3) RPC de checkout exposant, au joueur, les options + un flag `available`
--      (collecteur non bloqué) — sans lui donner accès à payment_collectors.

-- 1) Lecture des collecteurs élargie aux admins (cloisonnée pays) ────────────
drop policy if exists payment_collectors_select on public.payment_collectors;
create policy payment_collectors_select on public.payment_collectors
  for select to authenticated
  using (
    (public.is_admin()
     and public.admin_can_country((select auth.uid()), country_code))
    or profile_id = (select auth.uid())
  );

-- 2) set_competition_payment_options + collector_id ──────────────────────────
create or replace function public.set_competition_payment_options(
  p_competition_id uuid,
  p_options jsonb
)
returns integer
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_opt          jsonb;
  v_count        integer := 0;
  v_country      text;
  v_collector_id uuid;
  v_opt_country  text;
begin
  if not public.is_admin() then
    raise exception 'Reserve aux admins' using errcode = '42501';
  end if;

  select country_code into v_country
    from public.competitions where id = p_competition_id;
  if v_country is null then
    raise exception 'Competition introuvable' using errcode = 'P0002';
  end if;

  if not public.admin_can_country(auth.uid(), v_country) then
    raise exception 'Compétition hors de votre perimetre pays'
      using errcode = '42501';
  end if;

  delete from public.competition_payment_options
   where competition_id = p_competition_id;

  if p_options is null or jsonb_typeof(p_options) <> 'array' then
    return 0;
  end if;

  for v_opt in select * from jsonb_array_elements(p_options)
  loop
    v_opt_country := upper(trim(v_opt->>'country_code'));
    v_collector_id := nullif(trim(coalesce(v_opt->>'collector_id', '')), '')::uuid;

    -- Garde : le collecteur choisi doit exister et couvrir le pays de l'option.
    if v_collector_id is not null then
      if not exists (
        select 1 from public.payment_collectors c
        where c.id = v_collector_id and c.country_code = v_opt_country
      ) then
        raise exception 'Collecteur invalide pour le pays %', v_opt_country
          using errcode = '42501';
      end if;
    end if;

    insert into public.competition_payment_options
      (competition_id, country_code, operator_label, transfer_code,
       dial_code, payment_number, sort_order, collector_id)
    values (
      p_competition_id,
      v_opt_country,
      trim(v_opt->>'operator_label'),
      trim(v_opt->>'transfer_code'),
      nullif(trim(coalesce(v_opt->>'dial_code', '')), ''),
      nullif(trim(coalesce(v_opt->>'payment_number', '')), ''),
      coalesce((v_opt->>'sort_order')::int, v_count),
      v_collector_id
    );
    v_count := v_count + 1;
  end loop;

  return v_count;
end;
$$;

revoke execute on function public.set_competition_payment_options(uuid, jsonb)
  from anon, public;
grant execute on function public.set_competition_payment_options(uuid, jsonb)
  to authenticated;

-- 3) Options de checkout avec disponibilité (collecteur non bloqué) ──────────
--    SECURITY DEFINER : calcule collector_accepts_payments() sans exposer
--    payment_collectors au joueur. `available=false` → option masquée / pays en
--    « maintenance » côté app.
create or replace function public.competition_checkout_payment_options(
  p_competition_id uuid
)
returns table (
  id             uuid,
  competition_id uuid,
  country_code   text,
  operator_label text,
  transfer_code  text,
  dial_code      text,
  payment_number text,
  sort_order     integer,
  collector_id   uuid,
  available      boolean
)
language sql
stable
security definer
set search_path = public
as $$
  select
    o.id, o.competition_id, o.country_code, o.operator_label,
    o.transfer_code, o.dial_code, o.payment_number, o.sort_order,
    o.collector_id, public.collector_accepts_payments(o.collector_id)
  from public.competition_payment_options o
  where o.competition_id = p_competition_id
  order by o.country_code, o.sort_order;
$$;

grant execute on function public.competition_checkout_payment_options(uuid)
  to authenticated, anon;
