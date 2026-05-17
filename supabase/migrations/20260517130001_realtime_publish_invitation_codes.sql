-- Ajoute `invitation_codes` à la publication Realtime Supabase pour
-- que l'écran SA2 (Invitations admin) reçoive les push INSERT / UPDATE
-- / DELETE et se mette à jour sans pull-to-refresh. Sans ce GRANT, le
-- `_client.from('invitation_codes').stream(...)` ne reçoit que le
-- snapshot initial.
--
-- RLS reste appliquée côté serveur — seuls les super_admin reçoivent
-- les events (cf. invitation_codes_select_su).

ALTER PUBLICATION supabase_realtime ADD TABLE public.invitation_codes;
