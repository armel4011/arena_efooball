-- Règle « délai d'exécution des matchs » : passé un délai (défaut 30 min) après
-- l'heure PRÉVUE (scheduled_at), un match non joué est clôturé automatiquement.
--
-- Décidé avec le porteur produit :
--   * départ du délai = scheduled_at ;
--   * action = FORFAIT DE L'ABSENT (le présent gagne sur tapis vert, cohérent
--     avec forfeit_match) ; DOUBLE absence => match annulé (suite = admin) ;
--     les DEUX présents mais non finalisé => on ne force rien (flux/arbitrage).
--
-- « Présent » = le joueur a laissé une trace d'engagement dans le match :
--   soit un event `score_submitted`, soit un enregistrement démarré (streams).
--
-- Ne s'applique PAS aux dames (game='draughts') : elles ont déjà leur propre
-- timeout in-app (finalize_expired_draughts_timeouts).
--
-- Délai configurable via app_config.match_no_show_forfeit_minutes (jsonb entier),
-- défaut 30 si la clé est absente — pas besoin de migration pour l'ajuster.

create or replace function public.auto_forfeit_stale_matches()
  returns integer
  language plpgsql
  security definer
  set search_path = public
as $$
declare
  v_deadline_min int := coalesce(
    (select (value #>> '{}')::int from public.app_config
      where key = 'match_no_show_forfeit_minutes'),
    30);
  v_m record;
  v_p1_present boolean;
  v_p2_present boolean;
  v_count int := 0;
begin
  for v_m in
    select m.id, m.player1_id, m.player2_id
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
    -- présence = score soumis OU enregistrement démarré, par ce joueur.
    v_p1_present :=
      exists (select 1 from public.match_events e
                where e.match_id = v_m.id and e.type = 'score_submitted'
                  and e.created_by = v_m.player1_id)
      or exists (select 1 from public.streams s
                   where s.match_id = v_m.id and s.player_id = v_m.player1_id);
    v_p2_present :=
      exists (select 1 from public.match_events e
                where e.match_id = v_m.id and e.type = 'score_submitted'
                  and e.created_by = v_m.player2_id)
      or exists (select 1 from public.streams s
                   where s.match_id = v_m.id and s.player_id = v_m.player2_id);

    if v_p1_present and not v_p2_present then
      -- player2 absent : player1 gagne sur tapis vert.
      update public.matches
         set status = 'forfeited', winner_id = v_m.player1_id,
             finished_at = now()
       where id = v_m.id;
      update public.disputes set status = 'resolved', resolved_at = now(),
             resolution = 'auto_forfeit'
       where match_id = v_m.id and status = 'open';
      insert into public.match_events (match_id, type, created_by, payload)
      values (v_m.id, 'forfeit', v_m.player1_id,
        jsonb_build_object('opponent_id', v_m.player2_id,
          'reason', 'auto_timeout_no_show', 'auto', true));
      v_count := v_count + 1;

    elsif v_p2_present and not v_p1_present then
      -- player1 absent : player2 gagne sur tapis vert.
      update public.matches
         set status = 'forfeited', winner_id = v_m.player2_id,
             finished_at = now()
       where id = v_m.id;
      update public.disputes set status = 'resolved', resolved_at = now(),
             resolution = 'auto_forfeit'
       where match_id = v_m.id and status = 'open';
      insert into public.match_events (match_id, type, created_by, payload)
      values (v_m.id, 'forfeit', v_m.player2_id,
        jsonb_build_object('opponent_id', v_m.player1_id,
          'reason', 'auto_timeout_no_show', 'auto', true));
      v_count := v_count + 1;

    elsif not v_p1_present and not v_p2_present then
      -- double absence : match annulé (aucun vainqueur, suite = admin).
      update public.matches
         set status = 'cancelled', finished_at = now()
       where id = v_m.id;
      insert into public.match_events (match_id, type, created_by, payload)
      values (v_m.id, 'forfeit', null,
        jsonb_build_object('reason', 'auto_timeout_double_no_show',
          'auto', true));
      v_count := v_count + 1;
    end if;
    -- les DEUX présents : on ne force rien (laisser le flux / l'arbitrage).
  end loop;

  return v_count;
end;
$$;

-- Système uniquement (cron). Personne côté client ne l'exécute.
revoke all on function public.auto_forfeit_stale_matches() from public, anon, authenticated;

-- Cron chaque minute (comme les rappels / le timeout dames) : le match bascule
-- dans la minute qui suit l'échéance des 30 min.
select cron.schedule(
  'auto_forfeit_stale_matches_minute',
  '* * * * *',
  $cron$ select public.auto_forfeit_stale_matches(); $cron$
);
