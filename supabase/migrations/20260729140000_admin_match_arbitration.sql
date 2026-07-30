-- Consultation ADMIN de l'arbitrage d'un match : renvoie en un seul appel le
-- verdict (auto no-show / double absence / forfait manuel / litige / terminé),
-- les signaux d'engagement par joueur (Domicile vs Extérieur) et la chronologie
-- des events. Alimente le volet « Arbitrage » du détail de match admin.
--
-- SECURITY DEFINER + garde is_admin() : contourne les RLS match_events/streams
-- tout en réservant l'accès aux admins.

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

  -- Motif du dernier event forfeit (posé par l'auto-arbitrage ou le forfait).
  select payload into v_forfeit
    from public.match_events
   where match_id = p_match_id and type = 'forfeit'
   order by created_at desc limit 1;

  v_kind := case
    when v_m.status = 'completed' then 'completed'
    when v_m.status = 'forfeited'
         and coalesce(v_forfeit ->> 'reason', '') = 'auto_timeout_no_show'
      then 'auto_no_show'
    when v_m.status = 'forfeited' then 'manual_forfeit'
    when v_m.status = 'cancelled'
         and coalesce(v_forfeit ->> 'reason', '') = 'auto_timeout_double_no_show'
      then 'auto_double_no_show'
    when v_m.status = 'cancelled' then 'cancelled'
    when v_m.status = 'disputed' then 'disputed'
    else 'pending'
  end;

  -- Signaux d'engagement par joueur.
  select jsonb_agg(pj order by pj ->> 'seat') into v_players
  from (
    select jsonb_build_object(
      'id', t.pid,
      'username', (select username from public.profiles where id = t.pid),
      'seat', t.seat,
      'is_home', t.pid = v_home,
      'is_winner', t.pid is not null and t.pid = v_m.winner_id,
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

  -- Chronologie des events (lisibles côté app).
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
      'reason', v_forfeit ->> 'reason'),
    'players', coalesce(v_players, '[]'::jsonb),
    'events', v_events
  );
end;
$$;

grant execute on function public.admin_match_arbitration(uuid) to authenticated;
revoke execute on function public.admin_match_arbitration(uuid) from anon, public;
