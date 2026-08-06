-- Date de naissance (PII) : saisie à l'inscription, lisible par le propriétaire
-- et les admins (via admin_filter_users, DEFINER). PAS ajoutée à public_profiles.
-- Règle C-1 : SELECT sur profiles est accordé colonne par colonne → grant requis.

alter table public.profiles add column if not exists birth_date date;

alter table public.profiles drop constraint if exists profiles_birth_date_chk;
alter table public.profiles add constraint profiles_birth_date_chk
  check (
    birth_date is null
    or (birth_date <= current_date
        and birth_date > current_date - interval '120 years')
  );

grant select (birth_date) on public.profiles to anon, authenticated;
grant insert (birth_date) on public.profiles to authenticated;
grant update (birth_date) on public.profiles to authenticated;
