-- A.3 — Le trigger d'auto-bracket s'exécute aussi sur UPDATE → confirmed
-- (flux paiement validé par super-admin : INSERT pending → UPDATE confirmed).

DROP TRIGGER IF EXISTS z_auto_generate_bracket_on_update ON competition_registrations;
CREATE TRIGGER z_auto_generate_bracket_on_update
  AFTER UPDATE ON competition_registrations
  FOR EACH ROW
  WHEN (OLD.status IS DISTINCT FROM NEW.status AND NEW.status = 'confirmed')
  EXECUTE FUNCTION trigger_auto_generate_bracket();

COMMENT ON TRIGGER z_auto_generate_bracket_on_update ON competition_registrations IS
  'Lot A.3 — Auto-bracket déclenché aussi quand un super-admin valide un paiement et flippe status pending → confirmed.';
