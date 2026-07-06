-- =============================================================================
-- ARENA — Audit 2026-07-07 : fermeture de 2 escalades « admin simple »
-- =============================================================================
-- Fil rouge de l'audit : des durcissements ont été posés sur le chemin RPC /
-- super-admin (resolve_dispute, generate_payouts, delete_competition_cascade)
-- mais des VOIES D'ÉCRITURE RLS DIRECTES sont restées ouvertes à un admin
-- SIMPLE, contournant ces gardes.
--
-- P1 #1 — Détournement de cagnotte par écriture directe (matches / final_rank)
--   `resolve_dispute` (20260625120000) réserve l'arbitrage des matchs À PRIX au
--   super-admin, MAIS un admin simple pouvait encore :
--     • inverser `matches.winner_id` d'un match déjà réglé (setVerdict direct,
--       policy matches_update = is_admin(), guard s'auto-exemptait pour is_admin),
--     • écraser `competition_registrations.final_rank` après clôture (setFinalRank
--       direct, policy registrations_update_admin = is_admin(), AUCUN guard),
--   → au prochain generate_payouts (super-admin, qui fait confiance au
--     classement calculé), la cagnotte part au complice.
--
--   FRONTIÈRE RETENUE (verrou « re-décision ») : la 1re saisie d'un résultat /
--   rang par un admin simple reste ouverte (flux quotidien admin_matches /
--   admin_competitions inchangé). Sont réservés au super-admin, sur une
--   compétition À PRIX uniquement :
--     • MODIFIER un winner_id déjà posé (inversion d'un résultat réglé),
--     • RE-arbitrer (re-completed/forfeited) un match déjà terminal,
--     • MODIFIER final_rank d'une compétition CLÔTURÉE (completed).
--   Les fonctions serveur SECURITY DEFINER (compute_competition_final_ranks,
--   admin_recompute_final_ranks, finalize_match_score, resolve_dispute) tournent
--   en tant que propriétaire → current_user <> authenticated → guards ignorés :
--   le classement AUTOMATIQUE (déterministe) et l'arbitrage super-admin restent
--   pleinement fonctionnels.
--
-- P1 #2 — Levée d'un bannissement à vie (3-strikes) par un admin simple
--   `reintegration_admin_update` / `_delete` étaient gardées `is_admin()`, alors
--   que l'approbation débannit le compte (trigger DEFINER apply_reintegration_
--   decision → is_active=true, permanent_ban=false) et est documentée super-admin
--   only (/super/reintegration). On aligne sur is_super_admin(), comme
--   delete_competition_cascade (20260624120000).
-- =============================================================================

