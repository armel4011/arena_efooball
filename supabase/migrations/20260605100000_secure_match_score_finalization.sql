-- =============================================================================
-- ARENA — Sécurité — #1 : verrou anti-triche des scores de `matches`
-- =============================================================================
-- La policy `matches_update` (20260517110001_consolidate_permissive_policies.sql:61)
-- autorise `(is_admin() OR player1_id OR player2_id)` à UPDATE N'IMPORTE QUELLE
-- colonne d'un match. La restriction par-colonne pour les JOUEURS n'était
-- "enforced application-side" que par le repo Dart (`commitScore` /
-- `markForfeit`), en attendant des Edge Functions PHASE 12.5 jamais livrées
-- (cf. commentaire de 20260506200001_phase5_player_match_room_rls.sql:34).
--
-- Risque : un client modifié pouvait écrire directement, sous RLS,
--   UPDATE matches SET score1=99, winner_id=<self>, status='completed'
--   WHERE id=<match>
-- → triche de score + auto-avancement du bracket via le trigger
--   `cascade_match_winner` (20260505100003:184). Aucune validation serveur
--   que les DEUX joueurs étaient d'accord sur le score.
--
-- Correctif (même esprit que C1 `profiles` / C2 `payouts`) :
--   1. Trigger BEFORE UPDATE `guard_matches_protected_columns` (SECURITY
--      INVOKER) : pour tout appel client PostgREST NON-ADMIN
--      (`authenticated`/`anon` et `not is_admin()`), fige `score1`,
--      `score2`, `winner_id` et interdit la transition de `status` vers
--      un état terminal (`completed` / `forfeited`). Les flux légitimes
--      restants (room_code → `ready`, `in_progress`, `disputed`, noms
--      d'équipe…) passent toujours.
--   2. Fonction RPC `finalize_match_score(uuid)` (SECURITY DEFINER) : seule
--      voie joueur vers `completed`. Elle RELIT les deux `score_submitted`
--      de `match_events` côté serveur, exige qu'ils CONCORDENT (le client ne
--      peut donc pas mentir), calcule le vainqueur et écrit le résultat.
--   3. Fonction RPC `forfeit_match(uuid, text)` (SECURITY DEFINER) : un joueur
--      ne peut déclarer QUE son propre forfait (victoire à l'adversaire) —
--      auto-pénalisation, donc sûre.
--
-- Les ADMINS gardent l'écriture directe (arbitrage / `admin_adjustment`,
-- cf. admin_matches_repository.dart:60) : le guard les exempte via is_admin().
-- Le service_role (current_user <> authenticated/anon) reste libre.
-- =============================================================================
-- Depends on: 20260505100003_matches_and_brackets.sql (matches, match_events,
--               cascade_match_winner), 20260517110001 (policy matches_update),
--               20260519160000 (grant is_admin to authenticated).
-- =============================================================================

-- ─── 1. Trigger-garde : fige score/winner/transition terminale côté joueur ──
create or replace function public.guard_matches_protected_columns()
returns trigger
language plpgsql
security invoker
set search_path = public, pg_temp
as $$
begin
  -- service_role + fonctions SECURITY DEFINER (current_user = owner) et les
  -- admins gardent la main. Seul le client PostgREST joueur est contraint.
  if current_user in ('authenticated', 'anon') and not public.is_admin() then
    -- a) Colonnes de résultat gelées : le score et le vainqueur ne peuvent
    --    être posés que par finalize_match_score / forfeit_match (DEFINER).
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
  end if;
  return new;
end;
$$;

comment on function public.guard_matches_protected_columns() is
  '#1 : fige score1/score2/winner_id et les transitions completed/forfeited cote joueur RLS. Admins (is_admin) et service_role/DEFINER restent libres.';

drop trigger if exists trg_matches_guard_protected on public.matches;
create trigger trg_matches_guard_protected
  before update on public.matches
  for each row execute function public.guard_matches_protected_columns();

-- ─── 2. Finalisation serveur du score (concordance des deux soumissions) ────
create or replace function public.finalize_match_score(p_match_id uuid)
returns void
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_uid        uuid := auth.uid();
  v_p1         uuid;
  v_p2         uuid;
  v_status     public.match_status;
  v_pa         jsonb;   -- dernière soumission du joueur 1
  v_pb         jsonb;   -- dernière soumission du joueur 2
  v_s1         int;
  v_s2         int;
  v_via_pen    boolean;
  v_pen1       int;
  v_pen2       int;
  v_winner     uuid;
