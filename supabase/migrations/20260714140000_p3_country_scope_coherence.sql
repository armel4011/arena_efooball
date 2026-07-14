-- ════════════════════════════════════════════════════════════════════
-- FIX P3 (audit 2026-07-14) — cohérence du cloisonnement pays
-- ════════════════════════════════════════════════════════════════════
-- Quatre RPC admin gataient sur `is_admin()` (ou `is_super_admin()` pour la
-- cagnotte) SANS vérifier `admin_can_country` : un admin scopé à un pays pouvait
-- agir sur une compétition/un match d'un autre pays. Aucune sortie d'argent
-- directe, mais incohérence avec le modèle pays (cancel_competition,
-- generate_payouts, admin_filter_users… sont tous cloisonnés).
--
-- On ajoute la garde `admin_can_country(auth.uid(), competitions.country_code)`
-- à chacune. Sémantique fail-closed identique aux autres RPC : super-admin/admin
-- global (scope NULL) passent ; admin scopé borné à ses pays. Les corps de
-- fonction restent inchangés par ailleurs.
--   • reprogram_competition
--   • start_competition_now
--   • admin_recompute_final_ranks
--   • resolve_dispute   (couvre aussi le super-admin lui-même scopé pays)
-- ════════════════════════════════════════════════════════════════════

-- ─── 1. reprogram_competition ───────────────────────────────────────
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
  v_name    text;
  v_country text;
  v_count   integer;
begin
  if not public.is_admin() then
    raise exception 'forbidden' using errcode = '42501';
  end if;
  if p_new_start_date <= now() then
    raise exception 'La nouvelle date doit être dans le futur';
  end if;

  -- Cloisonnement pays (country_code est NOT NULL → v_country null ⟺ introuvable).
  select country_code into v_country
    from public.competitions where id = p_competition_id;
  if v_country is null then
    raise exception 'Compétition introuvable' using errcode = 'P0002';
  end if;
  if not public.admin_can_country(auth.uid(), v_country) then
    raise exception 'Compte non autorise sur ce pays' using errcode = '42501';
  end if;

  -- Réouvre les inscriptions à la nouvelle date — UNIQUEMENT depuis un état
  -- pré-démarrage. Interdit de « reprogrammer » une compétition ongoing /
  -- completed / cancelled (casserait son cycle de vie et rouvrirait des
  -- inscriptions sur un tournoi déjà lancé ou clos).
  update public.competitions
     set status     = 'registration_open',
         start_date = p_new_start_date
   where id = p_competition_id
     and status in ('draft', 'registration_open', 'registration_closed', 'to_reprogram')
   returning name into v_name;

  if v_name is null then
    raise exception
      'Reprogrammation impossible : la compétition n''est pas dans un état reprogrammable (déjà démarrée, terminée ou annulée)'
      using errcode = '42501';
  end if;

  insert into public.notifications (user_id, type, title, body, data)
  select distinct r.player_id, 'competition_reprogrammed',
    '📅 Tournoi reprogrammé',
    'La compétition « ' || v_name || ' » est reprogrammée au '
      || to_char(p_new_start_date at time zone 'Africa/Douala',
                 'DD/MM/YYYY "à" HH24"h"MI')
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
  'Admin : reprogramme une compétition (depuis draft/registration_*/to_reprogram '
  'uniquement) à une nouvelle date et rouvre les inscriptions. Refuse si la '
  'compétition est ongoing/completed/cancelled (fix audit 2026-06-26) + '
  'cloisonnement admin_can_country (fix audit 2026-07-14). Notifie les inscrits '
  'confirmés. Retourne le nombre de joueurs notifiés.';

revoke all on function public.reprogram_competition(uuid, timestamptz)
  from anon, public;
grant execute on function public.reprogram_competition(uuid, timestamptz)
  to authenticated;

-- ─── 2. start_competition_now ───────────────────────────────────────
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

  select id, name, format::text as format, country_code
    into v_comp
    from public.competitions
   where id = p_competition_id;
  if v_comp.id is null then
    raise exception 'Compétition introuvable';
  end if;

  -- Cloisonnement pays.
  if not public.admin_can_country(auth.uid(), v_comp.country_code) then
    raise exception 'Compte non autorise sur ce pays' using errcode = '42501';
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
  'Cloisonnement admin_can_country (fix audit 2026-07-14). Notifie tous les '
  'inscrits confirmés. Retourne le nombre de joueurs notifiés.';

revoke all on function public.start_competition_now(uuid) from anon, public;
grant execute on function public.start_competition_now(uuid) to authenticated;

