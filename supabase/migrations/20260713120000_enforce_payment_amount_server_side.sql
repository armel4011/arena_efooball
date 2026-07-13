-- Recale (source de vérité SERVEUR) le montant et la devise d'un paiement
-- manuel sur les valeurs autoritatives de la compétition.
--
-- Contexte / audit 2026-07-13 (P2) : `payments.amount_local` et `currency`
-- étaient insérés côté client (payment_repository.submitManualPayment). La
-- policy `payments_self_insert` ne validait que l'ownership + provider +
-- status='awaiting_admin', pas le montant. Un client modifié pouvait donc
-- créer un paiement `awaiting_admin` à 1 XAF pour n'importe quelle
-- compétition — seule la vérification humaine du super-admin (montant vs
-- preuve) compensait.
--
-- La subvention (`authorized_subsidy_local`) alimente la cagnotte, pas
-- l'entrée ; le parrainage gratuit ne crée pas de paiement. Le montant dû
-- est donc toujours `registration_fee` dans `registration_currency`.
-- Vérifié au déploiement : 0 écart sur l'historique (le recalage ne modifie
-- aucun paiement légitime existant) et corrige au passage la devise codée
-- en dur 'XAF' côté client (registration_currency devient autoritative).

create or replace function public.enforce_payment_amount()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_fee      numeric;
  v_currency text;
begin
  -- Ne touche que le canal d'inscription P2P manuel.
  if new.provider is distinct from 'mobile_money_manual' then
    return new;
  end if;

  select registration_fee, registration_currency
    into v_fee, v_currency
    from public.competitions
   where id = new.competition_id;

  if not found then
    raise exception 'Compétition introuvable pour ce paiement'
      using errcode = 'P0002';
  end if;

  -- Montant / devise dictés par le SERVEUR, pas par le client.
  new.amount_local := v_fee;
  new.currency     := coalesce(v_currency, new.currency);
  return new;
end;
$$;

drop trigger if exists trg_enforce_payment_amount on public.payments;
create trigger trg_enforce_payment_amount
  before insert on public.payments
  for each row execute function public.enforce_payment_amount();
