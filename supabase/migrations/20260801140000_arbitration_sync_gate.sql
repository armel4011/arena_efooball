-- Intègre l'ÉTAPE 0 « Synchronisation » (player1_ready / player2_ready) à
-- l'arbitrage du no-show : c'est le PREMIER signal d'engagement. Si un match
-- non joué n'a pas eu les DEUX confirmations « jeu ouvert », il a été bloqué à
-- l'étape 0 → le(s) joueur(s) qui n'a/n'ont pas confirmé est/sont en faute.
--
-- Ordre de décision :
--   0. Pas les deux `ready` → bloqué à la synchro :
--        - un seul confirmé  → forfait du non-confirmé (le confirmé gagne) ;
--        - aucun confirmé    → annulé (double absence).
--   1..n. Les deux confirmés → logique graduée existante (code / jeu / score).

create or replace function public.auto_forfeit_stale_matches()
  returns integer
  language plpgsql
  security definer
  set search_path = public
as $$
declare
  v_deadline_min int := coalesce(
    (select (value #>> '{}')::int from public.app_config
      where key = 'match_no_show_forfeit_minutes'), 30);
  v_m record;
  v_home uuid; v_away uuid;
  v_ready_home boolean; v_ready_away boolean;
  v_code_sent boolean;
  v_home_played boolean; v_away_played boolean; v_away_touched boolean;
  v_team_away boolean;
  v_p1 boolean; v_p2 boolean;
  v_action text; v_winner uuid; v_loser uuid; v_reason text;
  v_count int := 0;
begin
  for v_m in
    select m.id, m.player1_id, m.player2_id, m.home_player_id, m.room_code,
           m.player1_team_name, m.player2_team_name,
           m.player1_ready, m.player2_ready
      from public.matches m
      join public.competitions c on c.id = m.competition_id
     where c.game <> 'draughts'
       and c.status = 'ongoing'
       and m.scheduled_at is not null
       and m.player1_id is not null
       and m.player2_id is not null
       and m.scheduled_at + make_interval(mins => v_deadline_min) < now()
       and m.status not in
         ('completed', 'cancelled', 'forfeited', 'disputed')
     for update of m skip locked
  loop
    v_action := null; v_winner := null;
    v_reason := 'auto_timeout_no_show';
    v_home := v_m.home_player_id;

    if v_home is null then
      -- Pas de domicile désigné : présent = a confirmé la synchro OU a joué.
      v_p1 := v_m.player1_ready
           or exists (select 1 from public.streams s
                        where s.match_id = v_m.id and s.player_id = v_m.player1_id)
           or exists (select 1 from public.match_events e
                        where e.match_id = v_m.id and e.type = 'score_submitted'
                          and e.created_by = v_m.player1_id);
      v_p2 := v_m.player2_ready
           or exists (select 1 from public.streams s
                        where s.match_id = v_m.id and s.player_id = v_m.player2_id)
           or exists (select 1 from public.match_events e
                        where e.match_id = v_m.id and e.type = 'score_submitted'
                          and e.created_by = v_m.player2_id);
      if v_p1 and not v_p2 then v_action := 'forfeit'; v_winner := v_m.player1_id;
      elsif v_p2 and not v_p1 then v_action := 'forfeit'; v_winner := v_m.player2_id;
      elsif not v_p1 and not v_p2 then v_action := 'cancel';
      end if;
    else
      v_away := case when v_m.player1_id = v_home
                     then v_m.player2_id else v_m.player1_id end;
      v_ready_home := case when v_m.player1_id = v_home
                          then v_m.player1_ready else v_m.player2_ready end;
      v_ready_away := case when v_m.player1_id = v_away
                          then v_m.player1_ready else v_m.player2_ready end;

      if not (v_ready_home and v_ready_away) then
        -- ÉTAPE 0 non franchie : match bloqué à la synchronisation.
        v_reason := 'auto_timeout_not_synced';
        if v_ready_home and not v_ready_away then
          v_action := 'forfeit'; v_winner := v_home;   -- EXTÉRIEUR n'a pas confirmé
        elsif v_ready_away and not v_ready_home then
          v_action := 'forfeit'; v_winner := v_away;   -- DOMICILE n'a pas confirmé
        else
          v_action := 'cancel';                        -- aucun n'a confirmé
          v_reason := 'auto_timeout_not_synced_double';
        end if;
      else
        -- Les deux ont confirmé « jeu ouvert » → logique graduée existante.
        v_code_sent := v_m.room_code is not null;
        v_team_away := (case when v_m.player1_id = v_away
                             then v_m.player1_team_name
                             else v_m.player2_team_name end) is not null;
        v_home_played :=
          exists (select 1 from public.streams s
                    where s.match_id = v_m.id and s.player_id = v_home)
          or exists (select 1 from public.match_events e
                       where e.match_id = v_m.id and e.type = 'score_submitted'
                         and e.created_by = v_home);
        v_away_played :=
          exists (select 1 from public.streams s
                    where s.match_id = v_m.id and s.player_id = v_away)
          or exists (select 1 from public.match_events e
                       where e.match_id = v_m.id
                         and e.type in ('score_submitted', 'room_joined')
                         and e.created_by = v_away);
        v_away_touched := v_away_played or v_team_away;

        if v_code_sent then
          if not v_away_played then
            v_action := 'forfeit'; v_winner := v_home;
          elsif not v_home_played then
            v_action := 'forfeit'; v_winner := v_away;
          else
            v_action := null;
          end if;
        else
          if v_away_touched then
            v_action := 'forfeit'; v_winner := v_away;
          else
            v_action := 'cancel';
            v_reason := 'auto_timeout_double_no_show';
          end if;
        end if;
      end if;
    end if;

    if v_action = 'forfeit' then
      v_loser := case when v_winner = v_m.player1_id
                      then v_m.player2_id else v_m.player1_id end;
      update public.matches
         set status = 'forfeited', winner_id = v_winner, finished_at = now()
       where id = v_m.id;
      update public.disputes set status = 'resolved', resolved_at = now(),
             resolution = 'auto_forfeit'
       where match_id = v_m.id and status = 'open';
      insert into public.match_events (match_id, type, created_by, payload)
      values (v_m.id, 'forfeit', v_winner,
        jsonb_build_object('opponent_id', v_loser,
          'reason', v_reason, 'auto', true,
          'winner_role', case when v_home is null then null
                              when v_winner = v_home then 'home' else 'away' end));
      v_count := v_count + 1;
    elsif v_action = 'cancel' then
      update public.matches
         set status = 'cancelled', finished_at = now()
       where id = v_m.id;
      insert into public.match_events (match_id, type, created_by, payload)
      values (v_m.id, 'forfeit', null,
        jsonb_build_object('reason',
          coalesce(v_reason, 'auto_timeout_double_no_show'), 'auto', true));
      v_count := v_count + 1;
    end if;
  end loop;

  return v_count;
end;
$$;

revoke all on function public.auto_forfeit_stale_matches()
  from public, anon, authenticated;

-- RPC admin : ajoute le signal `sync_confirmed` (étape 0) par joueur, et
-- reconnaît les nouveaux motifs synchro dans le verdict.
create or replace function public.admin_match_arbitration(p_match_id uuid)
  returns jsonb
  language plpgsql
  security definer
  set search_path = public
as $$
declare
  v_m record;
  v_home uuid;
  v_forfeit jsonb;
  v_reason text;
  v_kind text;
  v_players jsonb;
  v_events jsonb;
begin
  if not public.is_admin() then
    raise exception 'Réservé aux administrateurs' using errcode = '42501';
  end if;

  select * into v_m from public.matches where id = p_match_id;
  if not found then
    raise exception 'Match introuvable' using errcode = 'P0002';
  end if;
  v_home := v_m.home_player_id;

  select payload into v_forfeit
    from public.match_events
   where match_id = p_match_id and type = 'forfeit'
   order by created_at desc limit 1;
  v_reason := v_forfeit ->> 'reason';

  v_kind := case
    when v_m.status = 'completed' then 'completed'
    when v_m.status = 'forfeited'
         and v_reason in ('auto_timeout_no_show', 'auto_timeout_not_synced')
      then 'auto_no_show'
    when v_m.status = 'forfeited' then 'manual_forfeit'
    when v_m.status = 'cancelled'
         and v_reason in ('auto_timeout_double_no_show',
                          'auto_timeout_not_synced_double')
      then 'auto_double_no_show'
    when v_m.status = 'cancelled' then 'cancelled'
    when v_m.status = 'disputed' then 'disputed'
    else 'pending'
  end;

  select jsonb_agg(pj order by pj ->> 'seat') into v_players
  from (
    select jsonb_build_object(
      'id', t.pid,
      'username', (select username from public.profiles where id = t.pid),
      'seat', t.seat,
      'is_home', t.pid = v_home,
      'is_winner', t.pid is not null and t.pid = v_m.winner_id,
      'sync_confirmed', case when t.seat = '1'
                             then v_m.player1_ready else v_m.player2_ready end,
      'sent_code', (t.pid = v_home and v_m.room_code is not null),
      'joined', exists (select 1 from public.match_events e
                          where e.match_id = p_match_id and e.type = 'room_joined'
                            and e.created_by = t.pid),
      'team_named', (case when t.seat = '1' then v_m.player1_team_name
                          else v_m.player2_team_name end) is not null,
      'recorded', exists (select 1 from public.streams s
                            where s.match_id = p_match_id and s.player_id = t.pid),
      'capture_status', (select s.capture_status from public.streams s
                           where s.match_id = p_match_id and s.player_id = t.pid
                           order by s.started_at desc nulls last limit 1),
      'submitted', exists (select 1 from public.match_events e
                             where e.match_id = p_match_id and e.type = 'score_submitted'
                               and e.created_by = t.pid)
    ) as pj
    from (values (v_m.player1_id, '1'), (v_m.player2_id, '2')) as t(pid, seat)
  ) s;

  select coalesce(jsonb_agg(jsonb_build_object(
           'type', e.type,
           'created_by', e.created_by,
           'username', (select username from public.profiles where id = e.created_by),
           'payload', e.payload,
           'created_at', e.created_at
         ) order by e.created_at), '[]'::jsonb) into v_events
  from public.match_events e where e.match_id = p_match_id;

  return jsonb_build_object(
    'match', jsonb_build_object(
      'id', v_m.id, 'match_number', v_m.match_number, 'status', v_m.status,
      'score1', v_m.score1, 'score2', v_m.score2, 'winner_id', v_m.winner_id,
      'home_player_id', v_home, 'room_code_present', v_m.room_code is not null,
      'scheduled_at', v_m.scheduled_at, 'finished_at', v_m.finished_at),
    'verdict', jsonb_build_object(
      'kind', v_kind, 'winner_id', v_m.winner_id,
      'winner_role', case when v_m.winner_id is null then null
                          when v_m.winner_id = v_home then 'home'
                          when v_home is not null then 'away' else null end,
      'reason', v_reason),
    'players', coalesce(v_players, '[]'::jsonb),
    'events', v_events
  );
end;
$$;
