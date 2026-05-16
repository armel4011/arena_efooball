-- Phase 12.5 — `invitation_codes` : alignement schéma sur le modèle
-- Flutter (`lib/data/models/invitation_code.dart`).
--
-- Changements :
--   1. `target_email`   (nullable) : si renseigné, le redeem doit utiliser
--                                    exactement cet email.
--   2. `max_uses`       (default 1) : pour V1.0 toujours 1 (à terme on
--                                     pourra ouvrir un code à plusieurs
--                                     admins d'un même call-for-mods).
--   3. `uses_count`     (default 0) : incrémenté par l'EF `register-admin`.
--   4. `expires_at`     : devient nullable pour supporter l'option
--                         "JAMAIS" du super-admin (cf. UI SA2).
--
-- Pas de back-fill : les rows existantes ont `max_uses=1`/`uses_count=0`
-- via le default, et `target_email=null` (libre).

alter table public.invitation_codes
  add column if not exists target_email text,
  add column if not exists max_uses int not null default 1 check (max_uses >= 1),
  add column if not exists uses_count int not null default 0 check (uses_count >= 0);

alter table public.invitation_codes
  alter column expires_at drop not null;

-- Garde-fou : uses_count ne doit pas dépasser max_uses.
do $$
begin
  if not exists (
    select 1 from pg_constraint where conname = 'invitation_codes_uses_within_max'
  ) then
    alter table public.invitation_codes
      add constraint invitation_codes_uses_within_max
      check (uses_count <= max_uses);
  end if;
end $$;

-- Index pour la lookup côté EF (`where code = ? and uses_count < max_uses`).
create index if not exists invitation_codes_code_active_idx
  on public.invitation_codes (code)
  where uses_count = 0;

comment on column public.invitation_codes.target_email is
  'Email cible (optionnel). Si renseigné, le redeem doit fournir exactement cet email.';
comment on column public.invitation_codes.max_uses is
  'Nombre maximal d''utilisations. V1.0 toujours 1.';
comment on column public.invitation_codes.uses_count is
  'Nombre d''utilisations actuelles (incrémenté par l''EF register-admin).';
