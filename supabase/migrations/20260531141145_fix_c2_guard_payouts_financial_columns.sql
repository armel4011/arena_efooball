-- =============================================================================
-- ARENA — Sécurité — C2 : verrou des colonnes financières de `payouts`
-- =============================================================================
-- La policy `payouts_admin_update` (20260512100001_phase11_admin_write_rls.sql:25)
-- autorise tout admin (`is_admin()`, pas seulement super-admin) à mettre à jour
-- N'IMPORTE QUELLE colonne d'un payout, y compris les montants et le
-- bénéficiaire. Les garanties de colonne étaient seulement "enforced
-- application-side" (le repo Dart ne touche que status / validated_by /
-- validated_at / justification — voir admin_payouts_repository.dart:43-64).
--
-- Risque : un admin (ou un joueur escaladé via C1) pouvait, directement sous
-- RLS, gonfler `amount_usd` / `amount_local`, réattribuer `user_id`, ou
-- valider son propre payout → vol des gains.
--
-- Correctif : trigger BEFORE UPDATE qui, pour tout appel client PostgREST
-- (`authenticated` / `anon`) :
--   1. fige les colonnes financières et d'attribution (montants, devise, taux,
--      user_id, competition_id, prize_id) — seul le workflow de validation
--      (status / validated_by / validated_at / justification / champs provider)
--      reste modifiable ;
--   2. interdit l'auto-validation : un admin ne peut pas être marqué validateur
--      d'un payout dont il est le bénéficiaire.
--
-- L'Edge Function `validate_payout` (PHASE 12.5), qui dispatchera réellement
-- l'argent, s'exécutera en service_role (`current_user <> authenticated/anon`)
-- et n'est donc pas bridée — elle reste la voie autorisée pour tout ajustement
-- financier exceptionnel.
-- =============================================================================
-- Depends on: 20260505100004_chat_payments_disputes_notifs.sql (table payouts),
--             20260512100001_phase11_admin_write_rls.sql (policy admin update)
-- =============================================================================

create or replace function public.guard_payouts_financial_columns()
returns trigger
language plpgsql
security invoker
set search_path = public, pg_temp
as $$
begin
  -- service_role + fonctions SECURITY DEFINER (current_user = owner) gardent
  -- la main : seul le client PostgREST direct est contraint.
  if current_user in ('authenticated', 'anon') then
    -- 1. Colonnes financières / d'attribution gelées côté client.
    if new.amount_usd     is distinct from old.amount_usd
       or new.amount_local    is distinct from old.amount_local
       or new.currency        is distinct from old.currency
       or new.exchange_rate   is distinct from old.exchange_rate
       or new.user_id         is distinct from old.user_id
       or new.competition_id  is distinct from old.competition_id
       or new.prize_id        is distinct from old.prize_id
    then
      raise exception 'Modification interdite : les colonnes financieres d''un payout (montants, devise, taux, beneficiaire) ne sont modifiables que par le service de versement'
        using errcode = '42501';
    end if;

    -- 2. Pas d'auto-validation : le validateur ne peut pas être le bénéficiaire.
    if new.validated_by_admin_id is not null
       and new.validated_by_admin_id = new.user_id
    then
      raise exception 'Conflit d''interet : un administrateur ne peut pas valider son propre payout'
        using errcode = '42501';
    end if;
  end if;
  return new;
end;
$$;

comment on function public.guard_payouts_financial_columns() is
  'C2 : fige les colonnes financieres/attribution de payouts cote client RLS et interdit l''auto-validation. Le service_role (EF validate_payout) reste libre.';

drop trigger if exists trg_payouts_guard_financial on public.payouts;
create trigger trg_payouts_guard_financial
  before update on public.payouts
  for each row execute function public.guard_payouts_financial_columns();
