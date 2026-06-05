-- =============================================================================
-- ARENA — Auto-annulation des compétitions sous-remplies (audit complétude)
-- =============================================================================
-- Trou : si une compétition n'atteint jamais son quota (`current_players <
-- max_players`) et que sa date de début passe, l'auto-bracket ne se déclenche
-- jamais (il exige `confirmed >= max_players`). Elle reste bloquée en
-- `registration_open`/`closed` indéfiniment, et les joueurs ayant payé sont
-- coincés sans tournoi ni remboursement.
--
-- Correctif : une fonction de balayage (cron quotidien) qui annule ces
-- compétitions et alimente la file de remboursement (réutilise la mécanique
-- C-2 : succeeded → refund_pending, awaiting_admin → rejected, + notifie tous
-- les inscrits). Pure SQL (pas d'EF) — même pattern que `match_reminders`.
-- =============================================================================

create or replace function public.auto_cancel_underfilled_competitions()
returns integer
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_comp  record;
  v_count integer := 0;
begin
  for v_comp in
    select id, name
      from public.competitions
     where status in ('draft', 'registration_open', 'registration_closed')
       and start_date is not null
       and start_date < now()
       and max_players is not null
       and current_players < max_players
  loop
    update public.competitions set status = 'cancelled' where id = v_comp.id;

    -- Notifie TOUS les inscrits confirmés (paiement ou non).
    insert into public.notifications (user_id, type, title, body, data)
    select distinct r.player_id, 'competition_cancelled', 'Competition annulee',
      'La competition « ' || v_comp.name || ' » a ete annulee faute de joueurs '
        || 'suffisants. Si tu as paye ton inscription, un remboursement Mobile '
        || 'Money te sera adresse par le staff.',
      jsonb_build_object('competition_id', v_comp.id, 'route', '/payments/history')
    from public.competition_registrations r
    where r.competition_id = v_comp.id and r.status = 'confirmed';

    -- Alimente la file de remboursement (paiements encaisses).
    update public.payments
       set status = 'refund_pending'
     where competition_id = v_comp.id and status = 'succeeded';

    -- Paiements non valides → rejetes (le joueur est notifie ci-dessus).
    update public.payments
       set status = 'rejected',
           rejection_reason = 'Competition annulee (joueurs insuffisants)'
     where competition_id = v_comp.id and status = 'awaiting_admin';

    v_count := v_count + 1;
  end loop;

  return v_count;
end;
$$;

comment on function public.auto_cancel_underfilled_competitions() is
  'Cron : annule les competitions dont start_date est passee sans atteindre '
  'max_players, alimente la file de remboursement (succeeded→refund_pending) '
  'et notifie les inscrits. Retourne le nombre de competitions annulees.';

-- Réservé au cron / service_role : aucun rôle applicatif ne doit l'appeler.
revoke all on function public.auto_cancel_underfilled_competitions() from anon, public, authenticated;

-- ─── Cron quotidien (03:30, après le cleanup RGPD de 03:15) ──────────────────
do $$
begin
  perform cron.unschedule('auto_cancel_underfilled_competitions_daily');
exception when others then
  null; -- pas encore programmé : on ignore.
end $$;

select cron.schedule(
  'auto_cancel_underfilled_competitions_daily',
  '30 3 * * *',
  $job$ select public.auto_cancel_underfilled_competitions(); $job$
);
