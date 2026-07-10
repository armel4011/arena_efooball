-- =============================================================================
-- ARENA — Capture d'écran d'inscription/paiement P2P (upload user + vue admin)
-- =============================================================================
-- L'inscription payante est un Mobile Money manuel P2P validé à la main par le
-- super-admin. Le joueur peut désormais joindre une CAPTURE de son paiement sur
-- l'écran d'attente ; l'admin la consulte avant de valider.
--
-- Sécurité (fil rouge audit) : le joueur ne peut PAS écrire librement dans
-- `payments` (aucune policy self-update ; on n'en ouvre pas une large qui
-- laisserait forger amount/status…). Il passe par la RPC `attach_payment_proof`
-- (SECURITY DEFINER) qui ne touche QUE `proof_path`, sur SON row `awaiting_admin`.
-- Le fichier vit dans un bucket privé dédié `payment-proofs`.
-- =============================================================================

-- ─── Colonne : clé storage de la capture (null tant que non fournie) ────────
alter table public.payments
  add column if not exists proof_path text;

comment on column public.payments.proof_path is
  'Clé storage (bucket payment-proofs) de la capture de paiement fournie par le '
  'joueur. Écrite via la RPC attach_payment_proof, lue par l''admin.';

-- ─── RPC : attache la capture (proof_path) — écriture ciblée, propriétaire ──
create or replace function public.attach_payment_proof(
  p_payment_id uuid,
  p_proof_path text
)
returns void
language plpgsql
security definer
set search_path to 'public', 'pg_temp'
as $function$
begin
  update public.payments
     set proof_path = p_proof_path
   where id = p_payment_id
     and user_id = auth.uid()
     and status = 'awaiting_admin';
  if not found then
    raise exception 'Paiement introuvable ou non modifiable'
      using errcode = 'P0002';
  end if;
end;
$function$;

revoke all on function public.attach_payment_proof(uuid, text)
  from public, anon;
grant execute on function public.attach_payment_proof(uuid, text)
  to authenticated;

-- ─── Bucket privé dédié (images seules, 10 Mo suffisent pour une capture) ───
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'payment-proofs',
  'payment-proofs',
  false,
  10485760, -- 10 MiB
  array['image/jpeg', 'image/png', 'image/webp']
)
on conflict (id) do update set
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

-- Chemin : payment-proofs/{paymentId}/{userId}/{ts}.{ext}
--   foldername(name)[1] = paymentId · [2] = userId (calqué sur match-proofs)

-- Le joueur dépose UNIQUEMENT dans son sous-dossier d'un paiement qui lui
-- appartient (n'importe quel statut : il peut joindre après coup).
drop policy if exists payment_proofs_owner_insert on storage.objects;
create policy payment_proofs_owner_insert on storage.objects
  for insert to authenticated
  with check (
    bucket_id = 'payment-proofs'
    and (auth.uid())::text = (storage.foldername(name))[2]
    and exists (
      select 1 from public.payments p
      where (p.id)::text = (storage.foldername(name))[1]
        and p.user_id = auth.uid()
    )
  );

-- Relecture / remplacement de sa propre capture.
drop policy if exists payment_proofs_owner_select on storage.objects;
create policy payment_proofs_owner_select on storage.objects
  for select to authenticated
  using (
    bucket_id = 'payment-proofs'
    and (auth.uid())::text = (storage.foldername(name))[2]
  );

drop policy if exists payment_proofs_owner_update on storage.objects;
create policy payment_proofs_owner_update on storage.objects
  for update to authenticated
  using (
    bucket_id = 'payment-proofs'
    and (auth.uid())::text = (storage.foldername(name))[2]
  );

-- Admin / super-admin lisent tout pour la validation.
drop policy if exists payment_proofs_admin_read on storage.objects;
create policy payment_proofs_admin_read on storage.objects
  for select to authenticated
  using (
    bucket_id = 'payment-proofs'
    and exists (
      select 1 from public.profiles p
      where p.id = auth.uid()
        and p.role in ('admin', 'super_admin')
    )
  );
