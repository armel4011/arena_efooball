-- =============================================================================
-- PHASE 11bis (suite) — Inscription auto sur comp gratuites + trigger payment
-- =============================================================================
-- 1. Policy : le joueur peut s'inscrire seul aux comps GRATUITES
--    (registration_fee = 0). Pour les comps PAYANTES, l'inscription est
--    insérée automatiquement par le trigger trg_payment_validated quand
--    le super-admin valide le paiement (status='succeeded').
--
-- 2. Trigger : après UPDATE de payments.status → 'succeeded',
--    insert/upsert competition_registrations en 'confirmed'.
--
-- 3. Fonction : expire_stale_payments() — passe en 'expired' les rows
--    awaiting_admin dont expires_at est dépassé. Appellable côté admin
--    page (refresh) ou via pg_cron PHASE 12.5.
-- =============================================================================

-- 1. Self-INSERT joueur sur comp gratuites uniquement
drop policy if exists "registrations_free_self_insert"
  on public.competition_registrations;

create policy "registrations_free_self_insert"
  on public.competition_registrations for insert
  with check (
    auth.uid() = player_id
    and status = 'confirmed'
    and payment_id is null
    and exists (
      select 1 from public.competitions c
      where c.id = competition_id
        and c.registration_fee = 0
    )
  );

-- 2. Trigger payment_validated → upsert registration
create or replace function public.on_payment_validated()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if new.status = 'succeeded' and (old.status is distinct from 'succeeded') then
    insert into public.competition_registrations
      (competition_id, player_id, status, payment_id)
    values
      (new.competition_id, new.user_id, 'confirmed', new.id)
    on conflict (competition_id, player_id) do update
      set status = 'confirmed',
          payment_id = excluded.payment_id;
  end if;
  return new;
end;
$$;

comment on function public.on_payment_validated is
  'PHASE 11bis : quand le super-admin valide un paiement (succeeded), insère ou met à jour la registration correspondante en confirmed.';

drop trigger if exists trg_payment_validated_insert_registration
  on public.payments;

create trigger trg_payment_validated_insert_registration
  after update on public.payments
  for each row execute function public.on_payment_validated();

-- 3. Helper : marquer les paiements awaiting_admin expirés
create or replace function public.expire_stale_payments()
returns int
language plpgsql
security definer
set search_path = public
as $$
declare
  updated_count int;
begin
  update public.payments
     set status = 'expired'
   where status = 'awaiting_admin'
     and expires_at < now();
  get diagnostics updated_count = row_count;
  return updated_count;
end;
$$;

comment on function public.expire_stale_payments is
  'PHASE 11bis : passe en expired tous les paiements awaiting_admin dont expires_at est dépassé. Retourne le nombre de rows mis à jour. À appeler par la page admin (refresh) ou pg_cron PHASE 12.5.';

grant execute on function public.expire_stale_payments() to authenticated;
