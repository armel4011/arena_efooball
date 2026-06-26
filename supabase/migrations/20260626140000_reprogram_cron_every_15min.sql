-- ════════════════════════════════════════════════════════════════════
-- Bascule « à reprogrammer » : cron quotidien → toutes les 15 minutes
-- ════════════════════════════════════════════════════════════════════
-- `flag_underfilled_competitions_for_reprogram()` détecte les compétitions
-- sous-remplies dont la date de début est passée et les bascule en
-- `to_reprogram`. C'était un cron QUOTIDIEN (03:30 UTC, cf.
-- 20260622120100), d'où un délai pouvant atteindre ~24 h entre l'échéance
-- réelle et la bascule. On passe à un balayage toutes les 15 minutes
-- (délai max ~15 min) — la fonction est légère (scan filtré). On renomme le
-- job en conséquence (`_daily` → `_15min`) pour rester lisible.
-- ════════════════════════════════════════════════════════════════════

do $$
begin
  perform cron.unschedule('flag_underfilled_competitions_daily');
exception when others then
  null; -- pas (ou plus) planifié : on ignore.
end $$;

do $$
begin
  perform cron.unschedule('flag_underfilled_competitions_15min');
exception when others then
  null; -- premier passage : pas encore planifié.
end $$;

select cron.schedule(
  'flag_underfilled_competitions_15min',
  '*/15 * * * *',
  $job$ select public.flag_underfilled_competitions_for_reprogram(); $job$
);
