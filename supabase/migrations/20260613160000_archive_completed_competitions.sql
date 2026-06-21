-- ════════════════════════════════════════════════════════════════════
-- Archivage automatique des compétitions terminées (7 jours)
-- ════════════════════════════════════════════════════════════════════
-- Choix : SOFT-DELETE (archivage), PAS de suppression dure. Un DELETE
-- détruirait en cascade paiements/gains/revenus/matchs/classements — perte
-- comptable irréversible. On ARCHIVE plutôt (masquage des listes), réversible
-- et sans perte, cohérent avec le pattern RGPD du projet.
--
--   1) `completed_at` : horodatage fiable du passage en `completed` (posé par
--      trigger ; `updated_at` ne convient pas — repoussé à chaque édition).
--   2) `archived_at`  : posé par un cron 7 jours après `completed_at`.
--   3) Les listes côté joueur filtrent `archived_at IS NULL`.
-- ════════════════════════════════════════════════════════════════════

alter table public.competitions
  add column if not exists completed_at timestamptz,
  add column if not exists archived_at  timestamptz;

comment on column public.competitions.completed_at is
  'Horodatage du passage en status=completed (posé par trigger). Base du délai d''archivage.';
comment on column public.competitions.archived_at is
  'Compétition archivée (masquée des listes joueur). Posé par le cron 7j après completed_at. NULL = active.';

-- Index partiel pour le balayage du cron (peu de lignes ciblées).
create index if not exists idx_competitions_archivable
  on public.competitions (completed_at)
  where archived_at is null and status = 'completed';

-- ─── (1) Pose completed_at au passage en 'completed' ────────────────
create or replace function public.set_competition_completed_at()
 returns trigger
 language plpgsql
 set search_path to 'public', 'pg_temp'
as $function$
BEGIN
  IF NEW.status = 'completed'
     AND (TG_OP = 'INSERT' OR OLD.status IS DISTINCT FROM 'completed'::competition_status)
     AND NEW.completed_at IS NULL THEN
    NEW.completed_at := now();
  END IF;
  RETURN NEW;
END;
$function$;

drop trigger if exists trg_competition_completed_at on public.competitions;
create trigger trg_competition_completed_at
  before insert or update on public.competitions
  for each row execute function public.set_competition_completed_at();

-- ─── (2) Archivage des compétitions terminées depuis > 7 jours ──────
create or replace function public.archive_old_completed_competitions()
 returns integer
 language plpgsql
 security definer
 set search_path to 'public'
as $function$
DECLARE
  v_count integer;
BEGIN
  UPDATE public.competitions
     SET archived_at = now()
   WHERE status = 'completed'
     AND archived_at IS NULL
     AND completed_at IS NOT NULL
     AND completed_at < now() - interval '7 days';
  GET DIAGNOSTICS v_count = ROW_COUNT;
  RETURN v_count;
END;
$function$;

-- Fonction interne réservée au cron : seul le propriétaire (rôle du job)
-- doit pouvoir l'exécuter. On retire l'accès aux rôles client pour éviter
-- qu'un utilisateur authentifié déclenche l'archivage (DEFINER interne, cf.
-- standard de durcissement projet : revoke sur fns DEFINER internes).
revoke all on function public.archive_old_completed_competitions()
  from public, anon, authenticated;

-- ─── (3) Cron quotidien (cohérent avec auto_cancel_underfilled à 3h30) ──
DO $cron$
BEGIN
  IF EXISTS (SELECT 1 FROM cron.job WHERE jobname = 'archive_completed_competitions_daily') THEN
    PERFORM cron.unschedule('archive_completed_competitions_daily');
  END IF;
  PERFORM cron.schedule(
    'archive_completed_competitions_daily',
    '45 3 * * *',
    $$ SELECT public.archive_old_completed_competitions(); $$
  );
END;
$cron$;
