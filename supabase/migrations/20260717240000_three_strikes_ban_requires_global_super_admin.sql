-- =============================================================================
-- ARENA — Audit 2026-07-17 (#2) : le ban à vie (3e strike) exige un super-admin
-- GLOBAL, jamais un super-admin scopé pays agissant seul.
-- =============================================================================
-- CONSTAT. `resolve_dispute` (20260717220000) réserve déjà la désignation d'un
-- coupable au super-admin (`is_super_admin()`) et cloisonne l'action au pays de
-- la compétition (`admin_can_country`). Mais l'autorisation est PER-MATCH, alors
-- que la conséquence — `permanent_ban` au 3e verdict via `trg_three_strikes_ban`
-- — est GLOBALE et irréversible (sortie seulement par Arena Requête sous 48 h).
--
-- Un super-admin restreint à un pays (ex. {'CM'}) qui voit une cible disputer
-- 3 matchs dans SON périmètre peut donc cumuler 3 `resolve_dispute(...,
-- p_guilty_party_id = cible)` et la bannir à vie UNILATÉRALEMENT, sans qu'aucun
-- pair ne valide. Chaque strike est audité, mais l'audit est postérieur au ban.
--
-- DURCISSEMENT. Le verdict qui ATTEINDRAIT le seuil de ban (3e strike) exige un
-- super-admin GLOBAL (`admin_allowed_countries IS NULL`). Les strikes 1 et 2
-- restent ouverts au super-admin scopé — un simple arbitrage de litige n'est pas
-- une décision de compte. Seul le franchissement du seuil, qui EST une décision
-- de compte, remonte au tier non restreint. Aligné sur l'esprit de
-- 20260709150000 (les décisions de compte au tier le plus haut).
--
-- Le contrôle est placé AVANT toute mutation (match + litige) : un refus laisse
-- l'état intact et atomique. Le seuil « 3 » est celui, codé en dur, de
-- `enforce_three_strikes_ban` (20260717190000) — on prédit ici ce que son
-- `count(*)` verra après l'UPDATE (les autres litiges déjà `resolved` + le
-- présent). Un `p_cancel` ne compte pas : le litige passe alors `cancelled`.
--
-- Même signature 8-args (20260717220000) : `create or replace` préserve l'ACL.
-- =============================================================================
-- Depends on: 20260717220000 (resolve_dispute 8-args), 20260717190000 (trigger
--   de strike), 20260706100400 (admin_allowed_countries).
-- =============================================================================

create or replace function public.resolve_dispute(
  p_match_id uuid,
  p_dispute_id uuid,
  p_justification text,
  p_cancel boolean default false,
  p_winner_id uuid default null,
  p_score1 integer default null,
  p_score2 integer default null,
  p_guilty_party_id uuid default null
)
returns void
language plpgsql
security definer
set search_path to 'public', 'pg_temp'
as $function$
declare
  v_admin         uuid := auth.uid();
  v_p1            uuid;
  v_p2            uuid;
  v_comp          uuid;
  v_country       text;
  v_pool          numeric;
  v_dist          jsonb;
  v_has_prize     boolean;
  v_score1        integer;
  v_score2        integer;
  v_prior_strikes integer;
