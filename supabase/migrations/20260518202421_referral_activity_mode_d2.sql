-- ════════════════════════════════════════════════════════════════════
-- LOT F.3 — Pondération filleul par activité (D.2)
-- ════════════════════════════════════════════════════════════════════
-- L'admin choisit si le compteur de parrainage prend tous les filleuls
-- (mode `any`, défaut) ou seulement ceux engagés (mode `engaged` :
-- ont joué au moins 1 match OU payé au moins 1 frais d'inscription).
--
-- Cette nuance bloque l'astuce "créer 10 faux comptes" pour bypasser
-- le quota : sans engagement réel, les filleuls ne comptent pas.

ALTER TABLE competitions
  ADD COLUMN IF NOT EXISTS referral_activity_mode text
    NOT NULL DEFAULT 'any'
    CHECK (referral_activity_mode IN ('any', 'engaged'));

COMMENT ON COLUMN competitions.referral_activity_mode IS
  'Lot D.2 — Pondération filleul. any = tous les filleuls actifs ; engaged = filleuls ayant joué un match OU payé une inscription.';

-- ─── Update count_user_referrals avec mode ───────────────────────────
CREATE OR REPLACE FUNCTION public.count_user_referrals(
  p_user_id uuid,
  p_mode    text DEFAULT 'any'
)
RETURNS integer
LANGUAGE sql
STABLE
SET search_path TO 'public'
AS $$
  SELECT count(*)::integer
    FROM profiles p
    JOIN profiles me ON me.id = p_user_id
   WHERE p.referred_by = me.referral_code
     AND p.id <> p_user_id
     AND p.is_active = true
     AND (
       p_mode = 'any'
       OR (
         p_mode = 'engaged' AND (
           EXISTS (SELECT 1 FROM matches m
                    WHERE p.id IN (m.player1_id, m.player2_id))
           OR EXISTS (SELECT 1 FROM payments pay
                       WHERE pay.user_id = p.id
                         AND pay.status IN ('succeeded', 'validated', 'confirmed'))
         )
       )
     );
$$;

COMMENT ON FUNCTION public.count_user_referrals(uuid, text) IS
  'Lot D + D.2 — Compte filleuls. Mode any = tous actifs, engaged = ont joué un match OU payé.';

GRANT EXECUTE ON FUNCTION public.count_user_referrals(uuid, text) TO authenticated;

-- Drop l'ancienne signature mono-arg (devenue ambiguë)
DROP FUNCTION IF EXISTS public.count_user_referrals(uuid);

-- Recrée le wrapper unaire qui appelle 'any' par défaut (back-compat)
CREATE OR REPLACE FUNCTION public.count_user_referrals(p_user_id uuid)
RETURNS integer
LANGUAGE sql
STABLE
SET search_path TO 'public'
AS $$
  SELECT public.count_user_referrals(p_user_id, 'any');
$$;
GRANT EXECUTE ON FUNCTION public.count_user_referrals(uuid) TO authenticated;

-- ─── Update can_register_via_referral avec mode lu sur la comp ──────
CREATE OR REPLACE FUNCTION public.can_register_via_referral(
  p_user_id uuid,
  p_competition_id uuid
)
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
  v_target integer;
  v_current integer;
  v_mode text;
  v_eligible boolean;
BEGIN
  SELECT referral_quota, referral_activity_mode INTO v_target, v_mode
    FROM competitions
   WHERE id = p_competition_id;

  IF v_target IS NULL THEN
    RETURN jsonb_build_object(
      'eligible', false, 'current', 0, 'target', 0,
      'mode', 'any', 'reason', 'competition_not_found'
    );
  END IF;

  IF v_target <= 0 THEN
    RETURN jsonb_build_object(
      'eligible', true, 'current', 0, 'target', 0,
      'mode', COALESCE(v_mode, 'any'), 'reason', 'no_quota'
    );
  END IF;

  v_current := count_user_referrals(p_user_id, COALESCE(v_mode, 'any'));
  v_eligible := v_current >= v_target;

  RETURN jsonb_build_object(
    'eligible', v_eligible,
    'current', v_current,
    'target', v_target,
    'mode', COALESCE(v_mode, 'any'),
    'reason', CASE WHEN v_eligible THEN 'quota_met' ELSE 'quota_not_met' END
  );
END;
$$;

GRANT EXECUTE ON FUNCTION public.can_register_via_referral(uuid, uuid) TO authenticated;

-- ─── Update trigger d'enforce pour passer le mode ───────────────────
CREATE OR REPLACE FUNCTION public.enforce_referral_quota_on_registration()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
  v_quota integer;
  v_mode text;
  v_current integer;
BEGIN
  SELECT referral_quota, referral_activity_mode INTO v_quota, v_mode
    FROM competitions WHERE id = NEW.competition_id;

  IF v_quota IS NULL OR v_quota <= 0 THEN
    RETURN NEW;
  END IF;

  v_current := count_user_referrals(NEW.player_id, COALESCE(v_mode, 'any'));

  IF v_current < v_quota THEN
    RAISE EXCEPTION USING
      MESSAGE = format('Referral quota not met: %s / %s (mode %s)',
                       v_current, v_quota, COALESCE(v_mode, 'any')),
      ERRCODE = 'P0001';
  END IF;

  RETURN NEW;
END;
$$;
