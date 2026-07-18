-- ============================================================================
-- set_game_interests — passe de « écriture unique » à « modifiable »
-- ============================================================================
-- Décision produit 2026-07-18 : l'utilisateur peut désormais mettre à jour ses
-- jeux d'intérêt depuis les réglages. On retire donc le verrou write-once
-- (`and game_interests is null`) de la définition initiale (20260718161000).
--
-- Gardes conservées :
--   • utilisateur authentifié, agit UNIQUEMENT sur sa propre ligne ;
--   • au moins un jeu (le sondage/les réglages exigent ≥1 jeu) ;
--   • valeurs bornées aux GameType connus (défense en profondeur + CHECK).
--
-- La sémantique NULL reste intacte : NULL = jamais répondu (déclenche le
-- dialogue obligatoire). Comme on impose ≥1 jeu, une ligne renseignée ne peut
-- jamais redevenir NULL ni vide → le dialogue ne se re-déclenche pas.
-- ⚠️ AJOUTER UN JEU = mettre à jour l'allowlist ci-dessous (cf. game_catalog_wiring).
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

  -- Modifiable : plus de garde `game_interests is null`. Écriture idempotente
  -- (dédoublonnée + triée) sur la ligne de l'appelant.
  update public.profiles
     set game_interests = (select array_agg(distinct g order by g) from unnest(p_games) g)
   where id = v_uid;
end;
$$;

revoke all on function public.set_game_interests(text[]) from public, anon;
grant execute on function public.set_game_interests(text[]) to authenticated;
