-- Étape 0 « Synchronisation » de la salle de match : chaque joueur confirme que
-- son application de jeu est ouverte AVANT que le processus continue. Deux
-- drapeaux booléens sur `matches`, lus/écrits par les joueurs (le trigger
-- `guard_matches_protected_columns` ne protège que score/winner/status, donc
-- ces colonnes sont librement modifiables par un joueur du match).

alter table public.matches
  add column if not exists player1_ready boolean not null default false,
  add column if not exists player2_ready boolean not null default false;
