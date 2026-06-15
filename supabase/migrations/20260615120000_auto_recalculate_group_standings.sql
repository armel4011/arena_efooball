-- ════════════════════════════════════════════════════════════════════
-- Classement de compétition : recalcul automatique après chaque match
-- ════════════════════════════════════════════════════════════════════
-- La table `group_memberships` est censée porter le « classement live »
-- (P / Pts / V / N / D / BP / BC / Diff / position) lu par
-- `StandingsRepository` + l'onglet Classement. Mais AUCUN code (générateur,
-- trigger, RPC) ne l'a jamais peuplée ni mise à jour → onglet vide en
-- permanence. Cette migration la fait vivre :
--
--   1. `recalculate_group_standings(group_id)` — dérive les joueurs depuis
--      TOUS les matchs du groupe (donc tous apparaissent, même à 0-0-0),
--      upsert les memberships, puis recalcule stats + points + position
--      depuis les matchs completed/forfeited.
--   2. Trigger `trg_matches_recalc_group_standings` AFTER INSERT OR UPDATE
--      OF status/score/winner ON matches (group_id non nul) :
--        * INSERT  → seed les memberships dès la génération du bracket ;
--        * passage completed/forfeited (ou correction admin d'un match déjà
--          clos) → recalcul du classement du groupe concerné.
--   3. `generate_round_robin_bracket` : crée désormais UN groupe unique
--      (tous les joueurs) + pose `group_id` sur ses matchs → le round-robin
--      obtient enfin son classement via le MÊME mécanisme (avant : aucun
--      groupe, donc aucun classement, alors que tout le format EST un
--      classement). groups_then_knockout posait déjà `group_id`, couvert sans
--      changement de générateur.
--   4. Backfill : recalcule les groupes déjà générés.
--
-- Convention forfait : compté joué + défaite pour le forfaitaire / victoire
-- pour l'adversaire, 0 but de part et d'autre (score null → COALESCE 0).
-- Points : 3 victoire / 1 nul / 0 défaite. Départage position :
-- points → diff de buts → buts pour → victoires.
--
-- Sécurité : fonctions SECURITY DEFINER (bypass RLS `memberships_*_admin`).
-- Depends on: 20260505100002 (group_memberships), 20260505100003 (matches),
--   20260518202313 (generate_round_robin_bracket).
-- ════════════════════════════════════════════════════════════════════

-- ─── 1. Recalcul du classement d'un groupe ──────────────────────────
create or replace function public.recalculate_group_standings(p_group_id uuid)
returns void
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
  if p_group_id is null then
    return;
  end if;

  -- a) Seed : une ligne par joueur apparaissant dans un match du groupe
  --    (quel que soit le statut) → tous les joueurs figurent au classement
  --    dès la génération, même avant d'avoir joué.
  insert into public.group_memberships (group_id, profile_id)
  select p_group_id, pid
  from (
    select player1_id as pid from public.matches
      where group_id = p_group_id and player1_id is not null
    union
    select player2_id as pid from public.matches
      where group_id = p_group_id and player2_id is not null
  ) s
  on conflict (group_id, profile_id) do nothing;

  -- b) Recalcule P/V/N/D/BP/BC/Pts depuis les matchs terminés du groupe.
  with results as (
    select
      gm.profile_id,
      m.id as match_id,
      case when m.player1_id = gm.profile_id
           then coalesce(m.score1, 0) else coalesce(m.score2, 0) end as gf,
      case when m.player1_id = gm.profile_id
           then coalesce(m.score2, 0) else coalesce(m.score1, 0) end as ga,
      m.winner_id,
      m.status
    from public.group_memberships gm
    join public.matches m
      on m.group_id = p_group_id
     and (m.player1_id = gm.profile_id or m.player2_id = gm.profile_id)
     and m.status in ('completed', 'forfeited')
    where gm.group_id = p_group_id
  ),
  agg as (
    select
      gm.profile_id,
      count(r.match_id)                                                    as played,
      count(*) filter (where r.winner_id = gm.profile_id)                  as wins,
      count(*) filter (where r.status = 'completed'
                         and r.winner_id is null)                          as draws,
      count(*) filter (where r.winner_id is not null
                         and r.winner_id <> gm.profile_id)                 as losses,
      coalesce(sum(r.gf), 0)                                               as goals_for,
      coalesce(sum(r.ga), 0)                                               as goals_against
    from public.group_memberships gm
    left join results r on r.profile_id = gm.profile_id
    where gm.group_id = p_group_id
    group by gm.profile_id
  )
  update public.group_memberships gm
     set played        = a.played,
         wins          = a.wins,
         draws         = a.draws,
         losses        = a.losses,
         goals_for     = a.goals_for,
         goals_against = a.goals_against,
         points        = a.wins * 3 + a.draws
    from agg a
   where gm.group_id = p_group_id
     and gm.profile_id = a.profile_id;

  -- c) Recalcule la position (rang) dans le groupe.
  with ranked as (
    select profile_id,
           row_number() over (
             order by points desc, goal_diff desc, goals_for desc, wins desc
           ) as pos
      from public.group_memberships
     where group_id = p_group_id
  )
  update public.group_memberships gm
     set position = r.pos
    from ranked r
   where gm.group_id = p_group_id
     and gm.profile_id = r.profile_id;
end;
$$;

comment on function public.recalculate_group_standings(uuid) is
  'Peuple/recalcule le classement live (group_memberships) d''un groupe depuis '
  'ses matchs. Seed tous les joueurs du groupe, calcule P/V/N/D/BP/BC/Pts/'
  'position. Forfait = défaite 0 but. SECURITY DEFINER (bypass RLS).';

