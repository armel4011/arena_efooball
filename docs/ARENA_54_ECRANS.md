# 📱 ARENA — Inventaire Détaillé des 54 Écrans

> **Document de référence** pour Claude Code afin de mettre à jour ou implémenter tous les écrans du projet ARENA.
>
> **Version** : 2.0 (mai 2026) — *correction du décompte (47 → 54), ajout AdminAuditLogPage*
> **Cohérent avec** : `ARENA_MASTER_PROMPT.md` v1.1 + `ARENA_FLUTTER_PROMPT.md` v1.1
>
> ⚠️ **Note historique** : la v1.0 de ce document annonçait "47 écrans" en titre, mais l'addition réelle des sections détaillées totalisait 54 écrans (35 USER + 19 ADMIN). Cette v2.0 corrige le décompte. La section Notifications (#19) fait partie de la section Core (et n'est plus comptée séparément). Un écran admin manquant (`AdminAuditLogPage`) a été ajouté pour respecter le total des 19 écrans admin annoncés.

---

## 📊 Vue d'ensemble

| App | Catégorie | Nombre d'écrans |
|-----|-----------|----------------|
| **APP USER** | Onboarding & Auth | 8 |
| **APP USER** | Core (home, comp, match, chat, notifications) | 11 |
| **APP USER** | Bracket | 2 |
| **APP USER** | Streaming | 2 |
| **APP USER** | Profil & Settings | 5 |
| **APP USER** | Paiements & Payouts | 7 |
| **Sous-total USER** | | **35** |
| **APP ADMIN** | Auth | 5 |
| **APP ADMIN** | Core (dashboard, comp, matchs) | 5 |
| **APP ADMIN** | Bracket / Streams / Payouts / Disputes | 4 |
| **APP ADMIN** | Super-Admin | 4 |
| **APP ADMIN** | Audit & journal | 1 |
| **Sous-total ADMIN** | | **19** |
| **TOTAL** | | **🎯 54 écrans** |

---

## 🎨 Design system (rappel)

> ⚠️ **TOUS les écrans doivent respecter ces standards** sans exception.

### Couleurs
```dart
// Backgrounds
bg = #07080F           // Très sombre (scaffold)
surface = #11131C      // Cartes
surfaceLight = #1A1D2A // Cartes elevées

// Brand
primary = #4C7AFF      // Bleu (USER app)
secondary = #FF3D5A    // Rouge (ADMIN/LIVE indicators)

// Game colors (par jeu)
efootball = #18E8D4    // Cyan
fifa = #FFAA00         // Orange
fcMobile = #FF6A1A     // Orange-rouge

// States
success = #0FE893      // Vert
warning = #FFAA00      // Orange
danger = #FF3D5A       // Rouge

// Text
text = #EEF1F8         // Blanc cassé
textMuted = #8A93A6    // Gris clair
textFaint = #555B6E    // Gris foncé
```

### Polices
- **Orbitron** (700, 800) → Headers, titres, scores
- **Nunito** (400, 600, 700) → Body, paragraphes, boutons
- **Fira Code** → Codes room, codes invitation

### Spacing & sizing
- Padding standard : 16px
- Padding sections : 24px
- Border radius cards : 16px
- Border radius boutons : 12px
- Bouton flottant anti-cheat : 72dp circulaire

---

# 📱 APP USER — 35 écrans

> 8 Onboarding/Auth + 11 Core + 2 Bracket + 2 Streaming + 5 Profil + 7 Paiements = **35 écrans**

## SECTION 1 — ONBOARDING & AUTH (8 écrans)

### Écran #1 — `OnboardingPage`

**Localisation** : `lib/features_user/onboarding/onboarding_page.dart`
**PHASE** : 0.5
**Affiché** : au premier lancement uniquement

**Description** :
4 slides d'introduction à l'app pour réduire l'abandon des nouveaux users (60% sans onboarding → 20% avec).

**Slides** :
1. **Welcome** — Logo ARENA animé + tagline "Tournois e-sport panafricains"
2. **Concept brackets** — Illustration arbre du tournoi (single elim)
3. **Match system** — Illustration code room partagé entre 2 joueurs
4. **Gains** — Illustration MoMo + trophée

**Composants** :
- `PageView.builder` avec 4 pages
- Indicateur progression (4 dots)
- Bouton "PASSER" (sauf dernier slide)
- Bouton "SUIVANT" / "COMMENCER" (dernier slide)
- Animations Lottie ou SVG

**Logique** :
- `SharedPreferences.setBool('onboarding_completed', true)` à la fin
- Au lancement de l'app : check ce bool → si `false` afficher, sinon sauter
- Update colonne `profiles.onboarding_completed = true` après inscription

**État Riverpod** : `onboardingCompletedProvider`

---

### Écran #2 — `SplashUserScreen`

**Localisation** : `lib/features_user/auth/splash_user_screen.dart`
**PHASE** : 2
**Affiché** : au lancement de l'app après onboarding

