-- =============================================================================
-- ARENA — Numéro de paiement dédié par option (zone CEMAC)
-- =============================================================================
-- Pour les pays CEMAC, le paiement Mobile Money se fait en composant un code
-- USSD PUIS en saisissant, DANS le menu de l'opérateur, le NUMÉRO destinataire.
-- Ce numéro était jusqu'ici noyé dans `transfer_code` (texte libre). On lui
-- donne un champ propre `payment_number` que le joueur peut copier — le code
-- USSD reste dans `transfer_code`.
--
-- Champ OPTIONNEL et rétro-compatible : les options existantes gardent un
-- numéro null (l'UI ne montre le bloc « numéro à copier » que s'il est fourni).
-- =============================================================================

alter table public.competition_payment_options
  add column if not exists payment_number text;

comment on column public.competition_payment_options.payment_number is
  'Numéro destinataire du paiement Mobile Money (à copier par le joueur, zone '
  'CEMAC). Distinct du code USSD (transfer_code). Optionnel.';

-- Recrée la RPC remplace-tout pour propager `payment_number` (corps inchangé
-- par ailleurs). Gate is_admin() conservé.
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
  v_opt     jsonb;
  v_count   integer := 0;
  v_country text;
begin
  if not public.is_admin() then
    raise exception 'Reserve aux admins' using errcode = '42501';
  end if;

  select country_code into v_country
    from public.competitions where id = p_competition_id;
  if v_country is null then
    raise exception 'Competition introuvable' using errcode = 'P0002';
  end if;

  -- Cloisonnement pays (miroir payouts/recordings) : un admin restreint ne peut
  -- pas réécrire les codes de collecte (transfer_code) d'une compétition hors de
  -- son périmètre. super-admin (scope NULL) = autorisé partout.
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
    insert into public.competition_payment_options
      (competition_id, country_code, operator_label, transfer_code,
       dial_code, payment_number, sort_order)
    values (
      p_competition_id,
      upper(trim(v_opt->>'country_code')),
      trim(v_opt->>'operator_label'),
      trim(v_opt->>'transfer_code'),
      nullif(trim(coalesce(v_opt->>'dial_code', '')), ''),
      nullif(trim(coalesce(v_opt->>'payment_number', '')), ''),
      coalesce((v_opt->>'sort_order')::int, v_count)
    );
    v_count := v_count + 1;
  end loop;

  return v_count;
end;
$$;

comment on function public.set_competition_payment_options(uuid, jsonb) is
  'Remplace-tout transactionnel des options de paiement (pays/opérateur/code/'
  'numéro) d''une compétition. Gate is_admin(). Création et édition.';

revoke execute on function public.set_competition_payment_options(uuid, jsonb) from anon, public;
grant execute on function public.set_competition_payment_options(uuid, jsonb) to authenticated;
