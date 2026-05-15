-- Phase 12.6 — Règle "3 strikes" : un utilisateur reconnu coupable
-- d'un litige à 3 reprises est définitivement banni de la plateforme.
-- Réintégration possible uniquement via une requête validée par
-- l'équipe Arena Requête (table reintegration_requests, migration
-- suivante).
--
-- Deux pièces :
-- 1. Colonne profiles.permanent_ban : distingue le ban "à vie" du ban
--    administratif classique (super-admin peut toujours débannir un
--    ban temporaire ; un permanent_ban ne saute que via approbation
--    d'une requête Arena Requête).
-- 2. Trigger AFTER UPDATE OF guilty_party_id sur disputes : à chaque
--    nouveau verdict coupable, compte le total et flippe is_active +
--    permanent_ban si on atteint 3.

alter table public.profiles
  add column if not exists permanent_ban boolean not null default false;

comment on column public.profiles.permanent_ban is
  'true = banni à vie suite à 3 verdicts coupables sur litige. Ne peut '
  'être levé qu''après approbation d''une reintegration_request par '
  'l''équipe Arena Requête.';

create index if not exists idx_profiles_permanent_ban
  on public.profiles(permanent_ban)
  where permanent_ban = true;

-- Trigger function : compte les disputes guilty pour le user désigné
-- et déclenche le ban à vie + notification si on atteint 3.
create or replace function public.enforce_three_strikes_ban()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_guilty_count int;
  v_username text;
begin
  if new.guilty_party_id is null then
    return new;
  end if;

  -- Sur UPDATE, ignore si le coupable n'a pas changé (évite de re-compter
  -- sur les UPDATE non-pertinents — set_updated_at, resolution text, etc.).
  if tg_op = 'UPDATE'
     and old.guilty_party_id is not distinct from new.guilty_party_id then
    return new;
  end if;

  select count(*) into v_guilty_count
  from public.disputes
  where guilty_party_id = new.guilty_party_id;

  if v_guilty_count < 3 then
    return new;
  end if;

  -- Idempotent : si déjà banni à vie, on ne re-banni pas (évite de
  -- ré-écrire is_active si un admin l'a déjà retoggle entretemps).
  update public.profiles
     set is_active = false,
         permanent_ban = true
   where id = new.guilty_party_id
     and permanent_ban = false
  returning username into v_username;

  if v_username is null then
    return new;
  end if;

  -- Notification user (FCM dispatché par trg_notifications_dispatch).
  insert into public.notifications(user_id, type, title, body, data)
  values (
    new.guilty_party_id,
    'permanent_ban',
    'Compte définitivement banni',
    'Vous avez été reconnu coupable d''un litige à 3 reprises. Votre '
    'compte est définitivement banni. Vous pouvez soumettre une requête '
    'de réintégration à l''équipe Arena Requête depuis l''écran de '
    'connexion (analyse sous 48h).',
    jsonb_build_object('route', '/banned', 'guilty_count', v_guilty_count)
  );

  return new;
end;
$$;

comment on function public.enforce_three_strikes_ban is
  'Trigger func : compte les verdicts coupables d''un user et applique '
  'le ban à vie + notification dès qu''on atteint 3.';

drop trigger if exists trg_three_strikes_ban on public.disputes;
create trigger trg_three_strikes_ban
  after insert or update of guilty_party_id on public.disputes
  for each row
  execute function public.enforce_three_strikes_ban();

-- Trigger function : pas d'exposition RPC (advisor 0028 + 0029).
revoke all on function public.enforce_three_strikes_ban()
  from public, anon, authenticated;