**Description** :
Splash screen avec logo animé + 2 CTAs (Login / S'inscrire). Affiche aussi des stats live de la plateforme.

**Composants** :
- Logo ARENA grand format avec animation (fade + scale)
- Stats live : "12 048 joueurs", "342 tournois", "1.2M XAF distribués"
- Bouton primaire "Se connecter" → `LoginUserScreen`
- Bouton secondaire "Créer un compte" → `RegisterUserScreen`
- Footer : "v1.0 — ARENA Cameroun"

**Logique** :
- Charge stats depuis Supabase (`select count from competitions where status='completed'`)
- Si user déjà connecté + `onboarding_completed=true` → skip vers `HomePage`
- Animations Hero pour transition vers Login/Register

---

### Écran #3 — `LoginUserScreen`

**Localisation** : `lib/features_user/auth/login_user_screen.dart`
**PHASE** : 2.1 + 2.3
**Affiché** : depuis `SplashUserScreen` ou si session expirée

**Description** :
Login avec email/password OU Google OU Apple Sign-In.

**Composants** :
- Titre "Bon retour parmi nous"
- TextField email (validation regex)
- TextField password (avec icône oeil)
- Bouton "Se connecter" (primaire bleu)
- Lien "Mot de passe oublié ?" → `ForgotPasswordPage`
- Séparateur "OU"
- Bouton "Continuer avec Google" (icône G + texte)
- Bouton "Continuer avec Apple" (uniquement si iOS)
- Footer : "Pas de compte ? S'inscrire" → `RegisterUserScreen`

**Logique** :
- Validation form avec `reactive_forms`
- `supabase.auth.signInWithPassword(email, password)`
- `signInWithGoogle()` via `google_sign_in`
- `signInWithApple()` via `sign_in_with_apple`
- ⚠️ **Filtre rôle strict** : si `profile.role IN ('admin', 'super_admin')` → erreur "Téléchargez ARENA Admin"
- Stockage refresh token en `flutter_secure_storage`

**Erreurs gérées** :
- Email invalide → message inline
- Mauvais credentials → toast rouge
- User non vérifié → bouton "Renvoyer email de vérification"
- Compte supprimé (deleted_at != null) → "Ce compte a été supprimé"

---

### Écran #4 — `RegisterUserScreen`

**Localisation** : `lib/features_user/auth/register_user_screen.dart`
**PHASE** : 2.1 + 2.4
**Affiché** : depuis `SplashUserScreen` ou `LoginUserScreen`

**Description** :
Inscription en **3 étapes** dans un même écran avec stepper.

**Étape 1/3 — Compte** :
- TextField email
- TextField password (force du mot de passe affichée)
- TextField confirm password
- Bouton "Suivant"

**Étape 2/3 — Profil** :
- TextField username (3-20 chars, vérif unicité en realtime)
- Picker pays (avec drapeaux)
- Color picker pour avatar (8 couleurs préfaites)

**Étape 3/3 — Conditions légales** ⭐ NOUVEAU
- Checkbox "J'accepte les CGU" (obligatoire) → lien vers CGU
- Checkbox "J'accepte la Privacy Policy" (obligatoire) → lien
- Checkbox "Je consens au marketing" (optionnel)
- Bouton "Créer mon compte" (désactivé si CGU/Privacy non cochées)

**Logique** :
- Création `auth.users` via Supabase Auth
- Insert dans `profiles` avec `auth_provider='email'`
- Stockage `cgu_accepted_at`, `cgu_version_accepted='v1.0'`, `privacy_policy_accepted_at`
- Email de vérification envoyé
- Redirige vers `HomePage` si auto-confirm activé

---

### Écran #5 — `ForgotPasswordPage` ⭐ NOUVEAU

**Localisation** : `lib/features_user/auth/forgot_password_page.dart`
**PHASE** : 2.2
**Affiché** : depuis `LoginUserScreen` (lien "Mot de passe oublié ?")

**Description** :
Saisie email → envoi mail de reset.

**Composants** :
- Titre "Mot de passe oublié ?"
- Description courte
- TextField email
- Bouton "Envoyer le lien"
- Lien "Retour à la connexion"

**Logique** :
- `supabase.auth.resetPasswordForEmail(email, redirectTo: 'arenaapp://reset-password')`
- Toast "Email envoyé ! Vérifie ta boîte"
- Cooldown 60s avant nouvel envoi

---

### Écran #6 — `ResetPasswordPage` ⭐ NOUVEAU

**Localisation** : `lib/features_user/auth/reset_password_page.dart`
**PHASE** : 2.2
**Affiché** : ouvert via deep link `arenaapp://reset-password?token=xxx`

**Description** :
Saisie nouveau mot de passe après clic sur lien email.

**Composants** :
- Titre "Nouveau mot de passe"
- TextField nouveau password (avec force)
- TextField confirm password
- Bouton "Réinitialiser"

**Logique** :
- Lib `app_links` ^6.0 pour deep links
- `supabase.auth.updateUser(password: newPassword)`
- Redirige vers `LoginUserScreen` avec toast "Mot de passe mis à jour"

---

### Écran #7 — `LinkExistingAccountPage` ⭐ NOUVEAU

**Localisation** : `lib/features_user/auth/link_existing_account_page.dart`
**PHASE** : 2.3
**Affiché** : si user fait login Google/Apple avec email déjà existant en email/pwd

**Description** :
Le user veut se connecter via Google mais son email existe déjà avec auth_provider='email'.

**Composants** :
- Avertissement "Un compte existe déjà avec cet email"
- Affiche les méthodes existantes (Email)
- TextField password (du compte email existant)
- Bouton "Lier mes comptes"
- Lien "Annuler"

**Logique** :
- Verify password avec `signInWithPassword`
- Si OK : link les 2 providers (`auth_provider` devient hybrid)
- Update `auth_provider_id` avec ID Google/Apple

---

### Écran #8 — `CGUAcceptancePage`

**Localisation** : `lib/features_user/auth/cgu_acceptance_page.dart`
**PHASE** : 2.4
**Affiché** : pour login Google/Apple à la 1re connexion (pas eu d'étape CGU dans Register)

**Description** :
Acceptation CGU/Privacy obligatoire pour les users qui se sont inscrits via social login.

**Composants** :
- Titre "Bienvenue sur ARENA !"
- Description courte
- Checkbox CGU (obligatoire)
- Checkbox Privacy (obligatoire)
- Checkbox Marketing (optionnel)
- Bouton "Continuer"

---

## SECTION 2 — CORE APP (11 écrans)

### Écran #9 — `HomePage`

**Localisation** : `lib/features_user/home/home_page.dart`
**PHASE** : 3
**Affiché** : écran principal après login

**Description** :
Dashboard joueur avec compétitions actives, prochains matchs, lives en cours, stats personnelles.

**Sections (de haut en bas)** :

1. **Header** :
   - Avatar coloré (couleur de profile.avatar_color)
   - Username + tier (ex: "Bronze")
   - Icône cloche notifications (badge count)
   - Bouton recherche

2. **Section "Prochains matchs"** (si user inscrit) :
   - Cards horizontales (PageView)
   - Affiche : adversaire, jeu, date/heure, status
   - Tap → `MatchRoomPage`

3. **Section "Lives en cours"** (si streams actifs) :
   - Cards avec preview + "🔴 LIVE"
   - Compteur viewers
   - Tap → `WatchStreamPage`

4. **Section "Compétitions actives"** :
   - Liste verticale de cards
   - Filtres rapides (Tous, eFootball, FIFA, FC Mobile)
   - Tap → `CompetitionDetailPage`

5. **Section "Tes stats"** :
   - W/L total
   - Win rate %
   - Goals scored/conceded
   - Bouton "Voir mon profil" → `PlayerProfilePage`

**Composants** :
- Bottom Navigation Bar (4 tabs : Home, Compétitions, Chat, Profil)
- Pull-to-refresh
- Empty states si pas de matchs/compet

**Logique** :
- StreamProvider Riverpod pour realtime updates
- Préchargement des images
- Cache local des stats

---

### Écran #10 — `CompetitionsListPage`

**Localisation** : `lib/features_user/competitions/competitions_list_page.dart`
**PHASE** : 4

**Description** :
Liste filtrée des compétitions disponibles.

**Composants** :
- Filtres top : `[Tous] [eFootball] [FIFA] [FC Mobile]`
- Filtre status : `[À venir] [En cours] [Terminés]`
- Liste cards verticales avec :
  - Image jeu (couleur game color)
  - Nom de la compétition
  - Date début/fin
  - Cagnotte totale (XAF)
  - Status badge (open_for_registration, in_progress, completed)
  - Nombre participants (X/Y)
  - Bouton "Détails" → `CompetitionDetailPage`

**Logique** :
- StreamProvider sur table `competitions`
- Filtres côté client (déjà chargé)
- Pull-to-refresh

---

### Écran #11 — `CompetitionDetailPage`

**Localisation** : `lib/features_user/competitions/competition_detail_page.dart`
**PHASE** : 4

**Description** :
Détails complets d'une compétition avec 4 tabs.

**Header (toujours visible)** :
- Banner avec couleur game color
- Nom compétition
- Status badge
- Cagnotte + nombre participants
- Bouton "S'inscrire" (ou "Inscrit ✓" si déjà inscrit)

**Tab 1 — Infos** :
- Description
- Format (Single Elim / Groupes+KO / Round Robin)
- Nombre de joueurs max
- Frais d'inscription
- Date début / fin
- Règles

**Tab 2 — Participants** :
- Liste avec avatars + usernames
- Pays + drapeau
- Tap → `PlayerProfilePage` (consultation)

**Tab 3 — Bracket** :
- Embed `BracketViewPage` (si phase démarrée)
- Sinon : "Le bracket sera généré au démarrage"

**Tab 4 — Prix** :
- Top 4 récompensés
- Affichage selon `prize_mode`:
  - Mode `percentage` : "1er - 50% (50 000 XAF estimé)"
  - Mode `fixed` : "1er - 100 000 XAF"

**Logique** :
- Bouton "S'inscrire" → vérifications :
  - Compétition `status='open_for_registration'`
  - `current_participants < max_participants`
  - Pas déjà inscrit
- Si OK : redirect vers `RegistrationConfirmPage`

---

### Écran #12 — `RegistrationConfirmPage`

**Localisation** : `lib/features_user/competitions/registration_confirm_page.dart`
**PHASE** : 4 (UI) + 11bis (paiement)

**Description** :
Confirmation avant inscription + lancement du paiement.

**Composants** :
- Récap compétition (nom, jeu, dates)
- Frais d'inscription (en XAF + équivalent USD)
- Cagnotte estimée
- Top 4 prix
- Checkbox "Je confirme avoir lu les règles"
- Bouton "Procéder au paiement" → `PaymentMethodPickerPage`

---

### Écran #13 — `MatchRoomPage` ⭐ LE CŒUR D'ARENA

**Localisation** : `lib/features_user/match_room/match_room_page.dart`
**PHASE** : 5

**Description** :
**LE CŒUR du système ARENA** : 4 étapes pour gérer un match entre 2 joueurs.

**Étape 1/4 — Partage code room** :
- Affiche les 2 joueurs (HOME + AWAY)
- Si HOME : TextField pour saisir code room eFootball
- Si AWAY : affiche "En attente du code de [HOME]"
- Timer 5 min (sinon forfait auto)
- Bouton HOME : "Code envoyé" (envoie au chat)

**Étape 2/4 — Configuration match (PHASE DE GROUPES UNIQUEMENT)** :
- Si `phase.type='groups'` :
  - Checklist OBLIGATOIRE pour HOME :
    - ☐ "J'ai désactivé les prolongations"
    - ☐ "J'ai désactivé les tirs au but"
  - Bouton "Confirmer" actif quand les 2 cochées
  - Stockage dans `matches.match_config` jsonb (anti-litige)
- Si autre type : skip cette étape

**Étape 3/4 — Saisie score concurrente** :
- Pendant que les 2 jouent : "Match en cours..."
- À la fin (quand un des 2 clique "Terminé") :
  - Les 2 saisissent leur score (HOME-AWAY)
  - TextField score joueur 1 + score joueur 2
  - Bouton "Soumettre"
  - Realtime : voir si l'adversaire a soumis

**Étape 4/4 — Validation collaborative** :
- Si scores concordent (HOME et AWAY ont saisi le même score) → match validé ✅
- Si discordance :
  - Modal "Désaccord !" avec les 2 scores
  - Bouton "Revoter"
  - Si 2 désaccords consécutifs → litige ouvert (bot d'arbitrage en PHASE 12.5)

**Composants** :
- Stepper visuel (4 étapes)
- Timer countdown
- Animations transitions entre étapes

**Logique** :
- StreamProvider pour realtime sync
- Stockage tous les events dans `match_events`
- Edge Function `submit_score_collaborative` pour la logique
- Forfait auto si timeout (PHASE 12.5)

**Important** : pendant ce match, le **bouton flottant anti-cheat** (PHASE 8) doit être actif.

---

### Écran #14 — `MatchHistoryPage`

**Localisation** : `lib/features_user/profile/match_history_page.dart`
**PHASE** : 9

**Description** :
Historique des matchs joués par l'utilisateur.

**Composants** :
- Filtres : `[Tous] [Victoires] [Défaites] [En cours]`
- Liste cards :
  - Vs [adversaire] (avatar)
  - Score final
  - Date
  - Compétition
  - Win/Loss badge
- Tap → détail (replay si recording dispo)

---

### Écran #15 — `MessagesInboxPage`

**Localisation** : `lib/features_user/chat/messages_inbox_page.dart`
**PHASE** : 6

**Description** :
Liste des conversations directes + canaux compétition.

**Composants** :
- Tab "Direct" (DM avec joueurs)
- Tab "Compétitions" (canaux par compet)
- Pour chaque conversation :
  - Avatar + username
  - Dernier message (preview)
  - Timestamp
  - Badge unread count
  - Indicateur online (vert)

**Logique** :
- StreamProvider Supabase Realtime
- Présence via Agora RTM
- Sort par dernier message

---

### Écran #16 — `ChatPage`

**Localisation** : `lib/features_user/chat/chat_page.dart`
**PHASE** : 6

**Description** :
Conversation 1-on-1 avec un autre joueur (ou canal compétition).

**Composants** :
- Header : avatar + username + indicateur online + "typing..."
- Liste messages :
  - Bulles texte (les miennes à droite)
  - Type spécial `room_code` : bulle cyan avec icône copy
  - Timestamps groupés
  - Status delivered/read
- Footer :
  - TextField (multiline)
  - Bouton emoji
  - Bouton attach (image)
  - Bouton envoyer

**Logique** :
- Messages : Supabase Realtime + `chat_messages` table
- Présence (typing/online) : Agora RTM channel attributes
- Modération : Edge Function `moderate_chat_message` (filtre `banned_words`)
- Scroll auto vers bas
- Lazy load historique au scroll up

---

### Écran #17 — `MatchInProgressOverlay`

**Localisation** : `lib/features_user/recording/match_in_progress_overlay.dart`
**PHASE** : 8

**Description** :
**Overlay flottant** affiché par-dessus le jeu (eFootball/FIFA/FC) pendant un match ARENA.

**Composants** :
- Bouton circulaire 72dp rouge
- Logo ARENA blanc
- Timer MM:SS (le match en cours)
- Drag-to-side : se colle aux bords droite/gauche
- Animation pulsation rouge

**Interactions** :
- **Tap court** : ramène ARENA en focus
- **Tap long** : dialogue avec 3 options :
  1. "Continuer" (ferme le dialogue)
  2. "Pause" (pause recording temporaire)
  3. "Arrêter (forfait)" (alerte admin + forfait)

**Logique** :
- Lib `flutter_overlay_window` ^0.4.5
- Service `flutter_foreground_task` ^8.0 pour persistance
- Sur tap long → vérification 2x avant forfait

---

### Écran #18 — `RecordingErrorPage`

**Localisation** : `lib/features_user/recording/recording_error_page.dart`
**PHASE** : 8

**Description** :
Affichée si le recording d'écran échoue (permissions, OEM tué le service, etc.).

**Composants** :
- Icône erreur rouge
- Titre "Erreur d'enregistrement"
- Description du problème
- Liste des solutions :
  - "Vérifier permissions : `SYSTEM_ALERT_WINDOW`"
  - "Désactiver Battery Saver"
  - "Autoriser ARENA en arrière-plan"
- Bouton "Réessayer"
- Bouton "Forfait (perdre le match)"
- Lien "Contacter le support"

---

### Écran #19 — `NotificationsPage`

**Localisation** : `lib/features_user/notifications/notifications_page.dart`
**PHASE** : 10

**Description** :
Centre des notifications in-app.

**Composants** :
- Tabs : `[Tout] [Non lues] [Compétitions] [Matchs] [Paiements]`
- Bouton "Tout marquer comme lu"
- Liste cards :
  - Icône (selon type)
  - Titre + description
  - Timestamp relatif ("il y a 2 min")
  - Badge unread (point bleu)
  - Tap → action contextuelle

**Types de notifs** :
- `match_reminder` (T-5 min)
- `match_terminated_validation_required`
- `competition_starting`
- `dispute_opened`
- `payout_received`
- `competition_completed`

---

## SECTION 3 — BRACKET (2 écrans)

### Écran #20 — `BracketViewPage`

**Localisation** : `lib/features_user/bracket/bracket_view_page.dart`
**PHASE** : 4

**Description** :
Visualisation de l'arbre du tournoi (bracket).

**3 modes selon `phase.type`** :

1. **Single Elimination** :
   - Arbre horizontal avec rounds (1/16, 1/8, ¼, ½, finale)
   - Chaque match = card avec 2 joueurs + score
   - Lignes connectrices animées
   - Zoom + pan (`InteractiveViewer`)

2. **Groupes + KO** :
   - Tab "Phase de groupes" (4 groupes A, B, C, D)
   - Tab "Phase finale" (bracket KO)
   - Cross-bracket : 1er Groupe A vs 2e Groupe B

3. **Round Robin** :
   - Pas de bracket, juste un classement
   - Redirige vers `GroupStandingsPage`

**Composants** :
- `CustomPainter` pour les lignes
- `InteractiveViewer` pour zoom/pan
- Highlight du match du user (si participant)
- Tap sur match → détail

---

### Écran #21 — `GroupStandingsPage`

**Localisation** : `lib/features_user/bracket/group_standings_page.dart`
**PHASE** : 4

**Description** :
Classement de la phase de groupes (table style FIFA).

**Composants** :
- Tabs par groupe (A, B, C, D...)
- Table avec colonnes :
  - Rang
  - Avatar + username
  - J (matchs joués)
  - V (victoires)
  - N (nuls — uniquement round robin)
  - D (défaites)
  - BP (buts pour)
  - BC (buts contre)
  - Diff (différence buts)
  - Pts (points)
- Highlight des qualifiés (top 2 = vert, autres = gris)
- Tap sur joueur → `PlayerProfilePage`

---

## SECTION 4 — STREAMING (2 écrans)

### Écran #22 — `LiveStreamsPage`

**Localisation** : `lib/features_user/streaming/live_streams_page.dart`
**PHASE** : 8.7

**Description** :
Liste des matchs en streaming live actuellement.

**Composants** :
- Header : "🔴 LIVE — X matchs en cours"
- Grid 2 colonnes (mobile) avec cards :
  - Preview thumbnail (si disponible)
  - Badge "🔴 LIVE"
  - Nom compétition + tour (ex: "Finale")
  - Joueurs : Avatar1 vs Avatar2
  - Score temps réel (si scores disponibles)
  - Compteur viewers (👁 245)
- Empty state : "Aucun match en live actuellement"

**Logique** :
- StreamProvider sur `streams` table où `is_active=true`
- Tap → `WatchStreamPage`

---

### Écran #23 — `WatchStreamPage`

**Localisation** : `lib/features_user/streaming/watch_stream_page.dart`
**PHASE** : 8.7

**Description** :
Écran pour regarder un stream Agora RTC + chat spectateurs.

**Layout (mobile portrait)** :
- **Top 60%** : Video player Agora (16:9 ratio)
  - Plein écran possible (paysage)
  - Contrôles : play/pause, qualité, fullscreen
  - Indicateur "🔴 LIVE" + viewers count
- **Bottom 40%** : Chat spectateurs
  - Messages temps réel (Supabase Realtime)
  - TextField envoi message
  - Modération auto (banned_words)

**Composants** :
- Lib `agora_rtc_engine` ^6.3
- Token sécurisé via Edge Function `get_agora_token`
- Heartbeat pour compter viewers (`current_viewers_count`)

**Logique** :
- À l'arrivée : `joinChannel()` en mode `audience`
- À la sortie : `leaveChannel()` + decrement viewers
- Auto-reconnexion si déconnexion

---

## SECTION 5 — PROFIL & SETTINGS (5 écrans)

### Écran #24 — `PlayerProfilePage`

**Localisation** : `lib/features_user/profile/player_profile_page.dart`
**PHASE** : 9.1

**Description** :
Profil joueur avec stats, achievements, historique.

**Sections** :

1. **Header** :
   - Avatar coloré (grand)
   - Username
   - Pays + drapeau
   - Tier (Bronze/Silver/Gold)
   - Bouton "Modifier" (si profil propre) → `EditProfilePage`

2. **Stats** :
   - Total matchs joués
   - Wins / Losses (W/L)
   - Win rate %
   - Buts marqués / encaissés
   - Différence de buts
   - Compétitions gagnées (1er, 2e, 3e, 4e)

3. **Achievements** :
   - Badges débloqués (First Win, 10 wins streak, etc.)
   - Grayed out pour non débloqués

4. **Historique récent** :
   - 10 derniers matchs (preview)
   - Bouton "Voir tout" → `MatchHistoryPage`

5. **Footer (profil propre seulement)** :
   - Bouton "Paramètres" → `SettingsPage`
   - Bouton "Mon historique de paiements" → `PaymentHistoryPage`

---

### Écran #25 — `EditProfilePage`

**Localisation** : `lib/features_user/profile/edit_profile_page.dart`
**PHASE** : 9.1

**Description** :
Modifier les infos du profil.

**Champs modifiables** :
- Username (avec vérif unicité)
- Avatar color (8 couleurs)
- Pays + drapeau
- Bio (optionnel, 200 chars max)

**Champs non modifiables** :
- Email (modifiable via SettingsPage > Compte)
- Date d'inscription
- Stats

**Composants** :
- Form avec `reactive_forms`
- Picker pays
- Color picker custom
- Bouton "Enregistrer"

---

### Écran #26 — `SettingsPage` ⭐ NOUVEAU

**Localisation** : `lib/features_user/profile/settings_page.dart`
**PHASE** : 9.2

**Description** :
Paramètres utilisateur regroupés en 4 sections.

**Section 1 — Préférences** :
- Langue (FR/EN/AR — V1.0 = FR seul)
- Devise (XAF/XOF/USD)
- Notifications push (toggle)
- Notifications email (toggle)
- Sons (toggle)
- Vibrations (toggle)

**Section 2 — Compte** :
- Modifier email
- Modifier mot de passe
- Méthodes de connexion (Google/Apple linked)
- Activer 2FA (futur V1.5)

**Section 3 — Confidentialité** :
- "Télécharger mes données" → email avec ZIP
- "Supprimer mon compte" → `DeleteAccountPage`
- "Politique de confidentialité" → web view
- "CGU" → web view

**Section 4 — Aide & Infos** :
- "Revoir l'intro" → relance `OnboardingPage`
- "Contacter le support" → email/WhatsApp
- "Évaluer ARENA" → store
- "À propos" → `AboutPage`
- "Version 1.0.0"

**Logique** :
- Toggle persiste dans `profiles` (preferred_language, etc.)
- Confirmations avant actions destructives

---

### Écran #27 — `DeleteAccountPage` ⭐ NOUVEAU

**Localisation** : `lib/features_user/profile/delete_account_page.dart`
**PHASE** : 9.3

**Description** :
**Workflow strict en 4 étapes** pour suppression compte (RGPD obligatoire pour Apple/Google).

**Étape 1 — Avertissement** :
- Liste de ce qui sera perdu :
  - Tous les matchs joués
  - Stats et achievements
  - Historique paiements
  - Inscriptions actives
- Bouton "Comprendre les conséquences"

**Étape 2 — Vérification gains pending** :
- Liste des payouts non encore versés
- Avertissement : "Réclame tes gains avant de supprimer"
- Si gains pending : bouton "Annuler" (force à attendre)
- Sinon : "Suivant"

**Étape 3 — Confirmation par mot de passe** :
- TextField password
- TextField "Tape SUPPRIMER pour confirmer"
- Bouton actif uniquement si les 2 sont remplis correctement
- Optionnel : raison de suppression (textarea)

**Étape 4 — Suppression effective** :
- Loader
- "Compte supprimé. Tu seras déconnecté."
- Logout auto + redirect vers `SplashUserScreen`

**Logique** :
- Soft-delete : `account_deletion_requested_at = now()`
- Délai grâce 30 jours (peut annuler en se reconnectant)
- Edge Function `cleanup_deleted_accounts` (cron 24h) anonymise après 30j
- Email de confirmation envoyé

---

### Écran #28 — `AboutPage`

**Localisation** : `lib/features_user/profile/about_page.dart`
**PHASE** : 9

**Description** :
Page "À propos" légale + crédits.

**Sections** :
- Logo ARENA
- Version (ex: "1.0.0+12")
- Copyright "© 2026 ARENA Cameroun"
- Liens :
  - CGU
  - Politique de confidentialité
  - Mentions légales
  - Code de conduite
- Crédits :
  - Designer
  - Développeur
- Tech stack utilisée (Flutter, Supabase, Agora)

---

## SECTION 6 — PAIEMENTS & PAYOUTS (7 écrans)

### Écran P1 — `PaymentMethodPickerPage`

**Localisation** : `lib/features_user/payments/payment_method_picker_page.dart`
**PHASE** : 11bis

**Description** :
Choix de la méthode de paiement (selon pays/devise du user).

**Composants** :
- Header : montant à payer (ex: "Frais d'inscription : 2 000 XAF")
- Section "Mobile Money" :
  - MTN Mobile Money (orange)
  - Orange Money (orange)
  - Wave (bleu)
  - Moov Money (bleu)
- Section "Cartes" (V1.1+) :
  - Visa
  - Mastercard
- Section "Crypto" :
  - USDT (TRC20)
  - BTC
  - ETH
- Tap sur méthode → écran spécifique

---

### Écran P2 — `MobileMoneyDetailsPage`

**Localisation** : `lib/features_user/payments/mobile_money_details_page.dart`
**PHASE** : 11bis

**Description** :
Saisie du numéro de téléphone Mobile Money.

**Composants** :
- Logo opérateur (MTN/Orange/Wave)
- TextField numéro (avec préfixe pays)
- Validation format selon opérateur
- Bouton "Continuer" → `PaymentProcessingPage`

---

### Écran P3 — `PaymentProcessingPage`

**Localisation** : `lib/features_user/payments/payment_processing_page.dart`
**PHASE** : 11bis

**Description** :
WebView CinetPay ou NowPayments pour finaliser le paiement.

**Composants** :
- WebView plein écran
- Loading initial
- Bouton "Annuler" en haut à droite
- Listener pour redirection success/failure

**Logique** :
- Lib `webview_flutter` ^4.7
- Edge Function `cinetpay_initiate_payment` ou `nowpayments_initiate_payment`
- Webhook backend reçoit confirmation (Edge Function)
- Polling status côté client toutes les 3s

---

### Écran P4 — `PaymentSuccessPage`

**Localisation** : `lib/features_user/payments/payment_success_page.dart`
**PHASE** : 11bis

**Description** :
Confirmation paiement réussi.

**Composants** :
- Animation Lottie "success" (checkmark vert)
- Titre "Paiement réussi !"
- Récap : montant, méthode, transaction ID
- Bouton "Voir mes inscriptions" → liste
- Bouton "Retour à l'accueil" → `HomePage`

---

### Écran P5 — `PaymentFailedPage`

**Localisation** : `lib/features_user/payments/payment_failed_page.dart`
**PHASE** : 11bis

**Description** :
Erreur de paiement.

**Composants** :
- Icône erreur rouge
- Titre "Paiement échoué"
- Description du problème
- Solutions suggérées
- Bouton "Réessayer" → `PaymentMethodPickerPage`
- Bouton "Annuler" → `HomePage`
- Lien "Contacter le support"

---

### Écran P6 — `PaymentHistoryPage`

**Localisation** : `lib/features_user/payments/payment_history_page.dart`
**PHASE** : 11bis

**Description** :
Historique paiements + payouts.

**Composants** :
- Tabs : `[Paiements] [Gains]`
- Filtres date (mois)
- Liste cards :
  - Date
  - Type (in/out)
  - Montant + devise
  - Méthode
  - Status (success, pending, failed)
  - Tap → détail avec transaction ID

**Logique** :
- StreamProvider sur `payments` + `payouts`
- Filtrage user_id

---

### Écran P7 — `PayoutKYCPage`

**Localisation** : `lib/features_user/payouts/payout_kyc_page.dart`
**PHASE** : 11bis

**Description** :
Vérification KYC pour payouts > seuil (ex: 100 000 XAF).

**Composants** :
- Avertissement "Pour ce gain, on doit vérifier ton identité"
- Upload pièce d'identité (recto)
- Upload pièce d'identité (verso)
- Selfie tenant la pièce
- Bouton "Soumettre"

**Logique** :
- Upload Supabase Storage (bucket `kyc-documents` privé)
- Update `profiles.kyc_status='pending'`
- Notification admin pour validation manuelle
- Une fois validé : `kyc_status='verified'` → payout débloqué

---

# 🛡️ APP ADMIN — 19 écrans

> 5 Auth + 5 Core + 4 Ops (bracket/streams/payouts/disputes) + 4 Super-Admin + 1 Audit = **19 écrans**

## SECTION 7 — AUTH ADMIN (5 écrans)

### Écran A1 — `SplashAdminScreen`

**Localisation** : `lib/features_admin/auth_admin/splash_admin_screen.dart`
**PHASE** : 2bis

**Description** :
Splash admin avec branding rouge.

**Composants** :
- Logo ARENA Admin (rouge)
- Animation
- 2 CTAs : "Se connecter" / "J'ai un code d'invitation"

---

### Écran A2 — `LoginAdminScreen`

**Localisation** : `lib/features_admin/auth_admin/login_admin_screen.dart`
**PHASE** : 2bis

**Description** :
Login admin avec email/password.

**Composants** :
- Email + password
- Bouton "Se connecter" (rouge)
- Lien "J'ai oublié mon mot de passe"
- ⚠️ Filtre rôle strict : seulement `admin` ou `super_admin`
- Pas de Google/Apple Sign-In (admin = sécurité max)

**Logique** :
- Après login OK → `TOTPVerifyScreen` (si TOTP activé)
- Si TOTP pas encore configuré → `TOTPSetupScreen`

---

### Écran A3 — `InvitationRedeemScreen`

**Localisation** : `lib/features_admin/auth_admin/invitation_redeem_screen.dart`
**PHASE** : 2bis

**Description** :
Saisie d'un code d'invitation pour devenir admin.

**Composants** :
- TextField code (format `ARENA-XXXX-XXXX-XXXX`, masque auto)
- Bouton "Valider"
- Si code OK → redirect vers création compte (email, password)

**Logique** :
- Vérifie `invitation_codes.status='pending'` + pas expiré
- Update `status='used'`
- Set `invited_by`, `invited_at` dans le profile créé

---

### Écran A4 — `TOTPSetupScreen`

**Localisation** : `lib/features_admin/auth_admin/totp_setup_screen.dart`
**PHASE** : 2bis

**Description** :
Configuration 2FA TOTP au premier login admin.

**Composants** :
- Étape 1 : "Télécharge Google Authenticator"
- Étape 2 : QR code (généré via `qr_flutter`)
- Étape 3 : "Saisis le code à 6 chiffres pour valider"
- TextField OTP (6 digits)
- Étape 4 : Affichage 10 backup codes
  - Bouton "Copier"
  - Bouton "Télécharger PDF"
  - Avertissement "Sauvegarde-les ailleurs"

**Logique** :
- Lib `otp` ^3.1 pour TOTP
- Secret stocké chiffré côté serveur (Edge Function)
- Backup codes hashés en DB

---

### Écran A5 — `TOTPVerifyScreen`

**Localisation** : `lib/features_admin/auth_admin/totp_verify_screen.dart`
**PHASE** : 2bis

**Description** :
Vérification TOTP à chaque login (après email/password OK).

**Composants** :
- Titre "Saisis ton code 2FA"
- 6 TextField (1 par chiffre, focus auto)
- Bouton "Vérifier"
- Lien "Utiliser un backup code"
- Lien "J'ai perdu mon device"

**Logique** :
- Vérification + comparaison avec `last_totp_used` (anti-replay)
- Si OK → `AdminDashboardPage`
- Si fail 3x → temporary lock 5 min

---

## SECTION 8 — CORE ADMIN (5 écrans)

### Écran A6 — `AdminDashboardPage`

**Localisation** : `lib/features_admin/dashboard/admin_dashboard_page.dart`
**PHASE** : 11

**Description** :
Dashboard admin avec stats et alertes.

**Sections** :
1. **KPIs en haut** :
   - Compétitions actives
   - Matchs en cours
   - Disputes ouvertes (badge rouge si > 0)
   - Payouts pending (badge rouge si > 0)

2. **Alertes** :
   - Liste des problèmes nécessitant attention
   - Tap → écran approprié

3. **Activité récente** :
   - Timeline des actions admin (depuis `admin_audit_log`)

4. **Quick actions** :
   - "+ Nouvelle compétition"
   - "Voir les disputes"
   - "Valider payouts"

**Logique** :
- StreamProvider sur multiples tables
- Realtime updates

---

### Écran A7 — `AdminCompetitionsListPage`

**Localisation** : `lib/features_admin/competitions_admin/admin_competitions_list_page.dart`
**PHASE** : 11

**Description** :
Liste de toutes les compétitions avec filtres avancés.

**Composants** :
- Filtres : status, jeu, créateur, dates
- Bouton "+ Nouvelle compétition" → `CreateCompetitionPage`
- Liste cards avec actions admin :
  - Voir détails → `AdminCompetitionDetailPage`
  - Modifier
  - Annuler
  - Forcer status

---

### Écran A8 — `CreateCompetitionPage`

**Localisation** : `lib/features_admin/competitions_admin/create_competition_page.dart`
**PHASE** : 11

**Description** :
**Formulaire en 5 étapes** pour créer une compétition.

**Étape 1/5 — Infos** :
- Nom (obligatoire)
- Jeu (eFootball / FIFA / FC Mobile)
- Description
- Date début / fin
- Image bannière (upload)

**Étape 2/5 — Format** :
- Type : Single Elim / Groupes+KO / Round Robin
- Nombre de joueurs : 8/16/32/64/128/256
- Si Groupes+KO : nombre de groupes
- Si Round Robin : 8-12 max

**Étape 3/5 — Prix (Top 4)** :
- Mode : `[Pourcentage]` ou `[Montants fixes]`
- Si %, sliders pour 4 positions (somme = 100%)
- Si fixe, TextField montants par position
- Devise

**Étape 4/5 — Frais & Commission** :
- Frais d'inscription
- Commission ARENA (%)
- Estimation cagnotte si plein

**Étape 5/5 — Review** :
- Récap complet
- Checkbox "Je valide"
- Bouton "Publier"

---

### Écran A9 — `AdminCompetitionDetailPage`

**Localisation** : `lib/features_admin/competitions_admin/admin_competition_detail_page.dart`
**PHASE** : 11

**Description** :
Détail compétition avec actions admin.

**Tabs** :
- Infos (édition)
- Participants (kick possible)
- Bracket (gestion → `AdminBracketManagementPage`)
- Matchs (liste)
- Disputes (de cette compet)
- Payouts (top 4)

**Actions admin** :
- Annuler la compétition
- Forcer démarrage
- Forcer completion
- Modifier prizes (avant démarrage)

---

### Écran A10 — `AdminMatchesListPage`

**Localisation** : `lib/features_admin/matches_admin/admin_matches_list_page.dart`
**PHASE** : 11

**Description** :
Liste de tous les matchs avec filtres.

**Filtres** :
- Status (pending, in_progress, validated, disputed)
- Compétition
- Joueurs
- Date

**Actions par match** :
- Voir détail → `AdminMatchDetailPage`
- Forcer validation score
- Marquer forfait
- Voir replay (si recording)

---

## SECTION 9 — BRACKET / STREAMS / PAYOUTS / DISPUTES (4 écrans)

### Écran A11 — `AdminBracketManagementPage`

**Localisation** : `lib/features_admin/bracket_admin/admin_bracket_management_page.dart`
**PHASE** : 11

**Description** :
Gestion du bracket d'une compétition (vue + actions).

**Composants** :
- Vue bracket (comme `BracketViewPage`)
- Sur chaque match, boutons admin :
  - "📺 Activer streaming" (sauf finales = auto)
  - "✅ Valider score manuellement"
  - "⚠️ Marquer dispute"
  - "🚫 Annuler match"

**Logique** :
- Toggle streaming → update `matches.is_streamed=true`, `streaming_activation_type='manual_admin'`
- Notif au HOME du match : "Ton match va être streamé !"

---

### Écran A12 — `AdminStreamModerationPage`

**Localisation** : `lib/features_admin/streams_admin/admin_stream_moderation_page.dart`
**PHASE** : 11

**Description** :
Grille des streams actifs avec stats temps réel.

**Composants** :
- Grid 2-3 colonnes (jusqu'à 6 streams simultanés)
- Pour chaque stream :
  - Preview vidéo (Agora subscriber mode)
  - Compteur viewers
  - Bouton "🔇 Couper" (modération)
  - Bouton "Voir le chat spectateurs"

**Logique** :
- Subscribe à tous les channels Agora simultanément
- Limite 6 pour ne pas crasher
- Audit log si coupure (`admin_audit_log`)

---

### Écran A13 — `AdminPayoutsPage` ⭐ CRITIQUE

**Localisation** : `lib/features_admin/payouts_admin/admin_payouts_page.dart`
**PHASE** : 11

**Description** :
**ÉCRAN LE PLUS CRITIQUE de l'admin** — validation manuelle des payouts (gestion d'argent réel).

**Layout** :

1. **Header** :
   - "Payouts en attente : X"
   - Total à verser : "X XAF"

2. **Liste des payouts pending** :
   - Card par payout :
     - Avatar joueur + username
     - Compétition
     - Position (1er, 2e, 3e, 4e)
     - Montant + devise
     - **5 contrôles auto** (icônes ✅/❌) :
       1. KYC vérifié
       2. Pas de litige ouvert sur ce joueur
       3. Pas d'alerte anti-cheat
       4. User non banni
       5. Données paiement valides (numéro MoMo OK)
     - Si 5/5 ✅ : bouton "Valider"
     - Si problème : bouton "Voir le problème"

3. **Mode batch** (par défaut) :
   - Checkbox "Sélectionner tout"
   - Bouton "Valider X payouts"
   - **Anti-erreur** : modal "Tape le total à verser : X XAF"
   - Si user tape le mauvais total → erreur
   - Si correct → exécution

4. **Mode 1-by-1** (pour disputes) :
   - Toggle pour switcher
   - Validation individuelle avec justification

**Logique** :
- StreamProvider sur `payouts WHERE status='pending_admin_validation'`
- Edge Function `execute_validated_payout` après validation
- Audit log obligatoire
- Notif au joueur : "Ton gain a été versé !"

⚠️ **Sécurité** : pas d'auto-payout. Tout passe par cet écran.

---

### Écran A14 — `AdminDisputesPage`

**Localisation** : `lib/features_admin/disputes_admin/admin_disputes_page.dart`
**PHASE** : 11

**Description** :
Gestion des litiges remontés par le bot d'arbitrage.

**Composants** :
- Liste cards avec :
  - Niveau d'escalade (1-3)
  - Match concerné
  - Joueurs + scores saisis (différents)
  - Timestamp ouverture
  - Tap → détail :
    - Replay (recording)
    - Chat de la match room
    - Events match
    - Bouton "Valider score 1"
    - Bouton "Valider score 2"
    - Bouton "Annuler match (refund)"
    - Champ justification (obligatoire)

---

## SECTION 10 — SUPER-ADMIN (4 écrans)

### Écran SA1 — `SuperAdminDashboard`

**Localisation** : `lib/features_admin/super_admin/super_admin_dashboard.dart`
**PHASE** : 12

**Description** :
Dashboard global pour le fondateur (toi).

**Composants** :
- KPIs globaux :
  - MAU (Monthly Active Users)
  - DAU (Daily Active Users)
  - Total revenus
  - Total payouts versés
  - Marge ARENA
- Graphiques (lib `fl_chart`) :
  - Inscriptions par mois
  - Revenus par mois
  - Top 10 joueurs (par gains)
  - Répartition par pays
- Alertes système (Sentry, Edge Functions errors)

---

### Écran SA2 — `SuperAdminInvitations`

**Localisation** : `lib/features_admin/super_admin/super_admin_invitations.dart`
**PHASE** : 12

**Description** :
Gestion des codes d'invitation pour nouveaux admins.

**Composants** :
- Liste codes avec status
- Bouton "Générer un code" :
  - Modal :
    - Rôle cible (admin / super_admin)
    - Email cible (optionnel)
    - Expiration (7j / 30j / never)
    - Nombre d'utilisations max
- Copy + share codes
- Révoquer un code

---

### Écran SA3 — `SuperAdminUsers`

**Localisation** : `lib/features_admin/super_admin/super_admin_users.dart`
**PHASE** : 12

**Description** :
Gestion globale des utilisateurs.

**Composants** :
- Recherche par username/email
- Filtres : rôle, pays, status (active/banned)
- Liste users avec :
  - Avatar + username
  - Email
  - Pays
  - Rôle
  - Status
  - Actions :
    - Voir détail complet
    - Bannir / débannir
    - Forcer reset mot de passe
    - Voir activité (audit log)

---

### Écran SA4 — `SuperAdminRevenue`

**Localisation** : `lib/features_admin/super_admin/super_admin_revenue.dart`
**PHASE** : 12

**Description** :
Comptabilité et fiscalité.

**Composants** :
- Filtres : période, devise, pays
- Stats :
  - Revenus total période
  - Commissions ARENA collectées
  - Payouts versés
  - Frais providers (CinetPay, NowPayments)
  - Marge nette
- Tableau détaillé (par compétition)
- Bouton "Export CSV" (pour comptable)
- Graphique évolution

---

## SECTION 11 — AUDIT & JOURNAL (1 écran)

### Écran A15 — `AdminAuditLogPage` ⭐ NOUVEAU (v2.0)

**Localisation** : `lib/features_admin/audit/admin_audit_log_page.dart`
**PHASE** : 11

**Description** :
Journal complet des actions admin pour audit et compliance. Affiche tous les événements stockés dans `admin_audit_log` (table déjà référencée dans plusieurs écrans : A6 dashboard, A12 stream moderation, A13 payouts).

**Composants** :
- Champ recherche (action, admin, ressource)
- Filtres catégorie : `[Toutes] [Payouts] [Disputes] [Bans] [Streams] [Compétitions] [Login admin]`
- Filtres période : `[Aujourd'hui] [7 jours] [30 jours] [Tout]`
- Liste cards par événement avec :
  - Icône catégorie + titre action
  - Timestamp (HH:mm)
  - Acteur (admin ID + username)
  - Ressource ciblée (lien cliquable vers la fiche : payout, match, user, etc.)
  - Justification (si fournie, ex: pour disputes)
  - Métadonnées : IP, device, géoloc approx (`maxmind` GeoIP)
- Bouton "📥 Exporter le journal" (CSV ou JSON pour audit externe)

**Logique** :
- StreamProvider sur `admin_audit_log` ordered by `created_at DESC`
- Pagination par 50 lignes
- Filtres côté client après chargement
- Export via Edge Function `export_audit_log` (génère CSV signé, lien valide 1h)
- Tap sur une ressource → navigation vers la fiche concernée (payout, dispute, user)

**Rôles autorisés** :
- `admin` : voit ses propres actions + actions de niveau ≤ son rôle
- `super_admin` : voit TOUT (y compris actions super-admin)

**Important — compliance** :
- Aucune ligne ne peut être supprimée (RGPD : conservation 5 ans pour les actions financières)
- Stockage en append-only (Supabase RLS empêche `DELETE`)
- Hash chaîné : chaque ligne contient le `prev_hash` de la précédente (anti-falsification)

---

# 📊 RÉCAPITULATIF — Mapping écrans / phases / fichiers

| Écran | Phase | Fichier |
|-------|-------|---------|
| OnboardingPage | 0.5 | `lib/features_user/onboarding/onboarding_page.dart` |
| SplashUserScreen | 2 | `lib/features_user/auth/splash_user_screen.dart` |
| LoginUserScreen | 2.1+2.3 | `lib/features_user/auth/login_user_screen.dart` |
| RegisterUserScreen | 2.1+2.4 | `lib/features_user/auth/register_user_screen.dart` |
| ForgotPasswordPage | 2.2 | `lib/features_user/auth/forgot_password_page.dart` |
| ResetPasswordPage | 2.2 | `lib/features_user/auth/reset_password_page.dart` |
| LinkExistingAccountPage | 2.3 | `lib/features_user/auth/link_existing_account_page.dart` |
| CGUAcceptancePage | 2.4 | `lib/features_user/auth/cgu_acceptance_page.dart` |
| HomePage | 3 | `lib/features_user/home/home_page.dart` |
| CompetitionsListPage | 4 | `lib/features_user/competitions/competitions_list_page.dart` |
| CompetitionDetailPage | 4 | `lib/features_user/competitions/competition_detail_page.dart` |
| RegistrationConfirmPage | 4 | `lib/features_user/competitions/registration_confirm_page.dart` |
| MatchRoomPage | 5 | `lib/features_user/match_room/match_room_page.dart` |
| MatchHistoryPage | 9 | `lib/features_user/profile/match_history_page.dart` |
| MessagesInboxPage | 6 | `lib/features_user/chat/messages_inbox_page.dart` |
| ChatPage | 6 | `lib/features_user/chat/chat_page.dart` |
| MatchInProgressOverlay | 8 | `lib/features_user/recording/match_in_progress_overlay.dart` |
| RecordingErrorPage | 8 | `lib/features_user/recording/recording_error_page.dart` |
| NotificationsPage | 10 | `lib/features_user/notifications/notifications_page.dart` |
| BracketViewPage | 4 | `lib/features_user/bracket/bracket_view_page.dart` |
| GroupStandingsPage | 4 | `lib/features_user/bracket/group_standings_page.dart` |
| LiveStreamsPage | 8.7 | `lib/features_user/streaming/live_streams_page.dart` |
| WatchStreamPage | 8.7 | `lib/features_user/streaming/watch_stream_page.dart` |
| PlayerProfilePage | 9.1 | `lib/features_user/profile/player_profile_page.dart` |
| EditProfilePage | 9.1 | `lib/features_user/profile/edit_profile_page.dart` |
| SettingsPage | 9.2 | `lib/features_user/profile/settings_page.dart` |
| DeleteAccountPage | 9.3 | `lib/features_user/profile/delete_account_page.dart` |
| AboutPage | 9 | `lib/features_user/profile/about_page.dart` |
| PaymentMethodPickerPage | 11bis | `lib/features_user/payments/payment_method_picker_page.dart` |
| MobileMoneyDetailsPage | 11bis | `lib/features_user/payments/mobile_money_details_page.dart` |
| PaymentProcessingPage | 11bis | `lib/features_user/payments/payment_processing_page.dart` |
| PaymentSuccessPage | 11bis | `lib/features_user/payments/payment_success_page.dart` |
| PaymentFailedPage | 11bis | `lib/features_user/payments/payment_failed_page.dart` |
| PaymentHistoryPage | 11bis | `lib/features_user/payments/payment_history_page.dart` |
| PayoutKYCPage | 11bis | `lib/features_user/payouts/payout_kyc_page.dart` |
| SplashAdminScreen | 2bis | `lib/features_admin/auth_admin/splash_admin_screen.dart` |
| LoginAdminScreen | 2bis | `lib/features_admin/auth_admin/login_admin_screen.dart` |
| InvitationRedeemScreen | 2bis | `lib/features_admin/auth_admin/invitation_redeem_screen.dart` |
| TOTPSetupScreen | 2bis | `lib/features_admin/auth_admin/totp_setup_screen.dart` |
| TOTPVerifyScreen | 2bis | `lib/features_admin/auth_admin/totp_verify_screen.dart` |
| AdminDashboardPage | 11 | `lib/features_admin/dashboard/admin_dashboard_page.dart` |
| AdminCompetitionsListPage | 11 | `lib/features_admin/competitions_admin/admin_competitions_list_page.dart` |
| CreateCompetitionPage | 11 | `lib/features_admin/competitions_admin/create_competition_page.dart` |
| AdminCompetitionDetailPage | 11 | `lib/features_admin/competitions_admin/admin_competition_detail_page.dart` |
| AdminMatchesListPage | 11 | `lib/features_admin/matches_admin/admin_matches_list_page.dart` |
| AdminBracketManagementPage | 11 | `lib/features_admin/bracket_admin/admin_bracket_management_page.dart` |
| AdminStreamModerationPage | 11 | `lib/features_admin/streams_admin/admin_stream_moderation_page.dart` |
| AdminPayoutsPage | 11 | `lib/features_admin/payouts_admin/admin_payouts_page.dart` |
| AdminDisputesPage | 11 | `lib/features_admin/disputes_admin/admin_disputes_page.dart` |
| SuperAdminDashboard | 12 | `lib/features_admin/super_admin/super_admin_dashboard.dart` |
| SuperAdminInvitations | 12 | `lib/features_admin/super_admin/super_admin_invitations.dart` |
| SuperAdminUsers | 12 | `lib/features_admin/super_admin/super_admin_users.dart` |
| SuperAdminRevenue | 12 | `lib/features_admin/super_admin/super_admin_revenue.dart` |
| AdminAuditLogPage | 11 | `lib/features_admin/audit/admin_audit_log_page.dart` |

**TOTAL : 54 écrans** (35 USER + 19 ADMIN)

---

# 🎯 Comment utiliser ce document avec Claude Code

## Cas 1 — Mise à jour d'un écran existant

```
Salut Claude.

📚 Lis ARENA_54_ECRANS.md, section "Écran #X — XxxPage" 

🎯 Je veux mettre à jour cet écran pour [raison].

Vérifie d'abord l'état actuel : 
view lib/features_user/.../xxx_page.dart

Puis propose les modifications nécessaires pour aligner sur le master.
Demande mon GO avant de modifier.
```

## Cas 2 — Création d'un écran manquant

```
Salut Claude.

📚 Lis ARENA_54_ECRANS.md, section "Écran #X — XxxPage"
   + ARENA_MASTER_PROMPT.md PARTIE 6 PHASE [N]

🎯 Cet écran n'existe pas encore. Crée-le selon les specs.

Étapes :
1. Crée le fichier au bon emplacement
2. Implémente les composants listés
3. Connecte au Supabase via repository
4. Ajoute les routes dans user_router.dart
5. Demande-moi de tester
```

## Cas 3 — Audit de cohérence

```
Salut Claude.

📚 Lis ARENA_54_ECRANS.md (54 écrans)

🎯 Audit de cohérence :
1. Liste tous les écrans actuellement présents dans lib/
2. Compare avec la liste des 54 écrans
3. Donne-moi :
   - Écrans manquants (à créer)
   - Écrans en trop (à supprimer)
   - Écrans présents mais incomplets (specs non respectées)

Pas de modification, juste un rapport.
```

## Cas 4 — Refacto navigation

```
Salut Claude.

📚 Lis ARENA_54_ECRANS.md (section RÉCAPITULATIF)

🎯 Mets à jour user_router.dart et admin_router.dart pour avoir 
toutes les routes des 54 écrans, même si les écrans n'existent 
pas encore (avec des Placeholder()).

Ainsi je pourrai lancer l'app et naviguer entre tous les écrans 
pour les implémenter au fur et à mesure.
```

---

# ✅ Checklist de validation

À cocher au fur et à mesure de l'implémentation :

## App User (35 écrans)

### Onboarding & Auth
- [ ] OnboardingPage
- [ ] SplashUserScreen
- [ ] LoginUserScreen
- [ ] RegisterUserScreen
- [ ] ForgotPasswordPage
- [ ] ResetPasswordPage
- [ ] LinkExistingAccountPage
- [ ] CGUAcceptancePage

### Core
- [ ] HomePage
- [ ] CompetitionsListPage
- [ ] CompetitionDetailPage
- [ ] RegistrationConfirmPage
- [ ] MatchRoomPage
- [ ] MatchHistoryPage
- [ ] MessagesInboxPage
- [ ] ChatPage
- [ ] MatchInProgressOverlay
- [ ] RecordingErrorPage
- [ ] NotificationsPage

### Bracket
- [ ] BracketViewPage
- [ ] GroupStandingsPage

### Streaming
- [ ] LiveStreamsPage
- [ ] WatchStreamPage

### Profil & Settings
- [ ] PlayerProfilePage
- [ ] EditProfilePage
- [ ] SettingsPage
- [ ] DeleteAccountPage
- [ ] AboutPage

### Paiements & Payouts
- [ ] PaymentMethodPickerPage
- [ ] MobileMoneyDetailsPage
- [ ] PaymentProcessingPage
- [ ] PaymentSuccessPage
- [ ] PaymentFailedPage
- [ ] PaymentHistoryPage
- [ ] PayoutKYCPage

## App Admin (19 écrans)

### Auth
- [ ] SplashAdminScreen
- [ ] LoginAdminScreen
- [ ] InvitationRedeemScreen
- [ ] TOTPSetupScreen
- [ ] TOTPVerifyScreen

### Core Admin
- [ ] AdminDashboardPage
- [ ] AdminCompetitionsListPage
- [ ] CreateCompetitionPage
- [ ] AdminCompetitionDetailPage
- [ ] AdminMatchesListPage

### Bracket / Streams / Payouts / Disputes
- [ ] AdminBracketManagementPage
- [ ] AdminStreamModerationPage
- [ ] AdminPayoutsPage
- [ ] AdminDisputesPage

### Super-Admin
- [ ] SuperAdminDashboard
- [ ] SuperAdminInvitations
- [ ] SuperAdminUsers
- [ ] SuperAdminRevenue

### Audit & journal
- [ ] AdminAuditLogPage

---

> 📝 **Document généré** : mai 2026
> 🔄 **Cohérent avec** : ARENA_MASTER_PROMPT.md v1.1
> 🎯 **Total écrans** : 54 (35 user + 19 admin)
> 🚀 **Objectif** : référence unique pour l'implémentation des écrans
