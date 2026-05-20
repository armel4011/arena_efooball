-- ════════════════════════════════════════════════════════════════════
-- LOT D — Système de parrainage + compétitions free gated (items 4 + 8)
-- ════════════════════════════════════════════════════════════════════
-- 1. Chaque profile reçoit un `referral_code` unique (auto-généré).
-- 2. Quand un joueur s'inscrit, il peut référencer un autre via
--    `referred_by` (= code du parrain).
-- 3. Les compétitions gratuites peuvent exiger un `referral_quota` :
--    pour s'inscrire, le joueur doit avoir parrainé N personnes
--    via son propre code.
-- 4. RPC `can_register_via_referral` renvoie {eligible, current, target}.

-- ─── 1. Colonnes profiles ────────────────────────────────────────────
ALTER TABLE profiles
  ADD COLUMN IF NOT EXISTS referral_code text,
  ADD COLUMN IF NOT EXISTS referred_by text;

-- Helper : génère un code de 6 caractères hex haut-uppercase (ex. ARN-3F9A)
CREATE OR REPLACE FUNCTION public.gen_referral_code()
RETURNS text
LANGUAGE plpgsql
VOLATILE
AS $$
DECLARE
  v_code text;
  v_attempts integer := 0;
BEGIN
  LOOP
    v_code := 'ARN-' || upper(substring(md5(random()::text || clock_timestamp()::text), 1, 4));
    EXIT WHEN NOT EXISTS (SELECT 1 FROM profiles WHERE referral_code = v_code);
    v_attempts := v_attempts + 1;
    IF v_attempts > 50 THEN
      RAISE EXCEPTION 'Could not generate unique referral_code after 50 attempts';
    END IF;
  END LOOP;
  RETURN v_code;
END;
$$;

COMMENT ON FUNCTION public.gen_referral_code() IS
  'Lot D — Génère un code parrainage unique au format ARN-XXXX (4 hex upper).';

-- Backfill : tous les profiles existants doivent avoir un code
UPDATE profiles SET referral_code = gen_referral_code()
 WHERE referral_code IS NULL;

ALTER TABLE profiles
  ALTER COLUMN referral_code SET NOT NULL,
  ADD CONSTRAINT profiles_referral_code_unique UNIQUE (referral_code);

-- Trigger : pose un referral_code sur INSERT si l'app ne le fournit pas
CREATE OR REPLACE FUNCTION public.ensure_referral_code()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
  IF NEW.referral_code IS NULL OR NEW.referral_code = '' THEN
    NEW.referral_code := gen_referral_code();
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_ensure_referral_code ON profiles;
CREATE TRIGGER trg_ensure_referral_code
  BEFORE INSERT ON profiles
  FOR EACH ROW
  EXECUTE FUNCTION ensure_referral_code();

-- FK soft sur referred_by (text, refs un autre referral_code)
CREATE INDEX IF NOT EXISTS idx_profiles_referred_by ON profiles(referred_by)
  WHERE referred_by IS NOT NULL;

COMMENT ON COLUMN profiles.referral_code IS
  'Lot D — Code parrainage unique partagé par le joueur. Auto-généré.';
COMMENT ON COLUMN profiles.referred_by IS
  'Lot D — Code parrainage du parrain (text, lookup soft sur referral_code).';

-- ─── 2. Colonne competitions.referral_quota ─────────────────────────
ALTER TABLE competitions
  ADD COLUMN IF NOT EXISTS referral_quota integer NOT NULL DEFAULT 0;

COMMENT ON COLUMN competitions.referral_quota IS
  'Lot D — Quota de parrainages requis pour s''inscrire. 0 = pas de gating. Pertinent uniquement pour les comp. gratuites avec récompense.';

-- ─── 3. SQL fn : compter les parrainages d'un user ──────────────────
CREATE OR REPLACE FUNCTION public.count_user_referrals(p_user_id uuid)
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
     AND p.is_active = true;
$$;

COMMENT ON FUNCTION public.count_user_referrals(uuid) IS
  'Lot D — Compte les profiles actifs qui ont referred_by = user.referral_code.';

GRANT EXECUTE ON FUNCTION public.count_user_referrals(uuid) TO authenticated;

-- ─── 4. SQL fn : eligibilité d'un user pour une compétition gated ───
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
  v_eligible boolean;
BEGIN
  SELECT referral_quota INTO v_target
    FROM competitions
   WHERE id = p_competition_id;

  IF v_target IS NULL THEN
    -- Compétition introuvable
    RETURN jsonb_build_object(
      'eligible', false,
      'current', 0,
      'target', 0,
      'reason', 'competition_not_found'
    );
  END IF;

  -- Pas de gating → toujours éligible
  IF v_target <= 0 THEN
    RETURN jsonb_build_object(
      'eligible', true,
      'current', 0,
      'target', 0,
      'reason', 'no_quota'
    );
  END IF;

  v_current := count_user_referrals(p_user_id);
  v_eligible := v_current >= v_target;

  RETURN jsonb_build_object(
    'eligible', v_eligible,
    'current', v_current,
    'target', v_target,
    'reason', CASE WHEN v_eligible THEN 'quota_met' ELSE 'quota_not_met' END
  );
END;
$$;

COMMENT ON FUNCTION public.can_register_via_referral(uuid, uuid) IS
  'Lot D — Retourne {eligible, current, target, reason} pour gating parrainage. Côté serveur pour éviter les bypass client.';

GRANT EXECUTE ON FUNCTION public.can_register_via_referral(uuid, uuid) TO authenticated;

-- ─── 5. Trigger côté competition_registrations : bloque si quota pas
--    atteint (sécurité serveur — la RPC peut être bypassée). ─────────
CREATE OR REPLACE FUNCTION public.enforce_referral_quota_on_registration()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
  v_quota integer;
  v_current integer;
BEGIN
  SELECT referral_quota INTO v_quota
    FROM competitions
   WHERE id = NEW.competition_id;

  IF v_quota IS NULL OR v_quota <= 0 THEN
    RETURN NEW;  -- pas de gating
  END IF;

  v_current := count_user_referrals(NEW.player_id);

  IF v_current < v_quota THEN
    RAISE EXCEPTION USING
      MESSAGE = format('Referral quota not met: %s / %s', v_current, v_quota),
      ERRCODE = 'P0001',
      HINT = 'Le joueur doit parrainer %s personnes via son code referral_code avant de s''inscrire.';
  END IF;

  RETURN NEW;
END;
$$;

COMMENT ON FUNCTION public.enforce_referral_quota_on_registration() IS
  'Lot D — Bloque les inscriptions si le quota de parrainage n''est pas atteint. Sécurité serveur.';

DROP TRIGGER IF EXISTS trg_enforce_referral_quota ON competition_registrations;
CREATE TRIGGER trg_enforce_referral_quota
  BEFORE INSERT ON competition_registrations
  FOR EACH ROW
  EXECUTE FUNCTION enforce_referral_quota_on_registration();
