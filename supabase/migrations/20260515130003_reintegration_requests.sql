-- Phase 12.6 — Table reintegration_requests : canal "Arena Requête"
-- par lequel un utilisateur banni à vie (3-strikes) peut demander sa
-- réintégration. SLA d'analyse : 48h (purement indicatif côté admin —
-- pas d'auto-décision).
--
-- Workflow :
-- 1. User banni à vie soumet une requête (INSERT) → status='pending'.
-- 2. Super-admin la traite → status='approved' (débannit) ou 'rejected'.
-- 3. Trigger trg_reintegration_apply : à l'approval, flippe is_active +
--    permanent_ban du profile concerné + notification de résolution.
--
-- Contrainte : un seul "pending" actif par user (évite le spam).

create table if not exists public.reintegration_requests (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid not null
    references public.profiles(id) on delete cascade,
  message text not null check (length(message) between 10 and 2000),
  status text not null default 'pending'
    check (status in ('pending', 'approved', 'rejected')),
  created_at timestamptz not null default now(),
  resolved_at timestamptz,
  resolved_by uuid references public.profiles(id) on delete set null,
  resolution_reason text,
  updated_at timestamptz not null default now(),

  check (
    (status = 'pending'  and resolved_at is null  and resolved_by is null)
    or (status in ('approved','rejected') and resolved_at is not null)
  )
);

comment on table public.reintegration_requests is
  'Requêtes de réintégration "Arena Requête" — déposées par un user banni à '
  'vie (3 verdicts coupables) ; SLA 48h indicatif.';

create trigger trg_reintegration_requests_updated_at
  before update on public.reintegration_requests
  for each row execute function public.set_updated_at();

-- Un seul pending par user à la fois.
create unique index if not exists uniq_reintegration_pending_per_user
  on public.reintegration_requests(user_id)
  where status = 'pending';

create index if not exists idx_reintegration_status_created
  on public.reintegration_requests(status, created_at desc);

-- RLS
alter table public.reintegration_requests enable row level security;

-- User voit ses propres requêtes (toute leur historique).
create policy "reintegration_self_select"
  on public.reintegration_requests for select
  using (user_id = (select auth.uid()));

-- User peut soumettre SES propres requêtes (le check unique pending
-- empêche le spam). On limite aux users effectivement bannis à vie.
create policy "reintegration_self_insert"
  on public.reintegration_requests for insert
  with check (
    user_id = (select auth.uid())
    and exists (
      select 1 from public.profiles p
      where p.id = (select auth.uid())
        and p.permanent_ban = true
    )
  );

-- Admin voit tout + tranche (UPDATE).
create policy "reintegration_admin_all"
  on public.reintegration_requests for all
  using (public.is_admin()) with check (public.is_admin());

-- Trigger : à l'approval, débannit le user concerné + notif.
create or replace function public.apply_reintegration_decision()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_username text;
begin
  if new.status = old.status then
    return new;
  end if;

  if new.status = 'approved' then
    update public.profiles
       set is_active = true,
           permanent_ban = false
     where id = new.user_id
    returning username into v_username;

    insert into public.notifications(user_id, type, title, body, data)
    values (
      new.user_id,
      'reintegration_approved',
      'Réintégration approuvée',
      'Votre requête a été acceptée par l''équipe Arena Requête. Bon '
      'retour sur la plateforme !',
      jsonb_build_object('request_id', new.id)
    );
  elsif new.status = 'rejected' then
    insert into public.notifications(user_id, type, title, body, data)
    values (
      new.user_id,
      'reintegration_rejected',
      'Réintégration refusée',
      coalesce(
        new.resolution_reason,
        'Votre requête a été refusée par l''équipe Arena Requête.'
      ),
      jsonb_build_object('request_id', new.id)
    );
  end if;

  return new;
end;
$$;

drop trigger if exists trg_reintegration_apply on public.reintegration_requests;
create trigger trg_reintegration_apply
  after update of status on public.reintegration_requests
  for each row
  when (old.status is distinct from new.status)
  execute function public.apply_reintegration_decision();

comment on function public.apply_reintegration_decision is
  'Trigger : à l''approval/rejet d''une reintegration_request, met à jour '
  'profiles + envoie une notification au demandeur.';

-- Trigger function : pas d'exposition RPC (advisor 0028 + 0029).
revoke all on function public.apply_reintegration_decision()
  from public, anon, authenticated;