-- ─── 3. admin_recompute_final_ranks ─────────────────────────────────
create or replace function public.admin_recompute_final_ranks(p_competition_id uuid)
returns void
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_country text;
begin
  if not public.is_admin() then
    raise exception 'Reserve aux admins' using errcode = '42501';
  end if;

  select country_code into v_country
    from public.competitions where id = p_competition_id;
  if v_country is null then
    raise exception 'Compétition introuvable' using errcode = 'P0002';
  end if;
  if not public.admin_can_country(auth.uid(), v_country) then
    raise exception 'Compte non autorise sur ce pays' using errcode = '42501';
  end if;

  perform public.compute_competition_final_ranks(p_competition_id);
end;
$$;
comment on function public.admin_recompute_final_ranks(uuid) is
  'Recalcule competition_registrations.final_rank via compute_competition_final_ranks '
  '(même logique que la clôture auto). Gardée is_admin() + cloisonnement '
  'admin_can_country (fix audit 2026-07-14). Utilisée par le bouton '
  '« Classement automatique » de la console admin.';

revoke all on function public.admin_recompute_final_ranks(uuid) from public, anon;
grant execute on function public.admin_recompute_final_ranks(uuid) to authenticated;

-- ─── 4. resolve_dispute ─────────────────────────────────────────────
create or replace function public.resolve_dispute(
  p_match_id uuid,
  p_dispute_id uuid,
  p_justification text,
  p_cancel boolean default false,
  p_winner_id uuid default null,
  p_score1 integer default null,
  p_score2 integer default null
)
returns void
language plpgsql
security definer
set search_path to 'public', 'pg_temp'
as $function$
declare
  v_admin     uuid := auth.uid();
  v_p1        uuid;
  v_p2        uuid;
  v_comp      uuid;
  v_country   text;
  v_pool      numeric;
  v_dist      jsonb;
  v_has_prize boolean;
  v_score1    integer;
  v_score2    integer;
begin
  if not public.is_admin() then
    raise exception 'Reserve aux administrateurs' using errcode = '42501';
  end if;
  if coalesce(trim(p_justification), '') = '' then
    raise exception 'Justification obligatoire' using errcode = '22023';
  end if;

  select player1_id, player2_id, competition_id into v_p1, v_p2, v_comp
    from public.matches
    where id = p_match_id
    for update;
  if not found then
    raise exception 'Match introuvable' using errcode = 'P0002';
  end if;

  -- Garde renforcée : compétition AVEC PRIX → arbitrage réservé au super-admin.
  select prize_pool_local, prize_distribution, country_code
    into v_pool, v_dist, v_country
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

  -- Cloisonnement pays (couvre aussi un super-admin lui-même scopé pays).
  if not public.admin_can_country(v_admin, v_country) then
    raise exception 'Compte non autorise sur ce pays' using errcode = '42501';
  end if;

  if p_cancel then
    update public.matches
       set status = 'cancelled', finished_at = now()
     where id = p_match_id;
  else
    if p_winner_id is null then
      raise exception 'Un vainqueur doit etre designe (tapis vert 3-0)'
        using errcode = '22023';
    end if;
    if p_winner_id <> v_p1 and p_winner_id <> v_p2 then
      raise exception 'Le vainqueur doit etre un des deux joueurs du match'
        using errcode = '22023';
    end if;

    -- TAPIS VERT : le favorisé gagne 3-0, l'autre 0-3. Les scores transmis
    -- (p_score1/p_score2) sont ignorés — un litige n'entérine pas un score
    -- déclaré invérifiable.
    v_score1 := case when p_winner_id = v_p1 then 3 else 0 end;
    v_score2 := case when p_winner_id = v_p2 then 3 else 0 end;

    update public.matches
       set score1 = v_score1, score2 = v_score2, winner_id = p_winner_id,
           status = 'completed', finished_at = now()
     where id = p_match_id;
  end if;

  if p_dispute_id is not null then
    update public.disputes
       set status      = case when p_cancel then 'cancelled' else 'resolved' end,
           resolved_at = now(),
           resolved_by = v_admin,
           resolution  = p_justification
     where id = p_dispute_id;
  end if;

  insert into public.admin_audit_log
    (admin_id, action, target_type, target_id, after_state)
  values (
    v_admin,
    case when p_cancel then 'dispute_cancelled' else 'dispute_resolved' end,
    'match', p_match_id,
    case when p_cancel
      then jsonb_build_object('justification', p_justification)
      else jsonb_build_object('winner_id', p_winner_id, 'score1', v_score1,
                              'score2', v_score2, 'walkover', true,
                              'justification', p_justification)
    end
  );
end;
$function$;
