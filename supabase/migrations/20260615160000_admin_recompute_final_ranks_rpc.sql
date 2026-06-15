-- ════════════════════════════════════════════════════════════════════
-- RPC admin : recalcule le classement final à la demande
-- ════════════════════════════════════════════════════════════════════
-- La console admin avait un « Classement automatique » qui calculait les rangs
-- CÔTÉ CLIENT (heuristique niveau-atteint + buts), divergente de la logique
-- serveur `compute_competition_final_ranks` (20260615140000 : champion/finaliste/
-- match 3e place, position de poule round-robin, qualifiés/éliminés groups). Le
-- bouton écrasait donc les bons rangs auto par des rangs crude.
--
-- On expose la MÊME fonction serveur via une RPC gardée `is_admin()`, pour que
-- le re-calcul manuel de l'admin et la clôture automatique produisent un
-- classement identique.
-- Depends on: 20260615140000 (compute_competition_final_ranks).
-- ════════════════════════════════════════════════════════════════════

create or replace function public.admin_recompute_final_ranks(p_competition_id uuid)
returns void
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
  if not public.is_admin() then
    raise exception 'Reserve aux admins' using errcode = '42501';
  end if;
  perform public.compute_competition_final_ranks(p_competition_id);
end;
$$;

comment on function public.admin_recompute_final_ranks(uuid) is
  'Recalcule competition_registrations.final_rank via compute_competition_final_ranks '
  '(même logique que la clôture auto). Gardée is_admin(). Utilisée par le bouton '
  '« Classement automatique » de la console admin.';

revoke all on function public.admin_recompute_final_ranks(uuid) from public, anon;
grant execute on function public.admin_recompute_final_ranks(uuid) to authenticated;
