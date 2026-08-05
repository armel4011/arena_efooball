-- Lot 1a — Rôle « collecteur de paiement ».
-- ⚠️ ISOLÉ dans sa propre migration : en Postgres une nouvelle valeur d'enum
-- ne peut pas être UTILISÉE dans la même transaction que son ajout. La suite
-- (tables, RPC, RLS qui référencent 'collector') vit dans 20260805100100.
--
-- Le collecteur N'EST PAS un admin : is_admin()/is_super_admin() ne l'incluent
-- pas (elles testent role in ('admin','super_admin')). Son seul pouvoir passe
-- par des RPC dédiées (validation de paiement de SON pays sous quota).

alter type public.user_role add value if not exists 'collector';
