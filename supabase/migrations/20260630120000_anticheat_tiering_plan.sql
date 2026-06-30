-- =============================================================================
-- ARENA — Anti-triche P0 : plan de tiering + egress randomisé
-- =============================================================================
-- Réduit le NOMBRE d'egress LiveKit concurrents (capacité = matchs simultanés
-- en compétition) en n'enregistrant côté serveur QUE certains matchs, et pour
-- ceux-là UN SEUL joueur tiré au hasard côté serveur (design « opaque » : les
-- deux publient, un seul est egressé — le tricheur ignore s'il est filmé).
--
-- Rappel : P3 (commitment hash) couvre DÉJÀ 100 % des matchs à 0 egress
-- (plancher de preuve). L'egress LiveKit n'est qu'un RENFORT de dissuasion pour
-- les matchs à fort enjeu — d'où le tiering.
--
-- Dormant tant que `app_config.anticheat_provider = 'native_recorder'` : rien
-- n'appelle l'EF `livekit-token` en provider natif. S'active au switch
-- `livekit_track_egress`.
-- =============================================================================

-- ─── Table : une décision figée par match ──────────────────────────────────
create table if not exists public.match_anticheat_plans (
  match_id           uuid primary key
                       references public.matches(id) on delete cascade,
  -- 'native_only' : aucun egress (P3 seul) | 'livekit' : 1 egress de l'élu.
  mode               text not null check (mode in ('native_only', 'livekit')),
  -- Joueur tiré au hasard côté serveur dont la piste sera egressée (null si
  -- native_only). Non prédictible par le client.
  recorded_player_id uuid references auth.users(id),
  -- Pourquoi ce match est passé en tier livekit (observabilité P4) :
  -- 'prize' | 'surveillance' | 'dispute' | 'random' | null (native_only).
  reason             text,
  decided_at         timestamptz not null default now()
);

alter table public.match_anticheat_plans enable row level security;

-- Lecture admin (observabilité litiges / P4). Les écritures passent par le RPC
-- SECURITY DEFINER ci-dessous ou le service-role (EFs) — jamais le client.
drop policy if exists match_anticheat_plans_admin_read on public.match_anticheat_plans;
create policy match_anticheat_plans_admin_read
  on public.match_anticheat_plans
  for select
  using (public.is_admin());

-- ─── Seuils paramétrables (ajustables sans redéploiement / via P4 admin) ────
insert into public.app_config (key, value) values
  ('anticheat_tier_prize_threshold', '5000'::jsonb),
  ('anticheat_tier_strike_threshold', '1'::jsonb),
  ('anticheat_tier_sample_rate', '0.1'::jsonb)
on conflict (key) do nothing;

-- ─── RPC d'assignation : idempotente, décision figée au premier appel ───────
create or replace function public.assign_anticheat_plan(p_match_id uuid)
returns public.match_anticheat_plans
language plpgsql
security definer
set search_path to 'public', 'pg_temp'
as $function$
declare
  v_plan             public.match_anticheat_plans;
  v_p1               uuid;
  v_p2               uuid;
  v_prize            numeric;
  v_prize_threshold  numeric;
  v_strike_threshold int;
  v_sample_rate      numeric;
  v_livekit          boolean := false;
  v_reason           text;
  v_recorded         uuid;
  v_guilty           int;
begin
  -- Idempotence : une fois décidé, le plan est figé (retry EF, re-publication).
  select * into v_plan
    from public.match_anticheat_plans where match_id = p_match_id;
  if found then
    return v_plan;
  end if;

  -- Cagnotte du match = prize_pool_local de sa compétition (competition_id NOT NULL).
  select m.player1_id, m.player2_id, c.prize_pool_local
    into v_p1, v_p2, v_prize
  from public.matches m
  join public.competitions c on c.id = m.competition_id
  where m.id = p_match_id;
  if not found then
    raise exception 'Match introuvable' using errcode = 'P0002';
  end if;

  v_prize_threshold := coalesce(
    (select (value #>> '{}')::numeric from public.app_config
       where key = 'anticheat_tier_prize_threshold'), 5000);
  v_strike_threshold := coalesce(
    (select (value #>> '{}')::int from public.app_config
       where key = 'anticheat_tier_strike_threshold'), 1);
  v_sample_rate := coalesce(
    (select (value #>> '{}')::numeric from public.app_config
       where key = 'anticheat_tier_sample_rate'), 0.1);

  -- (1) Cagnotte ≥ seuil.
  if coalesce(v_prize, 0) >= v_prize_threshold then
    v_livekit := true;
    v_reason := 'prize';
  end if;

  -- (2) Joueur sous surveillance : a déjà été reconnu coupable (>= seuil).
  if not v_livekit then
    select count(*) into v_guilty
      from public.disputes
      where guilty_party_id in (v_p1, v_p2);
    if v_guilty >= v_strike_threshold then
      v_livekit := true;
      v_reason := 'surveillance';
    end if;
  end if;

  -- (3) Le match porte déjà un litige (réassignation sur match contesté).
  if not v_livekit
     and exists (select 1 from public.disputes where match_id = p_match_id) then
    v_livekit := true;
    v_reason := 'dispute';
  end if;

  -- (4) Échantillon aléatoire dissuasif.
  if not v_livekit and random() < v_sample_rate then
    v_livekit := true;
    v_reason := 'random';
  end if;

  -- Élu tiré au hasard CÔTÉ SERVEUR (non prédictible) si tier livekit.
  if v_livekit then
    v_recorded := case when random() < 0.5 then v_p1 else v_p2 end;
  end if;

  insert into public.match_anticheat_plans (match_id, mode, recorded_player_id, reason)
  values (
    p_match_id,
    case when v_livekit then 'livekit' else 'native_only' end,
    v_recorded,
    v_reason
  )
  on conflict (match_id) do nothing;

  -- Re-select : gère un insert concurrent (deux track_published quasi simultanés).
  select * into v_plan
    from public.match_anticheat_plans where match_id = p_match_id;
  return v_plan;
end;
$function$;

-- Interne : appelée uniquement par l'EF `livekit-token` en service-role.
-- Surtout pas exposée au client (revoke authenticated inclus — cf. audit).
revoke all on function public.assign_anticheat_plan(uuid) from public, anon, authenticated;
grant execute on function public.assign_anticheat_plan(uuid) to service_role;