begin
  if not public.is_admin() then
    raise exception 'Reserve aux administrateurs' using errcode = '42501';
  end if;
  if coalesce(trim(p_justification), '') = '' then
    raise exception 'Justification obligatoire' using errcode = '22023';
  end if;

  select player1_id, player2_id, competition_id into v_p1, v_p2, v_comp
    from public.matches
    where id = p_match_id
    for update;
  if not found then
    raise exception 'Match introuvable' using errcode = 'P0002';
  end if;

  -- Le coupable doit être un joueur DE CE MATCH. C'était l'absence de ce lien
  -- qui, côté REST, permettait de faire bannir un tiers arbitraire (P0).
  if p_guilty_party_id is not null
     and p_guilty_party_id <> v_p1 and p_guilty_party_id <> v_p2 then
    raise exception 'Le coupable doit etre un des deux joueurs du match'
      using errcode = '22023';
  end if;

  -- Un verdict de culpabilité n'a de sens que porté par un litige : c'est la
  -- ligne `disputes` qui compte le strike.
  if p_guilty_party_id is not null and p_dispute_id is null then
    raise exception 'Designer un coupable exige un litige (p_dispute_id)'
      using errcode = '22023';
  end if;

  -- Garde renforcée : compétition AVEC PRIX → arbitrage réservé au super-admin.
  select prize_pool_local, prize_distribution, country_code
    into v_pool, v_dist, v_country
    from public.competitions
    where id = v_comp;
  v_has_prize := coalesce(v_pool, 0) > 0
    or exists (
      select 1
      from jsonb_array_elements_text(
        case when jsonb_typeof(v_dist) = 'array' then v_dist else '[]'::jsonb end
      ) as e(val)
      where coalesce(nullif(e.val, '')::numeric, 0) > 0
    );
  if v_has_prize and not public.is_super_admin() then
    raise exception 'Litige sur un match a cagnotte : reserve au super-admin'
      using errcode = '42501';
  end if;

  -- Un verdict de culpabilité mène à un BAN À VIE au 3e : on le réserve au
  -- super-admin, même sur un match sans cagnotte. Aligné sur l'esprit de
  -- 20260709150000 (les décisions de compte sont au tier le plus haut).
  if p_guilty_party_id is not null and not public.is_super_admin() then
    raise exception 'Designer un coupable (strike) : reserve au super-admin'
      using errcode = '42501';
  end if;

  -- Cloisonnement pays (couvre aussi un super-admin lui-même scopé pays).
  if not public.admin_can_country(v_admin, v_country) then
    raise exception 'Compte non autorise sur ce pays' using errcode = '42501';
  end if;

  -- DURCISSEMENT #2 — le strike qui ATTEINDRAIT le seuil de ban à vie exige un
  -- super-admin GLOBAL. Un super-admin scopé pays peut poser les strikes 1 et 2
  -- (arbitrage), pas déclencher seul la sanction de compte. On prédit le compte
  -- que verra `enforce_three_strikes_ban` : autres litiges déjà `resolved` de la
  -- cible + celui-ci. `p_cancel` (litige 'cancelled') ne compte pas.
  if p_guilty_party_id is not null and not p_cancel then
    select count(*) into v_prior_strikes
      from public.disputes
      where guilty_party_id = p_guilty_party_id
        and status = 'resolved'
        and resolved_by is not null
        and id <> p_dispute_id;
    if v_prior_strikes + 1 >= 3
       and public.admin_allowed_countries(v_admin) is not null then
      raise exception 'Le 3e verdict de culpabilite (ban a vie) exige un super-admin global, non restreint a un pays. Escalade a un super-admin non scope.'
        using errcode = '42501';
    end if;
  end if;

  if p_cancel then
    update public.matches
       set status = 'cancelled', finished_at = now()
     where id = p_match_id;
  else
    if p_winner_id is null then
      raise exception 'Un vainqueur doit etre designe (tapis vert 3-0)'
        using errcode = '22023';
    end if;
    if p_winner_id <> v_p1 and p_winner_id <> v_p2 then
      raise exception 'Le vainqueur doit etre un des deux joueurs du match'
        using errcode = '22023';
    end if;

    -- TAPIS VERT : le favorisé gagne 3-0, l'autre 0-3. Les scores transmis
    -- (p_score1/p_score2) sont ignorés — un litige n'entérine pas un score
    -- déclaré invérifiable.
    v_score1 := case when p_winner_id = v_p1 then 3 else 0 end;
    v_score2 := case when p_winner_id = v_p2 then 3 else 0 end;

    update public.matches
       set score1 = v_score1, score2 = v_score2, winner_id = p_winner_id,
           status = 'completed', finished_at = now()
     where id = p_match_id;
  end if;

  if p_dispute_id is not null then
    -- `guilty_party_id` est écrit dans le MÊME UPDATE que status/resolved_by :
    -- le trigger AFTER voit alors une ligne déjà complète, donc un verdict
    -- réellement tranché — ce que son compteur exige depuis 20260717190000.
    update public.disputes
       set status          = case when p_cancel then 'cancelled' else 'resolved' end,
           resolved_at     = now(),
           resolved_by     = v_admin,
           resolution      = p_justification,
           guilty_party_id = p_guilty_party_id
     where id = p_dispute_id;
  end if;

  insert into public.admin_audit_log
    (admin_id, action, target_type, target_id, after_state)
  values (
    v_admin,
    case when p_cancel then 'dispute_cancelled' else 'dispute_resolved' end,
    'match', p_match_id,
    (case when p_cancel
      then jsonb_build_object('justification', p_justification)
      else jsonb_build_object('winner_id', p_winner_id, 'score1', v_score1,
                              'score2', v_score2, 'walkover', true,
                              'justification', p_justification)
    end) || jsonb_build_object('guilty_party_id', p_guilty_party_id)
  );
end;
$function$;

comment on function public.resolve_dispute(uuid, uuid, text, boolean, uuid, integer, integer, uuid) is
  'Arbitrage atomique d''un litige : tapis vert 3-0 (ou annulation) + cloture '
  'du litige + audit. `p_guilty_party_id` (optionnel, super-admin, joueur du '
  'match) enregistre un VERDICT de culpabilite -> 3 verdicts = ban a vie '
  '(trg_three_strikes_ban). Le 3e strike exige un super-admin GLOBAL '
  '(admin_allowed_countries IS NULL) : un scope pays ne bannit pas seul. '
  'Perdre un litige n''est PAS etre coupable : le choix est explicite et '
  'independant de p_winner_id.';

revoke all on function public.resolve_dispute(uuid, uuid, text, boolean, uuid, integer, integer, uuid)
  from public, anon;
grant execute on function public.resolve_dispute(uuid, uuid, text, boolean, uuid, integer, integer, uuid)
  to authenticated, service_role;
