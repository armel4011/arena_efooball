-- =============================================================================
-- ARENA — Sécurité — Correctifs advisors (2026-06-05)
-- =============================================================================
-- Deux warnings Supabase advisor (security) pré-existants :
--
--  1. public_bucket_allows_listing — storage.notification_images
--     La policy `notification_images_public_read` accordait SELECT à `anon`
--     sur tout le bucket → n'importe qui pouvait ÉNUMÉRER (list) les fichiers
--     uploadés. Or le bucket est `public=true` : l'affichage côté app
--     (super_admin_promo_banner / broadcast / admin_chat passent tous par
--     `getPublicUrl()`) et le fetch image par FCM se font via le CDN public,
--     qui contourne la RLS. La policy SELECT pour `anon` n'a donc AUCUN rôle
--     fonctionnel — seulement le listing. On la remplace par un SELECT
--     réservé aux admins (utile pour un éventuel écran d'admin qui lirait
--     le bucket via l'API storage), ce qui coupe l'énumération anon/user.
--
--  2. anon_security_definer_function_executable — public.admin_filter_users
--     La version LOT C (20260518163612) a recréé la fonction avec une
--     nouvelle signature (ajout de p_competition_id) → l'ACL par défaut
--     `EXECUTE TO PUBLIC` a été réappliquée et jamais révoquée, rendant la
--     RPC appelable par `anon`. La fonction vérifie `is_admin()` en interne
--     (donc pas d'exposition de données), mais par principe de moindre
--     privilège on retire anon/public et on ne laisse que `authenticated`.
-- =============================================================================

-- ─── 1. Bucket notification_images : couper le listing anon/user ────────────
-- Le bucket reste public (getPublicUrl + FCM OK via CDN, sans RLS).
drop policy if exists "notification_images_public_read" on storage.objects;

drop policy if exists "notification_images_admin_list" on storage.objects;
create policy "notification_images_admin_list"
  on storage.objects for select
  to authenticated
  using (
    bucket_id = 'notification_images'
    and public.is_admin()
  );

-- ─── 2. admin_filter_users : révoque execute de public/anon (tous overloads) ─
do $$
declare
  r record;
begin
  for r in
    select oid::regprocedure as sig
    from pg_proc
    where proname = 'admin_filter_users'
      and pronamespace = 'public'::regnamespace
  loop
    execute format('revoke execute on function %s from public, anon', r.sig);
    execute format('grant  execute on function %s to authenticated', r.sig);
  end loop;
end $$;
