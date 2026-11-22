-- Audit 2026-11-22 (P2-1) — Ancre le collecteur d'un paiement côté serveur.
--
-- Avant : `payments.collector_id` était posé par le CLIENT, et la seule garde
-- (`collector_accepts_payments`) renvoyait `true` quand collector_id IS NULL.
-- Un client modifié pouvait donc insérer un paiement avec collector_id null
-- (ou le collecteur d'un autre pays non bloqué) pour contourner le gel
-- « maintenance » d'un collecteur dont le quota est atteint → comptabilité
-- collecteur faussée / gel non opposable.
--
-- Fix : trigger BEFORE INSERT qui, SI la compétition est gérée par un
-- collecteur POUR LE PAYS du paiement, exige que `collector_id` soit non nul
-- ET rattaché à une option de paiement de cette compétition+pays.
--
-- Cameroun-safe : les compétitions/pays SANS option collecteur (codes directs
-- Orange/MTN, collector_id null) ne sont PAS impactés. Scope (competition_id,
-- country_code) pour ne pas rejeter un paiement direct légitime d'un pays sans
-- collecteur dans une compétition qui a un collecteur sur un AUTRE pays.
-- Validé : 0 paiement existant ne viole la règle au moment de la migration.

create or replace function public.guard_payment_collector_binding()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_managed boolean;
begin
  -- Ne concerne que les paiements manuels mobile money rattachés à une compét.
  if new.provider is distinct from 'mobile_money_manual'
     or new.competition_id is null then
    return new;
  end if;

  -- La compétition est-elle gérée par au moins un collecteur POUR CE PAYS ?
  -- SECURITY DEFINER → la vérif voit toutes les options, indépendamment du RLS
  -- du client (sinon un client qui ne « voit » pas l'option échapperait au gate).
  select exists (
    select 1 from public.competition_payment_options o
    where o.competition_id = new.competition_id
      and o.country_code   = new.country_code
      and o.collector_id is not null
  ) into v_managed;

  if v_managed then
    if new.collector_id is null
       or not exists (
         select 1 from public.competition_payment_options o
         where o.competition_id = new.competition_id
           and o.country_code   = new.country_code
           and o.collector_id   = new.collector_id
       ) then
      raise exception 'Collecteur de paiement invalide pour cette compétition'
        using errcode = '42501';
    end if;
  end if;

  return new;
end;
$$;

drop trigger if exists trg_guard_payment_collector_binding on public.payments;
create trigger trg_guard_payment_collector_binding
  before insert on public.payments
  for each row execute function public.guard_payment_collector_binding();

-- Fonction trigger : pas destinée à l'appel RPC.
revoke all on function public.guard_payment_collector_binding() from public, anon, authenticated;