revoke all on function public.recalculate_group_standings(uuid) from public, anon;

-- ─── 2. Trigger sur matches ─────────────────────────────────────────
create or replace function public.trigger_recalc_group_standings()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
  if new.group_id is not null
     and (tg_op = 'INSERT' or new.status::text in ('completed', 'forfeited'))
  then
    perform public.recalculate_group_standings(new.group_id);
  end if;
  return new;
end;
$$;

comment on function public.trigger_recalc_group_standings() is
  'Recalcule le classement du groupe d''un match : seed à l''INSERT, recalcul '
  'au passage completed/forfeited (et corrections admin score/winner).';

drop trigger if exists trg_matches_recalc_group_standings on public.matches;
create trigger trg_matches_recalc_group_standings
  after insert or update of status, score1, score2, winner_id, group_id
  on public.matches
  for each row
  execute function public.trigger_recalc_group_standings();

-- ─── 3. Round-robin : un groupe unique pour porter le classement ────
create or replace function public.generate_round_robin_bracket(p_competition_id uuid)
returns void
language plpgsql
security definer
set search_path to 'public'
as $$
DECLARE
  v_competition   record;
  v_players       uuid[];
  v_padded        uuid[];
  v_player_count  integer;
  v_n             integer;
  v_rounds        integer;
  v_half          integer;
  v_phase_id      uuid;
  v_group_id      uuid;
  v_round         integer;
  v_i             integer;
  v_a             uuid;
  v_b             uuid;
  v_rotation      uuid[];
  v_match_count   integer := 0;
  v_scheduled_at  timestamptz;
BEGIN
  SELECT * INTO v_competition FROM competitions
    WHERE id = p_competition_id FOR UPDATE;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Competition % not found', p_competition_id;
  END IF;

  IF v_competition.format::text <> 'round_robin' THEN
    RAISE EXCEPTION 'generate_round_robin_bracket called on format %', v_competition.format;
  END IF;

  IF EXISTS (SELECT 1 FROM matches WHERE competition_id = p_competition_id) THEN
    RAISE NOTICE 'Bracket already exists for %, skipping', p_competition_id;
    RETURN;
  END IF;

  SELECT array_agg(player_id ORDER BY random()) INTO v_players
    FROM competition_registrations
   WHERE competition_id = p_competition_id AND status = 'confirmed';

  v_player_count := COALESCE(array_length(v_players, 1), 0);
  IF v_player_count < 2 THEN
    RAISE EXCEPTION 'Need at least 2 confirmed registrations, got %', v_player_count;
  END IF;
  IF v_player_count > 32 THEN
    RAISE EXCEPTION 'Round robin capped at 32 players, got % (use groups_then_knockout for larger fields)', v_player_count;
  END IF;

  -- Pad avec NULL si impair
  IF v_player_count % 2 = 1 THEN
    v_padded := v_players || ARRAY[NULL::uuid];
  ELSE
    v_padded := v_players;
  END IF;
  v_n := array_length(v_padded, 1);
  v_rounds := v_n - 1;
  v_half := v_n / 2;
  v_rotation := v_padded;

  INSERT INTO phases (competition_id, phase_order, type, status, started_at)
  VALUES (p_competition_id, 1, 'round_robin', 'in_progress', now())
  RETURNING id INTO v_phase_id;

  -- Groupe unique : le round-robin EST un classement → on lui donne un groupe
  -- pour réutiliser le mécanisme group_memberships (trigger de recalcul).
  INSERT INTO groups (competition_id, phase_id, name, group_number)
  VALUES (p_competition_id, v_phase_id, 'Classement', 1)
  RETURNING id INTO v_group_id;

  v_scheduled_at := GREATEST(v_competition.start_date, now() + interval '5 minutes');

  FOR v_round IN 1..v_rounds LOOP
    FOR v_i IN 0..(v_half - 1) LOOP
      v_a := v_rotation[v_i + 1];
      v_b := v_rotation[v_n - v_i];
      IF v_a IS NULL OR v_b IS NULL THEN
        CONTINUE;  -- bye
      END IF;
      v_match_count := v_match_count + 1;
      INSERT INTO matches (
        competition_id, phase_id, group_id, round, match_number,
        player1_id, player2_id, status, scheduled_at, home_player_id
      ) VALUES (
        p_competition_id, v_phase_id, v_group_id, v_round, v_match_count,
        v_a, v_b,
        CASE WHEN v_round = 1 THEN 'scheduled'::match_status ELSE 'pending'::match_status END,
        CASE WHEN v_round = 1 THEN v_scheduled_at ELSE NULL END,
        v_a
      );
    END LOOP;
    v_rotation := v_rotation[1:1] || ARRAY[v_rotation[v_n]] || v_rotation[2:v_n - 1];
  END LOOP;

  -- Round robin ne crée pas de bracket_nodes (le classement = group_memberships
  -- agrégé par le trigger de recalcul, pas d'avancement par paire).

  UPDATE competitions SET status = 'ongoing'::competition_status, updated_at = now()
   WHERE id = p_competition_id;
END;
$$;

comment on function public.generate_round_robin_bracket(uuid) is
  'Lot F.1 — Génère un bracket round-robin (circle method, N*(N-1)/2 matches). '
  'Crée un groupe unique « Classement » porté par group_memberships (recalcul '
  'auto via trg_matches_recalc_group_standings).';

-- ─── 4. Backfill des groupes déjà générés ───────────────────────────
do $$
declare
  g record;
begin
  for g in select id from public.groups loop
    perform public.recalculate_group_standings(g.id);
  end loop;
end;
$$;
