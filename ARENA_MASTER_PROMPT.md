# 🏆 ARENA — MASTER PROMPT FLUTTER + CLAUDE CODE + CURSOR

> **Document de référence unique** pour développer la plateforme ARENA de A à Z.
> Écrit comme par un développeur senior Flutter avec 10 ans d'expérience.
> Optimisé pour un workflow **Claude Code + Cursor** sur Windows.

---

## 📖 SOMMAIRE

1. [🎯 Vision du projet & Comment utiliser ce document](#partie-1--vision)
2. [🏗️ Architecture technique complète](#partie-2--architecture)
3. [📱 Inventaire des 47 écrans](#partie-3--47-écrans)
4. [🗄️ Schéma de base de données complet](#partie-4--base-de-données)
5. [⚡ Edge Functions Supabase](#partie-5--edge-functions)
6. [🚀 Roadmap : 21 phases de développement](#partie-6--roadmap-21-phases)
7. [🛡️ Règles, conventions & sécurité](#partie-7--règles--conventions)
8. [💻 Workflow Claude Code + Cursor](#partie-8--workflow-claude-code)
9. [⚖️ Conformité légale](#partie-9--conformité-légale)
10. [📚 Références & ressources](#partie-10--références)

---

# PARTIE 1 — VISION

## 🎯 Qu'est-ce qu'ARENA ?

**ARENA** est une **plateforme panafricaine de tournois e-sport mobile** dédiée aux jeux de football virtuel : **eFootball**, **FIFA Mobile**, et **EA SPORTS FC Mobile**.

### Le problème qu'ARENA résout

Aujourd'hui, en Afrique, les passionnés de jeux de football mobile organisent leurs tournois via WhatsApp, avec :
- ❌ Pas de système automatique de bracket
- ❌ Pas de validation collaborative des scores
- ❌ Pas de paiement intégré (cash en main, MoMo manuel)
- ❌ Pas de protection anti-triche
- ❌ Pas d'historique ni de classement
- ❌ Risque élevé de litiges et arnaques

**ARENA résout tous ces problèmes** dans une app mobile native, avec :
- ✅ Brackets automatiques (single elim, groupes+KO, round robin)
- ✅ Match Room avec partage de code eFootball
- ✅ Validation collaborative des scores
- ✅ Paiements intégrés (CinetPay : MTN MoMo, Orange Money, Wave + crypto)
- ✅ Anti-triche : recording d'écran + bouton flottant
- ✅ Streaming live des finales (Agora RTC sélectif)
- ✅ Chat hybride (Supabase Realtime + Agora RTM)
- ✅ Bot d'arbitrage automatique des litiges
- ✅ Stats, classements, achievements

### Marché cible (rollout progressif)

| Version | Région | Pays | Langue | Devises |
|---------|--------|------|--------|---------|
| **V1.0** | Afrique francophone | 13 pays (Cameroun, Sénégal, Côte d'Ivoire, Gabon, Bénin, Togo, Burkina, Mali, Niger, Tchad, Guinée, RDC, Madagascar) | FR | XAF, XOF, USD |
| **V1.1** | Afrique anglophone | 7 pays (Nigeria, Ghana, Kenya, Afrique du Sud, Rwanda, Ouganda, Tanzanie) | EN | NGN, GHS, KES, ZAR, RWF, UGX, TZS |
| **V1.2** | Maghreb | 4 pays (Maroc, Algérie, Tunisie, Égypte) | AR (RTL) | MAD, DZD, TND, EGP |

### Modèle économique

- **Frais d'inscription** par compétition (définis par l'admin)
- **Commission ARENA** : 10-15% sur la cagnotte
- **Top 4 récompensés** (mode pourcentage OU montants fixes selon admin)
- **Sponsoring** possible (admin peut ajouter des fonds bonus)

---

## 👤 Profil du développeur (TOI)

Avant de plonger dans le code, voici **qui tu es** et comment ce document est adapté à ton profil :

| Caractéristique | Détail |
|-----------------|--------|
| **Niveau Flutter** | Débutant (mais motivé et déterminé) |
| **Système** | Windows 10/11 |
| **Outils** | Cursor (IDE), Claude Code (assistant), Git, Flutter SDK, Android Studio |
| **Langue** | Français |
| **Disponibilité** | Soutenue (jusqu'à 60h/semaine) |
| **Localisation** | Cameroun (Douala) |
| **Approche** | Validation phase par phase, pragmatique, exigeant sur la qualité |

### Implications pour ce document

- ✅ Explications **pédagogiques** quand des concepts Flutter avancés sont introduits
- ✅ **Étape par étape** avec validation à chaque palier
- ✅ Code **commenté en anglais** (standard dev) mais **explications en français**
- ✅ **Tableaux récapitulatifs** pour visualiser rapidement
- ✅ **Checklists actionnables** à cocher au fur et à mesure
- ✅ **Anti-blocages** : que faire quand Claude Code se trompe ou bloque
- ✅ **Tests** systématiques à chaque étape

---

## 🤖 Rôle de Claude Code dans ce projet

> ⚠️ **IMPORTANT** : tu travailles avec **Claude Code** (assistant IA dans Cursor), pas avec un développeur humain. Adapte tes attentes en conséquence.

### Ce que Claude Code fait BIEN ✅

- Écrire du code Flutter/Dart en suivant les specs
- Créer la structure de fichiers/dossiers
- Implémenter des écrans selon des wireframes
- Écrire les requêtes Supabase (SQL + Dart)
- Créer les services, providers, repositories
- Configurer les flavors, build settings
- Écrire les tests automatisés

### Ce que Claude Code ne fait PAS BIEN ⚠️

- **Prendre des décisions architecturales** : ce document les a déjà prises pour toi
- **Choisir entre plusieurs solutions** : ce document indique le choix retenu
- **Comprendre le métier complexe** : ce document explique la logique business
- **Tester sur de vrais devices** : c'est à toi de le faire
- **Configurer les comptes externes** : Supabase, Agora, Firebase = à toi
- **Décider des UI/UX** : suit les wireframes existants

### Comment Claude Code doit interagir avec TOI

À chaque interaction, Claude Code doit :

1. ✅ **Lire la phase concernée** dans ce document AVANT de coder
2. ✅ **Annoncer ce qu'il va faire** avant de le faire (1-2 lignes)
3. ✅ **Coder par sous-étapes** (pas tout d'un coup)
4. ✅ **Demander tes tests** après chaque sous-étape
5. ✅ **Ne JAMAIS halluciner des libs** ou inventer des APIs
6. ✅ **Utiliser web_search** quand il a un doute sur une API récente
7. ✅ **Te prévenir des risques** (code natif, permissions, deps lourdes)
8. ✅ **Respecter strictement la stack imposée** (pas de subsitution)

### Prompt à donner à Claude Code en début de chaque session

```
Salut Claude. Je travaille sur ARENA, une plateforme de tournois e-sport mobile.

📚 LECTURES OBLIGATOIRES avant de coder :
1. Lis le fichier ARENA_MASTER_PROMPT.md en entier (ou la section concernée)
2. Lis ARENA_FLUTTER_PROMPT.md pour les détails approfondis
3. Vérifie l'état actuel du projet avec : ls -la lib/

🎯 Aujourd'hui je veux implémenter : [PHASE X — Nom de la phase]

📋 Avant de commencer, dis-moi :
- Quelles sous-étapes tu prévois
- Quels fichiers tu vas créer/modifier
- Quels tests je devrai effectuer

⚠️ Règles non-négociables :
- Pas de substitution de libs (respecter la stack imposée)
- Code commenté en anglais
- Demande validation après chaque sous-étape
- Si tu hésites sur une API, utilise web_search
```

---

## 🛠️ Comment utiliser ce document avec Cursor + Claude Code

### Setup initial (une seule fois)

1. **Place ce fichier à la racine de ton projet ARENA**
   ```
   arena/
   ├── ARENA_MASTER_PROMPT.md    ← CE FICHIER
   ├── ARENA_FLUTTER_PROMPT.md   ← Détails approfondis
   ├── GUIDE_PHASE_0.md          ← Guide setup détaillé
   ├── lib/
   ├── android/
   ├── ios/
   └── ...
   ```

2. **Ouvre Cursor sur ton dossier projet**

3. **Lance Claude Code** (Ctrl+L dans Cursor)

4. **Donne-lui le prompt initial** (voir section ci-dessus)

### Workflow phase par phase

```
┌─────────────────────────────────────────────────────────┐
│  1. TU lis la phase dans ARENA_MASTER_PROMPT.md         │
│     pour comprendre ce qui va être fait                 │
│                          ↓                              │
│  2. TU donnes le prompt de phase à Claude Code          │
│     (templates fournis dans ce doc)                     │
│                          ↓                              │
│  3. CLAUDE CODE annonce son plan + sous-étapes          │
│                          ↓                              │
│  4. TU valides ou corriges le plan                      │
│                          ↓                              │
│  5. CLAUDE CODE implémente la sous-étape 1              │
│                          ↓                              │
│  6. TU testes la sous-étape 1 sur ton émulateur         │
│                          ↓                              │
│  7. Si ✅ : passe à la sous-étape 2                     │
│     Si ❌ : explique le bug à Claude Code               │
│                          ↓                              │
│  8. Répète jusqu'à fin de la phase                      │
│                          ↓                              │
│  9. TU coches les critères d'acceptation                │
│                          ↓                              │
│  10. Commit Git, passe à la phase suivante              │
└─────────────────────────────────────────────────────────┘
```

### Raccourcis Cursor utiles

| Action | Raccourci Windows |
|--------|-------------------|
| Ouvrir Claude Code | `Ctrl+L` |
| Code avec Claude (inline) | `Ctrl+K` |
| Ouvrir un fichier rapide | `Ctrl+P` |
| Recherche dans le projet | `Ctrl+Shift+F` |
| Terminal intégré | `Ctrl+ù` ou `Ctrl+\`` |
| Format code | `Shift+Alt+F` |

### Anti-blocages : que faire si Claude Code...

| Problème | Solution |
|----------|----------|
| ...invente une lib qui n'existe pas | Demande-lui de chercher via `web_search` |
| ...propose une stack différente | Rappelle-lui : "Respecte la stack du master prompt, pas de substitution" |
| ...code 500 lignes d'un coup | Stoppe-le : "Découpe en sous-étapes plus petites" |
| ...ne lit pas le master prompt | Force-le : "Lis d'abord ARENA_MASTER_PROMPT.md ligne X-Y" |
| ...se perd sur l'architecture | Renvoie-le à la PARTIE 2 du master |
| ...crée des fichiers en désordre | Renvoie-le à l'arbo dans la PARTIE 2 |
| ...donne du code obsolète | "Vérifie avec web_search la version actuelle de [lib]" |

---

## ⏱️ Estimation globale du projet V1.0

| Phase | Heures | Cumulé |
|-------|--------|--------|
| **Setup & Foundation** (PHASES 0 → 1bis) | 6-8h | 8h |
| **Authentification** (PHASES 2 + 2bis) | 8-10h | 18h |
| **Core App User** (PHASES 3 → 6) | 9-13h | 31h |
| **Anti-cheat & Streaming** (PHASE 8) | 6-7h | 38h |
| **Profil & Notifications** (PHASES 9 + 10) | 5h | 43h |
| **Espace Admin** (PHASE 11) | 4-5h | 48h |
| **Paiements** (PHASE 11bis) | 5-6h | 54h |
| **Super-Admin** (PHASE 12) | 2h | 56h |
| **Automatisation** (PHASE 12.5) | 10-12h | 68h |
| **Polish, Tests & Launch** (PHASE 13) | 5-6h | 74h |
| **TOTAL V1.0** | **~65-74h** | |

À raison de **20h/semaine** : **~4 semaines** de développement intensif.
À raison de **10h/semaine** : **~7-8 semaines** plus tranquille.

> ⚠️ **Important** : ces estimations supposent que Claude Code écrit le code, pas toi à la main. Sans IA, ce projet prendrait 200-300h.

---


# PARTIE 2 — ARCHITECTURE

## 🏛️ Vue d'ensemble : 2 apps, 1 codebase

ARENA est une **plateforme à 2 apps mobiles distinctes** :

```
┌──────────────────────────────────┐    ┌──────────────────────────────────┐
│       📱 ARENA (User App)        │    │     🛡️ ARENA Admin (Admin App)   │
│                                  │    │                                  │
│   Bundle ID: com.arena.app       │    │   Bundle ID: com.arena.admin     │
│   Public (Play Store/App Store)  │    │   Privé (sideload + web admin)   │
│   Pour les joueurs               │    │   Pour les admins/super-admins   │
│                                  │    │                                  │
│   - Inscription / Login          │    │   - Login + TOTP                 │
│   - Voir compétitions            │    │   - Créer compétitions           │
│   - S'inscrire / Payer           │    │   - Gérer matchs/litiges         │
│   - Jouer matchs                 │    │   - Valider payouts              │
│   - Streaming/Watch              │    │   - Modération                   │
│   - Chat 1-on-1                  │    │   - Web responsive (Chrome OK)   │
└──────────────────────────────────┘    └──────────────────────────────────┘
                  ↓                                       ↓
                  └─────────────┬─────────────────────────┘
                                ↓
┌────────────────────────────────────────────────────────────┐
│              💾 BACKEND PARTAGÉ — SUPABASE                 │
│                                                            │
│   - Postgres (26 tables avec RLS strict)                   │
│   - Auth (email + Google + Apple)                          │
│   - Realtime (chat, brackets, scores)                      │
│   - Storage (avatars, recordings anti-cheat)               │
│   - 16 Edge Functions (automatisation)                     │
│   - pg_cron (jobs récurrents)                              │
└────────────────────────────────────────────────────────────┘
                  ↓                ↓                ↓
       ┌──────────────┐  ┌──────────────┐  ┌──────────────┐
       │ Agora RTM    │  │ Agora RTC    │  │ Firebase     │
       │ (présence)   │  │ (streaming)  │  │ (FCM push)   │
       └──────────────┘  └──────────────┘  └──────────────┘
                                ↓
                       ┌──────────────┐
                       │ CinetPay +   │
                       │ NowPayments  │
                       │ (paiements)  │
                       └──────────────┘
```

### Pourquoi 2 apps séparées ?

| Raison | Explication |
|--------|-------------|
| **Sécurité** | Un user qui télécharge l'app User ne voit même pas l'existence des écrans admin |
| **Stores** | Apple/Google n'aiment pas les "apps avec mode admin caché" → rejet possible |
| **Performance** | Pas de bundle alourdi avec du code admin pour les users |
| **Permissions** | App User a besoin de SYSTEM_ALERT_WINDOW (overlay), pas l'admin |
| **UX** | Splash, navigation, branding différents pour chaque cible |
| **Distribution** | Admin ne va PAS sur les stores (privé) |

### Pourquoi 1 codebase (et pas 2 dépôts Git) ?

| Avantage | Explication |
|----------|-------------|
| **Code partagé ~80%** | Modèles, services, widgets, theme, router pattern |
| **DRY** | Une seule source de vérité pour les modèles `Profile`, `Match`, etc. |
| **Maintenance** | Un bug fixé dans un modèle = fixé dans les 2 apps |
| **Cohérence** | Même design system, même backend, même version |

### Comment fonctionne la séparation ?

Via **Flutter Flavors** (équivalent à des "build variants" Android) :

```
flutter run --flavor user --target lib/main_user.dart   → Lance ARENA (user)
flutter run --flavor admin --target lib/main_admin.dart → Lance ARENA Admin
flutter build apk --flavor user --release               → Build user.apk
flutter build apk --flavor admin --release              → Build admin.apk
```

---

## 📦 Stack technique imposée

> ⚠️ **NON NÉGOCIABLE** : ces choix ont été pris après analyse approfondie. Pas de substitution sans validation explicite.

### Couche application

| Couche | Lib choisie | Version | Pourquoi |
|--------|-------------|---------|----------|
| **Framework** | Flutter | 3.24+ stable | Cross-platform iOS + Android |
| **Langage** | Dart | 3.5+ | Null safety, records, patterns |
| **State management** | `flutter_riverpod` | ^2.5 | Plus simple que Bloc, plus puissant que Provider |
| **Navigation** | `go_router` | ^14.0 | Standard Flutter, deep links faciles |
| **Modèles immutables** | `freezed` + `json_serializable` | ^2.5 | Immutabilité, copyWith, fromJson auto |
| **Validation forms** | `reactive_forms` | ^17.0 | Validation déclarative |
| **Lints** | `very_good_analysis` | ^6.0 | Règles strictes mais raisonnables |
| **HTTP client** | `dio` | ^5.4 | Pour Edge Functions, retry auto |

### Backend & infrastructure

| Couche | Service/Lib | Version | Pourquoi |
|--------|-------------|---------|----------|
| **Backend principal** | Supabase (`supabase_flutter`) | ^2.5 | Auth + DB + Realtime + Storage en un |
| **Crash reporting** | `sentry_flutter` | ^8.0 | Monitoring prod, breadcrumbs, perf |
| **Analytics** | (différé V1.5 : PostHog) | - | Pas de tracking V1.0 |

### Communication temps réel

| Besoin | Solution | Coût | Pourquoi |
|--------|----------|------|----------|
| **Messages chat persistants** | Supabase Realtime + table `chat_messages` | 0$ | Persistance, modération possible |
| **Présence (typing, online)** | `agora_rtm` ^1.5 | 0$ jusqu'à 100k MAU | Latence 50ms, optimisé mobile |
| **Streaming live (sélectif)** | `agora_rtc_engine` ^6.3 | ~3,99$/1k min | HD, scalable |
| **Push notifications** | `firebase_messaging` ^15.0 | 0$ | Standard mobile |

### Anti-triche & Recording

| Lib | Version | Plateforme | Rôle |
|-----|---------|------------|------|
| `flutter_screen_recording` | ^2.0 | Android | Capture écran système |
| `flutter_overlay_window` | ^0.4.5 | Android | Bouton flottant par-dessus le jeu |
| `installed_apps` + `app_usage` | ^1.5 + ^3.0 | Android | Détecter quand le jeu démarre |
| `flutter_foreground_task` | ^8.0 | Android | Service persistant |
| `live_activities` | ^2.0 | iOS 16.1+ | Notification persistante côté iOS |

### Authentification & Sécurité

| Besoin | Lib/Service | Version |
|--------|-------------|---------|
| **Login Google** | `google_sign_in` | ^6.x |
| **Login Apple** | `sign_in_with_apple` | ^6.x |
| **Stockage sécurisé** | `flutter_secure_storage` | (tokens) |
| **Préférences** | `shared_preferences` | (settings) |
| **TOTP (Admin)** | `otp` ^3.1 + `qr_flutter` ^4.1 | 2FA admin |
| **Deep links** | `app_links` | ^6.0 |

### Internationalisation

| Couche | Lib | Pourquoi |
|--------|-----|----------|
| **Framework i18n** | `flutter_localizations` (SDK) + `intl` ^0.19 | i18n natif Flutter |
| **Détection locale** | `device_locale` ^0.5 | Auto-suggestion langue |
| **Format devises** | `intl` `NumberFormat.currency` | 1 234,56 € vs $1,234.56 |
| **Fuseaux horaires** | `timezone` ^0.9 | Convertir UTC en local |
| **Polices arabes** | `google_fonts` (Cairo) | Pour V1.2 (RTL) |

### Paiements

| Région | Lib/Service | Couverture |
|--------|-------------|------------|
| **Afrique francophone** | `webview_flutter` ^4.7 + CinetPay API | MTN MoMo, Orange Money, Wave, Moov |
| **Afrique anglophone (V1.1)** | `flutterwave_standard` ^1.0 + WebView | Cartes, M-Pesa, NGN bank, USSD |
| **Crypto (mondial)** | `webview_flutter` + NowPayments API | USDT (TRC20), BTC, ETH |
| **Conversion** | API exchangerate.host | Taux temps réel |

### Onboarding & Tests

| Besoin | Lib | Version |
|--------|-----|---------|
| **Onboarding** | `flutter_onboarding_slider` | ^1.1 |
| **Tests unitaires/widgets** | `flutter_test` (SDK) + `mocktail` | ^1.0 |
| **Tests intégration** | `integration_test` (SDK) | - |

### Polices imposées

| Police | Usage | Lib |
|--------|-------|-----|
| **Orbitron** (700, 800) | Headers, titles | `google_fonts` |
| **Nunito** (400, 600, 700) | Body, paragraphs | `google_fonts` |
| **Fira Code** | Codes room, scores | `google_fonts` |

### Build & Déploiement

| Besoin | Lib | Version |
|--------|-----|---------|
| **Build flavors** | `flutter_flavorizr` | ^2.2 |
| **Web admin responsive** | `flutter_adaptive_scaffold` | ^0.2 |

### Versions minimales

```yaml
android:
  minSdkVersion: 23     # Android 6.0
  targetSdkVersion: 34
ios:
  deploymentTarget: 13.0
flutter: 3.24
dart: 3.5
```

---

## 🌳 Structure des dossiers

```
arena/
├── android/
│   ├── app/
│   │   └── src/
│   │       ├── main/                    # Config commune
│   │       ├── user/                    # Flavor user (icône bleue)
│   │       └── admin/                   # Flavor admin (icône rouge)
│   └── build.gradle                     # Configuration flavors
│
├── ios/
│   ├── Runner/
│   │   ├── Info-User.plist              # Config user
│   │   └── Info-Admin.plist             # Config admin
│   └── Runner.xcodeproj/
│
├── lib/
│   ├── main_user.dart                   # Entry point app User
│   ├── main_admin.dart                  # Entry point app Admin
│   │
│   ├── core/                            # 🔧 SHARED — utils, constants, theme
│   │   ├── flavors/
│   │   │   └── flavor_config.dart       # Singleton FlavorConfig
│   │   ├── theme/
│   │   │   ├── arena_colors.dart        # Palette
│   │   │   ├── arena_typography.dart    # Polices
│   │   │   └── arena_theme.dart         # ThemeData
│   │   ├── router/
│   │   │   ├── user_router.dart         # GoRouter user
│   │   │   └── admin_router.dart        # GoRouter admin
│   │   ├── services/
│   │   │   ├── supabase_service.dart    # Singleton Supabase
│   │   │   ├── agora_service.dart       # Init Agora RTM + RTC
│   │   │   ├── notification_service.dart
│   │   │   └── sentry_service.dart      # Init crash reporting
│   │   ├── i18n/
│   │   │   └── arb files                # FR, EN, AR
│   │   └── utils/
│   │       ├── validators.dart
│   │       ├── formatters.dart
│   │       └── extensions.dart
│   │
│   ├── data/                            # 🔧 SHARED — modèles, repositories
│   │   ├── models/                      # Freezed models
│   │   │   ├── profile.dart
│   │   │   ├── competition.dart
│   │   │   ├── match.dart
│   │   │   ├── bracket_node.dart
│   │   │   ├── prize.dart
│   │   │   ├── payment.dart
│   │   │   ├── payout.dart
│   │   │   └── chat_message.dart
│   │   └── repositories/                # Accès données Supabase
│   │       ├── auth_repository.dart
│   │       ├── competition_repository.dart
│   │       ├── match_repository.dart
│   │       ├── payment_repository.dart
│   │       └── chat_repository.dart
│   │
│   ├── features_shared/                 # 🔧 SHARED — UI réutilisable
│   │   ├── auth_common/                 # Logique auth partagée
│   │   ├── widgets/                     # Boutons, cards, dialogs
│   │   │   ├── arena_button.dart
│   │   │   ├── arena_card.dart
│   │   │   ├── arena_text_field.dart
│   │   │   └── empty_state.dart
│   │   └── presentation/                # Pages partagées
│   │       └── error_pages/
│   │
│   ├── features_user/                   # 📱 APP USER ONLY
│   │   ├── onboarding/
│   │   │   ├── onboarding_page.dart
│   │   │   └── onboarding_slides.dart
│   │   ├── auth/
│   │   │   ├── splash_user_screen.dart
│   │   │   ├── login_user_screen.dart
│   │   │   ├── register_user_screen.dart
│   │   │   ├── forgot_password_page.dart
│   │   │   ├── reset_password_page.dart
│   │   │   └── link_existing_account_page.dart
│   │   ├── home/
│   │   │   └── home_page.dart
│   │   ├── competitions/
│   │   │   ├── competitions_list_page.dart
│   │   │   ├── competition_detail_page.dart
│   │   │   └── widgets/
│   │   ├── match_room/
│   │   │   ├── match_room_page.dart
│   │   │   ├── match_config_dialog.dart
│   │   │   └── score_validation_dialog.dart
│   │   ├── bracket/
│   │   │   ├── bracket_view_page.dart
│   │   │   └── widgets/
│   │   ├── chat/
│   │   │   ├── messages_inbox_page.dart
│   │   │   └── chat_page.dart
│   │   ├── recording/                   # Anti-triche
│   │   │   ├── recording_service.dart
│   │   │   ├── floating_button_service.dart
│   │   │   └── ios_live_activity.dart
│   │   ├── streaming/                   # Streaming user
│   │   │   ├── live_streams_page.dart
│   │   │   └── watch_stream_page.dart
│   │   ├── profile/
│   │   │   ├── player_profile_page.dart
│   │   │   ├── edit_profile_page.dart
│   │   │   ├── settings_page.dart
│   │   │   ├── delete_account_page.dart
│   │   │   └── about_page.dart
│   │   ├── notifications/
│   │   │   └── notifications_page.dart
│   │   ├── payments/
│   │   │   ├── payment_method_picker_page.dart
│   │   │   ├── payment_processing_page.dart
│   │   │   ├── payment_success_page.dart
│   │   │   ├── payment_failed_page.dart
│   │   │   └── payment_history_page.dart
│   │   └── payouts/
│   │       ├── payouts_history_page.dart
│   │       └── payout_kyc_page.dart
│   │
│   └── features_admin/                  # 🛡️ APP ADMIN ONLY
│       ├── auth_admin/
│       │   ├── splash_admin_screen.dart
│       │   ├── login_admin_screen.dart
│       │   ├── totp_setup_screen.dart
│       │   ├── totp_verify_screen.dart
│       │   └── invitation_redeem_screen.dart
│       ├── dashboard/
│       │   └── admin_dashboard_page.dart
│       ├── competitions_admin/
│       │   ├── admin_competitions_list_page.dart
│       │   ├── create_competition_page.dart
│       │   └── admin_competition_detail_page.dart
│       ├── bracket_admin/
│       │   ├── admin_bracket_management_page.dart
│       │   ├── manual_bracket_editor_page.dart
│       │   └── widgets/
│       ├── matches_admin/
│       │   ├── admin_matches_list_page.dart
│       │   └── admin_match_detail_page.dart
│       ├── streams_admin/
│       │   └── admin_stream_moderation_page.dart
│       ├── payouts_admin/
│       │   ├── admin_payouts_page.dart
│       │   └── admin_payout_validation_dialog.dart
│       ├── disputes_admin/
│       │   └── admin_disputes_page.dart
│       └── super_admin/
│           ├── super_admin_dashboard.dart
│           ├── super_admin_invitations.dart
│           ├── super_admin_users.dart
│           └── super_admin_revenue.dart
│
├── supabase/
│   ├── migrations/                      # SQL migrations
│   │   ├── 001_initial_schema.sql
│   │   ├── 002_rls_policies.sql
│   │   ├── 003_indexes.sql
│   │   └── 004_triggers.sql
│   └── functions/                       # Edge Functions (Deno/TS)
│       ├── _shared/
│       │   ├── cors.ts
│       │   ├── supabase-client.ts
│       │   ├── fcm.ts
│       │   └── agora_token.ts
│       ├── auto_close_registrations/
│       ├── auto_generate_bracket/
│       ├── auto_start_competition/
│       ├── auto_complete_competition/
│       ├── send_match_reminders/
│       ├── submit_score_collaborative/
│       ├── moderate_chat_message/
│       ├── process_dispute/
│       ├── escalate_dispute_after_timeout/
│       ├── prepare_payouts_for_competition/
│       ├── execute_validated_payout/
│       ├── notify_admin_pending_payouts/
│       ├── check_match_forfeits/
│       ├── get_agora_token/
│       ├── cleanup_deleted_accounts/
│       └── send_targeted_notification/
│
├── test/                                # Tests automatisés
│   ├── unit/
│   ├── widget/
│   └── integration/
│
├── assets/
│   ├── images/
│   ├── animations/                      # Lottie pour onboarding
│   └── translations/                    # ARB files
│
├── .env                                 # Variables (NE PAS COMMITTER)
├── .env.example                         # Template
├── pubspec.yaml
├── analysis_options.yaml                # Lints
├── .vscode/
│   └── launch.json                      # Configs Run user/admin
└── ARENA_MASTER_PROMPT.md               # CE FICHIER
```

### Convention de nommage

| Type | Pattern | Exemple |
|------|---------|---------|
| **Dossiers** | snake_case | `match_room`, `payouts_admin` |
| **Fichiers Dart** | snake_case.dart | `home_page.dart`, `auth_repository.dart` |
| **Classes** | PascalCase | `HomePage`, `AuthRepository` |
| **Variables/fonctions** | camelCase | `currentUser`, `signInWithGoogle()` |
| **Constants** | UPPER_SNAKE | `MAX_PLAYERS = 256` |
| **Pages** | `XxxPage` | `LoginPage`, `MatchRoomPage` |
| **Services** | `XxxService` | `AgoraService`, `NotificationService` |
| **Repositories** | `XxxRepository` | `AuthRepository` |
| **Providers Riverpod** | `xxxProvider` | `currentUserProvider` |
| **Tables SQL** | snake_case | `profiles`, `match_events` |
| **Colonnes SQL** | snake_case | `created_at`, `home_player_id` |

---

## 🎨 Identité visuelle (à respecter strictement)

### Palette de couleurs

```dart
class ArenaColors {
  // Backgrounds
  static const bg = Color(0xFF07080F);          // Très sombre
  static const surface = Color(0xFF11131C);     // Cartes
  static const surfaceLight = Color(0xFF1A1D2A); // Cartes elevées
  
  // Brand
  static const primary = Color(0xFF4C7AFF);     // Bleu (USER)
  static const secondary = Color(0xFFFF3D5A);   // Rouge (ADMIN/LIVE)
  
  // Game colors
  static const efootball = Color(0xFF18E8D4);   // Cyan
  static const fifa = Color(0xFFFFAA00);        // Orange
  static const fcMobile = Color(0xFFFF6A1A);    // Orange-rouge
  
  // States
  static const success = Color(0xFF0FE893);     // Vert
  static const warning = Color(0xFFFFAA00);     // Orange
  static const danger = Color(0xFFFF3D5A);      // Rouge
  
  // Text
  static const text = Color(0xFFEEF1F8);        // Blanc cassé
  static const textMuted = Color(0xFF8A93A6);   // Gris clair
  static const textFaint = Color(0xFF555B6E);   // Gris foncé
  
  // Borders
  static const border = Color(0x264C7AFF);      // 15% opacity bleu
}
```

### Theme Flutter

```dart
final arenaThemeData = ThemeData.dark().copyWith(
  scaffoldBackgroundColor: ArenaColors.bg,
  colorScheme: ColorScheme.dark(
    primary: ArenaColors.primary,
    secondary: ArenaColors.secondary,
    surface: ArenaColors.surface,
    error: ArenaColors.danger,
  ),
  textTheme: GoogleFonts.nunitoTextTheme(
    ThemeData.dark().textTheme.copyWith(
      headlineLarge: GoogleFonts.orbitron(
        fontSize: 28,
        fontWeight: FontWeight.w800,
        letterSpacing: 3,
      ),
    ),
  ),
);
```

### Spacing & sizing

| Token | Valeur | Usage |
|-------|--------|-------|
| `spacing.xs` | 4 | Très serré |
| `spacing.sm` | 8 | Serré |
| `spacing.md` | 16 | Standard |
| `spacing.lg` | 24 | Espacé |
| `spacing.xl` | 32 | Très espacé |
| `radius.sm` | 8 | Petits éléments |
| `radius.md` | 12 | Boutons, inputs |
| `radius.lg` | 16 | Cards |
| `radius.xl` | 24 | Phone screens |
| `floating_btn.size` | 72 | Bouton flottant anti-cheat |

---


# PARTIE 3 — 47 ÉCRANS

## 📱 Récapitulatif global

| App | Catégorie | Nombre |
|-----|-----------|--------|
| **APP USER** | Onboarding & Auth | 8 écrans |
| **APP USER** | Core (home, comp, match, chat) | 11 écrans |
| **APP USER** | Bracket | 2 écrans |
| **APP USER** | Streaming | 2 écrans |
| **APP USER** | Profil & Settings | 5 écrans |
| **APP USER** | Paiements & Payouts | 7 écrans |
| **APP USER** | Notifications | 1 écran |
| **APP ADMIN** | Auth | 5 écrans |
| **APP ADMIN** | Core (dashboard, comp, matchs) | 5 écrans |
| **APP ADMIN** | Bracket management | 1 écran |
| **APP ADMIN** | Disputes, Streams, Payouts | 3 écrans |
| **APP ADMIN** | Super-Admin | 4 écrans |
| **TOTAL** | | **🎯 47 écrans** |

---

## 📱 APP USER (28 écrans)

### Onboarding & Auth (8 écrans)

| # | Écran | Description | PHASE |
|---|-------|-------------|-------|
| 1 | `OnboardingPage` | 4 slides intro (Welcome, Concept, Match, Inscription) | 0.5 |
| 2 | `SplashUserScreen` | Logo animé, stats plateforme, 2 CTAs | 2 |
| 3 | `LoginUserScreen` | Email/pwd + Google + Apple + Forgot pwd | 2 |
| 4 | `RegisterUserScreen` | 3 steps : compte → profil → succès | 2 |
| 5 | `ForgotPasswordPage` | Saisie email → envoi mail reset | 2 |
| 6 | `ResetPasswordPage` | Depuis deep link → nouveau mdp | 2 |
| 7 | `LinkExistingAccountPage` | User social vs email existant | 2 |
| 8 | `CGUAcceptancePage` | Acceptation CGU/Privacy à la 1re connexion | 2 |

### Core App (11 écrans)

| # | Écran | Description | PHASE |
|---|-------|-------------|-------|
| 9 | `HomePage` | Dashboard avec compétitions actives, prochains matchs | 3 |
| 10 | `CompetitionsListPage` | Liste filtrée par jeu (eFootball, FIFA, FC) | 4 |
| 11 | `CompetitionDetailPage` | Détails comp, inscription, prizes | 4 |
| 12 | `RegistrationConfirmPage` | Confirmation inscription, paiement | 4 |
| 13 | `MatchRoomPage` | 4 étapes : code → config → score → validation | 5 |
| 14 | `MatchHistoryPage` | Historique des matchs joués | 9 |
| 15 | `MessagesInboxPage` | Conversations directes + canaux | 6 |
| 16 | `ChatPage` | 1-on-1 avec présence (typing, online) | 6 |
| 17 | `MatchInProgressOverlay` | Bouton flottant + timer pendant le match | 8 |
| 18 | `RecordingErrorPage` | Si recording échoue | 8 |
| 19 | `NotificationsPage` | Centre de notifs in-app | 10 |

### Bracket (2 écrans)

| # | Écran | Description | PHASE |
|---|-------|-------------|-------|
| 20 | `BracketViewPage` | Vue arbre tournoi (single elim ou groupes+KO) | 4 |
| 21 | `GroupStandingsPage` | Classement phase de groupes | 4 |

### Streaming (2 écrans)

| # | Écran | Description | PHASE |
|---|-------|-------------|-------|
| 22 | `LiveStreamsPage` | Liste matchs en live | 8 |
| 23 | `WatchStreamPage` | Regarder un stream + chat spectateurs | 8 |

### Profil & Settings (5 écrans)

| # | Écran | Description | PHASE |
|---|-------|-------------|-------|
| 24 | `PlayerProfilePage` | Stats, achievements, historique | 9 |
| 25 | `EditProfilePage` | Modifier username, avatar, pays | 9 |
| 26 | `SettingsPage` | Langue, devise, notifs, privacy | 9 |
| 27 | `DeleteAccountPage` | Workflow 4 étapes (RGPD) | 9 |
| 28 | `AboutPage` | Version, CGU, Privacy, mentions légales | 9 |

### Paiements & Payouts (7 écrans)

| # | Écran | Description | PHASE |
|---|-------|-------------|-------|
| P1 | `PaymentMethodPickerPage` | Choix MoMo / Crypto | 11bis |
| P2 | `MobileMoneyDetailsPage` | Saisie numéro téléphone | 11bis |
| P3 | `PaymentProcessingPage` | WebView CinetPay / NowPayments | 11bis |
| P4 | `PaymentSuccessPage` | Confirmation paiement | 11bis |
| P5 | `PaymentFailedPage` | Erreur + retry | 11bis |
| P6 | `PaymentHistoryPage` | Historique paiements | 11bis |
| P7 | `PayoutKYCPage` | Vérification KYC pour gros payouts | 11bis |

---

## 🛡️ APP ADMIN (11 écrans + 4 super-admin)

### Authentification (5 écrans)

| # | Écran | Description | PHASE |
|---|-------|-------------|-------|
| A1 | `SplashAdminScreen` | Logo rouge admin | 2bis |
| A2 | `LoginAdminScreen` | Email/pwd | 2bis |
| A3 | `InvitationRedeemScreen` | Code d'invitation pour devenir admin | 2bis |
| A4 | `TOTPSetupScreen` | QR code + scan Google Authenticator | 2bis |
| A5 | `TOTPVerifyScreen` | Saisie code 6 chiffres | 2bis |

### Core Admin (5 écrans)

| # | Écran | Description | PHASE |
|---|-------|-------------|-------|
| A6 | `AdminDashboardPage` | Stats compétitions, matchs en cours, alertes | 11 |
| A7 | `AdminCompetitionsListPage` | Liste compétitions + filtres | 11 |
| A8 | `CreateCompetitionPage` | 5 étapes : info → format → prizes → review → publish | 11 |
| A9 | `AdminCompetitionDetailPage` | Vue détaillée + actions | 11 |
| A10 | `AdminMatchesListPage` | Tous les matchs + filtres | 11 |

### Gestion Bracket / Streams / Payouts (3 écrans)

| # | Écran | Description | PHASE |
|---|-------|-------------|-------|
| A11 | `AdminBracketManagementPage` | Voir bracket, sélection streaming, valider scores | 11 |
| A12 | `AdminStreamModerationPage` | Grille live des streams + sélection matchs | 11 |
| A13 | `AdminPayoutsPage` | Validation manuelle des payouts | 11 |
| A14 | `AdminDisputesPage` | Litiges en cours + arbitrage | 11 |

### Super-Admin (4 écrans)

| # | Écran | Description | PHASE |
|---|-------|-------------|-------|
| SA1 | `SuperAdminDashboard` | Stats globales plateforme | 12 |
| SA2 | `SuperAdminInvitations` | Générer codes pour nouveaux admins | 12 |
| SA3 | `SuperAdminUsers` | Gestion users (ban, unban) | 12 |
| SA4 | `SuperAdminRevenue` | Revenus, commissions, fiscalité | 12 |

---

## 🎬 Workflow utilisateur type

### Workflow joueur — Première utilisation

```
1. Télécharge ARENA depuis Play Store
   ↓
2. Onboarding 4 écrans (PHASE 0.5)
   ↓
3. Clic "S'inscrire" → RegisterUserScreen (PHASE 2)
   ↓
4. Étape 1/3 : Email + password OU "Continuer avec Google"
   ↓
5. Étape 2/3 : Username + pays + acceptation CGU/Privacy
   ↓
6. Étape 3/3 : Succès → HomePage
   ↓
7. Voit liste compétitions actives (PHASE 4)
   ↓
8. Clic sur "Cameroon eFootball Cup" → CompetitionDetailPage
   ↓
9. Clic "S'inscrire" → Paiement (PHASE 11bis)
   ↓
10. Choix méthode → MTN MoMo
   ↓
11. WebView CinetPay → confirmation paiement
   ↓
12. Retour app → "Inscrit ! En attente du début"
   ↓
13. Notification : "Compétition démarre, prépare-toi !"
   ↓
14. HomePage affiche "Match dans 5 min"
   ↓
15. Clic → MatchRoomPage (PHASE 5)
   ↓
16. Étape 1/4 : Reçoit code room de l'adversaire ou le génère
   ↓
17. Étape 2/4 : (Si phase de groupes) Confirme désactivation prolongations
   ↓
18. Lance eFootball, joue le match
   ↓
19. Bouton flottant rouge visible (PHASE 8) avec timer
   ↓
20. Match terminé → revient sur ARENA
   ↓
21. Étape 3/4 : Saisie score concurrente avec adversaire
   ↓
22. Si concorde → match validé
   Si discorde → revote OU litige → bot d'arbitrage
   ↓
23. HomePage : "Tu es qualifié pour le quart"
   ↓
24. Bracket avance, joueur progresse
   ↓
25. Si finale → match auto-streamé sur LiveStreamsPage
   ↓
26. Fin compétition → notif "Tu es 2e ! Gain 25 000 XAF"
   ↓
27. PayoutsHistoryPage → "En attente validation admin"
   ↓
28. Admin valide → "Versé sur ton MoMo"
```

### Workflow admin — Création compétition

```
1. Login app Admin → TOTP → AdminDashboard
   ↓
2. Clic "+ Nouvelle compétition"
   ↓
3. Étape 1/5 : Infos (nom, jeu, description, dates)
   ↓
4. Étape 2/5 : Format (single elim / groupes+KO / round robin)
              + nombre joueurs (8/16/32/64...)
   ↓
5. Étape 3/5 : Prizes — Top 4 (mode % ou montants fixes)
   ↓
6. Étape 4/5 : Frais inscription + commission ARENA
   ↓
7. Étape 5/5 : Review final + Publier
   ↓
8. Compétition créée → status "open_for_registration"
   ↓
9. Joueurs s'inscrivent et paient
   ↓
10. À l'heure prévue : auto-fermeture inscriptions
   ↓
11. Auto-génération bracket
   ↓
12. Auto-streaming activé sur la finale
   ↓
13. Admin peut activer manuellement le streaming sur d'autres matchs
   ↓
14. Matchs se jouent, scores validés (collaborativement)
   ↓
15. Si litige → bot tente résolution → escalade admin si fail
   ↓
16. Admin tranche le litige depuis AdminDisputesPage
   ↓
17. Compétition se termine → auto-completion
   ↓
18. AdminPayoutsPage : 4 lignes en pending (top 4)
   ↓
19. Admin vérifie les 5 contrôles auto (KYC, disputes, etc.)
   ↓
20. Validation batch ou 1-by-1 si dispute
   ↓
21. Edge Function execute_validated_payout → transfer vers MoMo joueur
   ↓
22. Joueur reçoit son gain
```

---


# PARTIE 4 — BASE DE DONNÉES

## 🗄️ Schéma Postgres (Supabase) — 26 tables

> 📚 **SQL complet** disponible dans `ARENA_FLUTTER_PROMPT.md` ligne 1159+
> Cette section présente la **vue d'ensemble** des tables et leurs rôles.

### Schéma général (diagramme relationnel)

```
auth.users (Supabase Auth)
    ↓
profiles ←─────┬─────────────────────────────────────────┐
    │          │                                          │
    │          ↓                                          ↓
    │     competitions                              admin_audit_log
    │          │
    │          ├──> phases ──> groups ──> group_memberships
    │          │       │
    │          │       └──> matches ──> match_events
    │          │               │           ↑
    │          │               │           └──> anti_cheat_events
    │          │               │
    │          │               ├──> bracket_nodes
    │          │               └──> streams (live recordings)
    │          │
    │          ├──> competition_registrations
    │          │
    │          ├──> prizes
    │          │
    │          ├──> chat_channels ──> chat_messages
    │          │
    │          ├──> payments ──> platform_revenue
    │          │
    │          └──> payouts ──> payment_webhook_log
    │
    ├──> notifications
    └──> disputes ──> auto_actions_log

(global)
- exchange_rates
- app_config (feature flags)
- invitation_codes
- banned_words
```

### Liste des 26 tables

> ⚠️ **NOTE IMPORTANTE** : ce sont bien **26 tables** au total (corrigé en v1.1 — la version v1.0 annonçait 23 tables par erreur).

| # | Table | Rôle | RLS ? | Realtime ? |
|---|-------|------|-------|------------|
| 1 | `profiles` | Utilisateurs (joueurs + admins) | ✅ | ✅ |
| 2 | `competitions` | Tournois | ✅ | ✅ |
| 3 | `phases` | Phases (groups, knockout, round_robin) | ✅ | ✅ |
| 4 | `groups` | Groupes en phase de groupes | ✅ | ✅ |
| 5 | `group_memberships` | Joueurs dans groupes | ✅ | ✅ |
| 6 | `competition_registrations` | Inscriptions joueurs aux compétitions | ✅ | ✅ |
| 7 | `prizes` | Top 4 récompenses (% ou fixe) | ✅ | - |
| 8 | `bracket_nodes` | Arbre du bracket (next_node_id) | ✅ | ✅ |
| 9 | `matches` | Matchs entre joueurs | ✅ | ✅ |
| 10 | `match_events` | Timeline des événements match | ✅ | ✅ |
| 11 | `streams` | Sessions de streaming/recording live | ✅ | ✅ |
| 12 | `notifications` | Notifs push + in-app | ✅ | ✅ |
| 13 | `chat_channels` | Canaux chat (match, broadcast) | ✅ | - |
| 14 | `chat_messages` | Messages persistants | ✅ | ✅ |
| 15 | `anti_cheat_events` | Alertes anomalies recording | ✅ | - |
| 16 | `disputes` | Litiges + escalation levels | ✅ | ✅ |
| 17 | `auto_actions_log` | Log des actions auto (Edge Functions) | ✅ | - |
| 18 | `banned_words` | Modération chat | ✅ | - |
| 19 | `invitation_codes` | Codes pour nouveaux admins | ✅ | - |
| 20 | `admin_audit_log` | Audit trail actions admin | ✅ | - |
| 21 | `app_config` | Feature flags V1.0/V1.1/V1.2 | ✅ | ✅ |
| 22 | `payments` | Paiements entrants (frais inscr) | ✅ | - |
| 23 | `payouts` | Versements sortants (gains) | ✅ | ✅ |
| 24 | `platform_revenue` | Commissions ARENA | ✅ | - |
| 25 | `payment_webhook_log` | Logs webhooks providers | ✅ | - |
| 26 | `exchange_rates` | Cache taux de change | - | - |

### Ordre de création des tables (foreign keys)

> 🚨 **CRITIQUE pour les migrations** : créer dans cet ordre pour respecter les FK.

```
ÉTAPE 1 — Tables racines (aucune FK vers d'autres tables)
├── exchange_rates
├── app_config
└── banned_words

ÉTAPE 2 — Tables avec FK vers auth.users seulement
└── profiles (FK → auth.users)

ÉTAPE 3 — Tables avec FK vers profiles
├── competitions (FK → profiles via created_by)
├── invitation_codes (FK → profiles)
├── admin_audit_log (FK → profiles)
└── notifications (FK → profiles)

ÉTAPE 4 — Tables avec FK vers competitions
├── phases (FK → competitions)
├── prizes (FK → competitions)
└── competition_registrations (FK → competitions, profiles)

ÉTAPE 5 — Tables avec FK vers phases
├── groups (FK → phases)
└── group_memberships (FK → groups, profiles)

ÉTAPE 6 — Tables avec FK vers matches (créées avec matches)
├── matches (FK → competitions, phases, groups, profiles)
├── bracket_nodes (FK → competitions, matches, profiles)
├── match_events (FK → matches, profiles)
├── streams (FK → matches, profiles)
└── anti_cheat_events (FK → matches, profiles)

ÉTAPE 7 — Tables chat
├── chat_channels (FK → competitions, matches)
└── chat_messages (FK → chat_channels, profiles)

ÉTAPE 8 — Tables paiement
├── payments (FK → competitions, profiles)
├── payouts (FK → competitions, prizes, profiles)
├── platform_revenue (FK → competitions, payments)
└── payment_webhook_log (FK → payments, payouts)

ÉTAPE 9 — Tables système
├── disputes (FK → matches, profiles)
└── auto_actions_log (FK → competitions, matches, profiles)
```

### Tables clés — Détail rapide

#### `profiles` (la table la plus importante)

> ⚠️ Note : ceci est la **définition officielle** alignée sur le SQL d'`ARENA_FLUTTER_PROMPT.md` (ligne 1182+).

```sql
create table profiles (
  id uuid primary key references auth.users on delete cascade,
  username text unique not null check (length(username) between 3 and 20),
  email text unique not null,
  country_code text not null check (length(country_code) = 2),
  avatar_color text not null default '#4C7AFF',
  role user_role not null default 'player',  -- 'player' | 'admin' | 'super_admin'
  seed int,                                   -- Seed pour bracket (force estimée)
  is_active boolean default true,
  fcm_token text,
  stats jsonb default '{"wins":0,"losses":0,"goals_scored":0,"goals_conceded":0}'::jsonb,
  
  -- Authentification (méthode d'inscription)
  auth_provider text not null default 'email' check (auth_provider in ('email', 'google', 'apple')),
  auth_provider_id text,                      -- ID externe (Google sub, Apple sub)
  
  -- Internationalisation (architecture V1.2, valeurs par défaut V1.0)
  preferred_language text not null default 'fr' check (preferred_language in ('en', 'fr', 'ar')),
  preferred_currency text not null default 'XAF' check (preferred_currency in (
    'XAF', 'XOF',                                       -- V1.0 actives
    'NGN', 'GHS', 'KES', 'ZAR', 'UGX', 'RWF', 'TZS',    -- V1.1
    'MAD', 'DZD', 'TND', 'EGP',                         -- V1.2
    'USD'                                                -- Fallback
  )),
  timezone text not null default 'Africa/Douala',
  detected_country_code text,
  
  -- Onboarding
  onboarding_completed boolean default false,
  onboarding_completed_at timestamptz,
  
  -- Auth admin (TOTP)
  totp_secret text,                           -- Base32 chiffré côté serveur
  totp_enabled boolean default false,
  totp_verified_at timestamptz,
  backup_codes jsonb default '[]'::jsonb,     -- 10 codes hashés
  last_totp_used text,                        -- Anti-replay
  
  -- Invitation (admins only)
  invited_by uuid references profiles(id),
  invited_at timestamptz,
  invitation_code_used text,
  
  -- Conformité légale
  cgu_accepted_at timestamptz,
  cgu_version_accepted text,                  -- ex: 'v1.2'
  privacy_policy_accepted_at timestamptz,
  marketing_consent boolean default false,
  data_export_requested_at timestamptz,
  
  -- Suppression de compte (RGPD)
  account_deletion_requested_at timestamptz,
  account_deletion_reason text,
  deleted_at timestamptz,                     -- soft-delete
  
  -- KYC (pour payouts > seuil)
  kyc_status text default 'none' check (kyc_status in ('none', 'pending', 'verified', 'rejected')),
  kyc_verified_at timestamptz,
  
  -- Timestamps
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

create index idx_profiles_deleted on profiles(deleted_at) where deleted_at is not null;
create index idx_profiles_auth_provider on profiles(auth_provider);
```

#### `matches` (avec streaming Agora sélectif)

```sql
create table matches (
  id uuid primary key default uuid_generate_v4(),
  competition_id uuid references competitions on delete cascade,
  phase_id uuid references phases on delete cascade,
  group_id uuid references groups on delete cascade,
  round int,
  match_number int,
  player1_id uuid references profiles,
  player2_id uuid references profiles,
  score1 int,
  score2 int,
  winner_id uuid references profiles,
  status match_status default 'pending',
  home_player_id uuid references profiles,
  room_code text,
  
  -- STREAMING (sélectif Agora RTC)
  is_streamed boolean default false,
  streaming_activation_type text check (streaming_activation_type in ('auto_final', 'manual_admin', 'auto_premium')),
  streaming_activated_by_admin_id uuid references profiles,
  streaming_activated_at timestamptz,
  agora_stream_channel text,
  stream_status text default 'none',
  stream_started_at timestamptz,
  stream_ended_at timestamptz,
  current_viewers_count int default 0,
  peak_viewers_count int default 0,
  
  -- Timestamps
  scheduled_at timestamptz,
  started_at timestamptz,
  finished_at timestamptz,
  next_match_id uuid references matches,
  
  -- Configuration spécifique (phase de groupes)
  match_config jsonb default '{}',
  created_at timestamptz default now()
);
```

#### `prizes` (Top 4 récompensé)

```sql
create table prizes (
  id uuid primary key default uuid_generate_v4(),
  competition_id uuid references competitions on delete cascade,
  position int not null check (position between 1 and 4),
  
  -- Mode flexible : pourcentage OU montant fixe
  prize_mode text not null check (prize_mode in ('percentage', 'fixed')),
  percentage_value numeric(5,2),  -- Si mode percentage (ex: 50.00 pour 50%)
  fixed_amount numeric(15,2),      -- Si mode fixed (en devise de la compet)
  fixed_currency text,
  
  -- Calculé au moment du paiement
  final_amount_usd numeric(15,2),
  final_amount_local numeric(15,2),
  final_currency text,
  
  -- Display
  display_name text,                -- "1er", "Champion", "Top 4"
  
  unique(competition_id, position)
);
```

#### `bracket_nodes` (arbre du bracket)

```sql
create table bracket_nodes (
  id uuid primary key default uuid_generate_v4(),
  competition_id uuid references competitions on delete cascade,
  match_id uuid references matches on delete cascade,
  
  -- Position dans l'arbre
  round int not null,
  position_in_round int not null,
  
  -- Lien vers le node suivant
  next_node_id uuid references bracket_nodes,
  next_position text check (next_position in ('player1', 'player2')),
  
  -- Si bye
  is_bye boolean default false,
  bye_player_id uuid references profiles,
  
  created_at timestamptz default now()
);
```

#### `payouts` (versements sortants — STRICT)

```sql
create table payouts (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid references profiles on delete restrict,
  competition_id uuid references competitions on delete restrict,
  prize_id uuid references prizes on delete restrict,
  
  -- Montants
  amount_usd numeric(15,2) not null,
  amount_local numeric(15,2) not null,
  currency text not null,
  exchange_rate numeric(15,8),
  
  -- Status (workflow strict)
  status text not null default 'pending_admin_validation' check (status in (
    'pending_admin_validation',  -- En attente validation manuelle
    'validated',                 -- Validé par admin
    'processing',                -- En cours de transfer
    'completed',                 -- Versé
    'failed',                    -- Échec
    'refunded',                  -- Remboursé
    'cancelled'                  -- Annulé
  )),
  
  -- Validation admin (audit trail)
  validated_by_admin_id uuid references profiles,
  validated_at timestamptz,
  validation_justification text,
  
  -- Auto-checks (5 vérifications)
  auto_checks jsonb default '{}',
  -- Structure: {
  --   "kyc_verified": true,
  --   "no_open_disputes": true,
  --   "no_anti_cheat_alerts": true,
  --   "user_not_banned": true,
  --   "payment_data_valid": true
  -- }
  
  -- Provider data
  payout_provider text,            -- 'cinetpay', 'nowpayments'
  payout_method text,              -- 'mtn_momo', 'orange_money', 'wave', 'crypto_usdt'
  payout_destination jsonb,        -- numéro téléphone, adresse crypto
  provider_transaction_id text,
  provider_response jsonb,
  
  -- Timestamps
  created_at timestamptz default now(),
  updated_at timestamptz default now(),
  scheduled_for timestamptz,
  completed_at timestamptz
);
```

### Row Level Security (RLS) — Principes

**🚨 RÈGLE D'OR** : aucun client ne doit pouvoir lire/écrire des données qui ne lui appartiennent pas.

Exemples de policies :

```sql
-- Un user ne voit que son propre profil
create policy "Users can view own profile"
on profiles for select
using (auth.uid() = id);

-- Mais peut voir les profils des autres users (limité)
create policy "Users can view limited public profile data"
on profiles for select
using (true);  -- Tous les users peuvent voir
-- Mais on filtre les colonnes côté API/views

-- Un admin peut tout voir
create policy "Admins can view all profiles"
on profiles for select
using (
  exists (
    select 1 from profiles
    where id = auth.uid() and role in ('admin', 'super_admin')
  )
);

-- Personne ne peut modifier `payouts` directement
-- Seules les Edge Functions (avec service_role key) peuvent écrire
create policy "No direct writes to payouts"
on payouts for insert
using (false);
```

### Indexes critiques

```sql
-- Performance compétitions
create index idx_competitions_status on competitions(status);
create index idx_competitions_dates on competitions(start_date, end_date);

-- Performance matches
create index idx_matches_status on matches(status);
create index idx_matches_streamed_live on matches(is_streamed, stream_status) where stream_status = 'live';
create index idx_matches_next on matches(next_match_id);

-- Performance chat
create index idx_chat_messages_channel on chat_messages(channel_id, created_at desc);

-- Performance payouts
create index idx_payouts_status on payouts(status);
create index idx_payouts_admin_validation on payouts(status) where status = 'pending_admin_validation';

-- Performance soft-delete
create index idx_profiles_deleted on profiles(deleted_at) where deleted_at is not null;
```

### Triggers SQL importants

| Trigger | Quand | Action |
|---------|-------|--------|
| `update_updated_at` | UPDATE sur toutes les tables avec `updated_at` | Met à jour le timestamp |
| `cascade_match_winner` | UPDATE matches.winner_id | Avance le winner au next_match_id |
| `auto_complete_competition` | Quand le dernier match est terminé | Status compet → 'completed' + crée payouts pending |
| `prevent_double_registration` | INSERT competition_registrations | Vérifie pas déjà inscrit |
| `update_match_after_score_validation` | UPDATE match_events de type 'score_validated' | Met à jour matches.status, score, winner |

---

# PARTIE 5 — EDGE FUNCTIONS

## ⚡ 16 Edge Functions Supabase (Deno/TypeScript)

Les Edge Functions Supabase tournent sur **Deno** (serveur edge global). Elles sont déclenchées soit :
- **HTTP** : appelées depuis l'app (`supabase.functions.invoke('name')`)
- **Cron** : exécutées périodiquement via `pg_cron`
- **Trigger** : déclenchées sur INSERT/UPDATE de tables

### Liste complète

| # | Edge Function | Type | Fréquence | Rôle |
|---|---------------|------|-----------|------|
| 1 | `auto_close_registrations` | Cron | 1 min | Ferme inscriptions à `start_date` |
| 2 | `auto_generate_bracket` | Cron | 5 min | Génère bracket dès fermeture inscriptions |
| 3 | `auto_start_competition` | Cron | 1 min | Démarre comp à l'heure |
| 4 | `auto_complete_competition` | Trigger | Sur fin du dernier match | Marque comp 'completed' |
| 5 | `send_match_reminders` | Cron | 5 min | Notifs aux joueurs 5 min avant match |
| 6 | `submit_score_collaborative` | HTTP | À chaque saisie score | Logique de validation collaborative |
| 7 | `moderate_chat_message` | HTTP | À chaque message | Filtre banned_words, flag/block |
| 8 | `process_dispute` | Cron | 5 min | Bot d'arbitrage : tente résolution auto |
| 9 | `escalate_dispute_after_timeout` | Cron | 5 min | Si bot fail → escalade admin |
| 10 | `prepare_payouts_for_competition` | Trigger | Sur completion comp | Crée 4 entries `payouts` en pending |
| 11 | `execute_validated_payout` | HTTP | Sur validation admin | Appelle CinetPay API pour transfer |
| 12 | `notify_admin_pending_payouts` | Cron | 5 min | Rappel admin si payouts attendent |
| 13 | `check_match_forfeits` | Cron | 1 min | Forfait auto si joueur absent 30 min |
| 14 | `get_agora_token` | HTTP | À la demande (broadcaster ou audience) | Génère tokens RTC/RTM sécurisés |
| 15 | `cleanup_deleted_accounts` | Cron | 24h (3h du matin) | Anonymise comptes après 30 jours |
| 16 | `send_targeted_notification` | HTTP | Utility | Helper pour envoyer notifs ciblées |

### Architecture des Edge Functions

```
supabase/functions/
├── _shared/                    # Code partagé entre toutes les fonctions
│   ├── cors.ts                 # Headers CORS
│   ├── supabase-client.ts      # Init Supabase avec service_role
│   ├── fcm.ts                  # Helper FCM push notifications
│   └── agora_token.ts          # Helper génération tokens Agora
│
├── auto_close_registrations/
│   ├── index.ts                # Logique principale
│   └── deno.json               # Imports Deno
├── ...
└── shared.json                 # Config commune
```

### Setup pg_cron pour les Edge Functions cron

```sql
-- Activer pg_cron extension
create extension if not exists pg_cron;

-- Programmer une fonction toutes les minutes
select cron.schedule(
  'auto-close-registrations',
  '* * * * *',  -- Cron syntax : chaque minute
  $$ select net.http_post(
    url := 'https://[YOUR_PROJECT].supabase.co/functions/v1/auto_close_registrations',
    headers := '{"Authorization": "Bearer [SERVICE_ROLE_KEY]"}'::jsonb
  ); $$
);

-- Lister les jobs
select * from cron.job;

-- Logs des exécutions
select * from cron.job_run_details order by start_time desc limit 20;
```

### Exemple : `get_agora_token` (la plus critique)

```typescript
// supabase/functions/get_agora_token/index.ts
import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { RtcTokenBuilder, RtcRole } from 'npm:agora-token';
import { createClient } from 'jsr:@supabase/supabase-js@2';
import { corsHeaders } from '../_shared/cors.ts';

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }
  
  try {
    // 1. Authentication
    const authHeader = req.headers.get('Authorization');
    const token = authHeader?.replace('Bearer ', '');
    if (!token) return new Response('Unauthorized', { status: 401 });
    
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
    );
    
    const { data: { user } } = await supabase.auth.getUser(token);
    if (!user) return new Response('Invalid token', { status: 401 });
    
    // 2. Parse request
    const { channel, role, matchId } = await req.json();
    
    // 3. Authorization check
    if (role === 'broadcaster') {
      // Vérifier que c'est bien le HOME du match
      const { data: match } = await supabase
        .from('matches')
        .select('home_player_id, is_streamed')
        .eq('id', matchId)
        .single();
      
      if (!match || match.home_player_id !== user.id || !match.is_streamed) {
        return new Response('Forbidden', { status: 403 });
      }
    }
    
    // 4. Generate token
    const appId = Deno.env.get('AGORA_APP_ID')!;
    const appCertificate = Deno.env.get('AGORA_APP_CERTIFICATE')!;
    const tokenRole = role === 'broadcaster' ? RtcRole.PUBLISHER : RtcRole.SUBSCRIBER;
    const expirationTime = Math.floor(Date.now() / 1000) + 3600; // 1h
    
    const agoraToken = RtcTokenBuilder.buildTokenWithUid(
      appId, appCertificate, channel, 0, tokenRole, expirationTime,
    );
    
    return new Response(
      JSON.stringify({ token: agoraToken, expiresAt: expirationTime }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
    );
  } catch (error) {
    console.error('Error:', error);
    return new Response(
      JSON.stringify({ error: error.message }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
    );
  }
});
```

### Exemple : `cleanup_deleted_accounts` (RGPD)

```typescript
// supabase/functions/cleanup_deleted_accounts/index.ts
serve(async (req) => {
  const supabase = createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
  );
  
  // Trouver les profils avec deletion_request > 30 jours
  const thirtyDaysAgo = new Date(Date.now() - 30 * 24 * 60 * 60 * 1000).toISOString();
  
  const { data: profilesToAnonymize } = await supabase
    .from('profiles')
    .select('id, email, username')
    .lt('account_deletion_requested_at', thirtyDaysAgo)
    .is('deleted_at', null);
  
  console.log(`Anonymizing ${profilesToAnonymize?.length || 0} profiles`);
  
  for (const profile of profilesToAnonymize || []) {
    const shortId = profile.id.substring(0, 8);
    
    // Anonymisation : on garde l'ID pour l'intégrité référentielle
    // mais on supprime toutes les données personnelles
    await supabase.from('profiles').update({
      username: `deleted_${shortId}`,
      email: `deleted_${shortId}@deleted.arena`,
      avatar_color: '#555B6E',
      country_code: 'XX',
      preferred_language: 'en',
      preferred_currency: 'USD',
      timezone: 'UTC',
      detected_country_code: null,
      fcm_token: null,
      stats: {},
      auth_provider_id: null,
      totp_secret: null,
      backup_codes: [],
      deleted_at: new Date().toISOString(),
    }).eq('id', profile.id);
    
    // Supprimer du système d'auth Supabase
    await supabase.auth.admin.deleteUser(profile.id);
    
    // Logger l'action
    await supabase.from('admin_audit_log').insert({
      action: 'account_anonymized_after_30d',
      user_id: profile.id,
      metadata: { original_email: profile.email },
    });
  }
  
  return new Response(
    JSON.stringify({ anonymized: profilesToAnonymize?.length || 0 }),
    { headers: { 'Content-Type': 'application/json' } },
  );
});
```

### Variables d'environnement requises

À configurer dans Supabase Dashboard → Settings → Edge Functions → Secrets :

```bash
SUPABASE_URL=https://xxx.supabase.co
SUPABASE_SERVICE_ROLE_KEY=eyJh...

# Agora
AGORA_APP_ID=abc123...
AGORA_APP_CERTIFICATE=xyz789...

# Firebase (FCM)
FCM_SERVER_KEY=AAAA...

# CinetPay
CINETPAY_API_KEY=...
CINETPAY_SITE_ID=...

# NowPayments
NOWPAYMENTS_API_KEY=...

# Sentry
SENTRY_DSN_FUNCTIONS=https://...
```

---


# PARTIE 6 — ROADMAP 21 PHASES

## 📊 Vue d'ensemble du roadmap

| Phase | Nom | Heures | Cumul | Dépend de |
|-------|-----|--------|-------|-----------|
| **0** | Setup environnement + Flavors + Sentry | 1h | 1h | - |
| **0.5** | Onboarding 4 écrans | 2-3h | 4h | 0 |
| **1** | Theme + Router + Widgets de base | 1h | 5h | 0 |
| **1bis** | i18n + Devises + Feature Flags | 2-3h | 8h | 1 |
| **2** | Authentification User (4 sous-phases) | 4-5h | 13h | 1bis |
| **2bis** | Authentification Admin (TOTP) | 4-5h | 18h | 1bis |
| **3** | Layout principal + HomePage joueur | 1-2h | 20h | 2 |
| **4** | Compétitions | 3-4h | 24h | 3 |
| **5** | Système Match Room (eFootball) | 2-3h | 27h | 4 |
| **6** | Chat hybride Supabase + Agora RTM | 3-4h | 31h | 5 |
| **7** | ❌ SUPPRIMÉE (Appels vidéo Agora RTC) | 0h | 31h | - |
| **8** | Recording + Bouton flottant + Streaming Agora sélectif | 6-7h | 38h | 5 |
| **9** | Profil + Settings + Suppression compte | 3h | 41h | 2 |
| **10** | Notifications | 2h | 43h | 4 |
| **11** | Espace Admin | 4-5h | 48h | 2bis |
| **11bis** | Paiements CinetPay + Crypto | 5-6h | 54h | 11 |
| **12** | Espace Super-Admin | 2h | 56h | 11 |
| **12.5** | Automatisation & Orchestration (14 Edge Functions) | 10-12h | 68h | 11bis |
| **13** | Polish + Tests automatisés + Lancement V1.0 | 5-6h | 74h | Tout |
| **14** | Extension V1.1 (Afrique anglophone) | 5-6h | 80h | 13 (futur) |
| **15** | Extension V1.2 (Maghreb + RTL) | 6-8h | 88h | 14 (futur) |

> 🎯 **V1.0 = PHASES 0 → 13** (~74h) → Lancement Afrique francophone

### Légende des phases

- **Setup & Foundation** : PHASES 0, 0.5, 1, 1bis (8h)
- **Authentification** : PHASES 2, 2bis (10h)
- **Core User App** : PHASES 3, 4, 5, 6 (13h)
- **Anti-cheat & Streaming** : PHASE 8 (7h)
- **Profil & Notifs** : PHASES 9, 10 (5h)
- **Admin Space** : PHASES 11, 11bis, 12 (13h)
- **Automatisation** : PHASE 12.5 (12h)
- **Polish & Launch** : PHASE 13 (6h)

---


## PHASE 0 — Setup environnement + Flavors + Sentry (1h)

### 🎯 Objectif simple
Créer le projet Flutter, configurer les **2 flavors** (user et admin), connecter **Supabase + Firebase + Agora + Sentry**, vérifier que les builds fonctionnent.

### 📦 Pré-requis
- ✅ Flutter SDK installé (`flutter --version` ≥ 3.24)
- ✅ Android Studio installé avec un émulateur configuré
- ✅ Cursor installé avec Claude Code
- ✅ Compte Supabase, Firebase, Agora créés
- ✅ Compte Sentry créé (gratuit, plan 5k events/mois)

### 📋 Livrables
- [ ] Projet Flutter créé avec arbo correcte (cf. PARTIE 2)
- [ ] `flutter_flavorizr` configuré (2 flavors : user, admin)
- [ ] `pubspec.yaml` avec toutes les libs (cf. PARTIE 2)
- [ ] Supabase configuré + SQL initial exécuté (26 tables)
- [ ] Firebase configuré pour FCM (user uniquement)
- [ ] Agora App ID + App Certificate dans `.env`
- [ ] Sentry DSN dans `.env`, init dans `main_user.dart` et `main_admin.dart`
- [ ] `analysis_options.yaml` avec `very_good_analysis`
- [ ] `.gitignore` propre (`.env`, `build/`, `.dart_tool/`)
- [ ] `.vscode/launch.json` avec configs user/admin
- [ ] Builds debug fonctionnent pour les 2 flavors

### 💬 Prompt suggéré pour Claude Code

```
Salut Claude. Je commence ARENA en suivant ARENA_MASTER_PROMPT.md.

🎯 PHASE 0 : Setup environnement + Flavors + Sentry

Lis d'abord le fichier ARENA_MASTER_PROMPT.md (ou GUIDE_PHASE_0.md pour le détail).

Procède dans cet ordre :
1. Crée le projet Flutter (flutter create)
2. Configure pubspec.yaml avec TOUTES les libs (PARTIE 2 du master)
3. Configure flavorizr.yaml (2 flavors : user et admin)
4. Lance flutter_flavorizr pour générer les configs natives
5. Crée la structure de dossiers (cf. PARTIE 2)
6. Configure analysis_options.yaml avec very_good_analysis
7. Crée .env.example avec toutes les variables
8. Configure .vscode/launch.json
9. Initialise Sentry dans main_user.dart et main_admin.dart

⚠️ Demande-moi de tester APRÈS chaque étape avant de passer à la suivante.

À chaque étape, donne-moi les commandes exactes à exécuter dans le terminal Cursor.
```

### 🛠️ Commandes clés à connaître

```bash
# Créer le projet
flutter create arena --org com.arena --platforms android,ios

# Installer flutter_flavorizr
flutter pub add --dev flutter_flavorizr

# Lancer le générateur de flavors
flutter pub run flutter_flavorizr

# Build user
flutter run --flavor user --target lib/main_user.dart

# Build admin
flutter run --flavor admin --target lib/main_admin.dart

# Build admin web
flutter run --flavor admin --target lib/main_admin.dart -d chrome

# Build APK release
flutter build apk --flavor user --release --target lib/main_user.dart
```

### 🧪 Tests à valider

1. **Test flavor user** : `flutter run --flavor user --target lib/main_user.dart`
   - L'app s'ouvre avec icône bleue, nom "ARENA"
   - L'écran d'accueil affiche "ARENA — User App"

2. **Test flavor admin** : `flutter run --flavor admin --target lib/main_admin.dart`
   - L'app s'ouvre avec icône rouge, nom "ARENA Admin"
   - L'écran d'accueil affiche "ARENA Admin"

3. **Test admin web** : `flutter run --flavor admin --target lib/main_admin.dart -d chrome`
   - L'admin s'ouvre dans Chrome (responsive)

4. **Test Sentry** : provoque un crash test dans le code
   ```dart
   throw Exception('test sentry');
   ```
   - Vérifier que l'événement apparaît dans le dashboard Sentry

5. **Test connexion Supabase** : test simple dans une page
   ```dart
   final response = await supabase.from('app_config').select();
   print(response);
   ```

### ⚠️ Pièges courants

- ❌ Oublier de configurer `applicationId` différent pour chaque flavor → conflit
- ❌ Oublier d'ajouter `--target` dans la commande → mauvais entry point
- ❌ Oublier les permissions iOS dans `Info.plist` (caméra, micro, etc.)
- ❌ Mettre les clés Supabase dans le code source (toujours dans `.env`)
- ❌ Commit `.env` dans Git (ajouter dans `.gitignore` AVANT le premier commit)

### ✅ Critères d'acceptation

- [ ] `flutter run --flavor user` lance l'app User sans erreur
- [ ] `flutter run --flavor admin` lance l'app Admin sans erreur
- [ ] Les 2 apps ont des icônes/noms différents (bleu/rouge)
- [ ] Connexion Supabase fonctionne (test query OK)
- [ ] Sentry capture les exceptions
- [ ] `.env` est dans `.gitignore`
- [ ] Premier commit Git effectué

### 🔗 Références
- Détails complets : `ARENA_FLUTTER_PROMPT.md` ligne 2264+
- Guide pas-à-pas : `GUIDE_PHASE_0.md`
- Setup Sentry : https://docs.sentry.io/platforms/flutter/

---

## PHASE 0.5 — Onboarding 4 écrans (2-3h) ⭐ NOUVEAU

### 🎯 Objectif simple
Créer l'expérience de premier lancement avec **4 écrans illustrés** pour réduire l'abandon des nouveaux utilisateurs (60% sans onboarding → 20% avec).

### 📦 Pré-requis
- ✅ PHASE 0 complète
- ✅ Lib `flutter_onboarding_slider` ^1.1 installée

### 📋 Livrables
- [ ] `OnboardingPage` avec PageView 4 slides
- [ ] Slide 1 : Bienvenue (logo animé)
- [ ] Slide 2 : Concept brackets (illustration arbre)
- [ ] Slide 3 : Match system (illustration code partagé)
- [ ] Slide 4 : Gains (illustration MoMo + trophée)
- [ ] Bouton "PASSER" (sauf dernier écran)
- [ ] Indicateur de progression (4 dots)
- [ ] Stockage `SharedPreferences` (`onboarding_completed`)
- [ ] Logique de skip si déjà vu

### 💬 Prompt suggéré pour Claude Code

```
Claude, PHASE 0.5 : Onboarding 4 écrans.

Lis ARENA_MASTER_PROMPT.md PARTIE 6 PHASE 0.5.

Crée :
1. lib/features_user/onboarding/onboarding_page.dart
2. lib/features_user/onboarding/onboarding_slide.dart (widget réutilisable)
3. assets/animations/ (4 fichiers Lottie ou placeholders SVG)

Logique :
- Au lancement de l'app, check SharedPreferences['onboarding_completed']
- Si false → afficher OnboardingPage
- Sinon → afficher SplashUserScreen

Démarre par le widget OnboardingSlide réutilisable, montre-le moi avant les 4 slides.
```

### 🧪 Tests à valider

1. **Test premier lancement** : désinstaller/réinstaller l'app
   - L'onboarding s'affiche
2. **Test skip** : cliquer "PASSER" sur slide 1
   - Arrive directement à SplashUserScreen
3. **Test complet** : compléter les 4 slides
   - Arrive à SplashUserScreen
4. **Test re-ouverture** : fermer et relancer l'app
   - L'onboarding ne s'affiche plus

### ✅ Critères d'acceptation

- [ ] 4 slides s'affichent correctement
- [ ] Animations fluides
- [ ] Bouton PASSER fonctionne
- [ ] Bouton SUIVANT/COMMENCER fonctionne
- [ ] SharedPreferences stocke `onboarding_completed = true`
- [ ] Pas de re-affichage après complétion
- [ ] Possibilité de revoir l'onboarding via Settings (PHASE 9)

---

## PHASE 1 — Theme + Router + Widgets de base (1h)

### 🎯 Objectif simple
Mettre en place le **design system** (couleurs, polices, theme), le **routeur** (GoRouter) et les **widgets réutilisables** (boutons, cards, inputs).

### 📦 Pré-requis
- ✅ PHASE 0 complète

### 📋 Livrables
- [ ] `lib/core/theme/arena_colors.dart` (palette complète)
- [ ] `lib/core/theme/arena_typography.dart` (Orbitron, Nunito, Fira Code)
- [ ] `lib/core/theme/arena_theme.dart` (ThemeData)
- [ ] `lib/core/router/user_router.dart` (GoRouter user)
- [ ] `lib/core/router/admin_router.dart` (GoRouter admin)
- [ ] Widgets de base :
  - [ ] `ArenaButton` (variants : primary, secondary, danger)
  - [ ] `ArenaCard`
  - [ ] `ArenaTextField`
  - [ ] `ArenaLoadingIndicator`
  - [ ] `EmptyState`
  - [ ] `ErrorState`

### 💬 Prompt suggéré pour Claude Code

```
Claude, PHASE 1 : Theme + Router + Widgets.

Lis ARENA_MASTER_PROMPT.md PARTIE 2 (Identité visuelle).

Implémente dans cet ordre :
1. arena_colors.dart (toute la palette)
2. arena_typography.dart (avec google_fonts)
3. arena_theme.dart (ThemeData dark)
4. user_router.dart (GoRouter avec routes vides pour l'instant)
5. Widgets ArenaButton, ArenaCard, ArenaTextField

Crée une page de "preview" temporaire qui affiche tous les widgets pour les tester visuellement.
```

### ✅ Critères d'acceptation

- [ ] Page preview affiche tous les widgets
- [ ] Couleurs respectent la palette
- [ ] Polices Orbitron/Nunito/Fira Code chargent
- [ ] Theme dark partout
- [ ] GoRouter configuré (même si routes vides)

---

## PHASE 1 BIS — i18n + Devises + Feature Flags (2-3h)

### 🎯 Objectif simple
Préparer l'**architecture multi-langue, multi-devises** et **feature flags** dès le début, même si V1.0 = FR + XAF/XOF uniquement. Cela évite de tout refactorer en V1.1 et V1.2.

### 📦 Pré-requis
- ✅ PHASE 1 complète

### 📋 Livrables
- [ ] `flutter_localizations` configuré
- [ ] Fichiers ARB : `app_fr.arb`, `app_en.arb`, `app_ar.arb`
- [ ] Service `i18n_service.dart` (détection auto langue)
- [ ] Service `currency_service.dart` (formatage devises)
- [ ] Service `feature_flags_service.dart` (lecture `app_config`)
- [ ] Provider Riverpod `currentLanguageProvider`
- [ ] Provider Riverpod `currentCurrencyProvider`
- [ ] Widget `LanguageSwitcher` (V1.0 caché car FR seul)
- [ ] Tests : changer langue → app passe en EN

### 💬 Prompt suggéré pour Claude Code

```
Claude, PHASE 1 BIS : i18n + Devises + Feature Flags.

Lis ARENA_FLUTTER_PROMPT.md ligne 548-720 (section "Internationalisation").

Implémente :
1. Configuration flutter_localizations + intl
2. Fichiers ARB (FR seulement utilisé en V1.0, mais EN/AR créés vides)
3. Service i18n + provider
4. Service currency avec format selon devise
5. Service feature flags lecture app_config table

Pour V1.0 :
- Active uniquement FR
- Active uniquement XAF, XOF, USD
- Cache les options EN/AR/Maghreb
```

### ✅ Critères d'acceptation

- [ ] App charge en FR par défaut
- [ ] `intl` formate les devises (1 234,56 vs $1,234.56)
- [ ] Feature flags lus depuis `app_config`
- [ ] Architecture prête pour V1.1/V1.2 (sans tout refactorer)

---


## PHASE 2 — Authentification User (4-5h) ⭐ ENRICHIE

### 🎯 Objectif simple
Permettre à un joueur de **s'inscrire**, **se connecter**, **récupérer son mot de passe**, et **se connecter via Google ou Apple**. Apple est obligatoire si autre social login présent.

### 📦 Pré-requis
- ✅ PHASE 1 BIS complète
- ✅ Supabase Auth configuré (Email + Google + Apple activés)
- ✅ Apple Developer Account (99 €/an) si tu veux iOS

### 📋 Livrables (4 sous-phases)

#### SOUS-PHASE 2.1 — Auth email/password (1h)
- [ ] `SplashUserScreen`
- [ ] `LoginUserScreen` (sans social login)
- [ ] `RegisterUserScreen` (3 étapes)
- [ ] `auth_user_repository.dart`
- [ ] `auth_user_provider.dart` (Riverpod StreamProvider)
- [ ] Filtre rôle (un user avec `role='admin'` est rejeté)

#### SOUS-PHASE 2.2 — Forgot Password (1h) ⭐ NOUVEAU
- [ ] `ForgotPasswordPage`
- [ ] `ResetPasswordPage`
- [ ] Deep links configurés (Android `intent-filter`, iOS `CFBundleURLSchemes`)
- [ ] Lib `app_links` ^6.0
- [ ] Email template Supabase customisé en français

#### SOUS-PHASE 2.3 — Login Google + Apple (2h) ⭐ NOUVEAU
- [ ] Boutons Google + Apple dans `LoginUserScreen`
- [ ] Logique `signInWithGoogle()` (lib `google_sign_in`)
- [ ] Logique `signInWithApple()` (lib `sign_in_with_apple`)
- [ ] `LinkExistingAccountPage` (si email existe déjà avec auth différent)
- [ ] Auto-création `profiles` au premier login social

#### SOUS-PHASE 2.4 — CGU/Privacy à l'inscription (30 min) ⭐ NOUVEAU
- [ ] Cases à cocher CGU + Privacy (obligatoires)
- [ ] Case à cocher Marketing (optionnelle)
- [ ] Stockage `cgu_accepted_at`, `privacy_policy_accepted_at`
- [ ] Re-acceptation forcée si version CGU change

### 💬 Prompt suggéré pour Claude Code

```
Claude, PHASE 2 : Authentification User (4 sous-phases).

Lis ARENA_MASTER_PROMPT.md PARTIE 6 PHASE 2 + ARENA_FLUTTER_PROMPT.md ligne 2802+.

Procède dans l'ordre des sous-phases (2.1 → 2.2 → 2.3 → 2.4).

Pour chaque sous-phase :
1. Crée les fichiers
2. Demande-moi de tester
3. Si OK, passe à la suivante

Pour SOUS-PHASE 2.3, vérifie avec web_search la dernière version de google_sign_in et sign_in_with_apple.

⚠️ RAPPELS :
- Apple Sign In OBLIGATOIRE si Google Sign In présent (Apple guidelines)
- Stocker tous les utilisateurs dans table `profiles` avec `auth_provider`
```

### 🧪 Tests à valider

1. **Inscription email/password** : compte créé en DB avec `auth_provider='email'`
2. **Login Google** : compte créé avec `auth_provider='google'`
3. **Login Apple** : compte créé avec `auth_provider='apple'` (sur iPhone réel)
4. **Forgot Password** : email reçu, lien fonctionne, mdp mis à jour
5. **Login admin sur app User** : message d'erreur "Téléchargez ARENA Admin"
6. **CGU non cochée** : bouton SUIVANT désactivé

### ✅ Critères d'acceptation

- [ ] Inscription email fonctionne
- [ ] Login Google fonctionne (Android + iOS)
- [ ] Login Apple fonctionne (iOS testé sur device physique)
- [ ] Forgot Password : flow complet OK
- [ ] CGU obligatoires à l'inscription
- [ ] Filtre rôle admin → rejet sur app User
- [ ] Profile créé en DB après inscription/login social

---

## PHASE 2 BIS — Authentification Admin avec TOTP (4-5h)

### 🎯 Objectif simple
Auth admin avec **2FA TOTP** (Google Authenticator) + **codes d'invitation** + **filtre rôle strict**.

### 📦 Pré-requis
- ✅ PHASE 2 complète
- ✅ Lib `otp` ^3.1 + `qr_flutter` ^4.1

### 📋 Livrables
- [ ] `SplashAdminScreen` (rouge)
- [ ] `LoginAdminScreen`
- [ ] `InvitationRedeemScreen` (saisie code invitation)
- [ ] `TOTPSetupScreen` (QR code + scan Google Authenticator)
- [ ] `TOTPVerifyScreen` (saisie code 6 chiffres à chaque login)
- [ ] Logique génération secret TOTP côté serveur (Edge Function)
- [ ] Stockage backup codes (10 codes hashés)
- [ ] Anti-replay : vérifier `last_totp_used`
- [ ] Filtre rôle strict (seulement `admin` ou `super_admin`)

### 💬 Prompt suggéré pour Claude Code

```
Claude, PHASE 2 BIS : Auth Admin avec TOTP.

Lis ARENA_FLUTTER_PROMPT.md ligne 2856-3025 (PHASE 2 BIS détails).

Workflow :
1. Super-admin génère un code d'invitation
2. Nouvel admin télécharge l'app Admin
3. Saisit le code → InvitationRedeemScreen
4. Crée son compte (email + password)
5. Setup TOTP : scan QR avec Google Authenticator
6. Saisit le premier code TOTP pour valider
7. Backup codes affichés (à sauvegarder)
8. Désormais : login = email + password + TOTP

⚠️ Sécurité :
- TOTP secret stocké chiffré (jamais en clair)
- Vérifier last_totp_used (anti-replay)
- Backup codes hashés en DB (jamais en clair)
```

### ✅ Critères d'acceptation

- [ ] Code invitation valide → création compte admin
- [ ] QR code TOTP s'affiche, scannable par Google Authenticator
- [ ] Code TOTP correct → login OK
- [ ] Code TOTP incorrect → erreur
- [ ] Code TOTP réutilisé → bloqué
- [ ] Backup codes fonctionnent en cas de perte du téléphone
- [ ] Filtre rôle strict (un user `player` ne peut pas se connecter)

---

## PHASE 3 — Layout principal + HomePage joueur (1-2h)

### 🎯 Objectif simple
Layout principal de l'app User : **bottom navigation bar**, **HomePage** avec dashboard.

### 📋 Livrables
- [ ] Bottom Nav avec 4 tabs : Home, Compétitions, Chat, Profil
- [ ] `HomePage` :
  - [ ] Header avec avatar + notifications
  - [ ] Section "Compétitions actives" (cards horizontales)
  - [ ] Section "Prochains matchs" (si inscrit)
  - [ ] Section "Lives en cours" (si streams actifs)
  - [ ] Section "Stats personnelles" (W/L, ratio)

### 💬 Prompt suggéré pour Claude Code

```
Claude, PHASE 3 : Layout + HomePage.

Lis ARENA_MASTER_PROMPT.md PARTIE 3 (écran #9).

Crée :
1. lib/features_user/home/main_layout.dart (Scaffold avec BottomNavBar)
2. lib/features_user/home/home_page.dart
3. Cards/widgets nécessaires

UI : suit le design de arena_41_screens.html (mockup HomePage).
```

### ✅ Critères d'acceptation

- [ ] Navigation entre tabs fluide
- [ ] HomePage affiche données réelles depuis Supabase
- [ ] Empty states si pas de compet/match
- [ ] Pull-to-refresh fonctionne

---

## PHASE 4 — Compétitions (3-4h)

### 🎯 Objectif simple
Liste, détail, inscription aux compétitions.

### 📋 Livrables
- [ ] `CompetitionsListPage` avec filtres par jeu
- [ ] `CompetitionDetailPage` :
  - [ ] Header (nom, jeu, dates, prix d'inscription)
  - [ ] Tab "Infos" (description, format, règles)
  - [ ] Tab "Participants" (liste avec avatars)
  - [ ] Tab "Bracket" (si phase démarrée)
  - [ ] Tab "Prix" (top 4 affichés)
  - [ ] Bouton "S'inscrire" (ou "Inscrit ✓")
- [ ] `BracketViewPage` (vue arbre du tournoi)
- [ ] `GroupStandingsPage` (classement phase de groupes)

### 💬 Prompt suggéré

```
Claude, PHASE 4 : Compétitions.

Lis :
- ARENA_MASTER_PROMPT.md PARTIE 3 (écrans #10, #11, #20, #21)
- ARENA_MASTER_PROMPT.md PARTIE 4 (tables competitions, prizes)
- arena_brackets_schemas.html pour le système de brackets

Implémente :
1. Repository CompetitionRepository
2. Provider Riverpod (StreamProvider)
3. Pages list + detail + bracket + standings

Pour le bracket, utilise une approche custom avec CustomPainter ou InteractiveViewer.
```

### ✅ Critères d'acceptation

- [ ] Liste des compétitions affichée avec filtres
- [ ] Détail complet d'une compétition
- [ ] Bouton "S'inscrire" mène vers paiement (PHASE 11bis - implémenté plus tard)
- [ ] Bracket s'affiche correctement pour les 3 formats
- [ ] Realtime : si nouveau participant s'inscrit, affichage updated

---

## PHASE 5 — Système Match Room (2-3h)

### 🎯 Objectif simple
**LE CŒUR D'ARENA** : permettre à 2 joueurs de partager un code room eFootball, valider leurs scores ensemble, et résoudre les désaccords.

### 📦 Pré-requis
- ✅ PHASE 4 complète
- ✅ Tables `matches`, `match_events` créées

### 📋 Livrables (4 étapes)

#### Étape 1 — Partage code room
- [ ] HOME crée le code dans eFootball
- [ ] Saisit le code dans ARENA
- [ ] Code envoyé automatiquement dans le chat
- [ ] AWAY voit le code, le copie, rejoint la room
- [ ] Timer 5 min (forfait si pas démarré)

#### Étape 2 — Configuration match (PHASE DE GROUPES UNIQUEMENT)
- [ ] Si `phase.type = 'groups'` :
  - [ ] Checklist obligatoire pour HOME : "Prolongations désactivées" + "Tirs au but désactivés"
  - [ ] Stockage dans `matches.match_config` jsonb avec timestamp (anti-litige)

#### Étape 3 — Saisie score concurrente
- [ ] Les 2 joueurs saisissent leur score à la fin
- [ ] Si concorde → match validé automatiquement
- [ ] Si discorde → modal "désaccord" + revote

#### Étape 4 — Validation collaborative
- [ ] Si les 2 saisissent le même score : OK
- [ ] Si revote 2 fois en désaccord → litige ouvert (bot d'arbitrage en PHASE 12.5)

### 💬 Prompt suggéré

```
Claude, PHASE 5 : Match Room System.

Lis :
- ARENA_MASTER_PROMPT.md PARTIE 6 PHASE 5
- arena_match_config.html (mockup configuration HOME)
- ARENA_FLUTTER_PROMPT.md ligne 2935+ (détails)

Implémente les 4 étapes du Match Room.

⚠️ ATTENTION :
- L'étape 2 (config match) ne s'affiche QUE pour les phases de groupes
- Stocker la confirmation dans match_config jsonb pour éviter litiges
- Realtime : les 2 joueurs voient instantanément les changements

Procède étape par étape, demande-moi de tester chaque étape.
```

### 🧪 Tests à valider

1. **Test étape 1** : 2 joueurs (2 émulateurs ou 1 device + 1 émulateur)
   - HOME saisit code → AWAY le voit instantanément
2. **Test étape 2** : créer match en phase de groupes
   - Checklist apparaît pour HOME
   - HOME doit cocher les 2 cases pour passer
3. **Test étape 3 OK** : les 2 saisissent score concorde → validé
4. **Test étape 3 discorde** : score différent → modal revote
5. **Test forfait** : pas démarré dans 5 min → forfait auto

### ✅ Critères d'acceptation

- [ ] Code room partagé en realtime
- [ ] Configuration HOME en phase de groupes obligatoire
- [ ] Scores concordants validés
- [ ] Scores discordants → revote
- [ ] 2 désaccords consécutifs → litige ouvert
- [ ] Timestamp et trace de toutes les actions

---

## PHASE 6 — Chat hybride Supabase + Agora RTM (3-4h)

### 🎯 Objectif simple
**Architecture hybride** : Supabase Realtime pour les messages persistants + Agora RTM pour la présence (typing, online).

### 📦 Pré-requis
- ✅ PHASE 5 complète
- ✅ Lib `agora_rtm` ^1.5
- ✅ Table `chat_messages` créée

### 📋 Livrables
- [ ] `MessagesInboxPage`
- [ ] `ChatPage` (1-on-1)
- [ ] Service `chat_service.dart` (Supabase Realtime)
- [ ] Service `presence_service.dart` (Agora RTM)
- [ ] Indicateur "online/offline"
- [ ] Indicateur "typing..."
- [ ] Type de message spécial `room_code` (cyan)
- [ ] Modération basique (filter banned_words via Edge Function)

### 💬 Prompt suggéré

```
Claude, PHASE 6 : Chat hybride Supabase + Agora RTM.

Lis :
- ARENA_MASTER_PROMPT.md PARTIE 6 PHASE 6
- ARENA_FLUTTER_PROMPT.md ligne 3025+ (détails architecture hybride)
- arena_streaming_chat_final.html (mockups)

Architecture :
- Messages → INSERT chat_messages → Supabase Realtime broadcast
- Présence → Agora RTM channel attributes (typing, online)

Démarre par le chat_service Supabase, puis ajoute la présence Agora.
```

### ✅ Critères d'acceptation

- [ ] Messages texte envoyés/reçus en realtime
- [ ] Codes room mis en évidence (cyan)
- [ ] Indicateur "online" affiché
- [ ] Indicateur "typing..." s'affiche/disparaît correctement
- [ ] Historique chargé depuis DB au scroll up

---

## PHASE 7 — ❌ SUPPRIMÉE

> Cette phase (appels vidéo Agora RTC entre joueurs) a été retirée du projet.
> 
> **Économie** : ~24 $/mois + 2h de développement.
> 
> **Justification** : pas essentiel V1.0, les joueurs communiquent via chat texte (PHASE 6) et peuvent partager leur WhatsApp si besoin de communication vocale.

---


## PHASE 8 — Anti-cheat + Streaming Agora sélectif (6-7h, LA PLUS COMPLEXE)

### 🎯 Objectif simple
La **phase la plus difficile** du projet :
1. **Recording d'écran local** pendant le match (anti-triche)
2. **Bouton flottant** par-dessus eFootball (Android)
3. **Live Activity** pour iOS (16.1+)
4. **Streaming live sélectif** sur Agora RTC (finales auto + admin manuel)
5. **Page Live + Watch** pour les spectateurs

### ⚠️ Avant de commencer

> 🔴 **PHASE LA PLUS DIFFICILE.** Elle nécessite :
> - Du **code natif Kotlin** (Android) et **Swift** (iOS)
> - Une **bonne compréhension** des APIs natives
> - Du **temps pour tester sur devices physiques** (pas juste émulateur)

### 📦 Pré-requis
- ✅ PHASE 5 complète
- ✅ Libs : `flutter_screen_recording`, `flutter_overlay_window`, `flutter_foreground_task`, `live_activities`, `agora_rtc_engine`
- ✅ Permissions configurées (cf. PHASE 0)

### 📋 Livrables (7 sous-phases)

#### SOUS-PHASE 8.1 — Permissions et configuration native (1h)
- [ ] Android : `SYSTEM_ALERT_WINDOW`, `FOREGROUND_SERVICE`, `RECORD_AUDIO`, `MEDIA_PROJECTION`
- [ ] iOS : `NSCameraUsageDescription`, `NSMicrophoneUsageDescription`
- [ ] Demande de permissions runtime
- [ ] Service `permissions_service.dart`

#### SOUS-PHASE 8.2 — Détection lancement du jeu (1h)
- [ ] `installed_apps` : check si eFootball/FIFA/FC est installé
- [ ] `app_usage` : détecter quand le jeu passe en foreground
- [ ] Si jeu détecté → démarrer recording + overlay

#### SOUS-PHASE 8.3 — Service Foreground + recording (1.5h)
- [ ] `flutter_foreground_task` config
- [ ] Notification persistante "ARENA enregistre votre match"
- [ ] `flutter_screen_recording` démarre l'enregistrement
- [ ] Stockage local du fichier video
- [ ] Upload vers Supabase Storage à la fin du match

#### SOUS-PHASE 8.4 — Bouton flottant Android (1.5h)
- [ ] `flutter_overlay_window` : bouton 72dp circulaire rouge
- [ ] Timer MM:SS qui tourne
- [ ] Drag to side (le bouton se colle aux bords)
- [ ] Tap court : ramène ARENA en focus
- [ ] Tap long : dialogue de verrouillage (3 options)

#### SOUS-PHASE 8.5 — Verrouillage de l'arrêt (1h)
- [ ] 3 options dans le dialogue : "Continuer", "Pause", "Arrêter (forfait)"
- [ ] "Arrêter" → alerte admin + forfait auto
- [ ] Recording continue même si screen verrouillé/déverrouillé

#### SOUS-PHASE 8.6 — iOS Live Activity (1h)
- [ ] `live_activities` config
- [ ] Widget Live Activity avec timer
- [ ] Affiché dans Dynamic Island (iPhone 14 Pro+)

#### SOUS-PHASE 8.7 — Streaming Agora RTC sélectif (2-3h) ⭐ NOUVEAU
- [ ] Auto-streaming des finales (logique métier)
- [ ] Sélection manuelle admin
- [ ] Service `agora_streaming_service.dart`
- [ ] Edge Function `get_agora_token` (sécurité)
- [ ] `LiveStreamsPage` (liste matchs en live)
- [ ] `WatchStreamPage` (regarder un stream)
- [ ] Compteur viewers en realtime
- [ ] Notification au HOME quand son match est sélectionné

### 💬 Prompt suggéré pour Claude Code

```
Claude, PHASE 8 : Anti-cheat + Streaming (LA PLUS COMPLEXE).

⚠️ Cette phase nécessite du code natif Android (Kotlin) et iOS (Swift).
Si tu hésites sur une API native, utilise web_search pour vérifier la version actuelle.

Lis :
- ARENA_MASTER_PROMPT.md PARTIE 6 PHASE 8
- ARENA_FLUTTER_PROMPT.md ligne 3217+ (PHASE 8 détaillée)
- arena_streaming_chat_final.html (mockups streaming)

Procède SOUS-PHASE par SOUS-PHASE (8.1 → 8.7).
Après CHAQUE sous-phase, demande-moi de tester avant de passer à la suivante.

⚠️ Tests obligatoires sur devices physiques :
- Android (Samsung ou autre) avec un vrai jeu installé
- iPhone (avec compte Apple Developer pour signer)
```

### 🧪 Tests à valider

1. **Test recording** : démarrer match → vérifier fichier vidéo créé
2. **Test bouton flottant** : par-dessus eFootball, timer tourne
3. **Test drag** : déplacer le bouton, il se colle aux bords
4. **Test tap court** : ramène ARENA en focus
5. **Test tap long** : dialogue 3 options
6. **Test arrêt forfait** : alerte admin reçue
7. **Test iOS Live Activity** : visible sur Dynamic Island
8. **Test streaming auto finale** : créer compet → finale = `is_streamed=true`
9. **Test streaming manuel admin** : admin coche un match → streaming activé
10. **Test broadcaster** : HOME démarre stream, audience peut voir
11. **Test viewers count** : 3 spectateurs joignent → compteur à 3

### ✅ Critères d'acceptation

- [ ] Recording fonctionne sur Android
- [ ] Bouton flottant Android OK
- [ ] iOS Live Activity OK (sur device physique)
- [ ] Recording uploadé vers Supabase Storage à la fin du match
- [ ] Forfait auto si arrêt forcé
- [ ] Streaming Agora finales = auto
- [ ] Admin peut activer manuellement
- [ ] Spectateurs peuvent regarder via WatchStreamPage
- [ ] Compteur viewers à jour en realtime

### ⚠️ Pièges courants

- ❌ Oublier les permissions runtime (l'app crash silencieusement)
- ❌ Tester uniquement sur émulateur (le recording ne marche pas pareil)
- ❌ Code natif désynchronisé entre Android et iOS
- ❌ Ne pas tester sur le vrai jeu (eFootball spécifiquement)
- ❌ Stocker l'App Certificate Agora côté client (jamais !)

---

## PHASE 9 — Profil + Settings + Suppression compte (3h) ⭐ ENRICHIE

### 🎯 Objectif simple
Page profil joueur + page paramètres + **suppression de compte (RGPD obligatoire)**.

### 📋 Livrables (4 sous-phases)

#### SOUS-PHASE 9.1 — Profil + Édition (1h)
- [ ] `PlayerProfilePage` (stats, achievements, historique)
- [ ] `EditProfilePage` (modifier username, avatar color, pays)
- [ ] Stats calculées : W/L, ratio victoires, goals_scored/conceded

#### SOUS-PHASE 9.2 — Settings Page (1h) ⭐ NOUVEAU
- [ ] `SettingsPage` avec sections :
  - [ ] Préférences (langue, devise, notifs)
  - [ ] Compte (changer email, mdp, méthodes de connexion)
  - [ ] Confidentialité (téléchargement données, supprimer compte)
  - [ ] Aide & Infos (revoir intro, support, à propos)

#### SOUS-PHASE 9.3 — Suppression compte 4 étapes (1h) ⭐ NOUVEAU
- [ ] `DeleteAccountPage` workflow :
  - Étape 1 : Avertissement (perte de données)
  - Étape 2 : Vérification gains pending
  - Étape 3 : Confirmation par mdp + typer "SUPPRIMER"
  - Étape 4 : Suppression effective (soft-delete)
- [ ] Edge Function `cleanup_deleted_accounts` (cron 24h, anonymise après 30j)
- [ ] Email de confirmation au user

#### SOUS-PHASE 9.4 — Export données (30 min)
- [ ] Bouton "Télécharger mes données" génère un ZIP
- [ ] Edge Function génère le ZIP avec `profile.json`, `matches.json`, `payments.json`, `chat_messages.json`
- [ ] Email avec lien temporaire (24h)

### 💬 Prompt suggéré

```
Claude, PHASE 9 : Profil + Settings + Suppression compte.

Lis :
- ARENA_MASTER_PROMPT.md PARTIE 6 PHASE 9
- ARENA_FLUTTER_PROMPT.md ligne 4385+ (détails)
- arena_critical_screens.html (mockups suppression compte)

⚠️ La suppression de compte est OBLIGATOIRE pour Apple/Google App Store.
Workflow strict : 4 étapes + délai 30 jours + anonymisation auto.

Procède sous-phase par sous-phase.
```

### 🧪 Tests à valider

1. **Test profil** : modifier username → mis à jour
2. **Test settings** : changer langue → app passe en EN (architecture prête)
3. **Test suppression** : flow 4 étapes → compte désactivé
4. **Test cleanup** : simuler 30 jours → données anonymisées
5. **Test export** : ZIP reçu par email avec toutes les données

### ✅ Critères d'acceptation

- [ ] Profil affiche stats correctes
- [ ] Settings fonctionnel
- [ ] Suppression compte 4 étapes OK
- [ ] `account_deletion_requested_at` rempli en DB
- [ ] Edge Function cleanup configurée (cron 3h du matin)
- [ ] Export données ZIP généré

---

## PHASE 10 — Notifications (2h)

### 🎯 Objectif simple
Notifications push (FCM) + center in-app + toasts.

### 📋 Livrables
- [ ] `notification_service.dart` (init FCM, save token)
- [ ] `NotificationsPage` avec liste + "Tout marquer comme lu"
- [ ] Toasts in-app pour les notifs en foreground
- [ ] Edge Function de déclenchement FCM
- [ ] Types de notifs :
  - [ ] Match dans 5 min
  - [ ] Match terminé, score à valider
  - [ ] Compétition démarre
  - [ ] Litige ouvert
  - [ ] Gain reçu (payout completed)

### 💬 Prompt suggéré

```
Claude, PHASE 10 : Notifications FCM.

Lis ARENA_FLUTTER_PROMPT.md ligne 4554+ (PHASE 10).

Implémente :
1. notification_service.dart (init FCM, save fcm_token in profile)
2. NotificationsPage (liste depuis table notifications)
3. Edge Function send_targeted_notification (déjà prévue PHASE 12.5)

Pour tester : insérer manuellement dans `notifications` → vérifier que push reçu sur le device.
```

### ✅ Critères d'acceptation

- [ ] FCM token sauvegardé dans `profiles.fcm_token`
- [ ] Push notif reçue sur device
- [ ] Tap sur notif → ouvre l'écran approprié
- [ ] NotificationsPage liste toutes les notifs
- [ ] Marquer comme lu fonctionne

---


## PHASE 11 — Espace Admin (4-5h, gros morceau)

### 🎯 Objectif simple
Toute l'interface admin pour **créer/gérer les compétitions, matchs, brackets, streams, payouts, litiges**.

### 📦 Pré-requis
- ✅ PHASE 2 BIS complète (auth admin)
- ✅ PHASE 4 complète (compétitions côté user)

### 📋 Livrables (10 écrans admin)

#### `AdminDashboardPage`
- [ ] Stats : compétitions actives, matchs en cours, alertes
- [ ] Carte "Payouts en attente" (badge rouge si > 0)
- [ ] Carte "Litiges ouverts" (badge rouge si > 0)
- [ ] Liste des dernières actions admin (audit log)

#### `AdminCompetitionsListPage`
- [ ] Liste avec filtres (status, jeu, date)
- [ ] Bouton "+ Nouvelle compétition"

#### `CreateCompetitionPage` — 5 étapes
- [ ] Étape 1 : Infos (nom, jeu, description, dates)
- [ ] Étape 2 : Format (single elim / groupes+KO / round robin) + nb joueurs
- [ ] Étape 3 : **Prizes** (top 4 — mode % ou montants fixes)
- [ ] Étape 4 : Frais inscription + commission ARENA
- [ ] Étape 5 : Review final + Publier

#### `AdminCompetitionDetailPage`
- [ ] Tabs : Infos, Participants, Bracket, Matchs, Litiges
- [ ] Actions admin (forcer status, annuler, etc.)

#### `AdminBracketManagementPage`
- [ ] Vue bracket avec contrôles admin
- [ ] Sur chaque match : bouton "📺 Streamer" (sauf finales = auto)
- [ ] Sur chaque match : bouton "Valider score" (manuel)

#### `AdminMatchesListPage`
- [ ] Tous les matchs + filtres (status, compétition, joueurs)

#### `AdminMatchDetailPage`
- [ ] Détails complets d'un match
- [ ] Voir le replay (recording)
- [ ] Voir le chat
- [ ] Actions : valider score, annuler, marquer forfait

#### `AdminStreamModerationPage`
- [ ] Grille live des streams actifs (jusqu'à 6 simultanés)
- [ ] Stats viewers en realtime
- [ ] Possibilité de couper un stream (modération)

#### `AdminDisputesPage`
- [ ] Liste des litiges ouverts
- [ ] Voir contexte (chat, replay, scores saisis)
- [ ] Actions : valider score 1, valider score 2, annuler match

#### `AdminPayoutsPage` ⭐ CRITIQUE
- [ ] Liste payouts en `pending_admin_validation`
- [ ] Affichage des **5 contrôles auto** par payout :
  - ✓ KYC vérifié
  - ✓ Pas de litige ouvert
  - ✓ Pas d'alerte anti-cheat
  - ✓ User non banni
  - ✓ Données paiement valides
- [ ] Mode validation **batch** (par défaut) ou **1-by-1** (si dispute)
- [ ] **Anti-erreur** : confirmation par typer le total à verser

### 💬 Prompt suggéré

```
Claude, PHASE 11 : Espace Admin (gros morceau).

Lis :
- ARENA_MASTER_PROMPT.md PARTIE 6 PHASE 11
- ARENA_FLUTTER_PROMPT.md ligne 4655+ (détails)
- arena_admin_payouts.html (mockup AdminPayoutsPage)

Procède page par page. Commence par AdminDashboardPage et AdminCompetitionsListPage.

⚠️ ATTENTION : 
- AdminPayoutsPage est CRITIQUE (gestion argent). Sécurité maximale.
- Toutes les actions admin doivent être loggées dans admin_audit_log.
- Validation manuelle obligatoire pour les payouts (pas d'auto-payout).
```

### ✅ Critères d'acceptation

- [ ] Toutes les pages admin créées
- [ ] CreateCompetitionPage : 5 étapes fonctionnelles
- [ ] Validation payouts manuelle stricte
- [ ] Audit log enregistre toutes les actions admin
- [ ] Stream moderation : grille live OK
- [ ] Litiges : workflow d'arbitrage admin OK

---

## PHASE 11 BIS — Paiements CinetPay + Crypto (5-6h, sensible)

### 🎯 Objectif simple
**Intégration des paiements** : MTN MoMo, Orange Money, Wave (via CinetPay) + USDT/BTC/ETH (via NowPayments).

### ⚠️ Avant de commencer

> 🚨 **PHASE TRÈS SENSIBLE** — gestion d'argent réel.
> 
> - **Test** : utiliser comptes sandbox avant production
> - **Sécurité** : webhooks signés, vérification serveur-serveur
> - **Conformité** : KYC obligatoire au-delà d'un seuil

### 📦 Pré-requis
- ✅ PHASE 11 complète
- ✅ Compte CinetPay créé (sandbox + production)
- ✅ Compte NowPayments créé
- ✅ Tables `payments`, `payouts`, `payment_webhook_log` créées

### 📋 Livrables (7 sous-phases)

#### 11B.1 — Setup comptes & Edge Functions sécurité (1h)
- [ ] Compte CinetPay sandbox configuré
- [ ] Compte NowPayments configuré
- [ ] Webhooks endpoints créés (Edge Functions)
- [ ] Vérification signatures webhooks

#### 11B.2 — Edge Functions paiement (1.5h)
- [ ] `cinetpay_initiate_payment` (génère URL de paiement)
- [ ] `cinetpay_webhook_handler` (reçoit confirmation)
- [ ] `nowpayments_initiate_payment` (génère adresse crypto)
- [ ] `nowpayments_webhook_handler` (reçoit confirmation)

#### 11B.3 — UI Payment picker (1h)
- [ ] `PaymentMethodPickerPage` : liste méthodes selon pays
- [ ] V1.0 : MTN MoMo, Orange Money, Wave, Crypto (USDT)

#### 11B.3.1 — UI Mobile Money (30 min)
- [ ] `MobileMoneyDetailsPage` : saisie numéro téléphone
- [ ] Validation format selon opérateur

#### 11B.4 — UI Crypto (30 min)
- [ ] Affichage adresse + QR code
- [ ] Compteur de confirmations blockchain

#### 11B.5 — Pages status (30 min)
- [ ] `PaymentProcessingPage` (WebView CinetPay)
- [ ] `PaymentSuccessPage`
- [ ] `PaymentFailedPage` (avec retry)

#### 11B.6 — Historique paiements (30 min)
- [ ] `PaymentHistoryPage` (liste paiements + payouts)

#### 11B.7 — Payouts (manuel admin) (1h)
- [ ] Edge Function `execute_validated_payout`
- [ ] Appelle CinetPay API pour transfer vers MoMo joueur
- [ ] Update `payouts.status = 'completed'` à la confirmation

### 💬 Prompt suggéré

```
Claude, PHASE 11 BIS : Paiements (sensible).

Lis ARENA_FLUTTER_PROMPT.md ligne 4983+ (PHASE 11 BIS détaillée).

⚠️ RÈGLES STRICTES :
- API keys dans Edge Functions UNIQUEMENT (jamais côté client)
- Webhooks signés et vérifiés
- Idempotency : webhooks peuvent être appelés plusieurs fois
- Stocker tous les events dans payment_webhook_log

Procède dans cet ordre :
1. Setup comptes (toi)
2. Edge Functions paiement
3. UI mobile (PaymentMethodPicker, etc.)
4. Tests sandbox
5. Passage en production (après validation complète)
```

### 🧪 Tests à valider (en sandbox d'abord !)

1. **Test paiement MoMo sandbox** : payer 100 XAF → succès
2. **Test paiement crypto sandbox** : payer 0.001 USDT → succès
3. **Test webhook fail** : simuler timeout → retry OK
4. **Test idempotency** : webhook envoyé 3 fois → 1 seul payment créé
5. **Test payout admin validation** : admin valide → MoMo reçu sur compte test

### ✅ Critères d'acceptation

- [ ] Paiement entrant fonctionne (CinetPay + NowPayments)
- [ ] Webhooks vérifiés (signatures)
- [ ] Idempotency assurée (anti-double-payment)
- [ ] Payout sortant fonctionne après validation admin
- [ ] Logs complets dans `payment_webhook_log`
- [ ] Pages success/failed OK avec retry

---

## PHASE 12 — Espace Super-Admin (2h)

### 🎯 Objectif simple
Espace pour le **fondateur d'ARENA** (toi) avec stats globales et gestion des admins.

### 📋 Livrables
- [ ] `SuperAdminDashboard` :
  - [ ] KPIs : MAU, DAU, revenus, payouts versés
  - [ ] Graphiques (Lib `fl_chart`)
- [ ] `SuperAdminInvitations` :
  - [ ] Générer codes d'invitation (avec expiration)
  - [ ] Liste codes utilisés/inutilisés
- [ ] `SuperAdminUsers` :
  - [ ] Recherche utilisateurs
  - [ ] Actions : ban, unban, voir détails complets
- [ ] `SuperAdminRevenue` :
  - [ ] Revenus par compétition, par mois, par pays
  - [ ] Export CSV pour comptable

### 💬 Prompt suggéré

```
Claude, PHASE 12 : Super-Admin.

Lis ARENA_FLUTTER_PROMPT.md ligne 5238+ (PHASE 12).

Crée 4 pages Super-Admin avec accès strict (role='super_admin' uniquement).

Pour les graphiques, utilise fl_chart.
Export CSV : utilise csv package.
```

### ✅ Critères d'acceptation

- [ ] 4 pages Super-Admin fonctionnelles
- [ ] KPIs dashboard à jour en realtime
- [ ] Codes d'invitation génériables et utilisables
- [ ] Export CSV revenus OK

---

## PHASE 12.5 — Automatisation & Orchestration (10-12h, gros morceau)

### 🎯 Objectif simple
**80% d'automatisation** pour réduire la charge admin de 5h30 à 20min par compétition.

### 📦 Pré-requis
- ✅ TOUTES les phases précédentes (0 → 12) complètes
- ✅ Coût Supabase Pro (recommandé pour pg_cron stable)

### 📋 Livrables : 14 Edge Functions + Triggers SQL

#### Orchestration auto (4 fonctions)
- [ ] `auto_close_registrations` (cron 1 min)
- [ ] `auto_generate_bracket` (cron 5 min)
- [ ] `auto_start_competition` (cron 1 min)
- [ ] `auto_complete_competition` (trigger SQL)

#### Notifications intelligentes (2 fonctions)
- [ ] `send_match_reminders` (cron 5 min, T-5 min avant match)
- [ ] `send_targeted_notification` (HTTP utility)

#### Validation collaborative scores (1 fonction)
- [ ] `submit_score_collaborative` (HTTP)

#### Gestion litiges (2 fonctions)
- [ ] `process_dispute` (cron 5 min, bot d'arbitrage)
- [ ] `escalate_dispute_after_timeout` (cron 5 min, escalade admin)

#### Modération chat (1 fonction)
- [ ] `moderate_chat_message` (HTTP, filtre `banned_words`)

#### Préparation payouts (3 fonctions)
- [ ] `prepare_payouts_for_competition` (trigger sur completion)
- [ ] `notify_admin_pending_payouts` (cron 5 min)
- [ ] `execute_validated_payout` (HTTP, après validation admin)

#### Forfaits & cleanup (1 fonction)
- [ ] `check_match_forfeits` (cron 1 min)

### 💬 Prompt suggéré

```
Claude, PHASE 12.5 : Automatisation (gros morceau).

Lis :
- ARENA_MASTER_PROMPT.md PARTIE 5 (Edge Functions)
- ARENA_FLUTTER_PROMPT.md ligne 5256+ (PHASE 12.5 détaillée)
- arena_automation.html (visualisation 5 axes)

Procède dans cet ordre :
1. Setup _shared/ (cors, supabase-client, fcm, agora_token)
2. Orchestration auto (4 fonctions)
3. Notifications intelligentes
4. Score validation
5. Disputes
6. Chat moderation
7. Payouts
8. Forfaits

Pour chaque fonction : code + déploiement + test + cron schedule.

⚠️ Service role key UNIQUEMENT côté Edge Functions, jamais côté client.
```

### 🧪 Tests à valider

1. **Test auto-close** : créer compet avec start_date dans 2 min → auto-fermeture après 2 min
2. **Test auto-bracket** : 8 joueurs inscrits → bracket auto-généré
3. **Test reminder** : T-5 min avant match → notif reçue
4. **Test score validation** : 2 joueurs concordent → match validé auto
5. **Test bot dispute** : simulier discorde → bot tente résolution

### ✅ Critères d'acceptation

- [ ] 14 Edge Functions déployées et fonctionnelles
- [ ] Crons configurés et stables
- [ ] Logs `auto_actions_log` à jour
- [ ] Réduction charge admin mesurée (5h30 → 20min)

---


## PHASE 13 — Polish + Tests automatisés + Lancement V1.0 (5-6h) ⭐ ENRICHIE

### 🎯 Objectif simple
Préparer l'app pour le **lancement** avec qualité production : polish UI, **tests automatisés**, builds release, soumissions stores.

### 📋 Livrables (4 sous-phases)

#### SOUS-PHASE 13.1 — Polish UI (1-2h)
- [ ] Animations Hero entre écrans
- [ ] Loading states partout (shimmer effect)
- [ ] Empty states avec illustrations
- [ ] Gestion d'erreurs réseau (retry button + offline banner)
- [ ] Animations transitions entre phases tournoi
- [ ] Sons et vibrations (optionnel)

#### SOUS-PHASE 13.2 — Tests automatisés (3-4h) ⭐ NOUVEAU
- [ ] Setup `test/` directory
- [ ] **Tests unitaires** prioritaires :
  - `BracketGenerator` (single elim, groupes+KO, round robin)
  - `PrizeCalculator` (mode % et mode fixe)
  - `CurrencyConverter`
  - `ScoreValidator`
- [ ] **Tests widgets** prioritaires :
  - `LoginPage`, `RegisterPage`, `ForgotPasswordPage`
  - `MatchRoomPage`
  - `ArenaButton`, `ArenaTextField`
- [ ] **Tests d'intégration** prioritaires :
  - Flux d'inscription complet
  - Flux paiement (sandbox)
  - Flux match complet
- [ ] Coverage cible : 60% sur le code métier critique

#### SOUS-PHASE 13.3 — Build production (1h)
- [ ] Configurer keystore Android
- [ ] Build APK release : `flutter build apk --flavor user --release`
- [ ] Build App Bundle : `flutter build appbundle --flavor user --release`
- [ ] Configurer profils provisioning iOS
- [ ] Build IPA release
- [ ] Tester builds release sur device physique

#### SOUS-PHASE 13.4 — Documentation et lancement (30 min)
- [ ] README projet propre
- [ ] Captures d'écran stores (8 par plateforme minimum)
- [ ] Description marketing (FR pour V1.0)
- [ ] CGU + Privacy Policy publiées (URL)
- [ ] Status page (UptimeRobot, gratuit)

### 💬 Prompt suggéré

```
Claude, PHASE 13 : Polish + Tests + Lancement.

Lis :
- ARENA_MASTER_PROMPT.md PARTIE 6 PHASE 13
- ARENA_FLUTTER_PROMPT.md ligne 5896+

Procède sous-phase par sous-phase.

Pour les tests :
- Mock les dépendances avec mocktail
- Tests unitaires pour la logique métier (brackets, prizes)
- Tests widgets pour les écrans critiques (login, match)
- Tests intégration pour les flux complets (inscription, paiement)

⚠️ Coverage cible 60% sur le code critique (pas besoin 100%).
```

### 🧪 Tests à valider

1. **Test coverage** : `flutter test --coverage` → ≥ 60%
2. **Test build user release** : APK installable
3. **Test build admin release** : APK installable
4. **Test sur device physique** : Android + iOS
5. **Test status page** : URL accessible (status.arena-app.com)

### 🚀 LANCEMENT V1.0

- 13 pays Afrique francophone
- Langue : FR uniquement
- Paiements : CinetPay (MoMo) + NowPayments (crypto)
- Apps : Play Store + App Store

### ✅ Critères d'acceptation

- [ ] Tests automatisés ≥ 60% coverage
- [ ] Builds release Android + iOS OK
- [ ] App soumise sur Play Store
- [ ] App soumise sur App Store
- [ ] CGU/Privacy publiées
- [ ] Status page en ligne

---

## PHASES 14 & 15 — Extensions futures (V1.1, V1.2)

> ⚠️ **À FAIRE 3-12 MOIS APRÈS V1.0** — quand traction validée.

### PHASE 14 — Extension V1.1 Afrique anglophone (5-6h)
- Activation langue EN
- Activation devises NGN, GHS, KES, ZAR, RWF, UGX, TZS
- Intégration Flutterwave (paiements anglophone)
- Localisation marketing 7 nouveaux pays

### PHASE 15 — Extension V1.2 Maghreb (6-8h)
- Activation langue AR (RTL)
- Activation devises MAD, DZD, TND, EGP
- Intégration Paymob/Paymee/CMI/SATIM (paiements Maghreb)
- Tests RTL extensifs (UI miroir)
- Localisation 4 nouveaux pays

---


# PARTIE 7 — RÈGLES & CONVENTIONS

## 🛡️ Règles de sécurité non-négociables

### Code & secrets

| Règle | Justification |
|-------|---------------|
| **JAMAIS** mettre une API key dans le code source | Push GitHub = clé compromise |
| **TOUJOURS** utiliser `.env` (et `.env` dans `.gitignore`) | Standard de l'industrie |
| **TOUJOURS** valider les inputs utilisateur côté serveur | Le client ment, le serveur tranche |
| **JAMAIS** désactiver la RLS sur les tables Supabase | Sinon tout est exposé publiquement |
| **JAMAIS** utiliser `service_role_key` côté client | Cette clé bypass la RLS |
| **TOUJOURS** signer les webhooks (CinetPay, NowPayments) | Sinon n'importe qui peut faker des paiements |

### Authentification

| Règle | Justification |
|-------|---------------|
| **TOUJOURS** filtrer le rôle au login | Un user `admin` ne doit pas se connecter à l'app User |
| **TOUJOURS** TOTP pour les admins | 2FA obligatoire pour la sécurité |
| **TOUJOURS** vérifier `last_totp_used` (anti-replay) | Empêche utiliser 2x le même code |
| **JAMAIS** exposer le `totp_secret` côté client | Doit rester côté serveur |
| **TOUJOURS** logger les tentatives de login | Audit trail |

### Paiements (extra-strict)

| Règle | Justification |
|-------|---------------|
| **JAMAIS** d'auto-payouts (toujours validation admin manuelle) | Erreur = perte d'argent |
| **TOUJOURS** vérifier les 5 contrôles auto avant validation | KYC, disputes, anti-cheat, ban, data |
| **TOUJOURS** confirmation par typer le total à verser | Anti-erreur de validation |
| **TOUJOURS** idempotency sur les webhooks paiement | Webhook reçu 2x = 1 seul payment |
| **TOUJOURS** logger TOUTES les actions payment dans `payment_webhook_log` | Forensics et compliance |

### Données utilisateurs (RGPD)

| Règle | Justification |
|-------|---------------|
| **TOUJOURS** offrir suppression de compte (RGPD + stores) | Obligation légale |
| **TOUJOURS** anonymisation après 30 jours (pas suppression hard) | Permet annulation + intégrité référentielle |
| **TOUJOURS** offrir export des données | Droit à la portabilité (RGPD) |
| **JAMAIS** vendre des données utilisateurs | Éthique + légalité |
| **TOUJOURS** demander consentement avant marketing | Loi Informatique et Libertés |

---

## 📋 Conventions de code Dart/Flutter

### Style général

```dart
// ✅ BON : nommage clair
final currentUser = ref.watch(currentUserProvider);

// ❌ MAUVAIS : variables cryptiques
final cu = ref.watch(cuProvider);
```

### Architecture Riverpod (state management)

```dart
// Provider simple
final authStateProvider = StreamProvider<AuthState>((ref) {
  return Supabase.instance.client.auth.onAuthStateChange;
});

// Provider avec dépendance
final currentUserProvider = FutureProvider<Profile?>((ref) async {
  final auth = ref.watch(authStateProvider).value;
  if (auth?.session == null) return null;
  
  return ref.read(authRepositoryProvider).getCurrentProfile();
});

// Provider famille (avec paramètre)
final competitionDetailProvider = FutureProvider.family<Competition, String>(
  (ref, competitionId) {
    return ref.read(competitionRepositoryProvider).getById(competitionId);
  },
);
```

### Modèles avec Freezed

```dart
// lib/data/models/profile.dart
@freezed
class Profile with _$Profile {
  const factory Profile({
    required String id,
    required String username,
    required String email,
    required String countryCode,
    @Default('#4C7AFF') String avatarColor,
    @Default(UserRole.player) UserRole role,
    Map<String, dynamic>? stats,
    @Default('email') String authProvider,
    String? deletedAt,
  }) = _Profile;
  
  factory Profile.fromJson(Map<String, dynamic> json) => _$ProfileFromJson(json);
}
```

### Repository pattern

```dart
// lib/data/repositories/competition_repository.dart
class CompetitionRepository {
  final SupabaseClient _client;
  
  CompetitionRepository(this._client);
  
  Future<List<Competition>> getActiveCompetitions() async {
    final response = await _client
      .from('competitions')
      .select()
      .eq('status', 'open_for_registration')
      .order('start_date', ascending: true);
    
    return response.map(Competition.fromJson).toList();
  }
  
  Stream<List<Competition>> watchActiveCompetitions() {
    return _client
      .from('competitions')
      .stream(primaryKey: ['id'])
      .eq('status', 'open_for_registration')
      .order('start_date')
      .map((data) => data.map(Competition.fromJson).toList());
  }
}
```

### Widgets

```dart
// ✅ BON : widget stateless pur
class CompetitionCard extends StatelessWidget {
  const CompetitionCard({super.key, required this.competition});
  
  final Competition competition;
  
  @override
  Widget build(BuildContext context) {
    return Card(/* ... */);
  }
}

// ✅ BON : Consumer pour Riverpod
class HomePage extends ConsumerWidget {
  const HomePage({super.key});
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    
    return user.when(
      data: (profile) => _buildContent(profile),
      loading: () => const ArenaLoadingIndicator(),
      error: (e, _) => ErrorState(message: e.toString()),
    );
  }
}
```

### Gestion des erreurs

```dart
// ✅ BON : try-catch avec gestion fine
Future<void> signIn(String email, String password) async {
  try {
    await _client.auth.signInWithPassword(email: email, password: password);
  } on AuthException catch (e) {
    // Erreur Supabase Auth spécifique
    throw FriendlyAuthException(_translateAuthError(e));
  } on Exception catch (e) {
    // Erreur générique
    Sentry.captureException(e);  // Log to Sentry
    throw FriendlyException('Une erreur est survenue. Réessaye.');
  }
}
```

### Internationalisation

```dart
// ❌ MAUVAIS : strings en dur
Text('Bonjour')

// ✅ BON : via AppLocalizations
Text(context.l10n.hello)

// Dans app_fr.arb
{
  "hello": "Bonjour"
}
```

---

## ✅ Checklist qualité par phase

À cocher AVANT de passer à la phase suivante :

### Code quality
- [ ] Aucun warning du linter (`very_good_analysis`)
- [ ] Pas de `print()` (utilise `debugPrint` ou Sentry)
- [ ] Pas de TODOs critiques restants
- [ ] Code commenté en anglais
- [ ] Noms explicites (pas de `temp`, `data`, `obj`)

### Architecture
- [ ] Respecte la structure des dossiers
- [ ] Repository pour accès données (pas de Supabase direct dans les pages)
- [ ] Providers Riverpod pour le state
- [ ] Modèles Freezed pour les données

### UI/UX
- [ ] Loading states partout
- [ ] Empty states partout
- [ ] Error states avec retry
- [ ] Animations fluides (60 FPS)
- [ ] Responsive (testé sur 2 tailles d'écran)

### Sécurité
- [ ] Aucun secret dans le code
- [ ] RLS activée sur toutes les tables touchées
- [ ] Validation côté serveur (pas seulement client)

### Tests
- [ ] Tests manuels effectués (cf. critères de la phase)
- [ ] Tests unitaires si applicable
- [ ] Pas de régression sur les phases précédentes

### Git
- [ ] Commit avec message clair (`feat: PHASE X - description`)
- [ ] Branche dédiée si phase complexe
- [ ] Pull request review (si team)

---

# PARTIE 8 — WORKFLOW CLAUDE CODE

## 💻 Comment travailler efficacement avec Claude Code dans Cursor

### Setup quotidien

1. **Ouvre Cursor** sur le dossier ARENA
2. **Vérifie l'état du projet** :
   ```bash
   git status              # Y a-t-il des changements non committés ?
   git log --oneline -5    # Les 5 derniers commits
   flutter pub get         # Sync les dépendances
   ```
3. **Lance Claude Code** : `Ctrl+L`
4. **Donne-lui le contexte** (prompt initial)

### Le prompt initial parfait

```
Salut Claude. Je travaille sur ARENA, plateforme de tournois e-sport mobile.

📚 LECTURES OBLIGATOIRES :
1. Lis ARENA_MASTER_PROMPT.md (au moins la PARTIE 6 PHASE X)
2. Vérifie l'état actuel : ls -la lib/

🎯 Aujourd'hui : PHASE [X] - [Nom de la phase]

📋 Avant de coder, dis-moi :
- Tes sous-étapes prévues
- Les fichiers que tu vas créer/modifier
- Les tests que je devrai effectuer

⚠️ Règles non-négociables :
- Stack imposée (pas de substitution de libs)
- Code commenté en anglais
- Demande validation après chaque sous-étape
- web_search si tu hésites sur une API
```

### Prompts par phase (templates)

#### Template phase simple

```
Claude, PHASE [X] : [Nom].

Lis ARENA_MASTER_PROMPT.md PARTIE 6 PHASE [X].

Procède dans cet ordre :
1. [Sous-étape 1]
2. [Sous-étape 2]
3. ...

Demande-moi de tester APRÈS chaque sous-étape avant de continuer.
```

#### Template phase complexe (PHASE 8 par exemple)

```
Claude, PHASE 8 : Anti-cheat + Streaming (LA PLUS COMPLEXE).

⚠️ Cette phase nécessite du code natif Android (Kotlin) et iOS (Swift).
Si tu hésites sur une API, utilise web_search.

Lis :
- ARENA_MASTER_PROMPT.md PARTIE 6 PHASE 8
- ARENA_FLUTTER_PROMPT.md ligne 3217+ (détails)

Procède SOUS-PHASE par SOUS-PHASE (8.1 → 8.7).
APRÈS CHAQUE sous-phase, demande-moi de tester avant de continuer.

Tests obligatoires sur devices physiques :
- Android (vrai jeu installé)
- iPhone (compte Apple Dev requis)
```

### Anti-blocages : que faire si...

#### Claude Code invente une lib qui n'existe pas

```
Stop. Cette lib n'existe pas. Vérifie avec web_search la lib correcte 
pour [besoin]. Respecte la stack du master prompt PARTIE 2.
```

#### Claude Code propose une stack différente

```
Non, on respecte STRICTEMENT la stack imposée du master prompt.
Pas de substitution. Lis ARENA_MASTER_PROMPT.md PARTIE 2 et utilise 
[lib correcte].
```

#### Claude Code code 500 lignes d'un coup

```
Stop. C'est trop pour un seul go. Découpe en sous-étapes plus petites.
Implémente d'abord [première sous-étape] et demande-moi de tester.
```

#### Claude Code ne lit pas le master prompt

```
Tu n'as pas lu le master prompt. Lis ARENA_MASTER_PROMPT.md ligne X-Y 
AVANT de coder. C'est obligatoire pour ce projet.
```

#### Claude Code se perd sur l'architecture

```
Tu te perds. Reviens à la PARTIE 2 du master prompt qui définit 
l'architecture. Le fichier doit aller dans [chemin exact selon arbo].
```

#### Claude Code donne du code obsolète

```
Vérifie avec web_search la version actuelle de [lib]. L'API a peut-être 
changé. La doc à jour est sur [docs.flutter.dev / docs.supabase.com].
```

### Stratégie de validation phase par phase

```
┌──────────────────────────────────────────────────┐
│  AVANT DE COMMENCER UNE PHASE                    │
│                                                  │
│  1. Lire les critères d'acceptation              │
│  2. Vérifier que la phase précédente est OK      │
│  3. Backup Git (commit propre avant)             │
│  4. Donner le prompt à Claude Code               │
└──────────────────────────────────────────────────┘
                    ↓
┌──────────────────────────────────────────────────┐
│  PENDANT LA PHASE                                │
│                                                  │
│  - Test manuel après chaque sous-étape           │
│  - Si bug : screenshot + description précise      │
│  - Ne pas accepter aveuglément le code           │
│  - Lire le code généré (pour apprendre)          │
└──────────────────────────────────────────────────┘
                    ↓
┌──────────────────────────────────────────────────┐
│  FIN DE PHASE                                    │
│                                                  │
│  1. Cocher TOUS les critères d'acceptation       │
│  2. Test régression (PHASE précédente toujours OK?)│
│  3. Commit Git avec message clair                │
│  4. Update README progress                       │
│  5. Pause de 30 min minimum avant phase suivante │
└──────────────────────────────────────────────────┘
```

### Tips pour rester efficace

1. **Une phase = un commit propre** (pas de "WIP" qui traîne)
2. **Pause toutes les 2h** (cerveau frais = moins de bugs)
3. **Test sur device physique** dès que possible
4. **Garder un journal** des bugs/solutions (markdown)
5. **Pas plus de 8h/jour** (au-delà, qualité chute)
6. **Commit après chaque sous-étape** (rollback facile)
7. **Avant de demander à Claude Code, essaie 5 min toi-même**
8. **Lire le code généré** (pour monter en compétence)

---

# PARTIE 9 — CONFORMITÉ LÉGALE

## ⚖️ Documents légaux requis avant lancement

> 🚨 **CRITIQUE** : ces documents sont **OBLIGATOIRES** pour Apple App Store et Google Play Store. Sans eux = rejet.

### 1. Conditions Générales d'Utilisation (CGU)

**Sections obligatoires** :
- Présentation de l'éditeur (toi, RCCM Cameroun)
- Description du service ARENA
- Inscription et compte (conditions d'âge : 13+)
- Règles de comportement (anti-triche, anti-harassment)
- Sanctions (warnings, mute, ban)
- Paiements et gains (frais, payouts, fiscalité)
- Propriété intellectuelle (Konami, EA Sports)
- Limitation de responsabilité
- Droit applicable (droit camerounais OHADA)
- Tribunaux compétents (Cameroun)

**Outils recommandés** :
- **Termly** : 11 $/mois — génère CGU adaptées
- **iubenda** : 27 $/mois — plus complet, multilingue
- **Avocat camerounais** : 200 000 - 500 000 XAF (recommandé)

### 2. Politique de Confidentialité (Privacy Policy)

**Sections obligatoires** :
- Identité du responsable de traitement
- Données collectées (email, username, pays, paiements)
- Finalités (organiser tournois, traiter paiements)
- Base légale (consentement, contrat, intérêt légitime)
- Tiers (Supabase, Agora, CinetPay, Firebase, Sentry)
- Durée de conservation
- Droits utilisateur (accès, rectification, suppression, portabilité)
- Cookies/Tracking
- Transferts internationaux (Supabase = USA)
- Contact DPO si applicable

### 3. Mentions légales (Cameroun)

Obligatoires pour le e-commerce (loi 2010/021) :
- Nom de l'éditeur
- Adresse complète
- Téléphone et email
- RCCM (Registre de Commerce)
- Numéro TVA si assujetti
- Hébergeur (Supabase Inc., Delaware, USA)

### 4. Code de conduite communautaire

Recommandé (bonne pratique) :
- Comportements attendus (fair-play, respect)
- Comportements interdits (insultes, harassment, multi-comptes)
- Sanctions progressives
- Procédure d'appel

## 🚨 Question critique : ARENA = jeu d'argent ?

**Au Cameroun** :
- Ordonnance n° 90/006 sur les loteries
- Décret n° 90/1359 jeux de hasard
- Si qualifié "jeu de hasard" → licence obligatoire MINFI

**Argument pro-ARENA (PAS un jeu de hasard)** :
- ✅ **Tournois de skill** : résultat dépend de la compétence
- ✅ **Paiement = participation**, pas pari
- ✅ **Modèle similaire** aux tournois tennis/échecs payants
- ⚠️ **Mais** : nuancé selon les juridictions

**Recommandations** :
1. **Consulter un avocat camerounais** (essentiel)
2. Déclarer comme "plateforme de tournois e-sport"
3. Frais d'inscription = participation, pas mise
4. Gains = prix de compétition, pas gains de pari
5. Pas de "cote" ou vocabulaire de pari sportif
6. Limiter aux jeux de skill (pas roulette)

**Si en doute** : commencer en compétitions GRATUITES uniquement (V1.0 sans paiement) pour valider concept avant.

## 💰 Fiscalité Cameroun

**Taxes à anticiper** :
- TVA : 19,25% (si CA > 50M XAF/an)
- Impôt sur le revenu (selon statut)
- Retenues sur gains joueurs (au-delà d'un seuil)

**Bonnes pratiques** :
- Gardez la trace de tous les paiements
- Conservez les reçus CinetPay/NowPayments
- Comptable dès le 6e mois (200 000 XAF/an min)
- Compte bancaire pro (pas perso)

---

# PARTIE 10 — RÉFÉRENCES

## 📚 Fichiers du projet ARENA

| Fichier | Description | Lignes |
|---------|-------------|--------|
| `ARENA_MASTER_PROMPT.md` | **CE FICHIER** — Référence master | ~3000 |
| `ARENA_FLUTTER_PROMPT.md` | Détails techniques approfondis | ~6500 |
| `GUIDE_PHASE_0.md` | Guide pas-à-pas Phase 0 | ~870 |
| `arena_41_screens.html` | Mockups 47 écrans | ~2270 |
| `arena_brackets_schemas.html` | Documentation brackets (3 formats) | ~1830 |
| `arena_match_config.html` | Mockup config phase de groupes | ~700 |
| `arena_automation.html` | Visualisation automatisation 5 axes | ~1500 |
| `arena_admin_payouts.html` | Mockup AdminPayoutsPage | ~900 |
| `arena_streaming_chat_final.html` | Architecture streaming + chat hybride | ~1100 |
| `arena_critical_screens.html` | Mockups onboarding + auth + delete | ~700 |

## 🌐 Documentation officielle

| Tech | Lien |
|------|------|
| Flutter | https://docs.flutter.dev |
| Dart | https://dart.dev/guides |
| Supabase | https://supabase.com/docs |
| Riverpod | https://riverpod.dev |
| GoRouter | https://pub.dev/packages/go_router |
| Freezed | https://pub.dev/packages/freezed |
| Agora RTM | https://docs.agora.io/en/rtm-flutter |
| Agora RTC | https://docs.agora.io/en/video-calling/get-started |
| Sentry Flutter | https://docs.sentry.io/platforms/flutter/ |
| Firebase | https://firebase.google.com/docs/flutter |
| CinetPay | https://docs.cinetpay.com |
| NowPayments | https://documenter.getpostman.com/view/7907941/S1a32n38 |

## 🛠️ Outils recommandés

| Besoin | Outil | Lien |
|--------|-------|------|
| IDE | Cursor | https://cursor.com |
| Assistant IA | Claude Code (intégré Cursor) | - |
| Version control | Git + GitHub | https://github.com |
| Design system inspiration | Figma | https://figma.com |
| Animations Lottie | LottieFiles | https://lottiefiles.com |
| Génération CGU/Privacy | Termly | https://termly.io |
| Status page | UptimeRobot | https://uptimerobot.com |
| Analytics (V1.5) | PostHog | https://posthog.com |
| Crash reporting | Sentry | https://sentry.io |

## 📖 Glossaire

| Terme | Définition |
|-------|------------|
| **Bracket** | Arbre du tournoi (élimination) |
| **Single Elim** | Single Elimination — tu perds, tu sors |
| **Round Robin** | Tous contre tous |
| **Groupes + KO** | Phase de groupes puis KO |
| **HOME** | Joueur qui crée la room eFootball |
| **AWAY** | Joueur qui rejoint la room |
| **Match Room** | Système ARENA pour gérer un match |
| **Code room** | Code à 6 caractères eFootball |
| **Bouton flottant** | Overlay anti-cheat par-dessus le jeu |
| **Recording** | Enregistrement local du match |
| **Streaming** | Diffusion live via Agora RTC |
| **TOTP** | 2FA Google Authenticator |
| **Edge Function** | Fonction serverless Supabase (Deno) |
| **RLS** | Row Level Security (Postgres) |
| **Flavor** | Build variant Flutter (user/admin) |
| **MoMo** | Mobile Money (MTN, Orange, Wave) |
| **KYC** | Know Your Customer (vérification identité) |
| **CGU** | Conditions Générales d'Utilisation |
| **RGPD** | Règlement Général sur la Protection des Données |

## 🎯 Checklist finale avant lancement V1.0

### Technique
- [ ] Toutes les phases 0 → 13 complètes
- [ ] Tests automatisés ≥ 60% coverage
- [ ] Sentry configuré et testé
- [ ] RLS activée sur toutes les tables
- [ ] Edge Functions déployées et testées
- [ ] Builds release Android + iOS OK

### Comptes & services
- [ ] Compte Supabase Pro (recommandé)
- [ ] Compte Firebase
- [ ] Compte Agora (App ID + App Certificate)
- [ ] Compte CinetPay (production)
- [ ] Compte NowPayments
- [ ] Compte Sentry
- [ ] Apple Developer Account (99 €/an)
- [ ] Google Play Developer Account (25 $ une fois)

### Légal
- [ ] CGU rédigées et publiées
- [ ] Privacy Policy rédigée et publiée
- [ ] Mentions légales publiées
- [ ] RCCM Cameroun (entreprise enregistrée)
- [ ] Avocat consulté (qualification jeu de hasard)
- [ ] Compte bancaire pro ouvert

### Marketing
- [ ] Site web ARENA (landing page)
- [ ] Captures stores (8 par plateforme)
- [ ] Description marketing FR
- [ ] Logo + assets graphiques
- [ ] Compte Instagram + TikTok pour V1.0

### Opérations
- [ ] Status page (UptimeRobot)
- [ ] Plan de support (WhatsApp Business ?)
- [ ] FAQ rédigée
- [ ] Procédure de gestion des litiges documentée
- [ ] Email pro (support@arena-app.com)

---

# 🚀 GO!

Ce document est ton **référentiel master**. Reviens-y à chaque étape.

À ce stade, tu as :
- ✅ Une vision claire du projet
- ✅ Une architecture professionnelle
- ✅ Un inventaire de 47 écrans
- ✅ Un schéma de 26 tables SQL
- ✅ 16 Edge Functions documentées
- ✅ 21 phases de développement structurées
- ✅ Des règles de sécurité non-négociables
- ✅ Un workflow Claude Code optimisé
- ✅ Une checklist conformité légale
- ✅ Des références complètes

**Bonne chance avec ARENA ! Tu as tout ce qu'il faut pour réussir.** 🏆

---

> 📝 **Version** : 1.1 (mai 2026)
> 🔄 **Dernière mise à jour** : correction des incohérences avec le SQL d'`ARENA_FLUTTER_PROMPT.md`
> 👨‍💻 **Conçu par** : développeur senior Flutter (10 ans d'XP)
> 🎯 **Pour** : développeur débutant motivé, basé au Cameroun
> 🚀 **Objectif** : lancer ARENA V1.0 en 4-8 semaines

---

## 📋 Changelog

### v1.1 (mai 2026)
- ✅ Correction du nombre de tables : 23 → **26** (3 tables manquantes : `competition_registrations`, `streams`, et confusion `phases`/`competition_phases`)
- ✅ Renommage `competition_phases` → `phases` (alignement avec le SQL réel)
- ✅ Ajout de `competition_registrations` (inscriptions joueurs)
- ✅ Ajout de `streams` (sessions streaming/recording)
- ✅ Mise à jour de la définition `profiles` (ajout `seed`, `invited_by`, `last_totp_used`, etc.)
- ✅ Ajout d'un **ordre de création des tables** par étapes (respect des FK)
- ✅ Mise à jour du diagramme relationnel

### v1.0 (mai 2026)
- 🎉 Version initiale du master prompt

