-- Pré-remplit les règles des 4 jeux (affichées sur l'écran de verrouillage de
-- salle). Élargit d'abord le CHECK de game_rules à `dream_league` (absent à la
-- création). Idempotent : upsert sur la PK `game`.

do $$
declare c_name text;
begin
  select conname into c_name
  from pg_constraint
  where conrelid = 'public.game_rules'::regclass and contype = 'c'
    and pg_get_constraintdef(oid) ilike '%game%';
  if c_name is not null then
    execute format('alter table public.game_rules drop constraint %I', c_name);
  end if;
end$$;

alter table public.game_rules
  add constraint game_rules_game_check
  check (game in ('efootball', 'draughts', 'ea_sports_fc', 'dream_league'));

insert into public.game_rules (game, rules_text) values
('efootball', $rules$RÈGLES DU MATCH — eFootball

1. Ponctualité : sois présent 5 min avant l'heure. Absence 30 min après l'heure = forfait.
2. Salon privé : le joueur à domicile crée un match amical en salon et envoie le code.
3. Enregistrement OBLIGATOIRE : filme ton écran du coup d'envoi au sifflet final. Sans preuve vidéo complète, tu perds le litige.
4. Équipes : interdit d'utiliser la même équipe que l'adversaire. Clubs/sélections autorisés uniquement, pas d'équipes sur-boostées : note d'équipe max 3200.
5. Réglages : mi-temps de 6 min, vitesse de jeu normale, blessures ON, remplacements autorisés. Mêmes réglages pour les deux.
6. Coupure : si moins de 5 min jouées et score 0-0, on rejoue ; sinon le score au moment de la coupure fait foi (capture obligatoire). Coupures volontaires répétées = forfait.
7. Abandon : quitter le match en cours = défaite par forfait.
8. Égalité : en phase KO, prolongations puis tirs au but. En poule, le match nul est autorisé.
9. Score : capture l'écran du score final ; les deux joueurs saisissent le même score. Désaccord = litige (la preuve vidéo décide).
10. Fair-play : pas d'insultes, pas de pause pour déstabiliser. Triche = 3 avertissements puis bannissement à vie.$rules$),
('ea_sports_fc', $rules$RÈGLES DU MATCH — Mobile FC (EA Sports FC)

1. Ponctualité : présent 5 min avant l'heure. Absence 30 min après = forfait.
2. Mode Tête-à-tête / salon privé : le joueur à domicile crée le match et envoie le code.
3. Enregistrement OBLIGATOIRE : filme ton écran du début à la fin. Sans preuve vidéo complète, tu perds le litige.
4. Équipes : interdit d'utiliser la même équipe que l'adversaire. Note d'équipe (OVR) max 100 pour l'équilibre.
5. Réglages : mi-temps de 4 min, remplacements autorisés, mêmes réglages pour les deux.
6. Coupure : moins de 5 min jouées et 0-0, on rejoue ; sinon le score au moment fait foi (capture). Coupures volontaires répétées = forfait.
7. Abandon : quitter en cours = défaite par forfait.
8. Égalité : en KO, prolongations puis tirs au but. En poule, match nul autorisé.
9. Score : capture le score final ; saisie identique des deux joueurs. Désaccord = litige (preuve vidéo décisive).
10. Fair-play : pas d'insultes, pas de pause abusive. Triche = 3 avertissements puis bannissement à vie.$rules$),
('dream_league', $rules$RÈGLES DU MATCH — Dream League Soccer

1. Ponctualité : présent 5 min avant l'heure. Absence 30 min après = forfait.
2. Le joueur à domicile organise la rencontre et transmet les informations de connexion via l'app.
3. Enregistrement OBLIGATOIRE : filme ton écran du coup d'envoi au sifflet final. Sans preuve vidéo complète, tu perds le litige.
4. Équipes : interdit d'utiliser la même équipe que l'adversaire.
5. Réglages : durée et paramètres convenus et identiques pour les deux joueurs avant le coup d'envoi.
6. Coupure : moins de 5 min jouées et 0-0, on rejoue ; sinon le score au moment fait foi (capture). Coupures volontaires répétées = forfait.
7. Abandon : quitter en cours = défaite par forfait.
8. Égalité : en KO, prolongations puis tirs au but. En poule, match nul autorisé.
9. Score : capture le score final ; saisie identique des deux joueurs. Désaccord = litige (preuve vidéo décisive).
10. Fair-play : pas d'insultes ni de comportement antisportif. Triche = 3 avertissements puis bannissement à vie.$rules$),
('draughts', $rules$RÈGLES DE LA PARTIE — Dames

1. Ponctualité : présent 5 min avant l'heure. Absence 30 min après = forfait.
2. La partie se joue DANS l'application : les règles (dames internationales 10x10, prise obligatoire, prise maximale, dame) sont appliquées automatiquement par le jeu.
3. Aucun enregistrement à faire : l'historique des coups fait foi.
4. Abandon : quitter la partie en cours = défaite par forfait.
5. Fair-play : pas d'insultes. Triche (aide extérieure, multi-compte) = 3 avertissements puis bannissement à vie.
6. Litige : via l'app uniquement ; décision de l'administration finale.$rules$)
on conflict (game) do update
  set rules_text = excluded.rules_text, updated_at = now();
