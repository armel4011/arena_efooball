-- Persiste la répartition des gains saisie dans le wizard admin de
-- création de compétition, pour que l'écran joueur « Confirmer inscription »
-- affiche la vraie distribution au lieu d'un barème codé en dur.
alter table public.competitions
  add column prize_distribution jsonb not null default '[50, 25, 15, 10]'::jsonb;

comment on column public.competitions.prize_distribution is
  'Pourcentages de gains par rang d''arrivée, ex. [50,25,15,10]. Somme = 100.';
