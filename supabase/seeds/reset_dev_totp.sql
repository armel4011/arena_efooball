-- =============================================================================
-- ARENA — Dev: reset TOTP enrolment for the super-admin test account
-- =============================================================================
-- Met l'admin de test dans l'état "jamais enrôlé" pour rejouer le vrai flow
-- setup-totp (QR + scan + backup codes). Inverse de dev_super_admin.sql qui
-- force totp_enabled=true pour sauter l'écran de setup.
--
--   ./bin/supabase.exe db query --file supabase/seeds/reset_dev_totp.sql
-- =============================================================================

update public.profiles
   set totp_enabled = false,
       totp_secret  = null,
       backup_codes = '[]'::jsonb
 where email = 'marketingsoft4011@gmail.com';

select email, role, totp_enabled,
       (totp_secret is not null) as has_secret,
       coalesce(jsonb_array_length(backup_codes), 0) as backup_count
  from public.profiles
 where email = 'marketingsoft4011@gmail.com';
