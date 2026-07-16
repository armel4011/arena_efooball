-- ════════════════════════════════════════════════════════════════════
-- replay_match : n'accepter QUE les matchs réellement en litige
-- ════════════════════════════════════════════════════════════════════
-- TROU dans 20260716130000 : `p_dispute_id` était accepté sans être vérifié.
-- La clôture du litige se contentait d'un
--   `update public.disputes ... where id = p_dispute_id`
-- qui touche ZÉRO ligne si l'id est NULL ou inconnu — **sans lever**. Le match
-- était donc remis en jeu quand même.
--
-- Conséquence : un admin pouvait rejouer N'IMPORTE QUEL match, sans le moindre
-- litige — en décrémentant les stats des 2 joueurs, en dé-propageant le bracket
-- et en rouvrant la compétition. « Faire rejouer » n'est pas une action de
-- gestion courante : c'est l'issue d'un litige qu'on n'arrive pas à trancher.
--
-- On exige donc un litige qui existe, qui porte SUR CE MATCH, et qui est encore
-- OUVERT (open / bot_review / admin_review). Un litige déjà tranché
-- (resolved / closed / cancelled) ne peut pas resservir à rejouer : sinon on
-- pourrait rejouer indéfiniment un match sur un vieux litige clos.
--
-- Seul le bloc de garde change ; le reste de la fonction est identique à
-- 20260716130000.
-- ════════════════════════════════════════════════════════════════════

create or replace function public.replay_match(
  p_match_id      uuid,
  p_dispute_id    uuid,
  p_justification text,
  p_scheduled_at  timestamptz
)
returns void
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_admin      uuid := auth.uid();
  v_m          record;
  v_comp       record;
  v_dispute    record;
  v_has_prize  boolean;
  v_next_pos   text;
