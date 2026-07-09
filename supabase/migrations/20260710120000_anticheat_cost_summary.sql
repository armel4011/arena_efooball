-- =============================================================================
-- ARENA — Anti-triche P4 (volet B) : coût egress CHIFFRABLE depuis les données
-- =============================================================================
-- Jusqu'ici le coût du tiering LiveKit n'était que PROJETÉ à la main (cf. plan
-- anti-triche). Cette migration le rend MESURABLE à partir des décisions réelles
-- figées dans `match_anticheat_plans` :
--   * combien de matchs décidés, combien egressés (tier livekit) vs natif seul,
--   * la ventilation par raison (cagnotte / surveillance / litige / aléa),
--   * le coût egress réel estimé = (nb egressés) × coût unitaire d'un egress,
--   * l'économie vs le scénario « sans tiering » (les 2 pistes de CHAQUE match
--     egressées), qui chiffre concrètement l'apport du tiering + egress unique.
--
-- Le coût unitaire est un paramètre `app_config` (modèle : 1 piste ≈ 12 min à
-- ~1,5 Mbps ≈ 0,034 $ chez LiveKit Ship — ajustable sans redéploiement). Reste
-- DORMANT tant que provider = native_recorder (aucun plan livekit créé).
-- =============================================================================

-- ─── Paramètre de coût unitaire (jsonb numérique, ajustable via l'admin) ─────
insert into public.app_config (key, value) values
  ('anticheat_cost_per_egress_usd', '0.034'::jsonb)
on conflict (key) do nothing;

-- ─── RPC d'agrégation : lecture super-admin, chiffrage depuis les plans ──────
-- p_since : borne basse optionnelle sur `decided_at` (null = depuis toujours).
create or replace function public.anticheat_cost_summary(
  p_since timestamptz default null
)
returns jsonb
language plpgsql
stable
security definer
set search_path to 'public', 'pg_temp'
as $function$
declare
  v_decided       int;
  v_livekit       int;
  v_native        int;
  v_prize         int;
  v_surveillance  int;
  v_dispute       int;
  v_random        int;
  v_cost_unit     numeric;
  v_actual        numeric;   -- coût egress réel estimé (1 piste / match egressé)
  v_baseline      numeric;   -- scénario sans tiering (2 pistes / match décidé)
  v_savings       numeric;
begin
  perform _require_super_admin();

  v_cost_unit := coalesce(
    (select (value #>> '{}')::numeric from public.app_config
       where key = 'anticheat_cost_per_egress_usd'), 0.034);

  select
    count(*),
    count(*) filter (where mode = 'livekit'),
    count(*) filter (where mode = 'native_only'),
    count(*) filter (where reason = 'prize'),
    count(*) filter (where reason = 'surveillance'),
    count(*) filter (where reason = 'dispute'),
    count(*) filter (where reason = 'random')
  into v_decided, v_livekit, v_native,
       v_prize, v_surveillance, v_dispute, v_random
  from public.match_anticheat_plans
  where p_since is null or decided_at >= p_since;

  -- Réel : un seul egress (1 piste) par match egressé (design opaque : les 2
  -- publient mais une seule piste est egressée).
  v_actual   := v_livekit * v_cost_unit;
  -- Baseline « sans tiering » : les 2 pistes de CHAQUE match décidé egressées.
  v_baseline := v_decided * 2 * v_cost_unit;
  v_savings  := v_baseline - v_actual;

  return jsonb_build_object(
    'since', p_since,
    'decided', v_decided,
    'livekit', v_livekit,
    'native_only', v_native,
    'livekit_fraction', case when v_decided > 0
                             then round(v_livekit::numeric / v_decided, 4)
                             else 0 end,
    'by_reason', jsonb_build_object(
      'prize', v_prize,
      'surveillance', v_surveillance,
      'dispute', v_dispute,
      'random', v_random
    ),
    'cost_per_egress_usd', v_cost_unit,
    'actual_cost_usd', round(v_actual, 4),
    'baseline_cost_usd', round(v_baseline, 4),
    'savings_usd', round(v_savings, 4),
    'savings_pct', case when v_baseline > 0
                       then round(v_savings / v_baseline * 100, 1)
                       else 0 end
  );
end;
$function$;

-- Interne : réservée à l'admin console (gate `_require_super_admin` dans le
-- corps). Jamais exposée au client anon/authenticated directement.
revoke all on function public.anticheat_cost_summary(timestamptz) from public, anon, authenticated;
grant execute on function public.anticheat_cost_summary(timestamptz) to authenticated;
