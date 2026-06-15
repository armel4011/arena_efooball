-- ════════════════════════════════════════════════════════════════════
-- Notifie chaque joueur de son classement final à la clôture
-- ════════════════════════════════════════════════════════════════════
-- À la clôture automatique d'une compétition (finalize_competition_if_complete,
-- 20260615140000 + fix 20260615170000), on insère une notification
-- `competition_result` par participant classé. Le trigger
-- `trg_notifications_dispatch` (AFTER INSERT) pousse ensuite en FCM ; la ligne
-- alimente aussi le feed in-app. `data.route` deep-linke vers la compétition.
--
-- Idempotent via le guard `status = 'ongoing'` de finalize : les notifications
-- ne sont insérées qu'une fois, au passage en `completed`.
-- Depends on: 20260615170000 (finalize), 20260515120001 (dispatch trigger).
-- ════════════════════════════════════════════════════════════════════

create or replace function public.finalize_competition_if_complete(p_competition_id uuid)
returns void
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_status   text;
  v_pending  integer;
  v_total    integer;
  v_name     text;
  v_dist     jsonb;
  v_currency text;
  g          record;
begin
  if p_competition_id is null then
    return;
  end if;
  select status::text, name, prize_distribution, registration_currency
    into v_status, v_name, v_dist, v_currency
    from competitions where id = p_competition_id;
  if v_status is distinct from 'ongoing' then
    return;
  end if;
  select count(*) into v_total from matches where competition_id = p_competition_id;
  if v_total = 0 then
    return;
  end if;
  select count(*) into v_pending
    from matches
   where competition_id = p_competition_id
     and status::text not in ('completed', 'forfeited', 'cancelled');
  if v_pending > 0 then
    return;
  end if;

  -- Classements de poule à jour AVANT le calcul du rang final (ordre triggers).
  for g in select id from groups where competition_id = p_competition_id loop
    perform public.recalculate_group_standings(g.id);
  end loop;

  perform public.compute_competition_final_ranks(p_competition_id);

  update competitions
     set status = 'completed'::competition_status, updated_at = now()
   where id = p_competition_id
     and status = 'ongoing'::competition_status;

  -- Notifie chaque participant classé de son rang (+ gain éventuel). Défensif :
  -- un échec de dispatch (pg_net / FCM) ne doit PAS empêcher la clôture.
  begin
    insert into public.notifications (user_id, type, title, body, data)
    select
      cr.player_id,
      'competition_result',
      case
        when cr.final_rank = 1 then '🥇 Champion !'
        when cr.final_rank = 2 then '🥈 Vice-champion !'
        when cr.final_rank = 3 then '🥉 Sur le podium !'
        else '🏁 Classement final publié'
      end,
      'Tu termines '
        || (case when cr.final_rank = 1 then '1er' else cr.final_rank::text || 'e' end)
        || ' de « ' || coalesce(v_name, 'la compétition') || ' »'
        || case
             when coalesce((v_dist ->> (cr.final_rank - 1))::numeric, 0) > 0
               then ' — tu remportes '
                 || ((v_dist ->> (cr.final_rank - 1))::numeric)::bigint::text
                 || ' ' || coalesce(v_currency, 'XAF') || ' !'
             else '.'
           end,
      jsonb_build_object(
        'competition_id', p_competition_id,
        'competition_name', v_name,
        'rank', cr.final_rank,
        'route', '/competitions/' || p_competition_id
      )
    from public.competition_registrations cr
    where cr.competition_id = p_competition_id
      and cr.final_rank is not null;
  exception when others then
    raise warning 'finalize: notification de classement échouée pour %: %',
      p_competition_id, sqlerrm;
  end;
end;
$$;
