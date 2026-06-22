-- =============================================================================
-- ARENA — Workflow « à reprogrammer » : bascule auto + 3 décisions admin
-- =============================================================================
-- Remplace l'auto-annulation des compétitions sous-remplies par une bascule en
-- `to_reprogram`. À l'échéance (start_date passée, quota incomplet), au lieu
-- d'annuler, on flague la compétition et on prévient les inscrits qu'une
-- décision va être prise. L'admin dispose alors de 3 RPC :
--   • reprogram_competition       → nouvelle date + réouverture des inscriptions
--   • start_competition_now       → démarrage avec les joueurs disponibles
--   • cancel_competition (existant) → annulation + file de remboursement
-- Chaque décision notifie automatiquement TOUS les inscrits confirmés.
-- Pré-requis : la valeur d'enum `to_reprogram` (migration 20260622120000).
-- =============================================================================

-- ─────────────────────────────────────────────────────────────────────────────
-- 1. Bascule automatique (cron) : sous-rempli à l'échéance → to_reprogram
--    (remplace `auto_cancel_underfilled_competitions`)
-- ─────────────────────────────────────────────────────────────────────────────
create or replace function public.flag_underfilled_competitions_for_reprogram()
returns integer
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_comp  record;
  v_count integer := 0;
begin
  for v_comp in
    select id, name
      from public.competitions
     where status in ('draft', 'registration_open', 'registration_closed')
       and start_date is not null
       and start_date < now()
       and max_players is not null
       and current_players < max_players
  loop
    update public.competitions
       set status = 'to_reprogram'
     where id = v_comp.id;

    -- Transparence : on prévient les inscrits qu'une décision va être prise
    -- (évite qu'ils croient à un démarrage imminent). Aucun remboursement ni
    -- annulation ici : tout reste suspendu à la décision de l'admin.
    insert into public.notifications (user_id, type, title, body, data)
    select distinct r.player_id, 'competition_to_reprogram',
      'Tournoi en attente',
      'La compétition « ' || v_comp.name || ' » n''a pas fait le plein à la date '
        || 'prévue. L''organisateur va décider de la suite (nouvelle date, '
        || 'démarrage avec les joueurs inscrits, ou annulation). Tu seras '
        || 'notifié dès qu''une décision est prise.',
      jsonb_build_object('competition_id', v_comp.id,
                         'route', '/competitions/' || v_comp.id)
    from public.competition_registrations r
    where r.competition_id = v_comp.id and r.status = 'confirmed';

    v_count := v_count + 1;
  end loop;

  return v_count;
end;
$$;

comment on function public.flag_underfilled_competitions_for_reprogram() is
  'Cron : bascule en to_reprogram les compétitions dont start_date est passée '
  'sans atteindre max_players, et notifie les inscrits. Remplace '
  'l''auto-annulation : aucun remboursement n''est déclenché ici, la décision '
  'revient à l''admin (reprogrammer / démarrer / annuler). Retourne le nombre '
  'de compétitions flaguées.';

revoke all on function public.flag_underfilled_competitions_for_reprogram()
  from anon, public, authenticated;

-- ─────────────────────────────────────────────────────────────────────────────
-- 2. Décision admin n°1 : reprogrammer (nouvelle date + réouverture)
-- ─────────────────────────────────────────────────────────────────────────────
create or replace function public.reprogram_competition(
  p_competition_id uuid,
  p_new_start_date timestamptz
)
returns integer
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_name  text;
  v_count integer;
begin
  if not public.is_admin() then
    raise exception 'forbidden' using errcode = '42501';
  end if;
  if p_new_start_date <= now() then
    raise exception 'La nouvelle date doit être dans le futur';
  end if;

  -- Réouvre les inscriptions à la nouvelle date pour permettre de compléter le
  -- tableau (décision produit : « rouvrir les inscriptions »).
  update public.competitions
     set status     = 'registration_open',
         start_date = p_new_start_date
   where id = p_competition_id
   returning name into v_name;

  if v_name is null then
    raise exception 'Compétition introuvable';
  end if;

  insert into public.notifications (user_id, type, title, body, data)
  select distinct r.player_id, 'competition_reprogrammed',
    '📅 Tournoi reprogrammé',
    'La compétition « ' || v_name || ' » est reprogrammée au '
      || to_char(p_new_start_date at time zone 'Africa/Douala',
                 'DD/MM/YYYY à HH24''h''MI')
      || '. Les inscriptions sont rouvertes — invite tes amis pour compléter '
      || 'le tableau !',
    jsonb_build_object('competition_id', p_competition_id,
                       'route', '/competitions/' || p_competition_id)
  from public.competition_registrations r
  where r.competition_id = p_competition_id and r.status = 'confirmed';

  get diagnostics v_count = row_count;
  return v_count;
end;
$$;

comment on function public.reprogram_competition(uuid, timestamptz) is
  'Admin : reprogramme une compétition (typiquement to_reprogram) à une nouvelle '
  'date et rouvre les inscriptions (registration_open). Notifie tous les '
  'inscrits confirmés. Retourne le nombre de joueurs notifiés.';

revoke all on function public.reprogram_competition(uuid, timestamptz)
  from anon, public;
grant execute on function public.reprogram_competition(uuid, timestamptz)
  to authenticated;

-- ─────────────────────────────────────────────────────────────────────────────
-- 3. Décision admin n°2 : démarrer avec les joueurs disponibles
-- ─────────────────────────────────────────────────────────────────────────────
create or replace function public.start_competition_now(p_competition_id uuid)
returns integer
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_comp      record;
  v_confirmed integer;
  v_count     integer;
begin
  if not public.is_admin() then
    raise exception 'forbidden' using errcode = '42501';
  end if;

  select id, name, format::text as format
    into v_comp
    from public.competitions
   where id = p_competition_id;
  if v_comp.id is null then
    raise exception 'Compétition introuvable';
  end if;

  select count(*) into v_confirmed
    from public.competition_registrations
   where competition_id = p_competition_id and status = 'confirmed';
  if v_confirmed < 2 then
    raise exception 'Au moins 2 joueurs confirmés sont requis pour démarrer';
  end if;

  insert into public.notifications (user_id, type, title, body, data)
  select distinct r.player_id, 'competition_starting',
    '🚀 Le tournoi démarre !',
    'La compétition « ' || v_comp.name || ' » démarre avec ' || v_confirmed
      || ' joueur(s). Prépare-toi, ton premier match arrive !',
    jsonb_build_object('competition_id', p_competition_id,
                       'route', '/competitions/' || p_competition_id)
  from public.competition_registrations r
  where r.competition_id = p_competition_id and r.status = 'confirmed';
  get diagnostics v_count = row_count;

  if v_comp.format = 'single_elimination' then
    -- Génère le bracket (gère le padding par byes) → passe en `ongoing`.
    perform public.generate_single_elim_bracket(p_competition_id);
  else
    -- Formats à génération manuelle (poules / round robin) : on ferme les
    -- inscriptions ; l'admin génère ensuite le bracket via l'écran dédié, ce
    -- qui fera passer la compétition en `ongoing`.
    update public.competitions
       set status = 'registration_closed'
     where id = p_competition_id;
  end if;

  return v_count;
end;
$$;

comment on function public.start_competition_now(uuid) is
  'Admin : démarre une compétition (typiquement to_reprogram) avec les joueurs '
  'confirmés disponibles (≥ 2). single_elimination → génère le bracket et passe '
  'en ongoing ; autres formats → ferme les inscriptions (bracket manuel ensuite). '
  'Notifie tous les inscrits confirmés. Retourne le nombre de joueurs notifiés.';

revoke all on function public.start_competition_now(uuid) from anon, public;
grant execute on function public.start_competition_now(uuid) to authenticated;

-- ─────────────────────────────────────────────────────────────────────────────
-- 4. Cron : remplace l'auto-annulation par la bascule to_reprogram
-- ─────────────────────────────────────────────────────────────────────────────
do $$
begin
  perform cron.unschedule('auto_cancel_underfilled_competitions_daily');
exception when others then
  null; -- pas programmé (db reset neuf) : on ignore.
end $$;

do $$
begin
  perform cron.unschedule('flag_underfilled_competitions_daily');
exception when others then
  null; -- premier passage : pas encore programmé.
end $$;

select cron.schedule(
  'flag_underfilled_competitions_daily',
  '30 3 * * *',
  $job$ select public.flag_underfilled_competitions_for_reprogram(); $job$
);
