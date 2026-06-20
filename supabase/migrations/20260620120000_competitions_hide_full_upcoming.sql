-- ─────────────────────────────────────────────────────────────────────
-- Masque les compétitions PLEINES + « à venir » aux non-inscrits
-- ─────────────────────────────────────────────────────────────────────
-- Règle produit : quand une compétition est PLEINE (current_players >=
-- max_players) mais que la date de début n'est pas encore arrivée (statut
-- encore « à venir » : draft / registration_open / registration_closed), elle
-- doit être MASQUÉE aux utilisateurs NON inscrits, et rester VISIBLE aux
-- inscrits (confirmés) ainsi qu'aux admins. Dès qu'elle passe en cours
-- (ongoing) ou terminée (completed / cancelled), elle redevient visible à tous.
--
-- Implémentation : on resserre la lecture publique de `competitions`. Deux
-- policies SELECT permissives `using (true)` coexistaient (`competitions_select`
-- de 20260505185438 + `competitions_public_read` résiduelle de 20260505100005,
-- jamais dédupliquée) — combinées en OR, elles rendaient TOUT visible. On les
-- supprime toutes les deux et on recrée UNE seule policy conditionnelle
-- (`competitions_select`, le nom canonique). Le masquage est ainsi appliqué
-- CÔTÉ BASE — la compétition disparaît de la liste ET l'accès direct par id
-- (`/competitions/:id`) renvoie « introuvable » (la page détail gère déjà null).
--
-- Perf : la sous-requête EXISTS s'appuie sur la PK
-- competition_registrations (competition_id, player_id) → index couvrant.
-- `(select auth.uid())` / `(select public.is_admin())` = pattern initplan
-- (évaluation unique par requête, pas par ligne).

drop policy if exists "competitions_public_read" on public.competitions;
drop policy if exists "competitions_select" on public.competitions;

create policy "competitions_select"
  on public.competitions for select
  using (
    -- Visible par défaut, SAUF le cas « pleine ET encore à venir »…
    not (
      current_players >= max_players
      and status in ('draft', 'registration_open', 'registration_closed')
    )
    -- …sauf pour les admins…
    or (select public.is_admin())
    -- …et pour les joueurs inscrits (confirmés) à cette compétition.
    or exists (
      select 1
      from public.competition_registrations r
      where r.competition_id = competitions.id
        and r.player_id = (select auth.uid())
        and r.status = 'confirmed'
    )
  );
