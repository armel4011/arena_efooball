-- =============================================================================
-- ARENA — Cloisonnement pays de la lecture admin des preuves (audit 2026-07-10)
-- =============================================================================
-- P3 cohérence : `payment_proofs_admin_read` et `match_proofs_admin_read`
-- laissaient TOUT admin lire les preuves (screenshots de paiement = PII
-- financière ; preuves de match) sans cloisonnement pays, alors que
-- `match_recordings_admin_read` (même famille) EST country-scopé. On aligne :
-- un admin restreint ne voit que les preuves des compétitions/paiements de son
-- périmètre ; super-admin (scope NULL via admin_can_country) voit tout.
--
-- NB : `storage.objects.name` est QUALIFIÉ (piège RLS storage : `name` seul est
-- ambigu). Chemins : payment-proofs = {payment_id}/{uid}/… ; match-proofs =
-- {match_id}/{uid}/…  → foldername[1] identifie la ressource parente.
-- =============================================================================

drop policy if exists payment_proofs_admin_read on storage.objects;
create policy payment_proofs_admin_read on storage.objects
  for select to authenticated
  using (
    bucket_id = 'payment-proofs'
    AND (EXISTS (
      SELECT 1 FROM public.profiles p
      WHERE p.id = auth.uid()
        AND p.role = ANY (ARRAY['admin'::user_role, 'super_admin'::user_role])
    ))
    AND public.admin_can_country(
      auth.uid(),
      (SELECT pay.country_code FROM public.payments pay
        WHERE pay.id::text = (storage.foldername(storage.objects.name))[1])
    )
  );

drop policy if exists match_proofs_admin_read on storage.objects;
create policy match_proofs_admin_read on storage.objects
  for select to authenticated
  using (
    bucket_id = 'match-proofs'
    AND (EXISTS (
      SELECT 1 FROM public.profiles p
      WHERE p.id = auth.uid()
        AND p.role = ANY (ARRAY['admin'::user_role, 'super_admin'::user_role])
    ))
    AND public.admin_can_country(
      auth.uid(),
      (SELECT c.country_code
         FROM public.matches m
         JOIN public.competitions c ON c.id = m.competition_id
        WHERE m.id::text = (storage.foldername(storage.objects.name))[1])
    )
  );
