-- ─────────────────────────────────────────────────────────────────────
-- Dames — spectateurs : ouvre la LECTURE des parties aux utilisateurs
-- authentifiés (cohérent avec `matches` dont le SELECT est déjà USING(true)).
-- ─────────────────────────────────────────────────────────────────────
-- Avant : seuls les 2 joueurs (+ admins) lisaient la partie. Désormais tout
-- utilisateur connecté peut REGARDER (lecture seule). L'écriture reste
-- impossible (aucune policy insert/update → seul le service_role/EF écrit),
-- donc un spectateur ne peut pas jouer ni tricher.
-- ─────────────────────────────────────────────────────────────────────

drop policy if exists draughts_games_player_select on public.draughts_games;
drop policy if exists draughts_moves_player_select on public.draughts_moves;

create policy draughts_games_select on public.draughts_games
  for select using ((select auth.uid()) is not null);

create policy draughts_moves_select on public.draughts_moves
  for select using ((select auth.uid()) is not null);
