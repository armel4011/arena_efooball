-- Phase 2.4 — Numéro WhatsApp requis pour les nouveaux comptes.
--
-- Nullable car les comptes existants n'ont pas cette donnée. La validation
-- "requis" se fait côté client au moment du sign-up. Les utilisateurs déjà
-- inscrits pourront compléter via l'écran de profil plus tard.

alter table public.profiles
  add column if not exists whatsapp_number text;

comment on column public.profiles.whatsapp_number is
  'Numéro WhatsApp au format E.164 international (ex: +2250707070707). '
  'Requis pour les nouveaux comptes (validation client-side au signup).';
