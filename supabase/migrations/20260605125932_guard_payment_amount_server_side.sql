-- =============================================================================
-- ARENA — Sécurité M-1 : montant de paiement autoritaire côté serveur
-- =============================================================================
-- La policy `payments_self_insert` (20260513100001) autorise le joueur à
-- insérer son row de paiement P2P manuel, mais ne contrôle que
-- (auth.uid()=user_id, provider='mobile_money_manual', status='awaiting_admin').
-- Le client fournissait `amount_local` et `currency` librement → un joueur
-- pouvait écrire un montant arbitraire ne correspondant pas aux frais
-- d'inscription de la compétition, induisant le super-admin en erreur lors de
-- la validation et faussant les agrégats de revenus (platform_revenue / KPIs).
--
-- Contrairement à `payouts` (verrouillé par C2) et `matches` (#1), `payments`
-- n'avait aucune garde serveur sur les colonnes financières à l'INSERT.
--
-- Correctif (même esprit que les guards C1/C2/#1) : trigger BEFORE INSERT
-- `SECURITY INVOKER` qui, pour tout chemin client PostgREST NON-ADMIN sur le
-- provider manuel, ÉCRASE `amount_local`/`currency` avec les valeurs
-- canoniques de la compétition (`registration_fee`/`registration_currency`).
-- Le client ne peut donc plus mentir sur le montant. Les admins et le
-- service_role (current_user <> authenticated/anon) restent libres — utile
-- pour les ajustements et les futurs flux passerelle (CinetPay/NowPayments V2).
--
-- Depends on: 20260513100001 (payments manual + competitions.registration_*),
--             20260519160000 (grant is_admin to authenticated).
-- =============================================================================

create or replace function public.guard_payments_amount()
returns trigger
language plpgsql
security invoker
set search_path = public, pg_temp
as $$
declare
  v_fee      numeric;
  v_currency text;
begin
  -- Seul le chemin client PostgREST non-admin du P2P manuel est contraint.
  if current_user in ('authenticated', 'anon')
     and not public.is_admin()
     and new.provider = 'mobile_money_manual'
  then
    -- Lecture autoritaire des frais d'inscription de la compétition ciblée.
    -- competitions est lisible par authenticated (navigation/inscription),
    -- donc SECURITY INVOKER suffit et préserve le test current_user.
    select registration_fee, registration_currency
      into v_fee, v_currency
      from public.competitions
      where id = new.competition_id;

    if v_fee is null then
      raise exception 'Paiement refuse : competition introuvable ou frais d''inscription absents'
        using errcode = '23503';
    end if;

    -- Montant et devise figés côté serveur : la valeur fournie par le client
    -- est ignorée et remplacée par celle de la compétition (fix audit M-1).
    new.amount_local := v_fee;
    new.currency     := v_currency;
  end if;
  return new;
end;
$$;

comment on function public.guard_payments_amount() is
  'M-1 : force amount_local/currency d''un paiement mobile_money_manual sur registration_fee/registration_currency de la competition cote serveur. Empeche un montant arbitraire cote client. Admins et service_role exemptes (current_user).';

drop trigger if exists trg_payments_guard_amount on public.payments;
create trigger trg_payments_guard_amount
  before insert on public.payments
  for each row execute function public.guard_payments_amount();
