-- Anti-faux-comptes : empreinte d'appareil sur le profil + garde à l'inscription.
--   1) max 5 comptes par appareil (device_id) ;
--   2) interdiction d'utiliser un code de parrainage dont le PARRAIN a été créé
--      sur le MÊME appareil (auto-parrainage / farming).
-- Le trigger est SECURITY DEFINER : il doit compter sur TOUS les profils
-- (la RLS profiles limiterait sinon la vue à soi-même).

alter table public.profiles add column if not exists device_id text;
grant select (device_id) on public.profiles to authenticated;
grant insert (device_id) on public.profiles to authenticated;

create index if not exists idx_profiles_device_id
  on public.profiles(device_id) where device_id is not null;

create or replace function public.guard_signup_fraud()
  returns trigger
  language plpgsql
  security definer
  set search_path = public
as $$
declare
  v_count int;
begin
  if new.device_id is not null and btrim(new.device_id) <> '' then
    -- 1) Plafond de comptes par appareil.
    select count(*) into v_count
      from public.profiles where device_id = new.device_id;
    if v_count >= 5 then
      raise exception
        'Trop de comptes ont déjà été créés depuis cet appareil (5 maximum).'
        using errcode = '42501';
    end if;

    -- 2) Pas d'auto-parrainage sur le même appareil.
    if new.referred_by is not null and btrim(new.referred_by) <> '' then
      if exists (
        select 1 from public.profiles r
        where r.referral_code = new.referred_by
          and r.device_id = new.device_id
      ) then
        raise exception
          'Ce code de parrainage ne peut pas être utilisé sur cet appareil.'
          using errcode = '42501';
      end if;
    end if;
  end if;
  return new;
end;
$$;

drop trigger if exists trg_guard_signup_fraud on public.profiles;
create trigger trg_guard_signup_fraud
  before insert on public.profiles
  for each row execute function public.guard_signup_fraud();
