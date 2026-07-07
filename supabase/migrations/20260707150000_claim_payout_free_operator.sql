-- =============================================================================
-- ARENA — Audit 2026-07-07 (P2) : retrait des gains multi-pays / opérateur libre
-- =============================================================================
-- La feature multi-pays (20260706100200) a relâché payments ET payouts
-- (opérateurs libres, colonnes country_code, DROP des CHECK payer_method /
-- payee_method), MAIS la RPC `claim_payout` codait toujours en dur
--   if p_method not in ('MTN_MOMO','ORANGE_MONEY') then raise ...
-- → un gagnant d'un tournoi hors Cameroun (ex. Sénégal / Wave) ne pouvait PAS
-- réclamer son gain (méthode « invalide »), et `mark_payout_paid` (qui exige un
-- numéro réclamé) restait alors bloqué : versement légitime impossible.
--
-- CORRECTIF : on aligne `claim_payout` sur le modèle multi-pays des paiements —
-- `p_method` porte désormais le libellé d'opérateur LIBRE choisi par le gagnant
-- (ex. « Wave », « MTN MoMo », « Orange Money »). On remplace la liste blanche
-- figée par une simple validation de forme (non vide, longueur raisonnable).
-- Le reste (owner-only, statut réclamable, numéro requis, FOR UPDATE) est
-- conservé à l'identique.
-- =============================================================================

create or replace function public.claim_payout(
  p_payout_id uuid,
  p_phone     text,
  p_method    text
)
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

  -- Opérateur LIBRE (multi-pays) : plus de liste blanche MTN/ORANGE. On exige
  -- seulement un libellé d'opérateur non vide et de longueur raisonnable.
  if coalesce(trim(p_method), '') = '' then
    raise exception 'Operateur de retrait requis' using errcode = '22023';
  end if;
  if char_length(trim(p_method)) > 40 then
    raise exception 'Operateur de retrait invalide (trop long)' using errcode = '22023';
  end if;
  if coalesce(trim(p_phone), '') = '' then
    raise exception 'Numero de retrait requis' using errcode = '22023';
  end if;

  update public.payouts
     set payee_phone  = trim(p_phone),
         payee_method = trim(p_method),
         claimed_at   = now()
   where id = p_payout_id;
end;
$$;

comment on function public.claim_payout(uuid, text, text) is
  'Le gagnant réclame son gain (owner-only, statut pending_admin_validation). '
  'P2 audit 2026-07-07 : p_method = opérateur LIBRE (multi-pays), plus de liste '
  'blanche MTN/ORANGE — validation de forme (non vide, <= 40 car.).';

revoke execute on function public.claim_payout(uuid, text, text) from anon, public;
grant execute on function public.claim_payout(uuid, text, text) to authenticated;
