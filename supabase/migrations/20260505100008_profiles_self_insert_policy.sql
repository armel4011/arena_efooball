-- =============================================================================
-- ARENA — Phase 0 — Hotfix signup
-- Permet aux utilisateurs nouvellement authentifiés (post auth.signUp)
-- d'insérer leur propre ligne dans public.profiles depuis le client.
--
-- Contexte : le repository client (lib/data/repositories/auth_repository.dart)
-- fait un INSERT côté client juste après auth.signUp. Sans policy INSERT,
-- RLS refuse avec "new row violates row-level security policy".
--
-- L'architecture initiale prévoyait une Edge Function de signup (service_role)
-- mais elle n'a pas encore été implémentée. Cette policy autorise l'insertion
-- client avec des garde-fous stricts pour éviter toute escalade de privilèges.
-- =============================================================================
-- Dépend de : 20260505100005, 20260505100007
-- =============================================================================

create policy "profiles_self_insert"
  on public.profiles for insert
  to authenticated
  with check (
    -- L'utilisateur ne peut insérer que sa propre ligne
    (select auth.uid()) = id
    -- Pas de self-promotion : forcer le rôle à 'player'
    and role = 'player'
    -- Pas d'insertion en état désactivé / soft-deleted
    and is_active = true
    and deleted_at is null
  );

comment on policy "profiles_self_insert" on public.profiles is
  'Autorise un user authentifié à créer SA ligne profil (id = auth.uid()) avec role=player.';
