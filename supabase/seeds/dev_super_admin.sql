-- =============================================================================
-- ARENA — Dev seed: super-admin test account
-- =============================================================================
-- Creates (or upgrades) marketingsoft4011@gmail.com as a super_admin with
-- totp_enabled = true so the admin app router skips the TOTP setup screen
-- (which depends on PHASE 12.5 Edge Functions not deployed yet).
--
-- HOW TO RUN
--   npx supabase db query --linked --file supabase/seeds/dev_super_admin.sql
-- =============================================================================

do $$
declare
  v_email text := 'marketingsoft4011@gmail.com';
  v_password text := 'famille4011';
  v_user_id uuid;
begin
  -- 1. Ensure the auth.users row exists.
  select id into v_user_id from auth.users where email = v_email;

  if v_user_id is null then
    insert into auth.users (
      instance_id,
      id,
      aud,
      role,
      email,
      encrypted_password,
      email_confirmed_at,
      raw_app_meta_data,
      raw_user_meta_data,
      created_at,
      updated_at,
      confirmation_token,
      email_change,
      email_change_token_new,
      recovery_token
    ) values (
      '00000000-0000-0000-0000-000000000000',
      gen_random_uuid(),
      'authenticated',
      'authenticated',
      v_email,
      crypt(v_password, gen_salt('bf')),
      now(),
      '{"provider":"email","providers":["email"]}'::jsonb,
      jsonb_build_object('username', 'superadmin'),
      now(),
      now(),
      '',
      '',
      '',
      ''
    )
    returning id into v_user_id;
  else
    -- Reset password + ensure email is confirmed.
    update auth.users
       set encrypted_password = crypt(v_password, gen_salt('bf')),
           email_confirmed_at = coalesce(email_confirmed_at, now()),
           updated_at = now()
     where id = v_user_id;
  end if;

  -- 2. Upsert the profile row as super_admin with TOTP marked enabled
  --    so the admin router skips the setup gate.
  insert into public.profiles (
    id,
    username,
    email,
    country_code,
    role,
    totp_enabled,
    is_active,
    cgu_accepted_at,
    cgu_version_accepted,
    privacy_policy_accepted_at
  ) values (
    v_user_id,
    'superadmin',
    v_email,
    'CM',
    'super_admin',
    true,
    true,
    now(),
    'v1.0',
    now()
  )
  on conflict (id) do update
     set role = excluded.role,
         totp_enabled = excluded.totp_enabled,
         is_active = excluded.is_active,
         cgu_accepted_at = coalesce(public.profiles.cgu_accepted_at, excluded.cgu_accepted_at),
         cgu_version_accepted = coalesce(public.profiles.cgu_version_accepted, excluded.cgu_version_accepted),
         privacy_policy_accepted_at = coalesce(public.profiles.privacy_policy_accepted_at, excluded.privacy_policy_accepted_at);

  raise notice 'Super-admin seeded: % (id=%)', v_email, v_user_id;
end $$;

-- Verification: show the seeded row.
select u.id, u.email, p.username, p.role, p.totp_enabled, p.is_active
  from auth.users u
  join public.profiles p on p.id = u.id
 where u.email = 'marketingsoft4011@gmail.com';
