-- ============================================================================
-- Sondage « jeux qui intéressent l'utilisateur » — colonne de stockage
-- ============================================================================
-- `profiles.game_interests text[]` : liste des GameType.value dont l'utilisateur
-- veut disputer des compétitions. Sémantique de l'état :
--   • NULL  → l'utilisateur n'a JAMAIS répondu (nouveau compte) → le dialogue
--             obligatoire s'affiche au 1er démarrage (déclenché sur IS NULL).
--   • {…}   → a répondu (liste des jeux cochés). {} = répondu sans aucun jeu
--             (cas des comptes EXISTANTS backfillés : on ne les sollicite pas,
--             le sondage cible les NOUVEAUX users).
--
-- Règle profiles C-1 : toute nouvelle colonne lue au client exige un
-- `grant select (col)` explicite (sinon 42501). Fait ici, dans le même fichier
-- (on ne répète pas l'oubli avatar_url de 20260617131921).
-- ----------------------------------------------------------------------------

alter table public.profiles
  add column if not exists game_interests text[];

comment on column public.profiles.game_interests is
  'Jeux (GameType.value) dont l''utilisateur veut disputer des compétitions. '
  'NULL = jamais répondu (déclenche le sondage au 1er démarrage) ; {} = répondu '
  'sans jeu (comptes existants backfillés). Écrit une seule fois via set_game_interests.';

-- Valeurs bornées aux jeux connus (aligné sur competitions_game_check).
-- ⚠️ AJOUTER UN JEU = mettre à jour CETTE contrainte aussi (cf. game_catalog_wiring).
alter table public.profiles
  drop constraint if exists profiles_game_interests_valid;
alter table public.profiles
  add constraint profiles_game_interests_valid
  check (
    game_interests is null
    or game_interests <@ array['efootball', 'draughts', 'ea_sports_fc', 'dream_league']::text[]
  );

-- Backfill : les comptes EXISTANTS ne doivent PAS voir le dialogue (sondage =
-- nouveaux users). On les marque « répondu = {} » → game_interests IS NOT NULL.
update public.profiles set game_interests = '{}'::text[] where game_interests is null;

grant select (game_interests) on public.profiles to anon, authenticated;
