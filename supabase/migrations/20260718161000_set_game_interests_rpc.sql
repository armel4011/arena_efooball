-- ============================================================================
-- RPC set_game_interests — écriture (une seule fois) des jeux d'intérêt
-- ============================================================================
-- Seul chemin d'écriture de profiles.game_interests. SECURITY DEFINER :
--   • exige un utilisateur authentifié (agit sur sa propre ligne uniquement) ;
--   • valide que toutes les valeurs sont des GameType connus (défense en profondeur
--     en plus de la contrainte CHECK) ;
--   • exige au moins un jeu (sondage obligatoire) ;
--   • n'écrit QUE si game_interests IS NULL → réponse figée « une seule fois »
--     (un rejeu ne modifie rien, cohérent avec le choix produit non-modifiable).
-- ----------------------------------------------------------------------------

create or replace function public.set_game_interests(p_games text[])
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_uid uuid := (select auth.uid());
  v_allowed text[] := array['efootball', 'draughts', 'ea_sports_fc', 'dream_league'];
begin
  if v_uid is null then
    raise exception 'not_authenticated';
  end if;
  if p_games is null or array_length(p_games, 1) is null then
    raise exception 'at_least_one_game_required';
  end if;
  if not (p_games <@ v_allowed) then
    raise exception 'invalid_game_value';
  end if;

  update public.profiles
     set game_interests = (select array_agg(distinct g order by g) from unnest(p_games) g)
   where id = v_uid
     and game_interests is null;
end;
$$;

revoke all on function public.set_game_interests(text[]) from public, anon;
grant execute on function public.set_game_interests(text[]) to authenticated;
