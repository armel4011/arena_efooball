-- Classement général final d'une compétition : un rang d'arrivée par
-- participant, saisi par l'admin depuis la console et lu côté joueur
-- pour afficher le podium + les gains (croisé avec prize_distribution).
--
-- Nullable : null = pas encore classé. Pas de policy RLS à ajouter —
-- registrations_update_admin couvre déjà l'écriture admin sur cette table.
alter table public.competition_registrations
  add column final_rank int;

alter table public.competition_registrations
  add constraint competition_registrations_final_rank_check
  check (final_rank is null or final_rank >= 1);

comment on column public.competition_registrations.final_rank is
  'Rang d''arrivée final du participant (1 = vainqueur). Null tant que '
  'l''admin n''a pas publié le classement.';
