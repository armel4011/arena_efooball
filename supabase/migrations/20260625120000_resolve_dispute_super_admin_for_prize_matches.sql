-- =============================================================================
-- ARENA — Durcissement resolve_dispute : super-admin pour matchs à cagnotte
-- =============================================================================
-- Suite audit 2026-06-24 (point résiduel MOYEN). La migration 20260624140000 a
-- fermé la faille critique (vainqueur = complice hors-match). Reste un risque :
-- un admin SIMPLE peut encore INVERSER le vainqueur entre les deux vrais joueurs
-- d'une finale à cagnotte → il oriente le versement vers le joueur de son choix.
--
-- On verrouille donc l'arbitrage des litiges sur un match RATTACHÉ À UNE
-- COMPÉTITION AVEC PRIX au super-admin uniquement. Les litiges sans enjeu
-- d'argent (compétitions sans prix) restent ouverts aux admins simples.
--
-- « A des prix » = prize_pool_local > 0 OU au moins une part > 0 dans
-- prize_distribution (robuste au cas prize_pool_local=0 + distribution saisie,
-- cf. note du cap generate_payouts).
-- =============================================================================

create or replace function public.resolve_dispute(
  p_match_id      uuid,
  p_dispute_id    uuid,
  p_justification text,
  p_cancel        boolean default false,
  p_winner_id     uuid    default null,
  p_score1        integer default null,
  p_score2        integer default null
)
returns void
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_admin     uuid := auth.uid();
  v_p1        uuid;
  v_p2        uuid;
  v_comp      uuid;
  v_pool      numeric;
  v_dist      jsonb;
  v_has_prize boolean;
begin
  if not public.is_admin() then
    raise exception 'Reserve aux administrateurs' using errcode = '42501';
  end if;
  if coalesce(trim(p_justification), '') = '' then
    raise exception 'Justification obligatoire' using errcode = '22023';
  end if;

  -- Charge + verrouille le match : existence ET source de vérité pour valider
  -- le vainqueur (anti-détournement de gains).
  select player1_id, player2_id, competition_id into v_p1, v_p2, v_comp
    from public.matches
    where id = p_match_id
    for update;
  if not found then
    raise exception 'Match introuvable' using errcode = 'P0002';
  end if;

  -- Garde renforcée : si le match appartient à une compétition AVEC PRIX,
  -- l'arbitrage est réservé au super-admin (un admin simple ne doit pas
  -- pouvoir orienter un versement en inversant le vainqueur).
  select prize_pool_local, prize_distribution into v_pool, v_dist
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

  -- 1. Verdict (score/winner/completed) OU annulation du match.
  if p_cancel then
    update public.matches
       set status = 'cancelled', finished_at = now()
     where id = p_match_id;
  else
    -- Le vainqueur DOIT être l'un des deux participants du match.
    if p_winner_id is not null and p_winner_id <> v_p1 and p_winner_id <> v_p2 then
      raise exception 'Le vainqueur doit etre un des deux joueurs du match'
        using errcode = '22023';
    end if;
    -- Pas de scores négatifs.
    if coalesce(p_score1, 0) < 0 or coalesce(p_score2, 0) < 0 then
      raise exception 'Les scores ne peuvent pas etre negatifs' using errcode = '22023';
    end if;

    update public.matches
       set score1 = p_score1, score2 = p_score2, winner_id = p_winner_id,
           status = 'completed', finished_at = now()
     where id = p_match_id;
  end if;

  -- 2. Résout le litige (s'il existe) — même transaction.
  if p_dispute_id is not null then
    update public.disputes
       set status      = case when p_cancel then 'cancelled' else 'resolved' end,
           resolved_at = now(),
           resolved_by = v_admin,
           resolution  = p_justification
     where id = p_dispute_id;
  end if;

  -- 3. Trace d'audit — même transaction.
  insert into public.admin_audit_log
    (admin_id, action, target_type, target_id, after_state)
  values (
    v_admin,
    case when p_cancel then 'dispute_cancelled' else 'dispute_resolved' end,
    'match', p_match_id,
    case when p_cancel
      then jsonb_build_object('justification', p_justification)
      else jsonb_build_object('winner_id', p_winner_id, 'score1', p_score1,
                              'score2', p_score2, 'justification', p_justification)
    end
  );
end;
$$;

comment on function public.resolve_dispute(uuid, uuid, text, boolean, uuid, integer, integer) is
  'Robustesse : résout un litige de façon ATOMIQUE (verdict/annulation match + '
  'resolve dispute + audit) dans une seule transaction. Gate is_admin(). '
  'P0 audit 2026-06-24 : valide winner_id ∈ {player1, player2} et scores >= 0. '
  'Durcissement 2026-06-25 : super-admin requis si la compétition a des prix.';

revoke execute on function public.resolve_dispute(uuid, uuid, text, boolean, uuid, integer, integer)
  from anon, public;
grant execute on function public.resolve_dispute(uuid, uuid, text, boolean, uuid, integer, integer)
  to authenticated;
