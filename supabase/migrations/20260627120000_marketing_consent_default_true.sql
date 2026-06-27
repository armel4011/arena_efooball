-- Consentement marketing activé par défaut pour les NOUVEAUX comptes.
-- (Les comptes existants conservent leur choix — pas de bascule rétroactive,
--  l'utilisateur peut toujours désactiver dans Réglages.)
alter table public.profiles
  alter column marketing_consent set default true;
