-- ════════════════════════════════════════════════════════════════════
-- Reprogrammation : décaler un ROUND + purger les rappels + notifier
-- ════════════════════════════════════════════════════════════════════
-- Trois manques constatés (session 2026-07-16) :
--
--   1. RAPPELS PERDUS. `_dispatch_match_reminders` (20260526110000) dédoublonne
--      via le ledger `match_reminders_sent`. Ce ledger n'était JAMAIS purgé
--      quand un match était décalé → un match repoussé dont le rappel T-60 était
--      déjà parti ne rappelait plus jamais le joueur à la nouvelle heure.
--      Décaler un match revenait donc à priver les joueurs de leur rappel.
--
--   2. AUCUN MOYEN DE DÉCALER UN ROUND. `shift_competition_matches_on_reschedule`
--      (20260711140000) décale TOUS les matchs du delta de `start_date` ;
--      `reschedule` par match est unitaire. Rien ne permettait de dire
--      « le round 2 passe à demain 18h », alors qu'un round est justement
--      l'unité de planification (tous ses matchs partagent le même créneau —
--      cf. `try_schedule_next_round`, qui les pose tous à la même heure).
--
--   3. DÉCALAGE SILENCIEUX. Le trigger de shift ne notifie personne, et le
--      wizard admin pousse `start_date` sans un mot aux joueurs. Seule
--      `reprogram_competition` notifie — mais elle force `registration_open`,
--      donc inutilisable sur une compétition déjà en cours.
-- ════════════════════════════════════════════════════════════════════

-- ─────────────────────────────────────────────────────────────────────────────
-- 1. Purge du ledger de rappels dès qu'un match change d'horaire
-- ─────────────────────────────────────────────────────────────────────────────
-- Central : couvre TOUS les chemins de décalage (trigger de shift sur
-- start_date, reschedule unitaire, reschedule_round ci-dessous) — présents et à
-- venir. Le ledger n'est qu'un cache d'idempotence : le repurger fait
-- simplement re-planifier les rappels sur le nouvel horaire.
create or replace function public.purge_match_reminders_on_reschedule()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
  delete from public.match_reminders_sent where match_id = new.id;
  return new;
end;
$$;

comment on function public.purge_match_reminders_on_reschedule() is
  'Purge le ledger match_reminders_sent d''un match dont scheduled_at change, '
  'pour que les rappels T-60/30/10/5 repartent sur le nouvel horaire. Sans ça '
  'un match décalé ne rappelle plus jamais ses joueurs.';

drop trigger if exists trg_purge_match_reminders_on_reschedule on public.matches;
create trigger trg_purge_match_reminders_on_reschedule
  after update of scheduled_at on public.matches
  for each row
  when (new.scheduled_at is distinct from old.scheduled_at)
  execute function public.purge_match_reminders_on_reschedule();

-- ─────────────────────────────────────────────────────────────────────────────
-- 2. Décaler un ROUND entier + notifier les inscrits
-- ─────────────────────────────────────────────────────────────────────────────
-- Gardes alignées sur `reprogram_competition` / `resolve_dispute` :
-- `is_admin()` + `admin_can_country()` (cloisonnement pays, cf. 20260714140000).
--
-- Ne touche QUE les matchs non démarrés (pending/scheduled/ready) : un match en
-- cours, en litige ou terminé garde son horaire — le replanifier n'aurait aucun
-- sens et réécrirait un historique.
--
-- Fonctionne même compétition démarrée (`ongoing`), contrairement à
-- `reprogram_competition` qui rouvre les inscriptions.
create or replace function public.reschedule_round(
  p_competition_id uuid,
  p_round integer,
  p_scheduled_at timestamptz
)
returns integer
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_name     text;
  v_country  text;
  v_moved    integer;
  v_notified integer;
begin
  if not public.is_admin() then
    raise exception 'forbidden' using errcode = '42501';
  end if;
  if p_scheduled_at <= now() then
    raise exception 'La nouvelle date doit être dans le futur';
  end if;

  select name, country_code into v_name, v_country
    from public.competitions
   where id = p_competition_id;
  if v_name is null then
    raise exception 'Compétition introuvable';
  end if;
  if not public.admin_can_country(auth.uid(), v_country) then
    raise exception 'forbidden' using errcode = '42501';
  end if;

  update public.matches
     set scheduled_at = p_scheduled_at
   where competition_id = p_competition_id
     and round = p_round
     and status in ('pending', 'scheduled', 'ready');
  get diagnostics v_moved = row_count;

  -- 0 match déplaçable = round inexistant, déjà joué ou en cours. On lève
  -- plutôt que de rendre 0 en silence : l'admin croirait avoir replanifié.
  if v_moved = 0 then
    raise exception
      'Aucun match à replanifier sur le round % (inexistant, déjà démarré ou terminé)',
      p_round;
  end if;

  -- Notifie TOUS les inscrits confirmés (et pas seulement les joueurs du
  -- round) : aux rounds ≥ 2 les slots sont encore NULL tant que les vainqueurs
  -- ne sont pas connus — cibler les joueurs du round ne notifierait personne.
  insert into public.notifications (user_id, type, title, body, data)
  select distinct r.player_id, 'competition_dates_changed',
    '📅 Horaire modifié',
    'Le round ' || p_round || ' de « ' || v_name || ' » est désormais prévu le '
      || to_char(p_scheduled_at at time zone 'Africa/Douala',
                 'DD/MM/YYYY "à" HH24"h"MI')
      || '.',
    jsonb_build_object('competition_id', p_competition_id,
                       'round', p_round,
                       'route', '/competitions/' || p_competition_id)
  from public.competition_registrations r
  where r.competition_id = p_competition_id
    and r.status = 'confirmed';
  get diagnostics v_notified = row_count;

  return v_notified;
end;
$$;

comment on function public.reschedule_round(uuid, integer, timestamptz) is
  'Admin : replanifie tous les matchs NON DÉMARRÉS d''un round à un nouveau '
  'créneau, même compétition en cours (contrairement à reprogram_competition, '
  'qui rouvre les inscriptions). Gardes is_admin + admin_can_country. Notifie '
  'les inscrits confirmés (type competition_dates_changed). Retourne le nombre '
  'de joueurs notifiés. Lève si aucun match n''est déplaçable.';

revoke all on function public.reschedule_round(uuid, integer, timestamptz)
  from anon, public;
grant execute on function public.reschedule_round(uuid, integer, timestamptz)
  to authenticated;
