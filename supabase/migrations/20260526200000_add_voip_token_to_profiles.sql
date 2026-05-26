-- Ajoute la colonne voip_token (PushKit APNs token iOS, base64).
-- Nullable : tant que iOS n'a pas de compte Apple Dev configure, la
-- colonne reste null et l'EF dispatch_notification retombe sur FCM.
-- Cf. supabase/functions/dispatch_notification/index.ts qui SELECT
-- fcm_token, voip_token sur profiles.
--
-- Bug fix : le deploiement EF v8 du 2026-05-26 (ajout APNs VoIP) a
-- casse TOUS les FCM en prod parce que la colonne n'existait pas et
-- le profile_lookup renvoyait `column profiles.voip_token does not
-- exist` (HTTP 500 de l'EF, notifications.sent_at restait null).
ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS voip_token TEXT;

COMMENT ON COLUMN public.profiles.voip_token IS
  'PushKit/APNs device token (iOS uniquement, format base64 string). '
  'Renseigne par AppDelegate iOS via PushKit. NULL = pas iOS ou compte '
  'Apple Dev non configure. Lu par dispatch_notification EF pour '
  'router les appels entrants via APNs VoIP au lieu de FCM.';
