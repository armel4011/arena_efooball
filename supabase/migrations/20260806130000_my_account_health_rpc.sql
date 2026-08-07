-- « Santé du compte » côté joueur : RPC SECURITY DEFINER qui agrège les
-- indicateurs anti-triche du joueur courant (auth.uid()) sans dépendre de la
-- surface RLS. Alignée sur le COUNT serveur des 3-strikes (disputes résolus
-- avec verdict) et sur streams.proof_hash_verified.

create or replace function public.my_account_health()
  returns table (
    strikes        int,
    strikes_max    int,
    verified_proofs int,
    is_active      boolean,
    permanent_ban  boolean
  )
  language sql
  stable
  security definer
  set search_path = public
as $$
  select
    (
      select count(*)::int from public.disputes d
      where d.guilty_party_id = (select auth.uid())
        and d.status = 'resolved'
        and d.resolved_by is not null
    ),
    3,
    (
      select count(*)::int from public.streams s
      where s.player_id = (select auth.uid())
        and s.proof_hash_verified is true
    ),
    coalesce(
      (select p.is_active from public.profiles p where p.id = (select auth.uid())),
      true
    ),
    coalesce(
      (select p.permanent_ban from public.profiles p
        where p.id = (select auth.uid())),
      false
    );
$$;

revoke execute on function public.my_account_health() from public, anon;
grant execute on function public.my_account_health() to authenticated;