-- ─── Helper : la compétition a-t-elle un enjeu financier ? ───────────────────
-- Même définition que le gate resolve_dispute (prize_pool_local > 0 OU au moins
-- une part > 0 dans prize_distribution, robuste au cas pool=0 + distribution
-- saisie). SECURITY DEFINER : lit `competitions` sans dépendre de la RLS de
-- visibilité (comp_visibility_match_gate) — sinon un admin ne « voyant » pas la
-- compétition obtiendrait un faux « sans prix ».
create or replace function public.competition_has_prize(p_competition_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select exists (
    select 1
    from public.competitions c
    where c.id = p_competition_id
      and (
        coalesce(c.prize_pool_local, 0) > 0
        or exists (
          select 1
          from jsonb_array_elements_text(
            case when jsonb_typeof(c.prize_distribution) = 'array'
                 then c.prize_distribution else '[]'::jsonb end
          ) as e(val)
          where coalesce(nullif(e.val, '')::numeric, 0) > 0
        )
      )
  );
$$;

comment on function public.competition_has_prize(uuid) is
  'True si la compétition a un enjeu financier (prize_pool_local > 0 OU une part '
  '> 0 dans prize_distribution). Même logique que le gate resolve_dispute. '
  'SECURITY DEFINER pour lire competitions indépendamment de la RLS de visibilité.';

revoke all on function public.competition_has_prize(uuid) from public, anon;
grant execute on function public.competition_has_prize(uuid) to authenticated;

-- ─── P1 #1a — matches : verrou re-décision sur les matchs à prix ─────────────
-- On ÉTEND guard_matches_protected_columns (BEFORE UPDATE, SECURITY INVOKER) :
--   • bloc joueur (non-admin) : INCHANGÉ (score/winner/status terminal/bracket).
--   • NOUVEAU bloc admin simple : sur comp à prix, interdit l'inversion d'un
--     vainqueur déjà posé et le ré-arbitrage d'un match déjà terminal.
create or replace function public.guard_matches_protected_columns()
returns trigger
language plpgsql
security invoker
set search_path = public, pg_temp
as $$
begin
  -- (1) Bloc joueur (non-admin) — inchangé (S-1 / #1).
  if current_user in ('authenticated', 'anon') and not public.is_admin() then
    -- a) Score et vainqueur figés (posés uniquement via finalize_match_score).
    if new.score1    is distinct from old.score1
       or new.score2    is distinct from old.score2
       or new.winner_id is distinct from old.winner_id
    then
      raise exception 'Modification interdite : le score et le vainqueur d''un match ne peuvent etre poses que via la finalisation serveur (accord des deux joueurs)'
        using errcode = '42501';
    end if;

    -- b) Transition vers un état terminal réservée aux fonctions serveur.
    if new.status is distinct from old.status
       and new.status in ('completed', 'forfeited')
    then
      raise exception 'Modification interdite : passer un match en "%" exige la finalisation serveur', new.status
        using errcode = '42501';
    end if;

    -- c) Colonnes d'intégrité du bracket figées (S-1).
    if new.player1_id    is distinct from old.player1_id
       or new.player2_id    is distinct from old.player2_id
       or new.next_match_id is distinct from old.next_match_id
       or new.competition_id is distinct from old.competition_id
       or new.phase_id      is distinct from old.phase_id
       or new.group_id      is distinct from old.group_id
       or new.round         is distinct from old.round
       or new.match_number  is distinct from old.match_number
    then
      raise exception 'Modification interdite : l''appariement et la position d''un match dans le bracket sont geres par l''organisateur, pas par les joueurs'
        using errcode = '42501';
    end if;
  end if;

  -- (2) Bloc admin SIMPLE (P1 #1) — re-décision sur un match À PRIX réservée au
  -- super-admin. Ne s'évalue QUE si une colonne de résultat change ET que
  -- l'acteur est un admin non-super (économise l'appel competition_has_prize
  -- sur les updates courants : room_code, team_name, status→in_progress…).
  if current_user in ('authenticated', 'anon')
     and public.is_admin()
     and not public.is_super_admin()
     and (new.winner_id is distinct from old.winner_id
          or new.status  is distinct from old.status
          or new.score1  is distinct from old.score1
          or new.score2  is distinct from old.score2)
     and public.competition_has_prize(new.competition_id)
  then
    -- a) Inverser / changer un vainqueur déjà posé = re-décision.
    if old.winner_id is not null
       and new.winner_id is distinct from old.winner_id
    then
      raise exception 'Modification interdite : inverser le vainqueur d''un match a cagnotte est reserve au super-admin (via resolve_dispute)'
        using errcode = '42501';
    end if;

    -- b) Ré-arbitrer un match DÉJÀ terminal (re-score / re-winner) = re-décision.
    if old.status in ('completed', 'forfeited')
       and (new.winner_id is distinct from old.winner_id
            or new.score1 is distinct from old.score1
            or new.score2 is distinct from old.score2)
    then
      raise exception 'Modification interdite : re-arbitrer un match a cagnotte deja termine est reserve au super-admin (via resolve_dispute)'
        using errcode = '42501';
    end if;
  end if;

  return new;
end;
$$;

comment on function public.guard_matches_protected_columns() is
  '#1 + S-1 : fige score/winner/transitions terminales/colonnes de bracket cote '
  'joueur RLS. P1 audit 2026-07-07 : sur une compétition À PRIX, un admin SIMPLE '
  'ne peut plus inverser un vainqueur déjà posé ni ré-arbitrer un match terminal '
  '(réservé super-admin / resolve_dispute). Fonctions serveur DEFINER exemptes.';

-- ─── P1 #1b — competition_registrations : verrou final_rank post-clôture ─────
-- Aucun guard n'existait sur cette table (final_rank pilote generate_payouts).
-- On bloque l'écrasement de final_rank par un admin simple sur une compétition
-- À PRIX déjà CLÔTURÉE. La 1re saisie / le classement auto (DEFINER) restent OK.
create or replace function public.guard_registrations_final_rank()
returns trigger
language plpgsql
security invoker
set search_path = public, pg_temp
as $$
begin
  if current_user in ('authenticated', 'anon')
     and public.is_admin()
     and not public.is_super_admin()
     and public.competition_has_prize(new.competition_id)
     and exists (
       select 1 from public.competitions c
       where c.id = new.competition_id
         and c.status = 'completed'
     )
  then
    raise exception 'Modification interdite : modifier le classement final d''une competition a cagnotte cloturee est reserve au super-admin'
      using errcode = '42501';
  end if;
  return new;
end;
$$;

comment on function public.guard_registrations_final_rank() is
  'P1 audit 2026-07-07 : empêche un admin SIMPLE d''écraser final_rank (qui '
  'pilote generate_payouts) sur une compétition À PRIX déjà clôturée. 1re saisie '
  'et classement auto (compute_competition_final_ranks, DEFINER) exemptés.';

drop trigger if exists trg_guard_registrations_final_rank on public.competition_registrations;
create trigger trg_guard_registrations_final_rank
  before update on public.competition_registrations
  for each row
  when (old.final_rank is distinct from new.final_rank)
  execute function public.guard_registrations_final_rank();

-- ─── P1 #2 — réintégration : approbation/suppression réservées au super-admin ─
drop policy if exists reintegration_admin_update on public.reintegration_requests;
create policy reintegration_admin_update on public.reintegration_requests
  for update to public
  using ((select public.is_super_admin()))
  with check ((select public.is_super_admin()));

drop policy if exists reintegration_admin_delete on public.reintegration_requests;
create policy reintegration_admin_delete on public.reintegration_requests
  for delete to public
  using ((select public.is_super_admin()));
