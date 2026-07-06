-- ─────────────────────────────────────────────────────────────────────
-- RPC : (ré)écriture atomique des options de paiement d'une compétition
-- ─────────────────────────────────────────────────────────────────────
-- Le wizard admin (création + édition) envoie la liste complète des options
-- de paiement (pays × opérateur × code). Cette RPC applique un REMPLACE-TOUT
-- transactionnel : elle supprime les options existantes puis réinsère la liste
-- fournie. En cas d'option invalide (contraintes de table), TOUTE l'opération
-- est annulée (le delete inclus) → jamais d'état partiel.
--
-- L'INSERT de la compétition elle-même reste côté client (RLS
-- competitions_insert_admin) ; on l'appelle juste après avec l'id retourné.
--
-- p_options : tableau JSON d'objets
--   { country_code, operator_label, transfer_code, dial_code?, sort_order? }

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
  v_opt   jsonb;
  v_count integer := 0;
begin
  if not public.is_admin() then
    raise exception 'Reserve aux admins' using errcode = '42501';
  end if;
  if not exists (select 1 from public.competitions where id = p_competition_id) then
    raise exception 'Competition introuvable' using errcode = 'P0002';
  end if;

  -- Remplace-tout : on repart d'une table vierge pour cette compétition.
  delete from public.competition_payment_options
   where competition_id = p_competition_id;

  if p_options is null or jsonb_typeof(p_options) <> 'array' then
    return 0;
  end if;

  for v_opt in select * from jsonb_array_elements(p_options)
  loop
    insert into public.competition_payment_options
      (competition_id, country_code, operator_label, transfer_code, dial_code, sort_order)
    values (
      p_competition_id,
      upper(trim(v_opt->>'country_code')),
      trim(v_opt->>'operator_label'),
      trim(v_opt->>'transfer_code'),
      nullif(trim(coalesce(v_opt->>'dial_code', '')), ''),
      coalesce((v_opt->>'sort_order')::int, v_count)
    );
    v_count := v_count + 1;
  end loop;

  return v_count;
end;
$$;

comment on function public.set_competition_payment_options(uuid, jsonb) is
  'Remplace-tout transactionnel des options de paiement (pays/opérateur/code) '
  'd''une compétition. Gate is_admin(). Utilisée à la création et à l''édition.';

revoke execute on function public.set_competition_payment_options(uuid, jsonb) from anon, public;
grant execute on function public.set_competition_payment_options(uuid, jsonb) to authenticated;
