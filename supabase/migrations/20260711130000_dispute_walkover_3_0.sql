-- ════════════════════════════════════════════════════════════════════
-- resolve_dispute : arbitrage d'un litige = TAPIS VERT 3-0
-- ════════════════════════════════════════════════════════════════════
-- Règle métier : quand l'admin tranche un litige en faveur d'un joueur, ce
-- joueur gagne d'office 3-0 (walkover / tapis vert). Un score déclaré par les
-- joueurs est invérifiable dans un litige — on n'entérine donc PAS de score
-- transmis : le favorisé gagne 3-0, l'autre 0-3.
--
-- Les paramètres p_score1/p_score2 restent dans la signature (compat client)
-- mais sont désormais IGNORÉS sur le chemin verdict. Un vainqueur DOIT être
-- désigné (hors annulation).
--
-- Conserve : gate is_admin(), justification obligatoire, vainqueur ∈ {p1,p2},
-- verrou super-admin pour les matches à cagnotte, résolution du litige et trace
-- d'audit dans la même transaction.
-- ════════════════════════════════════════════════════════════════════

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
  select prize_pool_local, prize_distribution into v_pool, v_dist
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