begin
  if not public.is_admin() then
    raise exception 'Reserve aux administrateurs' using errcode = '42501';
  end if;
  if coalesce(trim(p_justification), '') = '' then
    raise exception 'Justification obligatoire' using errcode = '22023';
  end if;
  if p_scheduled_at is null or p_scheduled_at <= now() then
    raise exception 'La nouvelle date doit être dans le futur' using errcode = '22023';
  end if;

  select * into v_m from public.matches where id = p_match_id for update;
  if not found then
    raise exception 'Match introuvable' using errcode = 'P0002';
  end if;

  -- ─── LE match doit être en litige ───────────────────────────────────────
  -- Verrouillé aussi : deux admins ne doivent pas rejouer le même litige en
  -- parallèle (le 2e décrémenterait les stats une seconde fois).
  if p_dispute_id is null then
    raise exception 'Seul un match en litige peut etre remis en jeu'
      using errcode = '22023';
  end if;
  select * into v_dispute
    from public.disputes
   where id = p_dispute_id
     and match_id = p_match_id
   for update;
  if not found then
    raise exception 'Aucun litige ouvert sur ce match : remise en jeu impossible'
      using errcode = '22023';
  end if;
  if v_dispute.status in ('resolved', 'closed', 'cancelled') then
    raise exception 'Litige deja tranche : remise en jeu impossible'
      using errcode = '22023';
  end if;

  select * into v_comp from public.competitions where id = v_m.competition_id;

  -- Mêmes gardes que resolve_dispute : cagnotte → super-admin, + pays.
  v_has_prize := coalesce(v_comp.prize_pool_local, 0) > 0
    or exists (
      select 1
      from jsonb_array_elements_text(
        case when jsonb_typeof(v_comp.prize_distribution) = 'array'
             then v_comp.prize_distribution else '[]'::jsonb end
      ) as e(val)
      where coalesce(nullif(e.val, '')::numeric, 0) > 0
    );
  if v_has_prize and not public.is_super_admin() then
    raise exception 'Match a cagnotte : remise en jeu reservee au super-admin'
      using errcode = '42501';
  end if;
  if not public.admin_can_country(v_admin, v_comp.country_code) then
    raise exception 'Compte non autorise sur ce pays' using errcode = '42501';
  end if;

  -- L'argent est parti → on refuse, l'incohérence comptable n'est pas
  -- rattrapable ici.
  if exists (
    select 1 from public.payouts p
    where p.competition_id = v_m.competition_id
  ) then
    raise exception
      'Des gains ont deja ete generes pour cette competition : remise en jeu impossible'
      using errcode = '22023';
  end if;

  -- Dé-propager le vainqueur du match suivant AVANT de l'effacer.
  if v_m.next_match_id is not null and v_m.winner_id is not null then
    if exists (
      select 1 from public.matches n
      where n.id = v_m.next_match_id
        and n.status not in ('pending', 'scheduled', 'ready')
    ) then
      raise exception
        'Le match suivant est deja engage : remettre celui-ci en jeu casserait le tableau'
        using errcode = '22023';
    end if;
    select bn.next_position into v_next_pos
      from public.bracket_nodes bn
     where bn.match_id = v_m.id
     limit 1;
    if v_next_pos = 'player1' then
      update public.matches set player1_id = null
       where id = v_m.next_match_id and player1_id = v_m.winner_id;
    elsif v_next_pos = 'player2' then
      update public.matches set player2_id = null
       where id = v_m.next_match_id and player2_id = v_m.winner_id;
    end if;
  end if;

  -- Neutraliser le résultat déjà compté (seul chemin de décrément du système).
  if v_m.status = 'completed' then
    perform public._decrement_stats_for_replayed_match(
      v_m.player1_id, v_m.player2_id, v_m.winner_id, v_m.score1, v_m.score2
    );
  end if;

  -- Reset. `scheduled` (et non `pending`) : déclenche
  -- trg_notify_match_room_activated_upd → les 2 joueurs sont prévenus que la
  -- salle rouvre. room_code effacé : l'hôte doit créer une NOUVELLE room.
  update public.matches
     set status        = 'scheduled',
         score1        = null,
         score2        = null,
         winner_id     = null,
         started_at    = null,
         finished_at   = null,
         room_code     = null,
         scheduled_at  = p_scheduled_at,
         replayed_at   = now(),
         stream_status = 'none',
         stream_started_at = null,
         stream_ended_at   = null,
         current_viewers_count = 0
   where id = p_match_id;

  -- Rouvrir la compétition si ce match l'avait clôturée.
  if v_comp.status = 'completed' then
    update public.competitions
       set status = 'ongoing', completed_at = null
     where id = v_m.competition_id;
    update public.competition_registrations
       set final_rank = null
     where competition_id = v_m.competition_id;
  end if;

  -- Clôture le litige SANS guilty_party_id : personne n'est déclaré coupable —
  -- c'est tout l'objet d'un rejeu (sinon trg_three_strikes_ban sanctionnerait).
  update public.disputes
     set status      = 'resolved',
         resolved_at = now(),
         resolved_by = v_admin,
         resolution  = 'Match remis en jeu — ' || p_justification
   where id = p_dispute_id;

  insert into public.admin_audit_log (admin_id, action, target_type, target_id, after_state)
  values (
    v_admin, 'dispute_replay', 'match', p_match_id,
    jsonb_build_object(
      'dispute_id', p_dispute_id,
      'justification', p_justification,
      'scheduled_at', p_scheduled_at,
      'previous_score', jsonb_build_object('s1', v_m.score1, 's2', v_m.score2),
      'previous_winner_id', v_m.winner_id
    )
  );
end;
$$;

comment on function public.replay_match(uuid, uuid, text, timestamptz) is
  'Admin : remet un match en jeu quand un litige n''est pas tranchable. EXIGE un '
  'litige OUVERT portant sur ce match. Annule le résultat précédent (stats '
  'décrémentées, vainqueur dé-propagé du bracket, compétition rouverte si '
  'clôturée), replanifie et clôture le litige sans coupable. Refuse si des '
  'payouts existent ou si le match suivant est engagé. Gardes : is_admin + '
  'admin_can_country + super-admin si cagnotte.';

revoke all on function public.replay_match(uuid, uuid, text, timestamptz)
  from anon, public;
grant execute on function public.replay_match(uuid, uuid, text, timestamptz)
  to authenticated;