begin
  -- Verrou de ligne : empêche une double finalisation concurrente (les deux
  -- clients détectent la concordance quasi simultanément).
  select player1_id, player2_id, status
    into v_p1, v_p2, v_status
    from public.matches
    where id = p_match_id
    for update;

  if not found then
    raise exception 'Match introuvable' using errcode = 'P0002';
  end if;

  -- Seul un joueur assis sur le match peut finaliser.
  if v_uid is null or (v_uid is distinct from v_p1 and v_uid is distinct from v_p2) then
    raise exception 'Seul un joueur du match peut finaliser le score'
      using errcode = '42501';
  end if;

  -- Anti-rejeu : pas de re-finalisation d'un match déjà clos.
  if v_status in ('completed', 'cancelled', 'forfeited') then
    raise exception 'Ce match est deja finalise (statut %)', v_status
      using errcode = '42501';
  end if;

  -- Dernière soumission de chaque joueur (le client ne fournit aucun score :
  -- le serveur est autoritaire et relit match_events).
  select payload into v_pa
    from public.match_events
    where match_id = p_match_id and type = 'score_submitted' and created_by = v_p1
    order by created_at desc limit 1;

  select payload into v_pb
    from public.match_events
    where match_id = p_match_id and type = 'score_submitted' and created_by = v_p2
    order by created_at desc limit 1;

  if v_pa is null or v_pb is null then
    raise exception 'Finalisation impossible : les deux joueurs doivent avoir soumis un score'
      using errcode = '22023';
  end if;

  v_s1      := (v_pa->>'score1')::int;
  v_s2      := (v_pa->>'score2')::int;
  v_via_pen := coalesce((v_pa->>'via_penalties')::boolean, false);
  v_pen1    := (v_pa->>'penalty1')::int;
  v_pen2    := (v_pa->>'penalty2')::int;

  -- Concordance stricte des deux soumissions (score réglementaire + tirs
  -- au but le cas échéant). En cas de désaccord → dispute (côté client).
  if v_s1 is distinct from (v_pb->>'score1')::int
     or v_s2 is distinct from (v_pb->>'score2')::int
     or v_via_pen is distinct from coalesce((v_pb->>'via_penalties')::boolean, false)
     or (v_via_pen and (v_pen1 is distinct from (v_pb->>'penalty1')::int
                        or v_pen2 is distinct from (v_pb->>'penalty2')::int))
  then
    raise exception 'Finalisation impossible : les scores soumis par les deux joueurs ne concordent pas'
      using errcode = '22023';
  end if;

  -- Vainqueur : tirs au but si égalité réglementaire jouée aux penalties,
  -- sinon différence de buts, sinon nul (winner_id null — round-robin).
  if v_via_pen and v_pen1 is not null and v_pen2 is not null then
    v_winner := case when v_pen1 > v_pen2 then v_p1
                     when v_pen2 > v_pen1 then v_p2
                     else null end;
  else
    v_winner := case when v_s1 > v_s2 then v_p1
                     when v_s2 > v_s1 then v_p2
                     else null end;
  end if;

  update public.matches
    set score1      = v_s1,
        score2      = v_s2,
        winner_id   = v_winner,
        status      = 'completed',
        finished_at = now()
    where id = p_match_id;

  -- Trace d'arbitrage : score validé par accord mutuel.
  insert into public.match_events (match_id, type, created_by, payload)
  values (
    p_match_id, 'score_validated', v_uid,
    jsonb_build_object('score1', v_s1, 'score2', v_s2,
                       'winner_id', v_winner, 'via', 'mutual_agreement')
  );
end;
$$;

comment on function public.finalize_match_score(uuid) is
  '#1 : seule voie joueur vers status=completed. Relit les deux score_submitted, exige leur concordance cote serveur, calcule le vainqueur et ecrit le resultat. SECURITY DEFINER → contourne le guard de colonnes.';

-- ─── 3. Forfait : un joueur ne peut abandonner que pour lui-même ────────────
create or replace function public.forfeit_match(p_match_id uuid, p_reason text default null)
returns void
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_uid      uuid := auth.uid();
  v_p1       uuid;
  v_p2       uuid;
  v_status   public.match_status;
  v_opponent uuid;
begin
  select player1_id, player2_id, status
    into v_p1, v_p2, v_status
    from public.matches
    where id = p_match_id
    for update;

  if not found then
    raise exception 'Match introuvable' using errcode = 'P0002';
  end if;

  if v_uid is null or (v_uid is distinct from v_p1 and v_uid is distinct from v_p2) then
    raise exception 'Seul un joueur du match peut declarer forfait'
      using errcode = '42501';
  end if;

  if v_status in ('completed', 'cancelled', 'forfeited') then
    raise exception 'Ce match est deja finalise (statut %)', v_status
      using errcode = '42501';
  end if;

  -- Le vainqueur est toujours l'adversaire du déclarant (auto-pénalisation).
  v_opponent := case when v_uid = v_p1 then v_p2 else v_p1 end;

  update public.matches
    set status      = 'forfeited',
        winner_id   = v_opponent,
        finished_at = now()
    where id = p_match_id;

  insert into public.match_events (match_id, type, created_by, payload)
  values (
    p_match_id, 'forfeit', v_uid,
    jsonb_build_object('opponent_id', v_opponent)
      || case when p_reason is not null then jsonb_build_object('reason', p_reason)
              else '{}'::jsonb end
  );
end;
$$;

comment on function public.forfeit_match(uuid, text) is
  '#1 : le joueur courant (auth.uid) declare forfait ; victoire a l''adversaire, status=forfeited. SECURITY DEFINER → contourne le guard de colonnes.';

-- ─── 4. ACL : RPC réservées aux utilisateurs authentifiés ───────────────────
revoke execute on function public.finalize_match_score(uuid) from public, anon;
revoke execute on function public.forfeit_match(uuid, text)  from public, anon;
grant  execute on function public.finalize_match_score(uuid) to authenticated;
grant  execute on function public.forfeit_match(uuid, text)  to authenticated;
