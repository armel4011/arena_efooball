-- ════════════════════════════════════════════════════════════════════
-- iOS PushKit — token VoIP du destinataire
-- ════════════════════════════════════════════════════════════════════
-- Sur iOS, réveiller l'app (même tuée) pour un appel entrant exige un
-- push VoIP APNs : FCM n'en envoie pas. L'app enregistre ici son token
-- PushKit ; l'Edge Function `dispatch_notification` s'en sert pour
-- router les `call_invite` iOS vers APNs au lieu de FCM.
--
-- Colonne nullable, miroir de `profiles.fcm_token` (Android). Aucun
-- changement de RLS : la policy UPDATE existante du profil couvre déjà
-- toutes ses colonnes pour son propriétaire.

ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS voip_token text;

COMMENT ON COLUMN public.profiles.voip_token IS
  'Token PushKit VoIP iOS (APNs). NULL sur Android, device non-iOS ou '
  'utilisateur déconnecté. Pendant iOS de profiles.fcm_token.';
