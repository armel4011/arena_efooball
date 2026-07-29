-- Arbitrage GRADUÉ des matchs non joués (remplace la règle binaire de
-- 20260729120000). Tient compte de l'ASYMÉTRIE des rôles : le DOMICILE doit
-- créer+envoyer le code (sans quoi l'EXTÉRIEUR ne peut PAS jouer) ; l'EXTÉRIEUR
-- doit rejoindre+jouer. On ne forfaite jamais un joueur empêché par la faute
-- de l'autre.
--
-- Signaux persistés utilisés :
--   * room_code non-null           => le DOMICILE a envoyé le code (devoir clé)
--   * ligne streams (par joueur)   => a démarré l'enregistrement (bonne foi,
--                                     même si capture_status='unavailable')
--   * event score_submitted        => a soumis son score
--   * event room_joined (EXTÉRIEUR)=> a rejoint la salle (émis par l'app)
--   * player1/2_team_name          => a saisi son équipe
--
-- Nouveaux events : room_code_sent (émis par TRIGGER serveur ci-dessous) et
-- room_joined (émis par l'app côté EXTÉRIEUR).

-- 1) Étendre le CHECK des types d'events.
alter table public.match_events drop constraint match_events_type_check;
alter table public.match_events add constraint match_events_type_check
  check (type = any (array[
    'match_started', 'goal', 'score_submitted', 'score_validated',
    'score_disputed', 'forfeit', 'admin_adjustment', 'match_finished',
    'proof_missing', 'room_code_sent', 'room_joined'
  ]));

-- 2) Trigger : quand le DOMICILE écrit le room_code (null -> valeur), tracer un
--    event room_code_sent horodaté (créateur = home_player_id).
create or replace function public._emit_room_code_sent()
  returns trigger language plpgsql security definer set search_path = public
as $$
begin
  if new.room_code is not null
     and coalesce(old.room_code, '') = ''
     and new.home_player_id is not null then
    insert into public.match_events (match_id, type, created_by, payload)
    values (new.id, 'room_code_sent', new.home_player_id,
            jsonb_build_object('auto', true));
  end if;
  return new;
end;
$$;

drop trigger if exists trg_emit_room_code_sent on public.matches;
create trigger trg_emit_room_code_sent
  after update of room_code on public.matches
  for each row execute function public._emit_room_code_sent();

-- 3) Fonction d'arbitrage graduée (remplace la version binaire).
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
  v_code_sent boolean;
  v_home_played boolean; v_away_played boolean; v_away_touched boolean;
  v_team_away boolean;
  v_p1 boolean; v_p2 boolean;
  v_action text; v_winner uuid; v_loser uuid;
  v_count int := 0;
begin
  for v_m in
    select m.id, m.player1_id, m.player2_id, m.home_player_id, m.room_code,
           m.player1_team_name, m.player2_team_name
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
    v_home := v_m.home_player_id;

    if v_home is null then
      -- Pas de domicile désigné : logique symétrique (présent = a joué).
      v_p1 := exists (select 1 from public.streams s
                        where s.match_id = v_m.id and s.player_id = v_m.player1_id)
           or exists (select 1 from public.match_events e
                        where e.match_id = v_m.id and e.type = 'score_submitted'
                          and e.created_by = v_m.player1_id);
      v_p2 := exists (select 1 from public.streams s
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
          v_action := 'forfeit'; v_winner := v_home;   -- EXTÉRIEUR absent malgré le code
        elsif not v_home_played then
          v_action := 'forfeit'; v_winner := v_away;   -- DOMICILE a envoyé le code puis absent
        else
          v_action := null;                            -- les deux ont joué -> arbitrage/reprog
        end if;
      else
        -- DOMICILE n'a jamais envoyé le code (devoir clé non rempli).
        if v_away_touched then
          v_action := 'forfeit'; v_winner := v_away;   -- DOMICILE a bloqué le match
        else
          v_action := 'cancel';                        -- double absence
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
          'reason', 'auto_timeout_no_show', 'auto', true,
          'winner_role', case when v_home is null then null
                              when v_winner = v_home then 'home' else 'away' end));
      v_count := v_count + 1;
    elsif v_action = 'cancel' then
      update public.matches
         set status = 'cancelled', finished_at = now()
       where id = v_m.id;
      insert into public.match_events (match_id, type, created_by, payload)
      values (v_m.id, 'forfeit', null,
        jsonb_build_object('reason', 'auto_timeout_double_no_show', 'auto', true));
      v_count := v_count + 1;
    end if;
  end loop;

  return v_count;
end;
$$;

revoke all on function public.auto_forfeit_stale_matches()
  from public, anon, authenticated;
