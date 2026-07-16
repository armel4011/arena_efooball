-- ════════════════════════════════════════════════════════════════════
-- Litige non tranchable → FAIRE REJOUER le match
-- ════════════════════════════════════════════════════════════════════
-- `resolve_dispute` n'offre que deux issues : donner le match 3-0 à l'un
-- (tapis vert) ou l'annuler. Quand les preuves ne permettent PAS de départager,
-- les deux sont injustes : l'une punit peut-être un innocent, l'autre efface un
-- match qui a bien eu lieu. Il manquait « remettre les deux joueurs sur le
-- terrain ».
--
-- C'est l'inverse exact de tout ce que le schéma sait faire : le système est
-- conçu pour AVANCER (le vainqueur cascade, les stats s'accumulent, la
-- compétition se clôture). Rejouer demande de défaire proprement, d'où les
-- quatre pièges traités ci-dessous.
--
--   1. STATS DOUBLE-COMPTÉES. `_increment_stats_on_match_completed`
--      (20260615220000) incrémente `profiles.stats` au passage à `completed` et
--      ne décrémente JAMAIS (compteur de carrière, décision produit). Un match
--      tranché puis rejoué compterait donc 2 victoires. On écrit ici le PREMIER
--      chemin de décrément du système — le miroir exact de l'incrément.
--
--   2. CASCADE SANS MARCHE ARRIÈRE. `cascade_match_winner` (20260505100003) a
--      déjà écrit le vainqueur dans le match suivant, et n'écrit que `where
--      playerX_id is null` : le slot resterait figé sur l'ancien vainqueur, et
--      le nouveau ne s'y écrirait jamais. On dé-propage donc à la main, en
--      refusant si le match suivant est déjà lancé.
--
--   3. COMPÉTITION DÉJÀ CLÔTURÉE. Si le match tranché était le dernier,
--      `trg_matches_finalize_competition` a passé la compétition `completed` et
--      calculé les `final_rank`. On la rouvre.
--
--   4. ARGENT DÉJÀ VERSÉ. Si des payouts existent, le classement a produit des
--      paiements réels : rejouer les invaliderait. On refuse, plutôt que de
--      créer une incohérence comptable.
-- ════════════════════════════════════════════════════════════════════

-- ─────────────────────────────────────────────────────────────────────────────
-- 1. Décrément des stats — miroir exact de _increment_stats_on_match_completed
-- ─────────────────────────────────────────────────────────────────────────────
-- Prend les valeurs du match AVANT reset (scores + vainqueur d'origine).
-- `greatest(..., 0)` : filet contre un compteur déjà incohérent — on ne veut
-- surtout pas rendre un profil négatif en tentant de le réparer.
create or replace function public._decrement_stats_for_replayed_match(
  p_player1_id uuid,
  p_player2_id uuid,
  p_winner_id  uuid,
  p_score1     integer,
  p_score2     integer
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_s1 int := coalesce(p_score1, 0);
  v_s2 int := coalesce(p_score2, 0);
begin
  if p_player1_id is not null then
    update public.profiles
       set stats = jsonb_build_object(
         'wins',           greatest(coalesce((stats->>'wins')::int, 0)
                           - (case when p_winner_id = p_player1_id then 1 else 0 end), 0),
         'losses',         greatest(coalesce((stats->>'losses')::int, 0)
                           - (case when p_winner_id is not null
                                    and p_winner_id <> p_player1_id then 1 else 0 end), 0),
         'draws',          greatest(coalesce((stats->>'draws')::int, 0)
                           - (case when p_winner_id is null then 1 else 0 end), 0),
         'goals_scored',   greatest(coalesce((stats->>'goals_scored')::int, 0)   - v_s1, 0),
         'goals_conceded', greatest(coalesce((stats->>'goals_conceded')::int, 0) - v_s2, 0)
       )
     where id = p_player1_id;
  end if;

  -- player2 : même garde « distinct de player1 » que l'incrément (cas BYE).
  if p_player2_id is not null and p_player2_id is distinct from p_player1_id then
    update public.profiles
       set stats = jsonb_build_object(
         'wins',           greatest(coalesce((stats->>'wins')::int, 0)
                           - (case when p_winner_id = p_player2_id then 1 else 0 end), 0),
         'losses',         greatest(coalesce((stats->>'losses')::int, 0)
                           - (case when p_winner_id is not null
                                    and p_winner_id <> p_player2_id then 1 else 0 end), 0),
         'draws',          greatest(coalesce((stats->>'draws')::int, 0)
                           - (case when p_winner_id is null then 1 else 0 end), 0),
         'goals_scored',   greatest(coalesce((stats->>'goals_scored')::int, 0)   - v_s2, 0),
         'goals_conceded', greatest(coalesce((stats->>'goals_conceded')::int, 0) - v_s1, 0)
       )
     where id = p_player2_id;
  end if;
end;
$$;

revoke all on function public._decrement_stats_for_replayed_match(uuid, uuid, uuid, integer, integer)
  from public, anon, authenticated;

comment on function public._decrement_stats_for_replayed_match(uuid, uuid, uuid, integer, integer) is
  'Interne — annule l''effet de _increment_stats_on_match_completed pour un '
  'match remis en jeu, afin qu''un match rejoué ne compte pas deux fois. Seul '
  'chemin de décrément du compteur de carrière ; réservé à replay_match.';

-- ─────────────────────────────────────────────────────────────────────────────
-- 2. `matches.replayed_at` — borne les soumissions de la manche précédente
-- ─────────────────────────────────────────────────────────────────────────────
-- Sans ça, `finalize_match_score` relit la DERNIÈRE soumission de chaque joueur
-- dans `match_events` : les scores de la 1re manche re-finaliseraient le match
-- aussitôt, et l'écran de litige afficherait les vieux scores.
alter table public.matches
  add column if not exists replayed_at timestamptz;

comment on column public.matches.replayed_at is
  'Date de la dernière remise en jeu (replay_match). Les match_events / preuves '
  'antérieurs appartiennent à une manche périmée : tout consommateur de scores '
  'soumis doit filtrer created_at > replayed_at.';

-- ─────────────────────────────────────────────────────────────────────────────
-- 3. RPC replay_match
-- ─────────────────────────────────────────────────────────────────────────────
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

  -- Piège 4 : l'argent est parti → on refuse, l'incohérence comptable n'est
  -- pas rattrapable ici.
  if exists (
    select 1 from public.payouts p
    where p.competition_id = v_m.competition_id
  ) then
    raise exception
      'Des gains ont deja ete generes pour cette competition : remise en jeu impossible'
      using errcode = '22023';
  end if;

  -- Piège 2 : dé-propager le vainqueur du match suivant AVANT de l'effacer.
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

  -- Piège 1 : neutraliser le résultat déjà compté.
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

  -- Piège 3 : rouvrir la compétition si ce match l'avait clôturée.
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
  'Admin : remet un match en jeu quand un litige n''est pas tranchable. Annule '
  'le résultat précédent (stats décrémentées, vainqueur dé-propagé du bracket, '
  'compétition rouverte si clôturée), replanifie et clôture le litige sans '
  'coupable. Refuse si des payouts existent ou si le match suivant est engagé. '
  'Gardes : is_admin + admin_can_country + super-admin si cagnotte.';

revoke all on function public.replay_match(uuid, uuid, text, timestamptz)
  from anon, public;
grant execute on function public.replay_match(uuid, uuid, text, timestamptz)
  to authenticated;
