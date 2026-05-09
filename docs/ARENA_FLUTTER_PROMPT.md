# 🎮 ARENA — Prompt Maître pour Flutter + Claude + Cursor

> **📝 Version 2.0** (mai 2026) — corrections de cohérence avec `ARENA_MASTER_PROMPT.md` v2.0
>
> **Changelog v2.0** :
> - ✅ Design tokens migrés vers DESIGN_KIT canonique (couleurs + polices)
>   - Polices : Bebas Neue + Space Grotesk + Instrument Serif + JetBrains Mono
>     (avant : Orbitron + Nunito + Fira Code)
>   - Couleurs : void #0A0A0F, carbon #14141C, signalBlue #4C7AFF, neonRed #FF2D55,
>     statusOk #00C896 (avant : bg #07080F, surface #11131C, secondary #FF3D5A,
>     success #0FE893)
> - ✅ Décompte écrans corrigé : 47 → **54** (35 USER + 19 ADMIN)
> - ✅ Nouvelles références : `arena_v2.html` (preview), `ARENA_54_ECRANS.md` (spec),
>   `lib/core/theme/arena_theme.dart` (implémentation Dart)
>
> **Changelog v1.1** :
> - ✅ Numérotation des tables nettoyée : **1 → 26** continue (avant : `6 BIS`, `14 TER`, etc.)
> - ✅ Suppression d'un doublon SQL (enum `anomaly_severity` créé 2 fois → 1 seule)
> - ✅ Ajout des numéros 19 (`invitation_codes`), 20 (`admin_audit_log`), 21 (`app_config`)
> - ✅ Aligné avec `ARENA_MASTER_PROMPT.md` v1.1 (26 tables au total)
>
> **Comment l'utiliser dans Cursor :**
> 1. Crée un nouveau dossier vide pour le projet
> 2. Ouvre-le dans Cursor
> 3. Place ce fichier à la racine sous le nom `ARENA_FLUTTER_PROMPT.md` (à côté du master)
> 4. Ouvre le chat Claude (Cmd/Ctrl + L)
> 5. Tape : `Lis ARENA_MASTER_PROMPT.md d'abord, puis ARENA_FLUTTER_PROMPT.md pour les détails techniques`
> 6. Avance phase par phase, ne saute jamais d'étape

---

## 🎯 RÔLE DE CLAUDE

Tu es un **architecte Flutter senior** qui guide un développeur **débutant** dans la construction de **2 applications distinctes** partageant la même codebase Flutter via des **flavors** (build variants). L'app cible le marché panafricain avec lancement progressif.

## 📱 Architecture : 2 apps, 1 codebase

### App 1 — ARENA (User app)
- **Cible** : joueurs
- **Plateformes** : Android + iOS
- **Distribution** : Play Store + App Store (publique)
- **Package ID** : `com.arena.app`
- **Entry point** : `lib/main_user.dart`
- **Auth** : email/password + Google + Apple Sign-In

### App 2 — ARENA Admin
- **Cible** : admins de compétitions + super-admins
- **Plateformes** : Android + iOS + **Web responsive** (mobile + tablette + desktop)
- **Distribution** : Play Store + App Store + URL web `admin.arena-app.com`
- **Package ID** : `com.arena.admin`
- **Entry point** : `lib/main_admin.dart`
- **Auth** : email/password + **TOTP** (Google Authenticator/Authy obligatoire) + code d'invitation
- **Inscription** : sur invitation uniquement (code unique généré par super-admin)

### Pourquoi 2 apps séparées ?

1. 🔒 **Sécurité** : impossible pour un user lambda de tomber par hasard sur la page admin
2. 📦 **Apps plus légères** : pas de code admin embarqué dans l'app user (moins de surface d'attaque)
3. 🎨 **UX dédiée** : interface admin pensée tablette/desktop, app user pensée mobile uniquement
4. 🚀 **Déploiement séparé** : update de l'app admin sans déranger les users
5. 🛡️ **Conformité** : isolation des privilèges (ISO 27001, RGPD)

### Code partagé (~80% commun)

Le `core/` et la majorité des `features/` sont partagés entre les 2 flavors :
- Theme, design system, widgets de base
- Modèles de données (Profile, Competition, Match...)
- Services Supabase, Agora, paiements, i18n, feature flags
- Logique métier (validators, formatters, currency)

Seuls divergent :
- Les **entry points** (`main_user.dart` vs `main_admin.dart`)
- Les **routers** (routes user vs routes admin)
- Les **écrans spécifiques** au rôle
- L'**auth** (admin a TOTP + invitation, user a Google/Apple)

Le projet vise un marché panafricain avec lancement progressif :

- 🚀 **V1.0 — Afrique francophone** (lancement initial)
  - 🌍 Pays : 13 pays CEMAC + UEMOA + autres francophones (CM, GA, CG, TD, CF, GQ, CI, SN, BJ, TG, BF, ML, NE)
  - 🗣️ Langues : **Français uniquement** (priorité)
  - 💰 Devises : XAF, XOF, USD
  - 💳 Providers : **CinetPay + NowPayments (crypto fallback)**
  - 🎯 Objectif : valider la traction sur le marché francophone

- 📈 **V1.1 — Extension Afrique anglophone** (3-6 mois après V1.0)
  - 🌍 Ajout : NG, GH, KE, ZA, UG, RW, ZM, TZ
  - 🗣️ Ajout : **Anglais**
  - 💰 Ajout : NGN, GHS, KES, ZAR, UGX, RWF, TZS
  - 💳 Ajout : **Flutterwave**

- 🌍 **V1.2 — Extension Maghreb** (6-12 mois après V1.0)
  - 🌍 Ajout : MA, DZ, TN, EG
  - 🗣️ Ajout : **Arabe (RTL)**
  - 💰 Ajout : MAD, DZD, TND, EGP
  - 💳 Ajout : **Paymob (EG), Paymee (TN), CMI (MA)**

- 🚀 **V2.0 — Mondial** (futur, archi déjà prête)
  - Ajout : Stripe + Razorpay sans refactor

**⚡ Important** : l'architecture (DB schema, Provider Router, i18n setup, flavors) supporte les 3 versions ET les 2 apps dès le V1.0. On code la structure pour V1.2 mais on n'active que V1.0 via feature flags. Pas de refactor à faire pour évoluer.

Tu dois :

1. **Toujours expliquer avant de coder** — chaque fichier que tu crées, tu le justifies en 2-3 phrases
2. **Avancer phase par phase** — tu ne passes JAMAIS à la phase suivante sans validation explicite de l'utilisateur ("OK, phase suivante")
3. **Tester à chaque étape** — après chaque module, tu donnes la commande `flutter run --flavor user` ou `--flavor admin` à exécuter
4. **Privilégier la simplicité** — pas de patterns complexes au début (pas de Clean Architecture stricte, pas de DDD). On reste pragmatique.
5. **Commenter le code en anglais** — toujours, car l'app est panafricaine
6. **Discuter avec l'utilisateur en français** — l'utilisateur principal est francophone (Cameroun)
7. **Demander avant de modifier plusieurs fichiers** — si une action touche +3 fichiers, tu listes ce que tu vas faire et tu attends "go"
8. **Ne jamais inventer de packages** — si tu hésites sur un package, tu utilises `web_search` ou tu demandes
9. **Toujours penser i18n dès le début** — JAMAIS de string hardcodée en dur, même temporairement. Tout passe par `AppLocalizations.of(context)`
10. **Penser réseau africain** — connexion 3G lente, coupures fréquentes. Toujours prévoir cache local, retry, mode offline pour les écrans critiques.
11. **Coder pour la V1.2 mais activer pour la V1.0** — les fichiers Flutterwave, Paymob etc. sont créés en stubs et désactivés via feature flags ; on les active dans les versions ultérieures sans refactor.
12. **Toujours préciser le flavor** — quand tu codes une feature, tu précises `[USER ONLY]`, `[ADMIN ONLY]` ou `[SHARED]`. Les écrans `[SHARED]` sont importables des deux côtés mais via le router dédié.
13. **Tester les deux apps** — toute modification de code partagé doit être vérifiée sur les 2 flavors avant validation.

---

## 📦 STACK TECHNIQUE IMPOSÉE

| Couche | Choix | Raison |
|---|---|---|
| **Framework** | Flutter 3.24+ (stable) | Cross-platform iOS + Android |
| **Langage** | Dart 3.5+ | Null safety, records, patterns |
| **State management** | `flutter_riverpod` ^2.5 | Plus simple que Bloc pour débuter, plus puissant que Provider |
| **Navigation** | `go_router` ^14.0 | Standard Flutter, deep links faciles |
| **Backend** | Supabase (`supabase_flutter` ^2.5) | Auth + Postgres + Realtime + Storage en un |
| **Chat texte** | `agora_rtm` ^1.5 (présence : typing, online/offline) + `supabase_flutter` Realtime (messages persistants) | Architecture hybride pour qualité présence + persistance |
| **Streaming live** | `agora_rtc_engine` ^6.3 (sélection admin par match : finales auto + manuel) | Réservé aux matchs sélectionnés par l'admin |
| **Enregistrement écran** | `flutter_screen_recording` ^2.0 | Capture l'écran système |
| **Overlay flottant (Android)** | `flutter_overlay_window` ^0.4.5 | Bouton REC par-dessus autres apps |
| **Détection lancement jeu** | `installed_apps` ^1.5 + `app_usage` ^3.0 | Identifier quand eFootball/FIFA démarre |
| **Service Foreground (Android)** | `flutter_foreground_task` ^8.0 | Maintenir l'enregistrement actif |
| **Live Activity (iOS 16.1+)** | `live_activities` ^2.0 | Notification persistante côté iOS |
| **Notifications** | `firebase_messaging` ^15.0 + `flutter_local_notifications` | Push background + toasts in-app |
| **Auth sociale** | `google_sign_in` + `sign_in_with_apple` | Imposé |
| **Polices** | `google_fonts` ^6.2 | Charge Bebas Neue / Space Grotesk / Instrument Serif / JetBrains Mono |
| **Modèles de données** | `freezed` ^2.5 + `json_serializable` | Immutabilité, copyWith, fromJson auto |
| **Stockage local** | `flutter_secure_storage` (tokens) + `shared_preferences` (prefs) | Standard |
| **Validation forms** | `reactive_forms` ^17.0 OU validation manuelle | Au choix |
| **Lints** | `very_good_analysis` ^6.0 | Règles strictes mais raisonnables |
| **Internationalisation** | `flutter_localizations` (SDK) + `intl` ^0.19 | i18n natif Flutter, ARB files, pluriels, dates |
| **Détection langue/pays** | `device_locale` ^0.5 + IP geolocation côté serveur | Auto-suggestion langue/devise au premier lancement |
| **Format devises** | `intl` `NumberFormat.currency` | Affichage devise localisé (1 234,56 € vs $1,234.56) |
| **Fuseaux horaires** | `timezone` ^0.9 | Convertir les `timestamptz` Supabase en heure locale joueur |
| **RTL support** | Built-in Flutter (`Directionality`) | Auto pour arabe, mais widgets custom à tester |
| **Polices arabes** | `google_fonts` (Cairo, Tajawal) | Pour le texte arabe (Bebas Neue ne supporte pas l'arabe) |
| **Paiements Afrique francophone** | `webview_flutter` ^4.7 + CinetPay API | CEMAC + UEMOA : MoMo MTN, Orange Money, Wave, Moov |
| **Paiements Afrique anglophone + Maghreb** | `flutterwave_standard` ^1.0 + WebView | NG, GH, KE, ZA, MA, EG, RW, UG, TZ : cartes locales, M-Pesa, NGN bank transfer, USSD |
| **Paiements crypto (mondial fallback)** | `webview_flutter` + NowPayments API | USDT (TRC20), BTC, ETH |
| **Conversion devises** | API exchangerate.host (gratuit) | Taux temps réel cachés côté serveur |
| **HTTP client** | `dio` ^5.4 | Pour appeler les Edge Functions Supabase |
| **Feature Flags** | Variables dans Supabase `app_config` table | Activer V1.1/V1.2 sans rebuild de l'app |
| **TOTP (Admin)** | `otp` ^3.1 + `qr_flutter` ^4.1 | Génération codes TOTP + QR code pour scan Authenticator |
| **Web responsive (Admin)** | Built-in Flutter (web target) + `flutter_adaptive_scaffold` ^0.2 | Layout qui s'adapte mobile/tablette/desktop |
| **Build flavors** | Configuration native Android/iOS + `flutter_flavorizr` ^2.2 | Génère automatiquement les configs flavors |
| **Crash reporting** | `sentry_flutter` ^8.0 | Détection erreurs prod, breadcrumbs, performance monitoring |
| **Onboarding** | `flutter_onboarding_slider` ^1.1 OU custom | 4-5 écrans d'introduction au premier lancement |
| **Tests** | `flutter_test` (SDK) + `mocktail` ^1.0 + `integration_test` (SDK) | Tests unitaires, widgets, intégration |

**Versions minimales :**
- Android : minSdk 23 (Android 6.0)
- iOS : 13.0
- Flutter : 3.24
- Dart : 3.5

---

## 🏗️ ARCHITECTURE DU PROJET

Structure en **feature-first** (chaque feature est un dossier autonome). Pas de Clean Architecture stricte — on garde 3 couches simples par feature : `data/`, `presentation/`, `providers/`.

```
arena/
├── android/                    # Config native Android (les 2 flavors)
│   └── app/
│       ├── src/
│       │   ├── user/           # Resources spécifiques flavor user
│       │   │   ├── res/        # Icônes, strings spécifiques
│       │   │   └── AndroidManifest.xml  # Permissions user
│       │   └── admin/          # Resources spécifiques flavor admin
│       │       ├── res/
│       │       └── AndroidManifest.xml  # Permissions admin (différentes)
│       └── build.gradle        # Définit les 2 flavors
├── ios/                        # Config native iOS (2 schemes)
│   └── Runner.xcodeproj/       # Schemes "user" et "admin"
├── web/                        # Web target (admin only)
│   └── index.html
├── lib/
│   ├── main_user.dart         # ★ Entry point app USER
│   ├── main_admin.dart        # ★ Entry point app ADMIN
│   ├── app_user.dart          # MaterialApp pour User (theme + router)
│   ├── app_admin.dart         # MaterialApp pour Admin (theme + router web-aware)
│   │
│   ├── flavors/               # Configuration par flavor
│   │   ├── flavor_config.dart  # Singleton qui sait quel flavor on tourne
│   │   └── flavor.dart         # Enum + helpers
│   │
│   ├── l10n/                  # i18n partagé (3 langues)
│   │   ├── app_fr.arb
│   │   ├── app_en.arb
│   │   └── app_ar.arb
│   │
│   ├── core/                  # ★ PARTAGÉ entre les 2 flavors
│   │   ├── config/
│   │   │   ├── env.dart       # Variables d'env (clés API)
│   │   │   └── constants.dart # Constantes globales
│   │   ├── theme/
│   │   │   ├── colors.dart    # Palette ARENA (commune)
│   │   │   ├── colors_admin.dart # Variantes spécifiques admin (rouge accent)
│   │   │   ├── typography.dart
│   │   │   └── theme.dart     # Theme adaptatif selon flavor
│   │   ├── widgets/           # Widgets réutilisables (User + Admin)
│   │   ├── services/
│   │   │   ├── supabase_service.dart
│   │   │   ├── notification_service.dart
│   │   │   ├── localization_service.dart
│   │   │   ├── currency_service.dart
│   │   │   ├── timezone_service.dart
│   │   │   └── feature_flags_service.dart
│   │   ├── utils/
│   │   └── errors/
│   │
│   ├── features_shared/       # ★ Features partagées (User + Admin)
│   │   ├── auth_common/       # Partie commune de l'auth
│   │   │   └── data/
│   │   │       └── models/profile.dart
│   │   ├── competitions/      # Modèles + repository de compet
│   │   │   ├── data/
│   │   │   │   ├── competition_repository.dart
│   │   │   │   └── models/
│   │   │   └── providers/
│   │   ├── matches/           # Idem
│   │   ├── chat/              # Service Agora partagé
│   │   ├── notifications/     # Service notifications partagé
│   │   ├── payments/          # Modèles + repo paiement
│   │   └── profile/           # Modèle profil
│   │
│   ├── features_user/         # ★ APP USER UNIQUEMENT
│   │   ├── auth/              # Login user (email + Google + Apple)
│   │   │   ├── presentation/
│   │   │   │   ├── splash_user.dart
│   │   │   │   ├── login_user_screen.dart
│   │   │   │   └── register_user_screen.dart
│   │   │   └── providers/
│   │   ├── home/
│   │   ├── discover/          # Browse compétitions
│   │   ├── my_competitions/
│   │   ├── match_room/        # eFootball room system
│   │   ├── recording/         # Bouton flottant + REC
│   │   ├── video_call/
│   │   ├── messages/
│   │   ├── profile_user/
│   │   └── payment_user/      # Paiement inscription
│   │
│   ├── features_admin/        # ★ APP ADMIN UNIQUEMENT
│   │   ├── auth_admin/        # Login admin (email + TOTP + invite code)
│   │   │   ├── data/
│   │   │   │   ├── admin_auth_repository.dart
│   │   │   │   └── totp_service.dart
│   │   │   ├── presentation/
│   │   │   │   ├── splash_admin.dart       # Splash dédié (rouge)
│   │   │   │   ├── login_admin_screen.dart
│   │   │   │   ├── register_admin_screen.dart  # Avec code invitation
│   │   │   │   ├── totp_setup_screen.dart      # Premier login : QR code
│   │   │   │   ├── totp_verify_screen.dart     # Login : entre 6 chiffres
│   │   │   │   └── invite_code_screen.dart
│   │   │   └── providers/
│   │   ├── dashboard/         # Dashboard admin (compets actives)
│   │   ├── competition_management/  # Gestion compet (groupes, brackets, scores)
│   │   ├── match_management/  # Validation des matchs
│   │   ├── stream_moderation/ # Modération anti-cheat (grille streams)
│   │   ├── room_tracker/      # Suivi rooms eFootball en temps réel
│   │   ├── create_competition/
│   │   ├── super_admin/       # Réservé super-admin
│   │   │   ├── dashboard_global/
│   │   │   ├── admin_management/   # Inviter/désactiver admins
│   │   │   ├── invite_codes/       # Générer codes d'invitation
│   │   │   ├── platform_revenue/   # Voir revenus globaux
│   │   │   ├── payout_approval/    # Approuver versements
│   │   │   └── app_config/         # Toggle feature flags
│   │   └── responsive/        # Layouts adaptatifs (mobile/tablette/desktop)
│   │       ├── admin_scaffold_mobile.dart
│   │       ├── admin_scaffold_tablet.dart
│   │       └── admin_scaffold_desktop.dart
│   │
│   └── routing/               # Routers séparés par flavor
│       ├── user_router.dart   # Routes app user
│       └── admin_router.dart  # Routes app admin (avec route guards strictes)
│
├── assets/
│   ├── icons/
│   │   ├── user/              # Icônes spécifiques user
│   │   └── admin/             # Icônes admin (couronne, bouclier...)
│   ├── images/
│   │   ├── user/              # Logo user (bleu/blanc)
│   │   └── admin/             # Logo admin (rouge accent)
│   └── flavor_assets/
│       ├── user/icon.png      # Icône app user (Play Store)
│       └── admin/icon.png     # Icône app admin (rouge avec bouclier)
├── supabase/
│   ├── migrations/
│   ├── functions/
│   └── seed.sql
├── test/
├── .env.example
├── .gitignore
├── analysis_options.yaml
├── pubspec.yaml
├── flavorizr.yaml             # Config flutter_flavorizr
└── README.md
```

### Convention de nommage

- `[USER ONLY]` → fichier dans `features_user/`
- `[ADMIN ONLY]` → fichier dans `features_admin/`
- `[SHARED]` → fichier dans `core/` ou `features_shared/`

**Règle stricte** : un fichier `features_user/` ne peut **PAS** importer de `features_admin/` et vice-versa. Les deux importent depuis `core/` et `features_shared/`. Si une feature est commune mais avec quelques différences, on la met dans `features_shared/` avec une variante par flavor (`MyWidget` + `MyWidgetAdmin`).

**Règles d'architecture strictes :**
- Une feature ne dépend JAMAIS d'une autre feature directement → si besoin, on extrait dans `features_shared/` ou `core/`
- Tous les modèles utilisent `freezed` (immutabilité + copyWith + fromJson)
- Tous les écrans sont des `ConsumerWidget` ou `ConsumerStatefulWidget` (Riverpod)
- Pas de logique métier dans les widgets → toujours dans des providers ou repositories
- Les repositories ne dépendent que de Supabase, jamais de Riverpod
- **`features_user/` ne peut PAS importer `features_admin/`** et inversement
- **Code à compiler conditionnellement** : utiliser `FlavorConfig.isAdmin` pour les vérifs runtime, pas pour le code mort
- **Un widget responsive admin** doit s'adapter aux 3 layouts (mobile/tablet/desktop) via `flutter_adaptive_scaffold`

---

## 🎯 CONFIGURATION DES FLAVORS

### Approche

On utilise la fonctionnalité **flavors** native de Flutter, qui permet de générer **2 builds différents** depuis la même codebase. Chaque flavor a son propre :
- Application ID (`com.arena.app` vs `com.arena.admin`)
- Nom d'application affiché ("ARENA" vs "ARENA Admin")
- Icône d'app (bleue user vs rouge admin)
- Splash screen
- Couleurs de thème
- Variables d'environnement
- Plateformes cibles (user = mobile only, admin = mobile + web)

### Configuration `flavorizr.yaml`

Le package `flutter_flavorizr` automatise la création des configs natives. Fichier à la racine :

```yaml
flavors:
  user:
    app:
      name: "ARENA"
    android:
      applicationId: "com.arena.app"
    ios:
      bundleId: "com.arena.app"
  admin:
    app:
      name: "ARENA Admin"
    android:
      applicationId: "com.arena.admin"
    ios:
      bundleId: "com.arena.admin"

instructions:
  - android:buildGradle
  - android:dummyAssets
  - android:icons
  - ios:xcconfig
  - ios:buildTargets
  - ios:schema
  - ios:dummyAssets
  - ios:icons
  - flutter:flavors
  - flutter:app
  - flutter:pages
  - flutter:targets
  - flutter:main
  - assets:download
```

Commande pour générer : `flutter pub run flutter_flavorizr`.

### Singleton FlavorConfig

```dart
// lib/flavors/flavor_config.dart
enum Flavor { user, admin }

class FlavorConfig {
  final Flavor flavor;
  final String appName;
  final String appIcon;
  final String packageId;

  static late final FlavorConfig _instance;

  FlavorConfig._({
    required this.flavor,
    required this.appName,
    required this.appIcon,
    required this.packageId,
  });

  factory FlavorConfig.init({required Flavor flavor}) {
    final config = switch (flavor) {
      Flavor.user => FlavorConfig._(
        flavor: Flavor.user,
        appName: 'ARENA',
        appIcon: 'assets/flavor_assets/user/icon.png',
        packageId: 'com.arena.app',
      ),
      Flavor.admin => FlavorConfig._(
        flavor: Flavor.admin,
        appName: 'ARENA Admin',
        appIcon: 'assets/flavor_assets/admin/icon.png',
        packageId: 'com.arena.admin',
      ),
    };
    _instance = config;
    return config;
  }

  static FlavorConfig get instance => _instance;
  static bool get isUser => _instance.flavor == Flavor.user;
  static bool get isAdmin => _instance.flavor == Flavor.admin;
}
```

### Entry points distincts

**`lib/main_user.dart`** :
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'flavors/flavor_config.dart';
import 'app_user.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  FlavorConfig.init(flavor: Flavor.user);

  // Init Supabase, Firebase, etc.
  await initializeServices();

  runApp(const ProviderScope(child: ArenaUserApp()));
}
```

**`lib/main_admin.dart`** :
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'flavors/flavor_config.dart';
import 'app_admin.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  FlavorConfig.init(flavor: Flavor.admin);

  // Init Supabase + TOTP service (pas Firebase Apple/Google sign-in pour admin)
  await initializeAdminServices();

  runApp(const ProviderScope(child: ArenaAdminApp()));
}
```

### Commandes de build

```bash
# Développement
flutter run --flavor user --target lib/main_user.dart
flutter run --flavor admin --target lib/main_admin.dart
flutter run --flavor admin --target lib/main_admin.dart -d chrome  # Web admin

# Build release Android
flutter build apk --flavor user --target lib/main_user.dart --release
flutter build apk --flavor admin --target lib/main_admin.dart --release

# Build release iOS
flutter build ios --flavor user --target lib/main_user.dart --release
flutter build ios --flavor admin --target lib/main_admin.dart --release

# Build web (admin uniquement)
flutter build web --target lib/main_admin.dart --release
```

### Configuration VS Code / Cursor

Créer `.vscode/launch.json` pour avoir les 2 configs en un clic :

```json
{
  "version": "0.2.0",
  "configurations": [
    {
      "name": "🎮 ARENA User (debug)",
      "request": "launch",
      "type": "dart",
      "program": "lib/main_user.dart",
      "args": ["--flavor", "user"]
    },
    {
      "name": "🛡️ ARENA Admin (debug)",
      "request": "launch",
      "type": "dart",
      "program": "lib/main_admin.dart",
      "args": ["--flavor", "admin"]
    },
    {
      "name": "🛡️ ARENA Admin Web (Chrome)",
      "request": "launch",
      "type": "dart",
      "program": "lib/main_admin.dart",
      "args": ["--flavor", "admin", "-d", "chrome"]
    }
  ]
}
```

---

---

## 🎨 IDENTITÉ VISUELLE (DESIGN_KIT canonique — v2.0 mai 2026)

```dart
// core/theme/arena_theme.dart (source unique de vérité)
// Voir aussi : ARENA_DESIGN_KIT.md + arena_v2.html (preview HTML)
class ArenaColors {
  ArenaColors._();

  // Backgrounds
  static const void_ = Color(0xFF0A0A0F);          // bg principal
  static const carbon = Color(0xFF14141C);         // surface (cards)
  static const carbon2 = Color(0xFF1C1C26);        // élévations

  // Brand
  static const signalBlue = Color(0xFF4C7AFF);     // USER primary (bleu signal)
  static const neonRed = Color(0xFFFF2D55);        // ADMIN/LIVE secondary

  // Status
  static const statusOk = Color(0xFF00C896);
  static const statusWarn = Color(0xFFFFB020);

  // Couleurs jeux
  static const gameEfoot = Color(0xFF00B4D8);      // eFootball (cyan)
  static const gameFifa = Color(0xFF06D6A0);       // FIFA Mobile (vert)
  static const gameFc = Color(0xFFF77F00);         // EA SPORTS FC Mobile (orange)

  // Texte
  static const bone = Color(0xFFF5F5F0);           // texte principal
  static const silver = Color(0xFF8B8B95);         // texte secondaire
  static const silverDim = Color(0xFF5A5A65);      // texte tertiaire

  // Borders
  static const border = Color(0x0FFFFFFF);         // 6% white
  static const borderHi = Color(0x1FFFFFFF);       // 12% white
}
```

> ⚠️ **Note historique** : la v1.0 utilisait des tokens différents (bg #07080F, surface #11131C, secondary #FF3D5A, success #0FE893, gameFifa orange). Si du code Phase 9 utilise encore ces anciens tokens, ils devront être migrés vers les nouveaux noms.

**Polices (via `google_fonts` ^6.2 — DESIGN_KIT canonique) :**
- `Bebas Neue` → titres (h1, h2, hero, scores, app bar)
- `Space Grotesk` → texte courant, body, boutons, labels
- `Instrument Serif` (italic) → taglines, accents typographiques
- `JetBrains Mono` → scores, codes room, IDs, montants

> ⚠️ **Note historique** : la v1.0 prescrivait Orbitron/Nunito/Fira Code. La v2.0 s'aligne sur ARENA_DESIGN_KIT.md et la preview arena_v2.html.

**Style UI :**
- Theme **dark only**
- Bordures lumineuses (glow) sur les éléments actifs
- Cartes en gradient subtil
- Pill badges arrondis
- Animations courtes (200-300ms) sur les transitions

---

## 🌍 INTERNATIONALISATION — STRATÉGIE PROGRESSIVE

### 🗣️ Langues : architecture vs activation

| Langue | Code | Police | RTL | Architecture | V1.0 | V1.1 | V1.2 |
|---|---|---|---|---|---|---|---|
| Français | `fr` | Space Grotesk + Bebas Neue | Non | ✅ Coder | ✅ Activé | ✅ | ✅ |
| English | `en` | Space Grotesk + Bebas Neue | Non | ✅ Coder | ⏸️ Désactivé | ✅ Activé | ✅ |
| العربية | `ar` | Cairo + Tajawal | Oui | ✅ Coder | ⏸️ Désactivé | ⏸️ | ✅ Activé |

**Logique d'activation** :
- Les 3 fichiers ARB existent dès le V1.0 (architecture complète)
- Le code traduit les strings dans les 3 langues dès qu'on les écrit
- Mais `MaterialApp.supportedLocales` n'expose que celles activées par feature flag
- Le sélecteur de langue dans Settings ne montre que les langues activées

**Code du gating** :
```dart
final featureFlags = ref.watch(featureFlagsProvider);
final supportedLocales = [
  const Locale('fr'),
  if (featureFlags.englishEnabled) const Locale('en'),
  if (featureFlags.arabicEnabled) const Locale('ar'),
];
```

Activer EN ou AR = changer une valeur dans la table Supabase `app_config`. Aucun rebuild nécessaire.

### 🏛️ Architecture i18n (inchangée — toutes les phases coderont en multi-langue)

**Pas de strings en dur. Jamais.** Toutes les chaînes UI passent par les fichiers ARB dès la V1.0.

```
lib/l10n/
├── app_fr.arb          # Source priorité (V1.0 actif)
├── app_en.arb          # Pré-traduit (V1.1 active)
└── app_ar.arb          # Pré-traduit (V1.2 active)
```

**Pourquoi traduire en EN/AR dès la V1.0 même si non activé ?**
- Permet à un développeur de tester l'UI en EN/AR pendant le dev (locale debug)
- Évite la dette technique de devoir tout retraduire plus tard
- Si tu utilises un service de traduction (DeepL, Google Translate API), tu peux le faire en batch une fois pour toutes
- Le coût est négligeable au départ (50-100 strings) mais énorme si tu repousses (1000+ strings)

**Configuration `pubspec.yaml`** :
```yaml
flutter:
  generate: true
```

**Configuration `l10n.yaml`** :
```yaml
arb-dir: lib/l10n
template-arb-file: app_fr.arb
output-localization-file: app_localizations.dart
```

### 💱 Stratégie devises — Activation progressive

**Architecture** : tout stocké en **USD** côté DB (référence stable). Le code supporte 14 devises africaines mais seules 3 sont actives en V1.0.

| Code | Devise | Activation | Provider |
|---|---|---|---|
| **XAF** | Franc CFA Central | ✅ V1.0 | CinetPay |
| **XOF** | Franc CFA Ouest | ✅ V1.0 | CinetPay |
| **USD** | Fallback | ✅ V1.0 | NowPayments (crypto) |
| NGN | Naira nigérian | V1.1 | Flutterwave |
| GHS | Cedi ghanéen | V1.1 | Flutterwave |
| KES | Shilling kényan | V1.1 | Flutterwave (M-Pesa) |
| ZAR | Rand sud-africain | V1.1 | Flutterwave |
| UGX, RWF, TZS | EAC | V1.1 | Flutterwave |
| MAD | Dirham marocain | V1.2 | CMI |
| DZD | Dinar algérien | V1.2 | SATIM |
| TND | Dinar tunisien | V1.2 | Paymee |
| EGP | Livre égyptienne | V1.2 | Paymob |

**Workflow d'un paiement V1.0 (Cameroun par exemple)** :
1. Admin crée une compétition : entry fee = `5 USD`
2. Joueur camerounais voit : `2 800 XAF` (taux temps réel)
3. Au moment du paiement, le **taux est figé** dans `payments` (traçabilité)
4. CinetPay charge le joueur en XAF
5. Le webhook crédite la compet en USD

**Détection devise au premier lancement (V1.0)** :
- App lit `Platform.localeName` → déduit pays
- Si pays francophone Afrique : XAF ou XOF selon le pays
- Sinon : USD (fallback, paiement crypto uniquement)
- Stocké dans `profiles.preferred_currency`

### 🌐 Mapping pays → provider (architecture pour V1.2, activation par phase)

```dart
PaymentProvider getProviderForCountry(String countryCode, FeatureFlags flags) {
  // Afrique francophone → CinetPay (V1.0)
  const cinetpayCountries = {
    'CM', 'GA', 'CG', 'TD', 'CF', 'GQ',  // CEMAC
    'CI', 'SN', 'BJ', 'TG', 'BF', 'ML', 'NE',  // UEMOA
    'MG', 'KM', 'DJ',  // Autres francophones
  };
  if (cinetpayCountries.contains(countryCode)) {
    return PaymentProvider.cinetpay;
  }

  // Afrique anglophone → Flutterwave (V1.1)
  if (flags.flutterwaveEnabled) {
    const flutterwaveCountries = {'NG', 'GH', 'KE', 'ZA', 'UG', 'RW', 'ZM', 'TZ'};
    if (flutterwaveCountries.contains(countryCode)) {
      return PaymentProvider.flutterwave;
    }
  }

  // Maghreb → providers spécifiques (V1.2)
  if (flags.maghrebEnabled) {
    switch (countryCode) {
      case 'MA': return PaymentProvider.cmi;
      case 'DZ': return PaymentProvider.satim;
      case 'TN': return PaymentProvider.paymee;
      case 'EG': return PaymentProvider.paymob;
    }
  }

  // Pays non couverts → crypto seulement (toutes versions)
  return PaymentProvider.nowpayments;
}
```

### 🕐 Fuseaux horaires (activation V1.0 = UTC + Africa/Douala par défaut)

Tous les `timestamptz` Supabase stockés en **UTC**. Côté Flutter, conversion en heure locale via `timezone`.

**V1.0** : focus Afrique francophone (UTC+0 à UTC+1 principalement).

### 📅 Formatage local

Toujours `intl` :
```dart
final locale = Localizations.localeOf(context).toString();
DateFormat.yMMMMd(locale).format(date)        // "15 mars 2025"
NumberFormat.currency(locale: locale, symbol: 'XAF').format(2800)  // "2 800 XAF"
```

### 🔄 RTL (V1.2)

Code RTL-ready dès la V1.0 (`EdgeInsetsDirectional`, `AlignmentDirectional`), mais testé seulement en V1.2.

**Règle gravée dès V1.0** : utiliser systématiquement les variantes `Directional` :
- `EdgeInsetsDirectional` au lieu de `EdgeInsets`
- `AlignmentDirectional` au lieu de `Alignment`

### 🌐 Réseau africain : règles V1.0

**Réalité du terrain** : connexions 3G/4G inégales, coupures fréquentes, données mobiles coûteuses.

**Règles produit (toutes versions)** :
- **Cache agressif** : tout ce qui peut être lu sans réseau l'est
- **Mode offline gracieux** : banner "Mode hors ligne" + dernière mise à jour cachée
- **Optimisation données** : éviter les images lourdes, lazy loading, compression
- **Retry automatique** : exponential backoff sur opérations critiques
- **Indicateurs réseau** : pulse rouge si offline, vert si OK
- **Timeouts généreux** : 15-20s pour Supabase

**Implémentation** :
- `connectivity_plus` pour détecter état réseau
- `dio_cache_interceptor` pour cache HTTP transparent

### 🛡️ Conformité légale — focus V1.0 (Afrique francophone)

| Pays | Loi | Impact V1.0 |
|---|---|---|
| **Cameroun** | Loi 2010/012 cybersécurité + CONAC | Vérifier classification "skill-based gaming" |
| **Côte d'Ivoire** | Loi 2013-450 protection données | Politique vie privée locale |
| **Sénégal** | Loi 2008-12 (CDP) | Politique vie privée |
| **Bénin/Togo/BF/Mali/Niger** | Lois locales similaires | Politique vie privée généralisée |

**Règles produit V1.0** :
- Page **"Politique de confidentialité"** en français, accessible depuis Settings
- Page **"CGU"** française à accepter à l'inscription (checkbox + horodatage en DB)
- Bouton **"Supprimer mon compte"** avec purge données après 30 jours
- Export données : bouton "Télécharger mes données" → JSON
- Mention claire "compétition de jeu vidéo basée sur la compétence" (anti-classification jeu de hasard)

V1.1 et V1.2 ajouteront la conformité respective (NDPR Nigeria, POPIA SA, CNDP Maroc, etc.).

---

## 🏆 SYSTÈME DE BRACKETS / TOURNOIS

C'est un élément **central** d'ARENA. Les joueurs et admins consultent le bracket en permanence pour suivre la progression du tournoi.

### 🎯 Formats supportés en V1.0

ARENA supporte **3 formats configurables** par l'admin lors de la création de la compétition :

| Format | Description | Utilisation typique |
|---|---|---|
| **Single Elimination** | Une défaite = éliminé. Bracket arborescent classique. | Petits tournois (8-32 joueurs), eFootball Cup style FIFA Mobile |
| **Groupes + KO** | Phase 1 = groupes (round robin dans chaque groupe), Phase 2 = élimination directe avec qualifiés | Format Coupe du monde, idéal pour 16-256 joueurs |
| **Round Robin** | Championnat où tous les joueurs s'affrontent. Classement final à points. | Mini-tournois fermés (8-12 joueurs max recommandé) |

### 🎨 Style visuel (côté USER)

**Bracket interactif avec animations** :
- Scroll horizontal pour naviguer entre les rounds (Round 1 → 1/8 → 1/4 → 1/2 → Finale)
- Chaque match est une **carte cliquable** (tap → ouvre bottom sheet avec détails)
- Animations Hero entre la liste des matchs et le détail
- Lignes de connexion animées entre les rounds (subtilité : elles s'illuminent quand un match avance)
- Couleurs : vainqueur en vert (`#00C896`), perdant en rouge atténué, en cours en bleu (`#4C7AFF`)
- Le joueur connecté voit **son propre nom mis en évidence** dans tout le bracket (badge "TOI")
- Pour les groupes : tableau de classement classique avec points / GF / GC / Diff

### 🛠️ Génération côté ADMIN

**100% automatique** : l'admin n'a aucune configuration manuelle à faire. L'algorithme génère tout.

L'admin :
1. Crée la compétition (taille 8-256, format choisi, etc.)
2. Les inscriptions s'ouvrent → joueurs s'inscrivent
3. À la date limite ou quand il décide → bouton **"GÉNÉRER LE BRACKET"**
4. L'algorithme :
   - Mélange les joueurs de manière aléatoire (seed)
   - Crée tous les matchs et leurs liens (qui joue qui, qui avance où)
   - Met le statut compétition à `active`
5. L'admin peut maintenant valider les scores au fur et à mesure → progression auto du bracket

**Pas de drag & drop, pas de modification manuelle des matchups en V1.0** (potentiellement en V2).

### 📐 Algorithmes de génération

#### Single Elimination
```dart
// core/utils/bracket_generators/single_elimination_generator.dart
List<Match> generateSingleElimination(List<Player> players) {
  // 1. Vérifier que la taille est puissance de 2 (8, 16, 32, 64, 128, 256)
  //    Sinon, ajouter des "byes" (passages automatiques au tour suivant)
  
  // 2. Mélanger aléatoirement
  players.shuffle();
  
  // 3. Calculer le nombre de rounds : log2(n)
  final totalRounds = (math.log(players.length) / math.log(2)).ceil();
  
  // 4. Round 1 : créer les matchs en pairs
  final round1Matches = <Match>[];
  for (var i = 0; i < players.length; i += 2) {
    round1Matches.add(Match(
      round: 1,
      position: i ~/ 2,
      playerHome: players[i],
      playerAway: players[i + 1],
      status: MatchStatus.scheduled,
    ));
  }
  
  // 5. Rounds suivants : créer les matchs vides liés
  // Le vainqueur du match N va au match N/2 du round suivant
  
  return matches;
}
```

#### Groupes + Élimination directe
```dart
// 1. Diviser les joueurs en groupes
//    16 joueurs = 4 groupes de 4
//    32 joueurs = 8 groupes de 4
//    64 joueurs = 16 groupes de 4 OU 8 groupes de 8
//    Configuration auto selon la taille

// 2. Phase groupes : générer round robin dans chaque groupe
//    (n*(n-1)/2 matchs par groupe)
//    Pour 4 joueurs/groupe : 6 matchs par groupe

// 3. À la fin de la phase de groupes :
//    Top 2 (ou 1) de chaque groupe se qualifie
//    Ces qualifiés entrent dans une phase d'élimination directe
//    Optionnel : 1er groupe A vs 2e groupe B (cross-bracket)
```

#### Round Robin
```dart
// Tous les joueurs s'affrontent une fois
// n joueurs = n*(n-1)/2 matchs
// Algorithme de "circle method" pour générer les rondes

// Classement final basé sur :
// - Points (Victoire = 3, Nul = 1, Défaite = 0) configurable
// - Différence de buts (tie-breaker 1)
// - Buts marqués (tie-breaker 2)
// - Tirage au sort (tie-breaker final)
```

### 🗄️ Structure SQL

3 tables dédiées (intégrées dans le schéma SQL global plus bas) :

- **`competition_phases`** : phases d'une compétition (groupes, KO, etc.)
- **`groups`** : groupes pour le format groupes+KO
- **`bracket_nodes`** : nœuds du bracket arborescent (qui joue qui, qui avance où)

### 📱 Écrans concernés

#### Côté USER
- `CompetitionDetailPage` onglet **"Bracket"** (déjà mentionné dans Phase 4)
  - Vue scroll horizontal des rounds
  - Tap sur un match → `MatchDetailBottomSheet`
- `CompetitionDetailPage` onglet **"Groupes"** (pour format groupes+KO)
  - Tableau de classement par groupe
  - Top X surligné en vert (qualifiés)
- `MatchDetailBottomSheet`
  - Score, joueurs, date, room code (si applicable)
  - Lien vers stream si live

#### Côté ADMIN
- `AdminCompetitionPage` onglet **"Bracket Management"**
  - Bouton "GÉNÉRER LE BRACKET" (avant lancement)
  - Vue identique au User mais avec boutons "Valider score" sur chaque match
  - Bouton "RESET BRACKET" en cas de problème (avec confirmation forte)

### 🎬 Animations clés

- **Génération du bracket** : animation 1-2s qui montre les joueurs "s'organiser" dans l'arbre
- **Progression d'un joueur** : quand un score est validé, le nom du vainqueur "remonte" vers le round suivant avec une animation de glow
- **Match LIVE** : pulse rouge sur la carte du match en cours
- **Match terminé** : checkmark vert qui apparaît avec un fade-in

### ⚙️ Règles de validation

L'admin valide les scores match par match :
- Tap sur un match → bottom sheet avec inputs scores
- Validation → :
  1. Update du match en DB
  2. Update des stats joueurs (W/L/Buts)
  3. Si match KO : le vainqueur est inscrit dans le `bracket_node` du round suivant
  4. Notification push aux 2 joueurs
  5. Si dernier match du tournoi : compétition passée en `completed`, payouts déclenchés

### 📊 Affichage du gagnant final

Quand la finale est validée :
- Animation "🏆 CHAMPION" plein écran sur l'app User des joueurs concernés
- Carte spéciale dorée dans le bracket
- Notification générale à tous les inscrits "X est le champion de [Compétition]"
- Page profil du gagnant : ajout d'un trophée dans achievements

---

## 🤖 AUTOMATISATION & ORCHESTRATION (V1.0 — sans IA)

ARENA est conçue comme une **plateforme auto-gérée** : 80% des tâches répétitives sont automatisées, l'admin n'intervient que sur les décisions importantes (création compétitions, validation litiges, modération avancée). Cette automatisation est **critique pour la scalabilité** : un admin peut gérer 100+ compétitions/mois au lieu de 5-10.

### 🎯 Philosophie d'automatisation V1.0

**Principe** : règles métier déterministes, sans IA pour V1.0. L'IA viendra en V1.5+ quand on aura des données réelles pour la calibrer.

**Stack technique** :
- **Edge Functions Supabase** (Deno/TypeScript) pour la logique backend
- **pg_cron** (Postgres extension) pour les jobs planifiés
- **Triggers SQL** pour les réactions instantanées aux changements DB
- **Firebase Cloud Messaging** pour les notifications push automatiques
- **Supabase Realtime** pour les updates UI en temps réel

### 📋 Les 6 axes d'automatisation V1.0

#### 1. 🚀 Orchestration auto des compétitions

**Workflow auto** :
1. **Création** : admin crée la compétition avec dates (inscription + lancement)
2. **Ouverture inscriptions** : cron job ouvre les inscriptions à `registration_opens_at`
3. **Fermeture inscriptions** : cron job ferme à `registration_closes_at` (ou capacité atteinte)
4. **Génération bracket** : cron lance `generate_bracket()` si min_players atteint, sinon annule la compet et rembourse
5. **Lancement automatique** : cron change le statut en `active` à `starts_at`
6. **Progression rounds** : trigger SQL avance le bracket à chaque match validé
7. **Clôture** : quand le dernier match (finale) est validé, statut → `completed` et payouts auto déclenchés

**Edge Functions concernées** :
- `auto_close_registrations` (cron toutes les minutes)
- `auto_generate_bracket` (cron toutes les 5 min)
- `auto_start_competition` (cron toutes les minutes)
- `auto_complete_competition` (trigger sur match finale validé)

#### 2. ⏰ Communication intelligente

**Notifications automatiques** :
- **J-1 du match** : "Ton match contre X est demain à 19h00"
- **H-1 du match** : "Match contre X dans 1 heure. Prépare-toi."
- **M-30 du match** : "Match dans 30 minutes. Lance eFootball."
- **M-5 du match** : "Match dans 5 minutes. Ton adversaire est en ligne."
- **Adversaire prêt** : "X est connecté et prêt"
- **Score validé** : "Tu as gagné ! Tu passes en demi-finale vs Y"
- **Bracket mis à jour** : "Le bracket a évolué, consulte ta position"
- **Compétition terminée** : "Champion : X. Voir les résultats."

**Smart features** :
- Pas de notif si le joueur est déjà actif dans l'app (sauf push critiques)
- Throttling : max 1 notif/5min par joueur
- Préférences utilisateur : possibilité de désactiver certains types
- Multi-langue : notifs auto traduites selon `profile.language`

**Edge Function** : `send_match_reminders` (cron toutes les 5 min)

#### 3. ✅ Validation collaborative des scores

**Workflow nouveau (sans admin)** :

1. À la fin du match, **les 2 joueurs soumettent indépendamment** leur score via `MatchRoomPage` :
   - "Score final : 3-1" (pour le joueur Domicile)
   - "Score final : 1-3" (pour le joueur Extérieur)

2. **Cas A — Concordance** :
   - Les 2 scores sont identiques (3-1 = 3-1)
   - **Validation auto immédiate** : `match.status = 'finished'`, `winner_id` calculé
   - Trigger SQL fait progresser le bracket
   - Notif aux 2 joueurs

3. **Cas B — Discordance** :
   - Les 2 scores diffèrent (3-1 vs 2-1)
   - Statut `match.status = 'disputed'`
   - Trigger crée un **litige** dans la table `disputes`
   - Bot dans le chat : "Litige détecté. Veuillez tous les deux soumettre une preuve (capture d'écran du score final) dans les 30 minutes."
   - Si pas de résolution dans 30 min → escalade à l'admin

4. **Cas C — Un seul a soumis** :
   - Délai de 10 min pour que l'autre soumette
   - Si pas de réponse → l'admin reçoit une alerte de modération

**Edge Functions** :
- `submit_score_collaborative` (HTTP) : valide ou crée un litige
- `escalate_dispute_after_timeout` (cron) : passe à l'admin après 30 min

#### 4. 🛡️ Gestion auto des litiges (niveau 1-2)

**Niveaux d'escalade automatique** :

**Niveau 0 — Auto-résolution (instantané)**
- Tentative de résolution par règles simples :
  - Si un joueur a abandonné en cours de match → l'autre gagne par forfait
  - Si déconnexion mutuelle confirmée → match à rejouer
  - Si recording manquant chez l'un → l'autre gagne (à condition que son recording soit OK)

**Niveau 1 — Bot dans le chat (auto, instantané)**
- Bot Claude (V1.5+) **OU** bot scripté (V1.0) envoie un message dans le chat 1-on-1 :
  > "🤖 ARENA Bot — Litige détecté pour le match #M042. Veuillez tous les deux fournir une preuve (capture d'écran du score final eFootball) en réponse à ce message dans les 30 minutes."
- Les joueurs uploadent leur preuve dans le chat

**Niveau 2 — Tentative résolution semi-auto (cron, après 30 min)**
- Cron job analyse les preuves uploadées :
  - Si **les 2 preuves concordent** (même score visible) → le score qui correspond gagne
  - Si **un seul a fourni une preuve** → ce score gagne par défaut (ouverture sanction pour l'autre)
  - Si **preuves contradictoires** ou **aucune preuve** → escalade niveau 3 (admin)

**Niveau 3 — Admin humain**
- Si toujours non résolu → notification admin avec :
  - Recording de chaque joueur
  - Preuves uploadées
  - Historique du chat
  - Suggestion de résolution (si niveau 2 a tenté)

**Edge Function** : `process_dispute` (cron toutes les 5 min)

#### 5. 💬 Modération auto du chat (basique, sans IA)

**Filtres en temps réel** :

**Filtre 1 — Mots interdits**
- Liste de ~200 mots interdits (insultes français, anglais, arabe + variantes)
- Stockée dans table `banned_words` (admin peut éditer)
- Match exact + leetspeak (n1k → nik, f**k → fck)

**Filtre 2 — Pattern detection**
- Numéros de téléphone (regex)
- URLs externes (sauf whitelist)
- Spam (même message > 3 fois)
- Caps lock excessif (>80% du message en majuscules)
- Caractères répétés (aaaaaaaa, !!!!!!)

**Sanctions auto progressives** :
- 1ère infraction → message bloqué + warning au joueur
- 2ème infraction → mute 5 min sur ce chat
- 3ème infraction → mute 1h sur tous les chats
- 4ème infraction → ban temporaire compétition (24h)
- 5ème infraction → escalade admin (potentiel ban permanent)

**Edge Function** : `moderate_chat_message` (HTTP, appelée avant chaque envoi)

#### 6. 💸 Préparation des paiements gagnants (CONTRÔLE ADMIN STRICT)

> 🔴 **AUCUNE AUTOMATISATION FINANCIÈRE** : tous les paiements aux gagnants sont validés **manuellement** par l'admin. C'est volontaire pour protéger la plateforme et les joueurs contre bugs, tricheurs détectés tardivement, et litiges complexes.

**Workflow à la fin d'une compétition** :

1. Trigger : `match.status = 'finished'` ET c'est la finale
2. `auto_complete_competition` se déclenche :
   - Statut compet → `completed`
   - Calcul de la cagnotte : `total_inscriptions × frais − commission + sponsoring`
   - Récupération des `prizes` (top 4) définis à la création
   - Si mode = `percentage` : calcul des montants finaux pour les 4 gagnants
   - Si mode = `fixed` : montants utilisés tels quels
   - **Création des entrées `payouts`** avec statut `pending_admin_validation`
3. **Notification push à l'admin** : "Compétition X terminée — 4 payouts à valider"
4. **L'admin** va sur `AdminPayoutsPage` et :
   - Voit les 4 gagnants avec leurs montants
   - Voit les 5 vérifications de sécurité (KYC, litiges, anti-cheat, ban, données paiement)
   - Examine le recording vidéo de la finale
   - **Décide manuellement** : Valider / Refuser / Mettre en attente
5. Si validé → Edge Function `execute_validated_payout` envoie les fonds via CinetPay/NowPayments
6. Notifications aux gagnants

**Vérifications automatisées (informatives, n'autorisent pas le paiement)** :
- ✅ Compte vérifié (KYC OK)
- ✅ Pas de litige ouvert sur ses matchs
- ✅ Pas d'anomalie anti-cheat détectée
- ✅ Joueur non banni
- ✅ Données paiement complètes

**Ces 5 checks aident l'admin à décider mais NE déclenchent JAMAIS un paiement automatique.**

**Edge Functions concernées** :
- `prepare_payouts_for_competition` (trigger sur `competition.status = 'completed'`) — crée les entrées en attente
- `execute_validated_payout` (HTTP, appelée par l'admin après validation manuelle) — exécute le paiement
- `notify_admin_pending_payouts` (cron 5min) — rappel admin si payouts en attente depuis > 1h

### 🏗️ Architecture technique

```
┌────────────────────────────────────────────────────────────────┐
│                     SUPABASE                                   │
│                                                                │
│  ┌──────────────┐   ┌──────────────────┐   ┌──────────────┐  │
│  │   POSTGRES   │   │  EDGE FUNCTIONS  │   │   pg_cron    │  │
│  │              │   │                  │   │              │  │
│  │  - Tables    │←─→│  - 12 functions  │←──│  Jobs every  │  │
│  │  - Triggers  │   │  - Auto-logic    │   │  min/5min/h  │  │
│  │  - Policies  │   │                  │   │              │  │
│  └──────────────┘   └──────────────────┘   └──────────────┘  │
│         ↓                    ↓                                 │
└─────────┼────────────────────┼─────────────────────────────────┘
          ↓                    ↓
   ┌──────────────┐    ┌──────────────┐
   │    FCM       │    │  CinetPay    │
   │ Push notifs  │    │  Payouts     │
   └──────────────┘    └──────────────┘
          ↓                    ↓
   ┌────────────────────────────────────┐
   │    APPS FLUTTER (User + Admin)     │
   │  Realtime updates via Supabase     │
   └────────────────────────────────────┘
```

### 📦 Liste des Edge Functions (12 au total)

À créer dans `supabase/functions/` :

```
supabase/functions/
├── _shared/
│   ├── cors.ts
│   ├── supabase-client.ts
│   ├── fcm.ts
│   └── agora_token.ts                # Helper génération tokens Agora RTC + RTM
├── auto_close_registrations/        # cron 1min
├── auto_generate_bracket/            # cron 5min
├── auto_start_competition/           # cron 1min
├── auto_complete_competition/        # trigger
├── send_match_reminders/             # cron 5min
├── submit_score_collaborative/       # HTTP
├── moderate_chat_message/            # HTTP
├── process_dispute/                  # cron 5min
├── escalate_dispute_after_timeout/   # cron 5min
├── prepare_payouts_for_competition/  # trigger - crée entrées en attente
├── execute_validated_payout/         # HTTP - appelée par admin après validation manuelle
├── notify_admin_pending_payouts/     # cron 5min - rappel admin
├── check_match_forfeits/             # cron 1min
├── get_agora_token/                  # HTTP - génère token Agora RTC/RTM (sécurité)
└── send_targeted_notification/       # HTTP (utility)
```

### 📊 Tables SQL supplémentaires

3 nouvelles tables nécessaires (intégrées dans le SQL global ci-dessous) :

- **`disputes`** : litiges en cours avec statut/preuves/résolution
- **`auto_actions_log`** : log de toutes les actions automatiques (pour audit)
- **`banned_words`** : liste des mots interdits modérables par admin

### 🎯 Réduction de la charge admin

| Tâche | Avant (manuel) | Après V1.0 (auto) |
|---|---|---|
| Lancement compétition | 30 min | 0 (auto) |
| Génération bracket | 10 min | 0 (auto) |
| Validation scores | 5 min × N matchs | 0 (sauf litiges) |
| Notifications joueurs | 20 min | 0 (auto) |
| Modération chat | 15 min/h | 0 (sauf escalade) |
| Payouts gagnants | 30 min | 0 (auto, sauf litiges) |
| **Total/compétition** | **~5 heures** | **~30 minutes** |

**Gain** : 90% de temps économisé. Un admin peut gérer 10x plus de compétitions.

### 🛡️ Garde-fous

L'automatisation doit être **réversible** et **observable** :

1. **Toutes les actions auto sont loggées** dans `auto_actions_log`
2. **L'admin peut désactiver** une auto-feature via feature flag (`app_config`)
3. **Notifications admin** pour les cas limites (ex: 5 litiges sur même compet)
4. **Mode "manual override"** : l'admin peut toujours forcer une décision contraire à l'auto
5. **Dashboard de supervision** : monitoring des auto-actions (nb succès/échecs, temps réponse)

---

## 🗄️ SCHÉMA SUPABASE COMPLET

À exécuter dans le SQL Editor de Supabase **avant de toucher au code Flutter**.

```sql
-- Extensions
create extension if not exists "uuid-ossp";

-- ENUMS
create type user_role as enum ('player', 'admin', 'super_admin');
create type game_type as enum ('efootball', 'fifa', 'fc_mobile');
create type comp_format as enum ('groups_ko', 'single_elim', 'league');
create type comp_status as enum ('draft', 'registration', 'live', 'finished');
create type match_status as enum ('pending', 'room_setup', 'live', 'finished', 'cancelled');
create type phase_type as enum ('groups', 'knockout', 'round_robin');
-- Note: 'single_elimination' = phase 'knockout' simple sans phase 'groups' précédente
-- 'groups_then_knockout' = phase 'groups' + phase 'knockout' liées (Coupe du monde)
-- 'round_robin' = championnat tous contre tous, classement final à points

-- 1. PROFILES (étend auth.users)
create table profiles (
  id uuid primary key references auth.users on delete cascade,
  username text unique not null check (length(username) between 3 and 20),
  email text unique not null,
  country_code text not null check (length(country_code) = 2),
  avatar_color text not null default '#4C7AFF',
  role user_role not null default 'player',
  seed int,
  is_active boolean default true,
  fcm_token text,
  stats jsonb default '{"wins":0,"losses":0,"goals_scored":0,"goals_conceded":0}'::jsonb,
  -- AUTHENTIFICATION (méthode d'inscription)
  auth_provider text not null default 'email' check (auth_provider in ('email', 'google', 'apple')),
  auth_provider_id text,                  -- ID externe (Google sub, Apple sub) si applicable
  -- INTERNATIONALISATION (architecture V1.2, valeurs par défaut V1.0)
  preferred_language text not null default 'fr' check (preferred_language in ('en', 'fr', 'ar')),
  preferred_currency text not null default 'XAF' check (preferred_currency in (
    'XAF', 'XOF',                                          -- V1.0 actives
    'NGN', 'GHS', 'KES', 'ZAR', 'UGX', 'RWF', 'TZS',       -- V1.1
    'MAD', 'DZD', 'TND', 'EGP',                            -- V1.2
    'USD'                                                   -- Fallback toutes versions
  )),
  timezone text not null default 'Africa/Douala',
  detected_country_code text,
  -- ONBOARDING
  onboarding_completed boolean default false,
  onboarding_completed_at timestamptz,
  -- AUTHENTIFICATION ADMIN (TOTP)
  totp_secret text,                       -- Base32 secret pour Google Authenticator (chiffré côté serveur)
  totp_enabled boolean default false,     -- L'admin a-t-il complété la config TOTP ?
  totp_verified_at timestamptz,           -- Date de la première verification TOTP réussie
  backup_codes jsonb default '[]'::jsonb, -- 10 codes de récupération (hashés)
  last_totp_used text,                    -- Anti-replay : dernier code TOTP utilisé
  -- INVITATION (admins only)
  invited_by uuid references profiles(id),
  invited_at timestamptz,
  invitation_code_used text,
  -- CONFORMITÉ LÉGALE
  cgu_accepted_at timestamptz,
  cgu_version_accepted text,                             -- ex: 'v1.2'
  privacy_policy_accepted_at timestamptz,
  marketing_consent boolean default false,
  data_export_requested_at timestamptz,
  -- SUPPRESSION DE COMPTE (RGPD/conformité)
  -- Workflow soft-delete : 1) demande utilisateur 2) marquage 3) anonymisation après 30j
  account_deletion_requested_at timestamptz,
  account_deletion_reason text,
  deleted_at timestamptz,                                -- soft-delete (anonymisation des données)
  -- KYC (pour payouts > seuil)
  kyc_status text default 'none' check (kyc_status in ('none', 'pending', 'verified', 'rejected')),
  kyc_verified_at timestamptz,
  -- TIMESTAMPS
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

create index idx_profiles_deleted on profiles(deleted_at) where deleted_at is not null;
create index idx_profiles_auth_provider on profiles(auth_provider);

-- 2. COMPETITIONS
create table competitions (
  id uuid primary key default uuid_generate_v4(),
  -- TRADUCTIONS NOM/DESCRIPTION (i18n)
  name text not null,                              -- Nom par défaut (langue de l'admin)
  name_translations jsonb default '{}',            -- {"en": "...", "fr": "...", "es": "..."}
  description text,
  description_translations jsonb default '{}',
  game game_type not null,
  format comp_format not null,
  size int not null check (size in (8, 16, 32, 64, 128, 256) or size > 0),
  current_phase text,
  status comp_status not null default 'draft',
  admin_id uuid references profiles(id),
  prize text,
  -- PAIEMENTS (montants stockés en USD comme référence)
  entry_fee_amount_usd numeric(12,2) default 0 check (entry_fee_amount_usd >= 0),
  is_free boolean generated always as (entry_fee_amount_usd = 0) stored,
  platform_commission_pct numeric(5,2) default 15.00 check (platform_commission_pct between 0 and 100),
  -- Mode de définition des gains : 'percentage' ou 'fixed'
  -- Les montants exacts sont stockés dans la table 'prizes' (top 4)
  prize_mode text default 'percentage' check (prize_mode in ('percentage', 'fixed')),
  prize_pool_usd numeric(12,2) default 0,         -- Total cagnotte (calculé)
  sponsored_amount_usd numeric(12,2) default 0,   -- Bonus sponsoring admin (optionnel)
  -- RESTRICTIONS GÉOGRAPHIQUES
  allowed_countries text[],                        -- NULL = mondial, sinon liste codes ISO
  blocked_countries text[] default array[]::text[],
  age_restriction int default 13,                  -- 13+ par défaut (RGPD/COPPA)
  -- OPTIONS
  options_json jsonb default '{
    "anti_cheat_recording": true,
    "agora_chat": true,
    "auto_room": true,
    "public_streams": false
  }'::jsonb,
  start_date timestamptz,
  end_date timestamptz,
  registration_deadline timestamptz,
  created_at timestamptz default now(),
  created_by uuid references profiles(id)
);

-- 3. PHASES
create table phases (
  id uuid primary key default uuid_generate_v4(),
  competition_id uuid not null references competitions on delete cascade,
  type phase_type not null,
  round_number int not null,
  is_active boolean default false,
  created_at timestamptz default now()
);

-- 4. GROUPS
create table groups (
  id uuid primary key default uuid_generate_v4(),
  phase_id uuid not null references phases on delete cascade,
  competition_id uuid not null references competitions on delete cascade,
  name text not null,
  created_at timestamptz default now()
);

-- 5. GROUP MEMBERSHIPS
create table group_memberships (
  group_id uuid references groups on delete cascade,
  player_id uuid references profiles on delete cascade,
  matches_played int default 0,
  wins int default 0,
  losses int default 0,
  goals_scored int default 0,
  goals_conceded int default 0,
  points int default 0,
  primary key (group_id, player_id)
);

-- 6. COMPETITION REGISTRATIONS
create table competition_registrations (
  competition_id uuid references competitions on delete cascade,
  player_id uuid references profiles on delete cascade,
  registered_at timestamptz default now(),
  primary key (competition_id, player_id)
);

-- 7. PRIZES (gains top 4 d'une compétition, définis manuellement par l'admin)
-- L'admin saisit les 4 gains à la création de la compétition.
-- Stockage USD comme référence + version locale pour affichage.
-- Chaque compétition a EXACTEMENT 4 lignes (positions 1, 2, 3, 4).
create table prizes (
  id uuid primary key default uuid_generate_v4(),
  competition_id uuid not null references competitions on delete cascade,
  position int not null check (position between 1 and 4),
  -- Mode de définition (hérité de competitions.prize_mode pour cohérence)
  -- Si percentage: percentage_value est défini, amount calculé à la fin
  -- Si fixed: amount_usd directement défini
  mode text not null check (mode in ('percentage', 'fixed')),
  percentage_value numeric(5,2),                    -- Si mode = 'percentage' (ex: 50.00 pour 50%)
  amount_usd numeric(12,2) not null default 0,      -- Montant final en USD (calculé ou fixe)
  -- Affichage local (récupéré via exchange_rates au moment de la définition)
  display_currency text default 'XAF',              -- XAF, XOF, USD selon admin
  display_amount numeric(12,2),                     -- Montant affiché dans la devise admin
  -- Métadonnées
  label text,                                       -- "Champion", "Finaliste", "3ème place", "4ème place"
  created_at timestamptz default now(),
  unique(competition_id, position)
);

create index idx_prizes_competition on prizes(competition_id);

-- 8. BRACKET NODES (pour single elimination et phase KO de groupes+KO)
-- Chaque ligne = un emplacement dans l'arbre de bracket
-- Permet de connaître la structure complète : qui joue qui, qui avance où
create table bracket_nodes (
  id uuid primary key default uuid_generate_v4(),
  phase_id uuid not null references phases on delete cascade,
  competition_id uuid not null references competitions on delete cascade,
  -- Position dans l'arbre
  round_number int not null,           -- 1 = round 1, 2 = round 2 (ex: 1/8), etc.
  position_in_round int not null,      -- 0, 1, 2... position dans le round
  total_rounds int not null,           -- nombre total de rounds dans cette phase
  -- Le match associé à ce nœud (peut être null si pas encore créé)
  match_id uuid references matches on delete set null,
  -- Liens dans l'arbre
  next_node_id uuid references bracket_nodes,  -- où va le vainqueur
  parent_node_id uuid references bracket_nodes,  -- d'où vient ce nœud
  -- Spéciaux
  is_grand_final boolean default false,
  is_third_place_match boolean default false,  -- match pour la 3e place (optionnel)
  created_at timestamptz default now(),
  unique(phase_id, round_number, position_in_round)
);

create index idx_bracket_nodes_phase on bracket_nodes(phase_id, round_number, position_in_round);
create index idx_bracket_nodes_match on bracket_nodes(match_id);

-- 9. MATCHES
create table matches (
  id uuid primary key default uuid_generate_v4(),
  competition_id uuid not null references competitions on delete cascade,
  phase_id uuid references phases on delete cascade,
  round int,
  match_code text unique not null,
  player1_id uuid references profiles,
  player2_id uuid references profiles,
  score1 int,
  score2 int,
  winner_id uuid references profiles,
  status match_status default 'pending',
  home_player_id uuid references profiles,
  room_code text,
  -- STREAMING LIVE (Agora RTC — sélection admin par match)
  is_streamed boolean default false,                -- Match streamé ou non
  -- Raison de l'activation du streaming
  -- 'auto_final' : auto-streamé car finale (logique automatique)
  -- 'manual_admin' : ajouté manuellement par l'admin
  -- 'auto_premium' : auto-streamé car compétition premium (V1.5+)
  streaming_activation_type text check (streaming_activation_type in ('auto_final', 'manual_admin', 'auto_premium')),
  streaming_activated_by_admin_id uuid references profiles,
  streaming_activated_at timestamptz,
  -- État du stream Agora
  agora_stream_channel text,                        -- Nom du channel Agora pour ce match
  stream_status text default 'none' check (stream_status in ('none', 'scheduled', 'live', 'ended', 'failed')),
  stream_started_at timestamptz,
  stream_ended_at timestamptz,
  -- Stats du stream (mises à jour en temps réel)
  current_viewers_count int default 0,
  peak_viewers_count int default 0,
  total_viewers_unique int default 0,
  scheduled_at timestamptz,
  started_at timestamptz,
  finished_at timestamptz,
  next_match_id uuid references matches,
  -- Configuration spécifique du match (phases de groupes/round robin)
  -- Contient les confirmations de désactivation prolongations/TAB
  -- Ex: {"extra_time_disabled": true, "penalties_disabled": true,
  --      "confirmed_by_home": true, "confirmed_by_home_at": "2026-05-04T19:30:00Z"}
  match_config jsonb default '{}',
  created_at timestamptz default now()
);

create index idx_matches_streamed_live on matches(is_streamed, stream_status) where stream_status = 'live';

-- 10. MATCH EVENTS (timeline)
create table match_events (
  id uuid primary key default uuid_generate_v4(),
  match_id uuid not null references matches on delete cascade,
  type text not null,
  scorer_id uuid references profiles,
  minute int,
  score_after jsonb,
  metadata jsonb,
  created_at timestamptz default now()
);

-- 11. STREAMS
create table streams (
  id uuid primary key default uuid_generate_v4(),
  match_id uuid not null references matches on delete cascade,
  player_id uuid not null references profiles on delete cascade,
  url text,
  is_public boolean default false,
  is_active boolean default true,
  started_at timestamptz default now(),
  ended_at timestamptz
);

-- 12. NOTIFICATIONS
create table notifications (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid not null references profiles on delete cascade,
  type text not null,
  title text not null,
  body text not null,
  match_id uuid references matches on delete cascade,
  competition_id uuid references competitions on delete cascade,
  is_read boolean default false,
  created_at timestamptz default now()
);

-- 13. CHAT CHANNELS (canaux de chat — utilisés par Supabase Realtime + Agora RTM en parallèle)
-- Architecture hybride : messages persistants dans chat_messages (Supabase),
-- présence (typing/online) gérée par Agora RTM avec le même channel_name
create table chat_channels (
  id uuid primary key default uuid_generate_v4(),
  match_id uuid references matches on delete cascade,
  competition_id uuid references competitions on delete cascade,
  channel_name text unique not null,
  channel_type text not null check (channel_type in ('match_chat', 'competition_broadcast', 'stream_audience_chat')),
  created_at timestamptz default now()
);

create index idx_chat_channels_match on chat_channels(match_id);
create index idx_chat_channels_competition on chat_channels(competition_id);

-- 14. CHAT MESSAGES (persistance Supabase + Realtime pour livraison)
-- Tous les messages sont stockés ici (vs Agora RTM qui est éphémère).
-- Supabase Realtime broadcast l'INSERT à tous les souscripteurs du channel.
create table chat_messages (
  id uuid primary key default uuid_generate_v4(),
  channel_id uuid references chat_channels on delete cascade,
  sender_id uuid not null references profiles,
  message_type text not null check (message_type in ('text', 'room_code', 'system', 'bot')),
  content text not null,
  metadata jsonb,
  -- Modération (PHASE 12.5.6)
  is_moderated boolean default false,
  moderation_action text,                          -- 'allowed', 'blocked', 'flagged'
  created_at timestamptz default now()
);

create index idx_chat_messages_channel on chat_messages(channel_id, created_at desc);
create index idx_chat_messages_sender on chat_messages(sender_id, created_at desc);

-- 15. ANTI-CHEAT EVENTS (alertes anomalies enregistrement)
create type anomaly_severity as enum ('low', 'medium', 'high', 'critical');
create type anomaly_type as enum (
  'recording_paused',
  'recording_stopped_by_player',
  'recording_force_stop_attempt',
  'overlay_permission_revoked',
  'foreground_service_killed',
  'media_projection_revoked',
  'airplane_mode_during_match',
  'app_killed_during_match',
  'unauthorized_app_launched'
);

create table anti_cheat_events (
  id uuid primary key default uuid_generate_v4(),
  match_id uuid not null references matches on delete cascade,
  player_id uuid not null references profiles on delete cascade,
  type anomaly_type not null,
  severity anomaly_severity not null default 'medium',
  description text,
  metadata jsonb,
  reviewed_by uuid references profiles,
  reviewed_at timestamptz,
  action_taken text,
  created_at timestamptz default now()
);

create index idx_anticheat_match on anti_cheat_events(match_id);
create index idx_anticheat_unreviewed on anti_cheat_events(reviewed_at) where reviewed_at is null;

-- INDEX pour performance
create index idx_matches_competition on matches(competition_id);
create index idx_matches_status on matches(status);
create index idx_matches_players on matches(player1_id, player2_id);
create index idx_notifications_user_unread on notifications(user_id, is_read);
create index idx_chat_messages_channel on chat_messages(channel_id, created_at desc);

-- ════════════════════════════════════════════════════════════
-- 🤖 AUTOMATISATION & ORCHESTRATION
-- ════════════════════════════════════════════════════════════

-- Status des litiges
create type dispute_status as enum (
  'open',                  -- Litige créé, en attente de preuves
  'evidence_submitted',    -- Au moins un joueur a soumis preuve
  'auto_resolved',         -- Résolu automatiquement (niveau 0-2)
  'admin_review',          -- Escaladé à l'admin (niveau 3)
  'resolved',              -- Décision finale prise
  'cancelled'              -- Litige annulé
);

create type dispute_resolution as enum (
  'player1_wins',
  'player2_wins',
  'rematch',
  'both_disqualified',
  'cancelled_no_decision'
);

-- 16. DISPUTES (litiges)
create table disputes (
  id uuid primary key default uuid_generate_v4(),
  match_id uuid not null references matches on delete cascade,
  competition_id uuid not null references competitions on delete cascade,
  -- Scores soumis par chaque joueur (peuvent différer = litige)
  player1_score_claim jsonb,    -- {"score1": 3, "score2": 1, "submitted_at": "..."}
  player2_score_claim jsonb,
  -- Preuves uploadées dans le chat (URLs Supabase Storage)
  player1_evidence_urls text[],
  player2_evidence_urls text[],
  -- Statut et résolution
  status dispute_status default 'open',
  current_escalation_level int default 0,  -- 0, 1, 2, 3 (admin)
  auto_resolution_attempted boolean default false,
  auto_resolution_reason text,             -- raison de l'auto-décision si applicable
  resolution dispute_resolution,
  resolved_by_admin_id uuid references profiles,
  resolution_notes text,
  -- Timestamps clés
  opened_at timestamptz default now(),
  evidence_deadline timestamptz,           -- 30 min après ouverture
  escalated_to_admin_at timestamptz,
  resolved_at timestamptz
);

create index idx_disputes_status on disputes(status, opened_at);
create index idx_disputes_match on disputes(match_id);
create index idx_disputes_competition on disputes(competition_id);

-- 17. AUTO ACTIONS LOG (audit complet des actions automatiques)
create type auto_action_type as enum (
  'open_registrations',
  'close_registrations',
  'generate_bracket',
  'start_competition',
  'complete_competition',
  'progress_bracket',
  'send_match_reminder',
  'check_match_forfeit',
  'apply_forfeit',
  'validate_score_collaborative',
  'create_dispute',
  'auto_resolve_dispute',
  'escalate_dispute',
  'moderate_chat_message',
  'mute_player',
  'ban_player_temporary',
  'process_payout',
  'cancel_payout_check_failed'
);

create type auto_action_status as enum (
  'success',
  'failed',
  'skipped',
  'escalated'
);

create table auto_actions_log (
  id uuid primary key default uuid_generate_v4(),
  action_type auto_action_type not null,
  status auto_action_status not null,
  -- Référence à l'entité concernée (au moins un parmi)
  competition_id uuid references competitions on delete cascade,
  match_id uuid references matches on delete cascade,
  user_id uuid references profiles on delete cascade,
  dispute_id uuid references disputes on delete cascade,
  -- Détails
  metadata jsonb default '{}',         -- contexte spécifique de l'action
  error_message text,                  -- si status = 'failed'
  duration_ms int,                     -- temps d'exécution
  edge_function_name text,             -- nom de l'Edge Function qui a déclenché
  triggered_by text,                   -- 'cron' | 'trigger' | 'http'
  created_at timestamptz default now()
);

create index idx_auto_actions_type_status on auto_actions_log(action_type, status, created_at desc);
create index idx_auto_actions_competition on auto_actions_log(competition_id, created_at desc);

-- 18. BANNED WORDS (modération chat)
create type banned_word_severity as enum ('warning', 'mute', 'ban');

create table banned_words (
  id uuid primary key default uuid_generate_v4(),
  word text not null unique,
  severity banned_word_severity default 'warning',
  language text default 'fr',          -- fr, en, ar
  is_regex boolean default false,      -- si true, traité comme regex
  created_by_admin_id uuid references profiles,
  created_at timestamptz default now(),
  is_active boolean default true
);

create index idx_banned_words_active on banned_words(is_active, language);

-- Données initiales banned_words (à étendre par l'admin)
-- Note : les mots les plus offensifs sont volontairement omis ici, l'admin remplit
insert into banned_words (word, severity, language) values
  ('spam', 'warning', 'fr'),
  ('arnaque', 'warning', 'fr'),
  ('scam', 'warning', 'en'),
  ('fuck', 'mute', 'en'),
  ('whatsapp\\.me', 'warning', 'fr'),       -- regex
  ('telegram\\.me', 'warning', 'fr'),       -- regex
  ('\\d{8,}', 'warning', 'fr')              -- numéros téléphone
on conflict (word) do nothing;

-- ════════════════════════════════════════════════════════════
-- TRIGGERS SQL — Automatisation instantanée
-- ════════════════════════════════════════════════════════════

-- Trigger : à la fin d'un match (status = 'finished'), faire progresser le bracket
create or replace function on_match_finished()
returns trigger as $$
declare
  v_next_node_id uuid;
  v_winner_id uuid;
begin
  -- Si le match vient de passer en 'finished'
  if NEW.status = 'finished' and OLD.status != 'finished' then
    v_winner_id := NEW.winner_id;
    
    -- Trouver le bracket_node lié à ce match
    select next_node_id into v_next_node_id
    from bracket_nodes
    where match_id = NEW.id;
    
    -- Si un nœud suivant existe (pas la finale), inscrire le vainqueur
    if v_next_node_id is not null then
      -- Trouver si c'est player1 ou player2 du prochain match qu'on doit remplir
      update matches
      set player1_id = case
        when player1_id is null then v_winner_id
        else player1_id
      end,
      player2_id = case
        when player1_id is not null and player2_id is null then v_winner_id
        else player2_id
      end
      where id = (select match_id from bracket_nodes where id = v_next_node_id);
    end if;
    
    -- Logger l'action auto
    insert into auto_actions_log (action_type, status, match_id, competition_id, metadata, triggered_by)
    values (
      'progress_bracket',
      'success',
      NEW.id,
      NEW.competition_id,
      jsonb_build_object('winner_id', v_winner_id, 'next_node_id', v_next_node_id),
      'trigger'
    );
  end if;
  return NEW;
end;
$$ language plpgsql security definer;

create trigger trg_on_match_finished
  after update on matches
  for each row execute function on_match_finished();

-- Trigger : créer automatiquement un litige si scores discordants
-- (Cette logique est aussi gérée côté Edge Function pour plus de flexibilité,
-- mais ce trigger sert de filet de sécurité)

-- Trigger : quand le dernier match d'une compétition est validé, marquer la compet comme completed
create or replace function on_final_match_finished()
returns trigger as $$
declare
  v_remaining_matches int;
begin
  if NEW.status = 'finished' and OLD.status != 'finished' then
    -- Compter les matchs non terminés de cette compétition
    select count(*) into v_remaining_matches
    from matches
    where competition_id = NEW.competition_id
      and status not in ('finished', 'cancelled');
    
    -- Si 0 match restant → la compétition est terminée
    if v_remaining_matches = 0 then
      update competitions
      set status = 'completed',
          completed_at = now()
      where id = NEW.competition_id;
      
      -- Log
      insert into auto_actions_log (action_type, status, competition_id, triggered_by)
      values ('complete_competition', 'success', NEW.competition_id, 'trigger');
      
      -- Note : les payouts seront déclenchés par l'Edge Function 'process_payouts_for_competition'
      -- qui écoute les changements de statut des compétitions
    end if;
  end if;
  return NEW;
end;
$$ language plpgsql security definer;

create trigger trg_on_final_match_finished
  after update on matches
  for each row execute function on_final_match_finished();

-- ════════════════════════════════════════════════════════════
-- CRON JOBS (pg_cron) — Automatisation planifiée
-- ════════════════════════════════════════════════════════════

-- Activer l'extension pg_cron (à faire une seule fois en tant que super-user)
-- create extension if not exists pg_cron;

-- IMPORTANT : pg_cron doit être configuré dans le dashboard Supabase
-- Database → Extensions → activer "pg_cron"
-- Puis configurer ces jobs via SQL :

-- Job 1 : toutes les minutes — fermeture inscriptions et démarrages
-- select cron.schedule(
--   'auto-orchestrate-competitions',
--   '* * * * *',
--   $$ select net.http_post(
--     url := 'https://[PROJECT].supabase.co/functions/v1/auto_close_registrations',
--     headers := '{"Content-Type": "application/json", "Authorization": "Bearer [SERVICE_ROLE_KEY]"}'::jsonb
--   ); $$
-- );

-- Job 2 : toutes les 5 min — génération brackets, rappels, traitement litiges
-- select cron.schedule(
--   'auto-process-tournaments',
--   '*/5 * * * *',
--   $$ select net.http_post(
--     url := 'https://[PROJECT].supabase.co/functions/v1/send_match_reminders',
--     headers := '{"Content-Type": "application/json", "Authorization": "Bearer [SERVICE_ROLE_KEY]"}'::jsonb
--   ); $$
-- );

-- Job 3 : toutes les minutes — détection forfaits
-- select cron.schedule(
--   'auto-check-forfeits',
--   '* * * * *',
--   $$ select net.http_post(
--     url := 'https://[PROJECT].supabase.co/functions/v1/check_match_forfeits',
--     headers := '{"Content-Type": "application/json", "Authorization": "Bearer [SERVICE_ROLE_KEY]"}'::jsonb
--   ); $$
-- );

-- Job 4 : toutes les heures — nettoyage logs anciens (> 30 jours)
-- select cron.schedule(
--   'cleanup-old-logs',
--   '0 * * * *',
--   $$ delete from auto_actions_log where created_at < now() - interval '30 days'; $$
-- );


-- ════════════════════════════════════════════════════════════
-- AUTHENTIFICATION ADMIN — Invitation codes
-- ════════════════════════════════════════════════════════════

-- 19. INVITATION CODES (pour onboarding nouveaux admins)
create type invitation_status as enum ('pending', 'used', 'expired', 'revoked');
create type invitation_role as enum ('admin', 'super_admin');

create table invitation_codes (
  id uuid primary key default uuid_generate_v4(),
  code text unique not null,                       -- Format: ARENA-XXXX-XXXX-XXXX
  role invitation_role not null default 'admin',
  -- Pré-attributions
  intended_email text,                             -- Optionnel : limiter à un email précis
  intended_competition_id uuid references competitions(id),  -- Pré-assigner à une compet
  -- Tracking
  status invitation_status not null default 'pending',
  used_by uuid references profiles(id),
  used_at timestamptz,
  -- Audit
  created_by uuid not null references profiles(id),
  created_at timestamptz default now(),
  expires_at timestamptz not null default (now() + interval '7 days'),
  revoked_at timestamptz,
  revoked_by uuid references profiles(id),
  revoke_reason text,
  -- Notes admin
  notes text                                       -- "Pour Jean qui gère la compet PSG vs RM"
);

create index idx_invitation_codes_code on invitation_codes(code) where status = 'pending';
create index idx_invitation_codes_status on invitation_codes(status, expires_at);

-- TRIGGER : auto-expiration des codes
create or replace function expire_old_invitations()
returns trigger as $$
begin
  update invitation_codes
  set status = 'expired'
  where status = 'pending' and expires_at < now();
  return null;
end;
$$ language plpgsql;

-- À déclencher via pg_cron toutes les heures (configuré côté Supabase)

-- RLS : seuls super-admins voient/créent les codes
alter table invitation_codes enable row level security;

create policy "Super-admins lisent tous les codes" on invitation_codes for select
  using (exists(select 1 from profiles where id = auth.uid() and role = 'super_admin'));

create policy "Super-admins créent codes" on invitation_codes for insert
  with check (exists(select 1 from profiles where id = auth.uid() and role = 'super_admin'));

create policy "Super-admins modifient codes" on invitation_codes for update
  using (exists(select 1 from profiles where id = auth.uid() and role = 'super_admin'));

-- ════════════════════════════════════════════════════════════
-- ADMIN AUDIT LOG (toutes les actions admin tracées)
-- ════════════════════════════════════════════════════════════

create type admin_action_type as enum (
  'login', 'logout', 'totp_setup', 'totp_failed',
  'competition_created', 'competition_updated', 'competition_deleted',
  'match_validated', 'match_score_updated', 'match_cancelled',
  'stream_made_public', 'stream_made_private', 'stream_flagged',
  'player_suspended', 'player_unsuspended',
  'admin_invited', 'admin_revoked', 'invitation_created',
  'payout_approved', 'payout_rejected',
  'app_config_changed'
);

-- 20. ADMIN AUDIT LOG (traçabilité complète des actions admin)
create table admin_audit_log (
  id uuid primary key default uuid_generate_v4(),
  admin_id uuid not null references profiles(id),
  action admin_action_type not null,
  target_id uuid,                          -- ID de l'entité concernée (compet, match, etc.)
  target_type text,                        -- 'competition', 'match', 'player', etc.
  metadata jsonb default '{}',             -- Détails (avant/après, raison...)
  ip_address inet,
  user_agent text,
  created_at timestamptz default now()
);

create index idx_admin_audit_admin on admin_audit_log(admin_id, created_at desc);
create index idx_admin_audit_action on admin_audit_log(action, created_at desc);

-- Récupération facile de l'historique d'un admin via une vue
create view admin_activity_recent as
  select aal.*, p.username as admin_username
  from admin_audit_log aal
  join profiles p on p.id = aal.admin_id
  where aal.created_at > now() - interval '30 days'
  order by aal.created_at desc;

alter table admin_audit_log enable row level security;
create policy "Super-admin lit tout l'audit" on admin_audit_log for select
  using (exists(select 1 from profiles where id = auth.uid() and role = 'super_admin'));
create policy "Admin lit son propre audit" on admin_audit_log for select
  using (admin_id = auth.uid());

-- Realtime sur audit log (super-admin voit en direct ce qui se passe)
alter publication supabase_realtime add table admin_audit_log;

-- ════════════════════════════════════════════════════════════
-- FEATURE FLAGS (app_config) — Activation progressive V1.0/V1.1/V1.2
-- ════════════════════════════════════════════════════════════

-- 21. APP CONFIG (feature flags multi-versions)
create table app_config (
  key text primary key,
  value jsonb not null,
  description text,
  updated_at timestamptz default now(),
  updated_by uuid references profiles(id)
);

-- Données initiales : V1.0 = Afrique francophone uniquement
insert into app_config (key, value, description) values
  -- Langues
  ('lang_fr_enabled', 'true'::jsonb, 'Français (V1.0 actif)'),
  ('lang_en_enabled', 'false'::jsonb, 'English (V1.1, désactivé en V1.0)'),
  ('lang_ar_enabled', 'false'::jsonb, 'Arabe (V1.2, désactivé en V1.0)'),

  -- Providers paiement
  ('provider_cinetpay_enabled', 'true'::jsonb, 'CinetPay V1.0 actif'),
  ('provider_nowpayments_enabled', 'true'::jsonb, 'Crypto fallback V1.0'),
  ('provider_flutterwave_enabled', 'false'::jsonb, 'Flutterwave V1.1 désactivé'),
  ('provider_cmi_enabled', 'false'::jsonb, 'CMI Maroc V1.2'),
  ('provider_satim_enabled', 'false'::jsonb, 'SATIM Algérie V1.2'),
  ('provider_paymee_enabled', 'false'::jsonb, 'Paymee Tunisie V1.2'),
  ('provider_paymob_enabled', 'false'::jsonb, 'Paymob Égypte V1.2'),

  -- Pays autorisés au lancement (whitelist V1.0)
  ('allowed_countries_v1', '["CM","GA","CG","TD","CF","GQ","CI","SN","BJ","TG","BF","ML","NE","MG","KM","DJ"]'::jsonb,
    'Pays Afrique francophone V1.0'),

  -- Devises actives V1.0
  ('active_currencies_v1', '["XAF","XOF","USD"]'::jsonb, 'Devises V1.0'),

  -- Crypto config
  ('min_payment_usd', '1.0'::jsonb, 'Montant minimum paiement en USD'),
  ('max_payment_usd', '500.0'::jsonb, 'Montant maximum (anti-fraude)')
on conflict (key) do nothing;

-- RLS : tout le monde peut lire, seul super-admin peut écrire
alter table app_config enable row level security;
create policy "Tout le monde lit les configs" on app_config for select using (true);
create policy "Super-admin modifie configs" on app_config for all
  using (exists(select 1 from profiles where id = auth.uid() and role = 'super_admin'));

-- Realtime sur app_config : changement instantané dans toutes les apps connectées
alter publication supabase_realtime add table app_config;

-- ════════════════════════════════════════════════════════════
-- TABLES PAIEMENT (13-16)
-- ════════════════════════════════════════════════════════════

-- ENUMS paiement
-- Note: tous les enums sont définis dès la V1.0 pour éviter les migrations ALTER ENUM (complexes en Postgres).
-- L'activation se fait via feature flags côté app, pas via la DB.
create type payment_method_type as enum (
  -- ═══ V1.0 — AFRIQUE FRANCOPHONE (CinetPay) ═══
  -- Cameroun
  'mtn_momo_cm', 'orange_money_cm',
  -- Côte d'Ivoire
  'mtn_momo_ci', 'orange_money_ci', 'moov_money_ci', 'wave_ci',
  -- Sénégal
  'orange_money_sn', 'wave_sn', 'free_money_sn',
  -- Bénin / Togo / Burkina / Mali / Niger
  'mtn_momo_bj', 'moov_money_bj',
  'tmoney_tg', 'flooz_tg',
  'orange_money_bf', 'moov_money_bf',
  'orange_money_ml', 'moov_money_ml',
  -- Gabon / Congo / Tchad
  'airtel_money_ga', 'moov_money_ga',
  'mtn_momo_cg', 'airtel_money_cg',
  'airtel_money_td',

  -- ═══ V1.1 — AFRIQUE ANGLOPHONE (Flutterwave, prêt mais désactivé) ═══
  'card_visa', 'card_mastercard', 'card_verve',
  'mpesa_ke',                                          -- Kenya M-Pesa
  'mtn_momo_gh', 'airteltigo_gh', 'vodafone_cash_gh',  -- Ghana
  'mtn_momo_ug', 'airtel_money_ug',                    -- Ouganda
  'mtn_momo_rw',                                       -- Rwanda
  'bank_transfer_ng', 'ussd_ng',                       -- Nigeria
  'bank_transfer_za',                                  -- Afrique du Sud

  -- ═══ V1.2 — MAGHREB (Paymob/Paymee/CMI/SATIM, prêt mais désactivé) ═══
  'card_cmi_ma',                                       -- Maroc CMI
  'edahabia_dz', 'cib_dz',                             -- Algérie
  'paymee_tn', 'card_clictopay_tn',                    -- Tunisie
  'fawry_eg', 'paymob_eg',                             -- Égypte

  -- ═══ V1.0 — CRYPTO (NowPayments, fallback mondial) ═══
  'crypto_usdt_trc20', 'crypto_usdt_erc20',
  'crypto_btc', 'crypto_eth', 'crypto_bnb'
);
create type payment_status as enum (
  'pending', 'processing', 'completed', 'failed', 'cancelled', 'refunded'
);
create type payment_provider as enum (
  'cinetpay',      -- V1.0 actif
  'nowpayments',   -- V1.0 actif
  'flutterwave',   -- V1.1 actif
  'cmi',           -- V1.2 actif (Maroc)
  'satim',         -- V1.2 actif (Algérie)
  'paymee',        -- V1.2 actif (Tunisie)
  'paymob'         -- V1.2 actif (Égypte)
);
create type payout_status as enum (
  'pending_admin_validation',  -- ⚠️ NOUVEAU : créé auto, attente validation admin
  'processing',                -- En cours d'envoi via CinetPay/NowPayments
  'completed',                 -- Paiement reçu par le gagnant
  'failed',                    -- Échec technique (réessaie possible)
  'rejected_by_admin',         -- Refusé par l'admin (raison à fournir)
  'cancelled',                 -- Annulé (compétition annulée, etc.)
  'on_hold'                    -- Mis en attente par l'admin (litige, enquête)
);

-- 22. PAYMENTS (paiements entrants : inscriptions)
create table payments (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid not null references profiles on delete restrict,
  competition_id uuid not null references competitions on delete restrict,
  -- Montant en devise locale du joueur (ce qu'il voit/paie)
  amount_local numeric(12,2) not null check (amount_local > 0),
  currency_local text not null,                  -- ISO 4217: EUR, INR, XAF, USD...
  -- Montant en USD (référence comptable)
  amount_usd numeric(12,2) not null,
  exchange_rate_used numeric(12,6) not null,     -- Taux figé au moment du paiement
  -- Provider
  method payment_method_type not null,
  provider payment_provider not null,
  provider_transaction_id text,
  provider_payment_url text,
  provider_metadata jsonb default '{}',
  -- État
  status payment_status not null default 'pending',
  failure_reason text,
  -- Anti-fraude
  ip_address inet,
  ip_country_code text,                          -- Pays détecté par IP
  user_agent text,
  fraud_score numeric(3,2),                      -- 0.00 (safe) → 1.00 (fraud)
  -- Timestamps
  created_at timestamptz default now(),
  completed_at timestamptz,
  expires_at timestamptz default (now() + interval '30 minutes'),
  webhook_received_at timestamptz,
  webhook_payload jsonb
);

-- 23. PAYOUTS (versements gagnants — VALIDATION MANUELLE ADMIN OBLIGATOIRE)
create table payouts (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid not null references profiles on delete restrict,
  competition_id uuid not null references competitions on delete restrict,
  -- Position dans le top 4 (1=Champion, 2=Finaliste, 3=3ème, 4=4ème)
  position int not null check (position between 1 and 4),
  -- Montants
  amount_usd numeric(12,2) not null check (amount_usd > 0),
  amount_local numeric(12,2) not null,
  currency_local text not null,
  exchange_rate_used numeric(12,6) not null,
  -- Destination
  destination_method payment_method_type not null,
  destination_account text not null,
  destination_metadata jsonb default '{}',
  -- État
  status payout_status not null default 'pending_admin_validation',
  provider payment_provider,
  provider_transaction_id text,
  failure_reason text,
  -- Vérifications auto au moment de la création (informatives)
  auto_checks jsonb default '{}',  
  -- Ex: {"kyc_verified": true, "no_disputes": true, "no_anti_cheat_anomalies": true,
  --      "not_banned": true, "payment_data_complete": true}
  -- KYC
  kyc_required boolean default false,
  kyc_verified boolean default false,
  -- VALIDATION ADMIN MANUELLE (CRITIQUE)
  validated_by_admin_id uuid references profiles(id),
  validated_at timestamptz,
  validation_justification text,                -- Raison de la décision (Refus/Hold)
  validation_admin_ip inet,                     -- IP de l'admin pour audit
  validation_admin_user_agent text,             -- User-agent pour audit
  -- Timestamps
  created_at timestamptz default now(),
  processed_at timestamptz                      -- Quand le paiement a été envoyé
);

create index idx_payouts_status on payouts(status, created_at desc);
create index idx_payouts_competition on payouts(competition_id);

-- 24. PLATFORM REVENUE (commissions, multi-devises)
create table platform_revenue (
  id uuid primary key default uuid_generate_v4(),
  competition_id uuid not null references competitions on delete restrict,
  total_collected_usd numeric(12,2) not null,
  total_paid_out_usd numeric(12,2) not null,
  commission_usd numeric(12,2) not null,
  commission_pct numeric(5,2) not null,
  computed_at timestamptz default now()
);

-- 25. PAYMENT WEBHOOK LOG
create table payment_webhook_log (
  id uuid primary key default uuid_generate_v4(),
  provider payment_provider not null,
  raw_payload jsonb not null,
  signature text,
  signature_valid boolean,
  payment_id uuid references payments(id),
  payout_id uuid references payouts(id),
  processed boolean default false,
  error text,
  received_at timestamptz default now()
);

-- 26. EXCHANGE RATES (cache des taux, vs USD)
create table exchange_rates (
  currency_code text primary key,                 -- 'EUR', 'XAF', 'INR'...
  rate_to_usd numeric(12,6) not null,             -- 1 EUR = 1.08 USD → rate = 1.08
  source text default 'exchangerate.host',
  updated_at timestamptz default now()
);

-- Données initiales exchange_rates (taux approximatifs, mis à jour par Edge Function)
-- Stratégie : tout converti vs USD comme référence
insert into exchange_rates (currency_code, rate_to_usd) values
  ('USD', 1.000000),
  -- Afrique francophone (CFA pegged à EUR)
  ('XAF', 0.001650),    -- 1 XAF ≈ 0.00165 USD (1 USD ≈ 605 XAF)
  ('XOF', 0.001650),    -- Idem (parité fixe)
  -- Maghreb
  ('MAD', 0.100000),    -- 1 MAD ≈ 0.10 USD (1 USD ≈ 10 MAD)
  ('DZD', 0.007400),    -- 1 DZD ≈ 0.0074 USD
  ('TND', 0.320000),    -- 1 TND ≈ 0.32 USD
  ('EGP', 0.020000),    -- 1 EGP ≈ 0.02 USD (très volatile, à actualiser)
  -- Afrique anglophone
  ('NGN', 0.000650),    -- 1 NGN ≈ 0.00065 USD (très volatile)
  ('GHS', 0.066000),    -- 1 GHS ≈ 0.066 USD
  ('KES', 0.007700),    -- 1 KES ≈ 0.0077 USD
  ('ZAR', 0.054000),    -- 1 ZAR ≈ 0.054 USD
  ('UGX', 0.000270),    -- 1 UGX ≈ 0.00027 USD
  ('TZS', 0.000390),    -- 1 TZS ≈ 0.00039 USD
  ('RWF', 0.000770)     -- 1 RWF ≈ 0.00077 USD
on conflict (currency_code) do nothing;

-- INDEX paiement
create index idx_payments_user on payments(user_id, created_at desc);
create index idx_payments_competition on payments(competition_id);
create index idx_payments_status on payments(status) where status in ('pending', 'processing');
create index idx_payments_provider_tx on payments(provider_transaction_id);
create index idx_payouts_user on payouts(user_id);
create index idx_payouts_pending on payouts(status) where status in ('pending', 'processing');

-- TRIGGER : recalculer prize_pool_usd quand un paiement est completed
create or replace function update_prize_pool()
returns trigger as $$
declare
  comp_id uuid;
  total numeric(12,2);
  commission_pct numeric(5,2);
begin
  if (TG_OP = 'INSERT' or TG_OP = 'UPDATE') and NEW.status = 'completed' then
    comp_id := NEW.competition_id;
  else
    return NEW;
  end if;

  select coalesce(sum(amount_usd), 0), c.platform_commission_pct
  into total, commission_pct
  from payments p
  join competitions c on c.id = comp_id
  where p.competition_id = comp_id and p.status = 'completed'
  group by c.platform_commission_pct;

  update competitions
  set prize_pool_usd = total * (1 - commission_pct / 100)
  where id = comp_id;

  return NEW;
end;
$$ language plpgsql;

create trigger payments_update_prize_pool
  after insert or update on payments
  for each row execute function update_prize_pool();

-- RLS paiements
alter table payments enable row level security;
alter table payouts enable row level security;

create policy "Voir ses propres paiements" on payments for select
  using (auth.uid() = user_id);
create policy "Voir ses propres payouts" on payouts for select
  using (auth.uid() = user_id);
create policy "Super-admin voit tout" on payments for all
  using (exists(select 1 from profiles where id = auth.uid() and role = 'super_admin'));
create policy "Super-admin gère payouts" on payouts for all
  using (exists(select 1 from profiles where id = auth.uid() and role = 'super_admin'));

-- ════════════════════════════════════════════════════════════
-- FIN TABLES PAIEMENT
-- ════════════════════════════════════════════════════════════

-- ════════════════════════════════════════════════════════════
-- TRIGGERS GLOBAUX (updated_at)
-- ════════════════════════════════════════════════════════════

-- TRIGGER : update profile updated_at
create or replace function update_updated_at()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

create trigger profiles_updated_at before update on profiles
  for each row execute function update_updated_at();

-- TRIGGER : créer profil automatiquement à l'inscription
create or replace function handle_new_user()
returns trigger as $$
begin
  insert into profiles (id, email, username, country_code)
  values (
    new.id,
    new.email,
    coalesce(new.raw_user_meta_data->>'username', split_part(new.email, '@', 1)),
    coalesce(new.raw_user_meta_data->>'country_code', 'FR')
  );
  return new;
end;
$$ language plpgsql security definer;

create trigger on_auth_user_created after insert on auth.users
  for each row execute function handle_new_user();

-- ROW LEVEL SECURITY
alter table profiles enable row level security;
alter table competitions enable row level security;
alter table matches enable row level security;
alter table notifications enable row level security;
alter table chat_messages enable row level security;

-- Politiques basiques (à raffiner par phase)
create policy "Profils publics en lecture" on profiles for select using (true);
create policy "Modifier son propre profil" on profiles for update using (auth.uid() = id);

create policy "Compétitions publiques en lecture" on competitions for select using (true);
create policy "Admins gèrent leurs compétitions" on competitions for all
  using (auth.uid() = admin_id or exists(
    select 1 from profiles where id = auth.uid() and role = 'super_admin'
  ));

create policy "Notifications privées" on notifications for select using (auth.uid() = user_id);

-- REALTIME
alter publication supabase_realtime add table matches;
alter publication supabase_realtime add table notifications;
alter publication supabase_realtime add table chat_messages;
alter publication supabase_realtime add table streams;
alter publication supabase_realtime add table anti_cheat_events;
alter publication supabase_realtime add table payments;
alter publication supabase_realtime add table payouts;
```

---

## 🚀 PHASES D'EXÉCUTION

> **Règle d'or** : tu finis une phase entière, tu fais tester l'utilisateur, tu attends son "OK phase suivante" avant de continuer.

---

### **PHASE 0 — Setup environnement + Flavors (1h)**

**Objectif** : avoir un projet Flutter avec **2 flavors fonctionnels** (user + admin) qui démarrent chacun de leur côté, connectés à Supabase.

**Étapes :**

1. Vérifier `flutter doctor` (Android Studio + Xcode si Mac, Chrome installé pour le web)
2. Activer le support web Flutter : `flutter config --enable-web`
3. Créer le projet : `flutter create arena --org com.arena --platforms=android,ios,web`
4. Configurer `pubspec.yaml` avec **toutes** les dépendances de la stack (incluant `flutter_flavorizr`, `otp`, `qr_flutter`, `flutter_adaptive_scaffold`)

5. **Configurer les flavors** (crucial, le faire EN PREMIER) :
   - Créer le fichier `flavorizr.yaml` à la racine (cf. section CONFIGURATION DES FLAVORS)
   - Lancer : `flutter pub run flutter_flavorizr`
   - Vérifier que `android/app/build.gradle` contient les 2 productFlavors
   - Vérifier que iOS a 2 schemes : "user" et "admin" dans Xcode

6. Créer manuellement les 2 entry points :
   - `lib/main_user.dart` (cf. section flavors)
   - `lib/main_admin.dart`
   - `lib/app_user.dart` (MaterialApp user)
   - `lib/app_admin.dart` (MaterialApp admin avec adaptive_scaffold)
   - `lib/flavors/flavor_config.dart` (singleton)

7. Créer `.env.example` :
   ```
   # ═══ SUPABASE (partagé) ═══
   SUPABASE_URL=
   SUPABASE_ANON_KEY=

   # ═══ COMMUNICATION (user app uniquement) ═══
   AGORA_APP_ID=
   AGORA_APP_CERTIFICATE=
   FCM_SERVER_KEY=
   GOOGLE_WEB_CLIENT_ID=
   ```

   **⚠️ IMPORTANT** : les clés providers paiement ne vont **PAS** dans le `.env` Flutter.
   Elles doivent être uniquement dans les **Secrets Supabase** :
   ```bash
   supabase secrets set CINETPAY_API_KEY=xxx
   supabase secrets set CINETPAY_SITE_ID=xxx
   supabase secrets set CINETPAY_SECRET_KEY=xxx
   supabase secrets set NOWPAYMENTS_API_KEY=xxx
   supabase secrets set NOWPAYMENTS_IPN_SECRET=xxx
   ```

8. Configurer `analysis_options.yaml` avec `very_good_analysis`
9. Créer la structure de dossiers selon l'arbo (avec `features_user/`, `features_admin/`, `features_shared/`)
10. Configurer `.gitignore` (.env, build/, .dart_tool/, ios/Flutter/Generated.xcconfig)
11. Configurer Android :
    - `minSdkVersion 23` dans `android/app/build.gradle`
    - `applicationIdSuffix` différents par flavor (`.user` et `.admin` ne sont pas ajoutés ici car les apps ont des IDs différents)
12. Configurer iOS : `platform :ios, '13.0'` dans `ios/Podfile`
13. Demander les permissions Android et iOS différentes selon flavor :
    - **User** (`features_user/recording`) : caméra, micro, enregistrement écran, overlay window, notifications
    - **Admin** : caméra (pour scan QR TOTP), notifications uniquement
14. Configurer `.vscode/launch.json` avec les 3 configs (cf. section flavors)

**Livrables côté utilisateur :**
- Créer le projet Supabase (https://supabase.com)
- Exécuter le SQL complet dans SQL Editor
- Créer le projet Firebase (uniquement pour FCM côté user)
- Créer le projet Agora (https://console.agora.io) avec **App ID + App Certificate** :
  - **RTM activé** (chat texte gratuit jusqu'à 100k MAU) — pour la présence (typing, online/offline)
  - **RTC activé** (streaming vidéo) — utilisé uniquement pour les matchs sélectionnés par l'admin
- **🆕 Créer un compte Sentry** (https://sentry.io) pour le crash reporting :
  - Plan gratuit : 5 000 événements/mois (largement suffisant V1.0)
  - Créer 2 projets : `arena-user` et `arena-admin`
  - Récupérer les DSN (data source names) à mettre dans `.env`
- Pour le web admin : préparer un domaine pour plus tard (`admin.arena-app.com`)
- Remplir `.env`

**🆕 Setup Sentry (crash reporting) — 30 min :**

Dans `lib/main_user.dart` et `lib/main_admin.dart`, wrapper l'app dans Sentry :

```dart
// lib/main_user.dart
import 'package:sentry_flutter/sentry_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load();
  
  await SentryFlutter.init(
    (options) {
      options.dsn = dotenv.env['SENTRY_DSN_USER']!;
      options.environment = FlavorConfig.instance.environment;
      options.tracesSampleRate = 0.2;        // 20% des transactions tracées (perf)
      options.profilesSampleRate = 0.2;
      options.attachScreenshot = true;        // Screenshot automatique sur crash
      options.attachViewHierarchy = true;     // Hiérarchie des widgets
    },
    appRunner: () => runApp(const ProviderScope(child: ArenaUserApp())),
  );
}
```

**Avantages immédiats** :
- Tu sauras dès le 1er crash en prod **où** ça crashe (stack trace complète)
- Screenshots automatiques pour reproduire visuellement
- Performance monitoring (écrans lents, requêtes Supabase qui timeout, etc.)
- Notifications email à chaque nouveau type d'erreur

**Test final** :
- `flutter run --flavor user --target lib/main_user.dart` doit lancer l'app User (icône bleue, nom "ARENA")
- `flutter run --flavor admin --target lib/main_admin.dart` doit lancer l'app Admin (icône rouge, nom "ARENA Admin")
- `flutter run --flavor admin --target lib/main_admin.dart -d chrome` doit ouvrir l'app Admin dans Chrome
- **🆕 Test Sentry** : provoquer un crash test (`throw Exception('test sentry')`) et vérifier qu'il apparaît dans le dashboard Sentry

---

### **PHASE 0.5 — Onboarding 4 écrans (2-3h)** ⭐ NOUVEAU

> 🎯 **Objectif** : créer l'expérience de premier lancement pour réduire l'abandon des nouveaux utilisateurs. **60% des utilisateurs qui n'ont pas d'onboarding abandonnent au 2e écran**.

**Concerne uniquement l'app User** (l'admin se connecte directement par invitation).

**Workflow** :
1. Premier lancement de l'app → check `profiles.onboarding_completed = false` (ou pas connecté)
2. Affichage des 4 écrans d'onboarding
3. Bouton "PASSER" disponible (sauf dernier écran)
4. À la fin → redirection vers SignUpPage
5. Après inscription → marquer `onboarding_completed = true`

**Écrans :**

#### Écran 1/4 — Bienvenue
```
┌──────────────────────────────────────┐
│                                      │
│    [Animation : logo ARENA pulse]    │
│                                      │
│                                      │
│       BIENVENUE SUR ARENA            │
│                                      │
│  La plateforme #1 de tournois        │
│  eFootball, FIFA et FC Mobile        │
│  en Afrique francophone              │
│                                      │
│         [Indicateur • ○ ○ ○]         │
│                                      │
│  [PASSER]              [SUIVANT →]   │
└──────────────────────────────────────┘
```

#### Écran 2/4 — Concept brackets
```
┌──────────────────────────────────────┐
│                                      │
│    [Illustration : bracket animé]    │
│                                      │
│                                      │
│      JOUE DE VRAIS TOURNOIS          │
│                                      │
│  Inscris-toi à des tournois         │
│  organisés par des admins.           │
│  Joue en bracket, gagne des prix.    │
│                                      │
│         [Indicateur ○ • ○ ○]         │
│                                      │
│  [PASSER]              [SUIVANT →]   │
└──────────────────────────────────────┘
```

#### Écran 3/4 — Système de match
```
┌──────────────────────────────────────┐
│                                      │
│   [Illustration : 2 téléphones      │
│    avec partage de code room]        │
│                                      │
│                                      │
│        JOUE AVEC TES AMIS            │
│                                      │
│  Code room partagé automatiquement,  │
│  chat intégré, validation de score   │
│  collaborative. C'est simple.        │
│                                      │
│         [Indicateur ○ ○ • ○]         │
│                                      │
│  [PASSER]              [SUIVANT →]   │
└──────────────────────────────────────┘
```

#### Écran 4/4 — Paiement / Inscription
```
┌──────────────────────────────────────┐
│                                      │
│   [Illustration : MoMo + trophée]    │
│                                      │
│                                      │
│       GAGNE DES VRAIS GAINS          │
│                                      │
│  Top 4 récompensés. Paiement direct  │
│  sur ton MTN MoMo, Orange Money,     │
│  Wave ou en crypto.                  │
│                                      │
│         [Indicateur ○ ○ ○ •]         │
│                                      │
│      [    COMMENCER →    ]           │
└──────────────────────────────────────┘
```

**Logique technique** :

```dart
// lib/features_user/onboarding/onboarding_page.dart
class OnboardingPage extends ConsumerStatefulWidget {
  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  final PageController _controller = PageController();
  int _currentPage = 0;
  
  final pages = [
    OnboardingSlide(
      illustration: 'assets/onboarding/welcome.json', // Lottie animation
      title: 'Bienvenue sur ARENA',
      description: 'La plateforme #1 de tournois...',
    ),
    // ... 3 autres pages
  ];

  void _completeOnboarding() async {
    // Marquer dans SharedPreferences (avant inscription)
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completed', true);
    
    // Si user connecté, marquer aussi en DB
    if (ref.read(currentUserProvider) != null) {
      await supabase.from('profiles').update({
        'onboarding_completed': true,
        'onboarding_completed_at': DateTime.now().toIso8601String(),
      }).eq('id', currentUser.id);
    }
    
    // Redirection
    context.goNamed('signup');
  }
}
```

**Stockage de l'état** :
- Avant inscription : `SharedPreferences` (clé `onboarding_completed`)
- Après inscription : `profiles.onboarding_completed` en DB
- Permet à l'utilisateur de revoir l'onboarding plus tard via Settings

**Logique d'affichage** :
- Premier lancement (jamais ouvert l'app) → onboarding obligatoire
- Si utilisateur déconnecté ayant déjà vu → skip onboarding
- Settings → bouton "Revoir l'introduction" possible

**Ressources nécessaires** :
- 4 illustrations (Lottie animations OU images PNG/SVG)
- Suggestion gratuite : LottieFiles.com pour des animations légères
- À créer ou commander à un freelance designer (~50-100€)

**Test** :
- Désinstaller/réinstaller l'app → vérifier que l'onboarding s'affiche
- Cliquer "PASSER" sur écran 1 → arriver direct au SignUpPage
- Compléter les 4 écrans → arriver au SignUpPage
- Réinstaller, se connecter avec un compte ayant `onboarding_completed = true` → pas d'onboarding

---

### **PHASE 1 — Theme + Router + Widgets de base (1h)**

**Objectif** : avoir un design system fonctionnel.

**À créer :**
- `core/theme/colors.dart` (palette ARENA)
- `core/theme/typography.dart` (Bebas Neue / Space Grotesk / Instrument Serif / JetBrains Mono via google_fonts)
- `core/theme/theme.dart` (ThemeData dark complet)
- `core/router/app_router.dart` (GoRouter avec routes vides pour l'instant)
- `core/widgets/arena_button.dart` (3 variantes : primary, ghost, danger)
- `core/widgets/gradient_card.dart`
- `core/widgets/status_pill.dart` (LIVE, EN ATTENTE, TERMINÉ, etc.)
- `core/widgets/arena_text_field.dart`
- `core/widgets/glow_border.dart`
- `core/services/supabase_service.dart` (init + provider Riverpod)
- `main.dart` (init Supabase + Firebase + ProviderScope)
- `app.dart` (MaterialApp.router avec theme)

**Test** : créer un écran de démo qui montre tous les widgets. `flutter run` doit afficher les boutons, cartes, badges avec le bon thème dark esport.

---

### **PHASE 1 BIS — i18n + Devises + Feature Flags (V1.0 = FR + XAF/XOF) (2-3h)**

> ⚠️ **À FAIRE AVANT TOUT le reste de l'UI.** Si tu skippes cette phase, tu auras des strings en dur partout et la migration sera un cauchemar.

#### 🎯 Objectif

Avoir une infrastructure complète prête pour 3 langues et 14 devises (architecture V1.2), mais **n'activer que FR + XAF/XOF/USD** au lancement V1.0.

#### 📋 Sous-phases

**SOUS-PHASE 1B.1 — Setup ARB files + Feature Flags (1h)**

1. Activer la génération i18n dans `pubspec.yaml` (`generate: true`)
2. Créer `l10n.yaml` à la racine (template = `app_fr.arb`, FR est priorité)
3. Créer les 3 fichiers ARB dans `lib/l10n/` :
   - `app_fr.arb` → contenu réel (V1.0 actif)
   - `app_en.arb` → traductions placeholder (à remplir au fil de l'eau, activé en V1.1)
   - `app_ar.arb` → traductions placeholder (V1.2)
4. Créer `core/services/feature_flags_service.dart` :
   ```dart
   @riverpod
   class FeatureFlags extends _$FeatureFlags {
     @override
     Stream<FeatureFlagsState> build() {
       return supabase
         .from('app_config')
         .stream(primaryKey: ['key'])
         .map((rows) => FeatureFlagsState.fromRows(rows));
     }
   }

   @freezed
   class FeatureFlagsState with _$FeatureFlagsState {
     const factory FeatureFlagsState({
       @Default(true) bool frenchEnabled,
       @Default(false) bool englishEnabled,
       @Default(false) bool arabicEnabled,
       @Default(true) bool cinetpayEnabled,
       @Default(false) bool flutterwaveEnabled,
       @Default(false) bool maghrebEnabled,
       @Default(['CM','GA','CG','TD','CF','GQ','CI','SN','BJ','TG','BF','ML','NE','MG','KM','DJ'])
       List<String> allowedCountries,
       @Default(['XAF','XOF','USD']) List<String> activeCurrencies,
     }) = _FeatureFlagsState;
   }
   ```

5. Configurer `MaterialApp.router` avec gating :
   ```dart
   final flags = ref.watch(featureFlagsProvider).valueOrNull;
   final supportedLocales = [
     const Locale('fr'),  // Toujours actif
     if (flags?.englishEnabled ?? false) const Locale('en'),
     if (flags?.arabicEnabled ?? false) const Locale('ar'),
   ];

   return MaterialApp.router(
     localizationsDelegates: AppLocalizations.localizationsDelegates,
     supportedLocales: supportedLocales,
     locale: ref.watch(localeProvider),  // Lit profile.preferred_language
   );
   ```

**Test 1B.1** : changer `lang_en_enabled` à `true` dans Supabase → l'option Anglais apparaît instantanément dans le sélecteur de langue de l'app, sans redémarrage.

---

**SOUS-PHASE 1B.2 — Premier set de strings FR + placeholders EN/AR (45min)**

Traduire les strings critiques pour les phases 2-3 (auth + home).

**Stratégie pour V1.0** :
- Écrire FR d'abord (~30 strings)
- Mettre une **note TODO** dans `app_en.arb` et `app_ar.arb` (placeholder identique à FR temporairement)
- Activer EN/AR seulement quand un humain les a vraiment traduits

**Exemple `app_fr.arb`** :
```json
{
  "@@locale": "fr",
  "appName": "ARENA",
  "tagline": "La Plateforme des Compétitions Gaming",
  "loginButton": "SE CONNECTER",
  "competitionPlayers": "{count, plural, =0{Aucun joueur} =1{1 joueur} other{{count} joueurs}}",
  "@competitionPlayers": {
    "placeholders": { "count": { "type": "int" } }
  }
}
```

**Exemple `app_en.arb` (placeholder pour V1.1)** :
```json
{
  "@@locale": "en",
  "appName": "ARENA",
  "tagline": "[TODO-EN] La Plateforme des Compétitions Gaming",
  "loginButton": "[TODO-EN] SE CONNECTER",
  "competitionPlayers": "{count, plural, =0{No players} =1{1 player} other{{count} players}}"
}
```

Le tag `[TODO-EN]` te rappelle de traduire avant d'activer EN. Tu peux scanner ton repo pour les trouver : `grep -r "TODO-EN" lib/l10n/`.

**Test 1B.2** : ajouter sélecteur de langue temporaire dans Settings (caché derrière flag `dev_mode`), switcher FR → EN → AR, vérifier que tout bascule sans crash.

---

**SOUS-PHASE 1B.3 — Service Currency + cache exchange rates (1h)**

1. Créer `currency_service.dart` :
   ```dart
   class CurrencyService {
     // Toutes les devises supportées (architecture V1.2)
     static const allSupported = [
       'XAF', 'XOF', 'USD',                           // V1.0
       'NGN', 'GHS', 'KES', 'ZAR', 'UGX', 'RWF', 'TZS',  // V1.1
       'MAD', 'DZD', 'TND', 'EGP',                    // V1.2
     ];

     // Devises actives selon feature flags
     List<String> activeCurrencies(FeatureFlagsState flags) =>
       flags.activeCurrencies;

     // Mapping pays → devise (toutes versions)
     static const countryToCurrency = {
       // CEMAC → XAF
       'CM': 'XAF', 'GA': 'XAF', 'CG': 'XAF',
       'TD': 'XAF', 'CF': 'XAF', 'GQ': 'XAF',
       // UEMOA → XOF
       'CI': 'XOF', 'SN': 'XOF', 'BJ': 'XOF',
       'TG': 'XOF', 'BF': 'XOF', 'ML': 'XOF', 'NE': 'XOF',
       // V1.1
       'NG': 'NGN', 'GH': 'GHS', 'KE': 'KES',
       'ZA': 'ZAR', 'UG': 'UGX', 'RW': 'RWF', 'TZ': 'TZS',
       // V1.2
       'MA': 'MAD', 'DZ': 'DZD', 'TN': 'TND', 'EG': 'EGP',
     };

     Future<double> convertUsdTo(double amountUsd, String targetCurrency);
     String formatAmount(double amount, String currency, Locale locale);
   }
   ```

2. Edge Function Supabase `fetch-exchange-rates` :
   - Appelle `https://api.exchangerate.host/latest?base=USD`
   - Met à jour la table `exchange_rates`
   - Cron horaire via `pg_cron`

3. Cache local : `shared_preferences` avec timestamp, fallback offline.

**Test 1B.3** : appel manuel à l'Edge Function → table `exchange_rates` mise à jour → app affiche taux. Couper le wifi → app utilise cache.

---

**SOUS-PHASE 1B.4 — Widget LocalizedAmount (30min)**

```dart
class LocalizedAmount extends ConsumerWidget {
  final double amountUsd;
  final TextStyle? style;
  final bool showUsdEquivalent;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userCurrency = ref.watch(userCurrencyProvider);
    final rate = ref.watch(exchangeRateProvider(userCurrency));
    final localAmount = amountUsd * rate;
    final locale = Localizations.localeOf(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          NumberFormat.currency(
            locale: locale.toString(),
            symbol: _getSymbol(userCurrency),
            decimalDigits: _getDecimals(userCurrency),  // XAF/XOF=0, USD=2
          ).format(localAmount),
          style: style,
        ),
        if (showUsdEquivalent && userCurrency != 'USD')
          Text('≈ ${amountUsd.toStringAsFixed(2)} USD',
            style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ],
    );
  }
}
```

`LocalizedAmount(amountUsd: 5.0)` affiche `2 800 XAF` au Cameroun, `5,00 $` aux USA.

---

**SOUS-PHASE 1B.5 — Test RTL (V1.0 = pré-développement, V1.2 = activation) (30min)**

Activer temporairement la locale `ar` côté dev (ne pas committer), naviguer dans l'app pour repérer les bugs RTL. Si l'arabe est désactivé via flag, ça ne sera pas accessible aux users finaux V1.0.

**Configuration polices arabes** dans `theme.dart` :
```dart
TextTheme buildTextTheme(Locale locale) {
  if (locale.languageCode == 'ar') {
    return TextTheme(
      bodyMedium: GoogleFonts.cairo(),
      headlineLarge: GoogleFonts.tajawal(fontWeight: FontWeight.bold),
    );
  }
  return TextTheme(
    bodyMedium: GoogleFonts.nunito(),
    headlineLarge: GoogleFonts.orbitron(fontWeight: FontWeight.bold),
  );
}
```

**Règle gravée** : à partir de maintenant, **chaque nouveau widget doit utiliser `EdgeInsetsDirectional` et `AlignmentDirectional`** même si AR n'est pas actif en V1.0.

---

#### ✅ Critères d'acceptation phase 1 BIS

- [ ] Aucune string hardcodée dans le code (`AppLocalizations` partout)
- [ ] L'app démarre en français par défaut
- [ ] Feature flags chargés depuis Supabase au démarrage
- [ ] Changer un flag dans Supabase impacte l'app en temps réel
- [ ] Les 3 fichiers ARB existent (FR rempli, EN/AR avec placeholders TODO)
- [ ] Le widget `LocalizedAmount(amountUsd: 5.0)` affiche `2 800 XAF` pour un user CM
- [ ] Les taux de change se mettent à jour automatiquement
- [ ] Le code utilise `EdgeInsetsDirectional` partout (RTL-ready)
- [ ] Polices Cairo/Tajawal chargées si AR activé (sinon Space Grotesk/Bebas Neue)

---

### **PHASE 2 — Authentification User (App USER, 4-5h)** ⭐ **ENRICHIE**

> 🎮 Cette phase concerne **uniquement l'app USER** (`features_user/auth/`). L'auth admin est traitée en PHASE 2 BIS séparément.

**Objectif** : un joueur peut s'inscrire, se connecter, se déconnecter, **récupérer son mot de passe**, et se connecter via **Google ou Apple**.

**Écrans (`features_user/auth/`) :**
- `SplashUserScreen` (logo animé, stats plateforme, 2 CTAs : "Rejoindre" / "J'ai déjà un compte")
- `LoginUserScreen` (email/password + boutons Google + Apple + lien "Mot de passe oublié")
- `RegisterUserScreen` (3 étapes avec stepper : compte → profil → succès)
- `ForgotPasswordPage` ⭐ **NOUVEAU** (saisie email → envoi mail reset)
- `ResetPasswordPage` ⭐ **NOUVEAU** (depuis deep link mail → nouveau mot de passe)
- `LinkExistingAccountPage` ⭐ **NOUVEAU** (cas où user social tente de se connecter avec email déjà existant)

**Important** : aucun bouton "Connexion Admin" sur le splash de l'app User. Les admins utilisent **une app différente**.

#### 🔑 SOUS-PHASE 2.1 — Auth email/password classique (1h)

**Logique de base (existait déjà)** :
- `auth_user_repository.dart` : `signUp`, `signIn`, `signOut`
- `auth_user_provider.dart` (Riverpod) : `StreamProvider<AuthState>` qui écoute `Supabase.instance.client.auth.onAuthStateChange`
- **Filtre rôle au login** : si `profile.role != 'player'`, on déconnecte
- `user_router.dart` route guard
- Validation forms (email regex, password strength)

#### 🔑 SOUS-PHASE 2.2 — Forgot Password (1h) ⭐ NOUVEAU

**Workflow complet** :

1. Sur `LoginUserScreen` → bouton "Mot de passe oublié ?"
2. → `ForgotPasswordPage` :
   ```
   ┌──────────────────────────────────────┐
   │  ← Retour                            │
   │                                      │
   │  🔒 RÉINITIALISATION                 │
   │                                      │
   │  Saisis ton email pour recevoir un   │
   │  lien de réinitialisation            │
   │                                      │
   │  📧 Email                            │
   │  [_________________________]         │
   │                                      │
   │  [    ENVOYER LE LIEN    ]           │
   │                                      │
   │  💡 Vérifie aussi tes spams          │
   └──────────────────────────────────────┘
   ```

3. Au clic → appel à Supabase :
   ```dart
   await supabase.auth.resetPasswordForEmail(
     email,
     redirectTo: 'arenaapp://reset-password',  // Deep link custom
   );
   ```

4. Toast vert : "Email envoyé ! Vérifie ta boîte de réception."

5. **Côté email** : Supabase envoie un email avec un lien `arenaapp://reset-password?token=xxx`
   - L'email est customisable dans Supabase Dashboard → Authentication → Email Templates
   - Template à personnaliser en français avec le branding ARENA

6. **Deep link handling** : quand l'utilisateur clique sur le lien :
   - Si app installée → ouvre directement `ResetPasswordPage`
   - Si app pas installée → redirige vers App Store / Play Store

7. → `ResetPasswordPage` :
   ```
   ┌──────────────────────────────────────┐
   │  🔒 NOUVEAU MOT DE PASSE             │
   │                                      │
   │  Choisis un nouveau mot de passe     │
   │  pour ton compte                     │
   │                                      │
   │  🔑 Nouveau mot de passe             │
   │  [_________________________]  👁️     │
   │                                      │
   │  ✓ Au moins 8 caractères             │
   │  ✓ Une majuscule                     │
   │  ✓ Un chiffre                        │
   │                                      │
   │  🔑 Confirmer                        │
   │  [_________________________]  👁️     │
   │                                      │
   │  [    METTRE À JOUR    ]             │
   └──────────────────────────────────────┘
   ```

8. Au clic → appel Supabase :
   ```dart
   await supabase.auth.updateUser(
     UserAttributes(password: newPassword),
   );
   ```

9. → Redirection vers `HomePage` (auto-connecté)

**Setup deep link Android** (`android/app/src/main/AndroidManifest.xml`) :
```xml
<intent-filter android:autoVerify="true">
    <action android:name="android.intent.action.VIEW" />
    <category android:name="android.intent.category.DEFAULT" />
    <category android:name="android.intent.category.BROWSABLE" />
    <data android:scheme="arenaapp" />
</intent-filter>
```

**Setup deep link iOS** (`ios/Runner/Info.plist`) :
```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>arenaapp</string>
        </array>
    </dict>
</array>
```

**Lib Flutter** : `app_links` ^6.0 ou `uni_links` pour écouter les deep links.

#### 🔑 SOUS-PHASE 2.3 — Login Google + Apple (2h) ⭐ NOUVEAU/RENFORCÉ

> ⚠️ **IMPORTANT** : Apple **impose** Sign in with Apple si tu offres d'autres logins sociaux. Ne pas l'inclure = rejet App Store.

**Pourquoi c'est critique** :
- 30%+ d'augmentation des conversions inscription (vs email/password seul)
- Apple le rend obligatoire dès qu'un autre social login est présent
- Les utilisateurs détestent créer un nouveau mot de passe

**Setup côté Supabase** :
1. Dashboard Supabase → Authentication → Providers
2. Activer **Google** : créer OAuth2 credentials sur Google Cloud Console
3. Activer **Apple** : créer Service ID sur Apple Developer Portal (50 $/an requis)

**Code Flutter** :

```dart
// lib/features_user/auth/auth_user_repository.dart
class AuthUserRepository {
  Future<void> signInWithGoogle() async {
    // Méthode native (recommandée)
    final googleSignIn = GoogleSignIn(
      serverClientId: dotenv.env['GOOGLE_OAUTH_CLIENT_ID']!,
    );
    
    final googleUser = await googleSignIn.signIn();
    if (googleUser == null) return; // Cancelled
    
    final googleAuth = await googleUser.authentication;
    
    // Connect à Supabase via OAuth
    await supabase.auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: googleAuth.idToken!,
      accessToken: googleAuth.accessToken!,
    );
    
    // Vérifier si profil existe déjà, sinon créer
    await _ensureProfileExists();
  }
  
  Future<void> signInWithApple() async {
    final credential = await SignInWithApple.getAppleIDCredential(
      scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
    );
    
    await supabase.auth.signInWithIdToken(
      provider: OAuthProvider.apple,
      idToken: credential.identityToken!,
    );
    
    await _ensureProfileExists(
      suggestedName: '${credential.givenName} ${credential.familyName}',
    );
  }
  
  Future<void> _ensureProfileExists({String? suggestedName}) async {
    final user = supabase.auth.currentUser!;
    
    // Check si profil existe
    final existing = await supabase
        .from('profiles')
        .select()
        .eq('id', user.id)
        .maybeSingle();
    
    if (existing == null) {
      // Premier login social → créer profil
      await supabase.from('profiles').insert({
        'id': user.id,
        'email': user.email,
        'username': _generateUsername(user.email!, suggestedName),
        'auth_provider': user.appMetadata['provider'],
        'auth_provider_id': user.id,
        'country_code': await _detectCountry(),
        'avatar_color': '#4C7AFF',
      });
    }
  }
}
```

**UI sur LoginUserScreen** :
```
┌──────────────────────────────────────┐
│  CONNEXION                           │
│                                      │
│  📧 Email                            │
│  [_________________________]         │
│                                      │
│  🔑 Mot de passe                     │
│  [_________________________]  👁️     │
│                                      │
│       Mot de passe oublié ?          │
│                                      │
│  [     SE CONNECTER     ]            │
│                                      │
│  ──────────  OU  ──────────          │
│                                      │
│  [ G  Continuer avec Google ]        │
│  [    Continuer avec Apple    ]      │
│                                      │
│  Pas de compte ? S'inscrire          │
└──────────────────────────────────────┘
```

**Cas spécial — Compte email existant** :
Si un utilisateur s'est inscrit par email puis tente "Continuer avec Google" avec le même email, on doit :
1. Détecter le conflit
2. Afficher `LinkExistingAccountPage` :
   ```
   "Tu as déjà un compte avec cet email.
   Veux-tu lier ton compte Google à ton compte existant ?"
   [LIER] [ANNULER]
   ```
3. Si "LIER" → demander mot de passe puis lier les comptes

#### 🔑 SOUS-PHASE 2.4 — Champs CGU/Privacy à l'inscription (30 min) ⭐ NOUVEAU

Sur `RegisterUserScreen` (étape 2), ajouter en bas :
```
☐ J'accepte les Conditions Générales d'Utilisation
☐ J'accepte la Politique de Confidentialité
☐ J'accepte de recevoir des emails marketing (optionnel)
```

- Les 2 premières cases sont **obligatoires** (le bouton SUIVANT est désactivé sans)
- Lien vers la page CGU et Privacy en pop-up scrollable
- À la création : remplir `cgu_accepted_at` et `privacy_policy_accepted_at`

**Test PHASE 2 complète** :
- Inscription email/password → profil créé avec `auth_provider='email'`
- Login Google → profil créé avec `auth_provider='google'`
- Login Apple → profil créé avec `auth_provider='apple'`
- Forgot Password → email reçu, lien fonctionne, mot de passe mis à jour
- Login avec compte qui a `role='admin'` → message d'erreur + déconnexion
- Tentative login Google avec email existant → `LinkExistingAccountPage` apparaît



---

### **PHASE 2 BIS — Authentification Admin (App ADMIN, 4-5h)**

> 🛡️ Cette phase concerne **uniquement l'app ADMIN** (`features_admin/auth_admin/`).
> Elle est plus complexe car implique TOTP + invitation codes + rôle restriction stricte.

**Objectif** : un admin peut être invité, s'inscrire avec code, configurer TOTP, se connecter de manière sécurisée.

#### 📋 Sous-phases

**SOUS-PHASE 2B.1 — Génération de codes d'invitation (super-admin) (1h)**

**Écran `InviteCodesScreen`** (super-admin uniquement) :
- Liste des codes générés (status pill : pending/used/expired/revoked)
- Bouton "GÉNÉRER UN CODE"
- Modal de génération :
  - Email destinataire (optionnel — limite l'usage à un email précis)
  - Compétition pré-assignée (optionnel)
  - Rôle : Admin / Super-Admin
  - Durée validité : 7 jours par défaut, ajustable jusqu'à 30j
  - Notes internes (libre texte : "Pour Jean qui gère la compet PSG")
  - Bouton "GÉNÉRER"
- Affichage du code généré dans un toast (format `ARENA-XXXX-XXXX-XXXX`)
- Bouton "Copier" + "Partager par email" (mailto avec template)
- Bouton "Révoquer" sur chaque code pending

**Edge Function `generate-invitation-code`** :
```typescript
serve(async (req) => {
  // 1. Vérifier que l'appelant est super_admin
  // 2. Générer un code aléatoire format ARENA-XXXX-XXXX-XXXX (12 chars hex)
  // 3. Insérer dans invitation_codes
  // 4. Logger dans admin_audit_log (action: 'invitation_created')
  // 5. (Optionnel) Envoyer email avec lien direct vers RegisterAdminScreen
});
```

**Test 2B.1** : un super-admin crée un code, le code apparaît dans la liste avec status `pending`.

---

**SOUS-PHASE 2B.2 — Inscription Admin avec code (1h)**

**Écran `SplashAdminScreen`** :
- Background rouge sombre (différencié de l'app User)
- Logo ARENA Admin (avec icône bouclier)
- Titre "ARENA Admin" en Bebas Neue
- Sous-titre "Accès Administrateur"
- 2 boutons :
  - "SE CONNECTER" → `LoginAdminScreen`
  - "JE SUIS INVITÉ" → `RegisterAdminScreen` (avec code)

**Écran `RegisterAdminScreen`** (4 étapes) :

Step 1 - Code d'invitation :
- Input "Code d'invitation" formaté `ARENA-XXXX-XXXX-XXXX`
- Auto-uppercase, masque de saisie
- Validation côté serveur via Edge Function `verify-invitation-code` :
  - Code existe et `status = 'pending'`
  - Pas expiré (`expires_at > now()`)
  - Si `intended_email` défini : vérifier que l'email matchera plus tard
- Si OK : afficher carte verte "Code valide. Invité par : [super-admin name]"
- Bouton "CONTINUER"

Step 2 - Création de compte :
- Email (préfilléavec `intended_email` si défini, et grisé non-modifiable)
- Password (min 12 caractères, doit contenir maj, min, chiffre, symbole)
- Confirmer password
- Username (admin display name)
- Acceptation CGU admin (différentes des CGU user — plus strictes)
- Bouton "CRÉER LE COMPTE"

Step 3 - Configuration TOTP (cf. sous-phase 2B.3)

Step 4 - Succès :
- Animation checkmark
- "Compte admin créé avec succès"
- Bouton "ACCÉDER AU DASHBOARD"

**Logique côté serveur** :
- Edge Function `register-admin` :
  1. Vérifier code valide
  2. Créer le compte Supabase Auth
  3. Créer profil avec `role = invitation.role`, `invited_by = invitation.created_by`, `invitation_code_used = code`
  4. Marquer invitation comme `used`
  5. Logger dans `admin_audit_log` (action: 'admin_invited')

**Test 2B.2** : un admin invité utilise son code → compte créé → invitation passe en `used` → impossible de réutiliser le même code.

---

**SOUS-PHASE 2B.3 — Configuration TOTP au premier login (1h)**

**Écran `TotpSetupScreen`** (affiché après 1ère création de compte ou si `totp_enabled = false`) :

UI en 3 cards verticales :

Card 1 - Instructions :
- "Pour sécuriser ton compte, télécharge **Google Authenticator** ou **Authy**"
- Liens vers les 2 stores (Play + App)
- "Ouvre l'app et appuie sur '+' pour ajouter un compte"

Card 2 - QR Code à scanner :
- QR code généré (via `qr_flutter`) qui contient l'URI TOTP standard :
  ```
  otpauth://totp/ARENA%20Admin:user@example.com?secret=XXXX&issuer=ARENA
  ```
- En-dessous : "Ou entre manuellement ce code : `XXXX-XXXX-XXXX-XXXX`"
- Le secret est généré côté serveur (Edge Function) avec `crypto.randomBytes(20)` en base32

Card 3 - Vérification :
- Input 6 chiffres (style OTP)
- Bouton "VÉRIFIER & ACTIVER"
- Au tap : Edge Function `verify-totp-setup` :
  1. Vérifier le code TOTP avec le secret
  2. Si OK : `update profiles set totp_enabled=true, totp_verified_at=now() where id=auth.uid()`
  3. Générer 10 codes de récupération aléatoires, hash bcrypt, stocker dans `backup_codes`

**Écran post-setup `TotpBackupCodesScreen`** :
- Affichage des 10 codes en clair (UNE SEULE FOIS) :
  ```
  XXXX-XXXX-XXXX
  XXXX-XXXX-XXXX
  ...
  ```
- Avertissement rouge : "Note ces codes maintenant. Ils ne seront plus jamais affichés."
- Bouton "Télécharger en PDF" + "Copier"
- Checkbox obligatoire : "J'ai sauvegardé mes codes"
- Bouton "CONTINUER" désactivé tant que checkbox non cochée

**Test 2B.3** : scan QR avec Google Authenticator → entrer code 6 chiffres → activation TOTP → 10 codes backup affichés → on ne peut pas continuer sans cocher la box.

---

**SOUS-PHASE 2B.4 — Login Admin avec TOTP (1h)**

**Écran `LoginAdminScreen`** :
- Background rouge tinté (cohérence avec splash admin)
- 2 inputs : email + password
- Bouton "SE CONNECTER"

**Écran `TotpVerifyScreen`** (affiché après email+password OK) :
- "Entre le code à 6 chiffres affiché dans Google Authenticator"
- Input OTP 6 cellules (style auto-focus)
- Lien "Utiliser un code de récupération à la place"
- Bouton "VÉRIFIER"

**Logique** :
- Edge Function `admin-login` :
  1. Vérifier email + password via Supabase Auth
  2. Si OK : retourner un token temporaire (5 min)
  3. Ne PAS établir la session encore
- Edge Function `admin-verify-totp` :
  1. Vérifier token temporaire
  2. Vérifier code TOTP avec secret de l'admin
  3. Anti-replay : refuser si `last_totp_used = code_actuel`
  4. Si OK : update `last_totp_used`, créer la vraie session Supabase, logger dans audit
  5. Si KO 3 fois : bloquer le compte 30 min

**Code de récupération comme alternative** :
- Si l'admin a perdu son téléphone, il peut utiliser un code backup
- Le code utilisé est marqué comme consommé dans `backup_codes`
- Un seul usage par code

**Test 2B.4** :
- Login email + password → écran TOTP
- Entrer code Google Authenticator → connexion réussie
- Réessayer avec même code dans la minute suivante → refusé (anti-replay)
- 3 essais wrong → compte bloqué 30 min

---

**SOUS-PHASE 2B.5 — Filtres de sécurité stricts (1h)**

Côté **app User** (rappel) :
- Filtre rôle au login : si `role != 'player'` → déconnexion immédiate

Côté **app Admin** :
- Filtre rôle au login : si `role NOT IN ('admin', 'super_admin')` → déconnexion immédiate
- Vérification permanente : à chaque navigation, vérifier `role` (un attaquant pourrait modifier sa session)
- Session expire après 30 min d'inactivité (vs 7 jours pour user)
- Re-vérification TOTP demandée pour actions sensibles (suspension joueur, approval payout)

**Logique** :
```dart
// Dans admin_router.dart
final adminGuard = (BuildContext context, GoRouterState state) {
  final user = ref.read(currentUserProvider);
  if (user?.role == 'player' || user == null) {
    // Logout + redirect vers SplashAdminScreen
    return '/splash';
  }
  if (!user.totpEnabled) {
    return '/totp-setup';  // Force config TOTP avant tout
  }
  return null;  // Continue navigation
};
```

**Audit log** :
- Toute action admin loggée dans `admin_audit_log` :
  - Login/logout
  - Échec TOTP
  - Validation match
  - Modification compétition
  - Approbation payout
  - Toggle feature flag

**Test 2B.5** :
- Forcer manuellement un user `role='player'` à se connecter à l'app admin → bloqué
- Inactivité 31 min dans l'app admin → re-login forcé
- Tester action sensible → re-prompt TOTP
- Vérifier que toutes les actions apparaissent dans `admin_audit_log`

---

#### ✅ Critères d'acceptation phase 2 BIS

- [ ] Super-admin peut générer/révoquer des codes d'invitation
- [ ] Inscription admin sans code valide est impossible
- [ ] TOTP obligatoire pour tous les admins (pas de bypass possible)
- [ ] 10 codes de récupération générés et téléchargeables
- [ ] Anti-replay TOTP fonctionnel
- [ ] App User refuse les comptes admin et inversement
- [ ] Audit log complet de toutes les actions admin
- [ ] Session admin expire après 30 min
- [ ] Tentatives de login échouées (>3) bloquent le compte 30 min

---

### **PHASE 3 — Layout principal + HomePage joueur (1-2h)**

**Objectif** : le shell de l'app avec bottom navigation et page d'accueil.

**Écrans :**
- `MainShell` : Scaffold avec bottom navigation 5 tabs (Accueil / Explorer / Mes Comps / Messages / Profil)
- `HomePage` :
  - Hero section "BONSOIR, [username]" + drapeau
  - 3 stat cards (compétitions actives, victoires, classement)
  - Carte "Prochain Match" (placeholder si rien)
  - Carte "En Direct" (placeholder)
  - Liste résultats récents (placeholder)

**Logique :**
- Provider `currentUserProfileProvider` (lit le profil depuis Supabase)
- Données mockées au début (on branche le repository à la phase 4)

**Test** : navigation entre les 5 tabs fonctionne, HomePage affiche le username connecté.

---

### **PHASE 4 — Compétitions (3-4h)**

**Objectif** : un joueur peut découvrir, voir le détail et s'inscrire à une compétition.

> 💰 **Inscription gratuite temporaire** : à ce stade du roadmap, les paiements ne sont **pas encore implémentés** (ils arrivent à la PHASE 11 BIS). Les compétitions ont un `entry_fee_amount_usd = 0` par défaut. Le code Flutter inclut déjà la logique conditionnelle :
> ```dart
> if (competition.entryFeeAmount > 0) {
>   // Affichage "Paiement bientôt disponible"
>   // Inscription bloquée tant que la PHASE 11 BIS n'est pas complétée
> } else {
>   // Inscription gratuite directe → call register()
> }
> ```
> Cela permet à l'admin (PHASE 11) de créer des compétitions de test gratuites pour valider tout le système avant l'activation des paiements.

**Écrans :**
- `DiscoverPage` (recherche, filtres, liste compétitions)
- `CompetitionDetailPage` (5 onglets : Aperçu, Groupes, Bracket, Matchs, Classement)
- `MyCompetitionsPage` (compétitions où le joueur est inscrit)

**Logique :**
- `competition_repository.dart` : `fetchAll`, `fetchById`, `register`, `fetchMyCompetitions`
- Modèles freezed : `Competition`, `Phase`, `Group`, `Match`, `GroupMembership`, `BracketNode`
- Provider Riverpod avec `AsyncNotifier` pour la pagination
- Subscription realtime sur les matchs (live score updates) ET sur les `bracket_nodes` (progression)

**Affichage du Bracket (USER, lecture seule)** :
- Widget `BracketView` dans `features_user/competitions/presentation/widgets/`
- Style : **scroll horizontal interactif avec animations** (cf. section "SYSTÈME DE BRACKETS")
- Tap sur un match → bottom sheet `MatchDetailSheet` avec :
  - Scores complets, joueurs, drapeaux pays
  - Si LIVE : bouton "Regarder le stream"
  - Si terminé : timeline des buts
- Le joueur connecté voit son nom **mis en évidence** (badge "TOI" + glow bleu)
- Lignes de connexion entre matchs animées (s'illuminent quand un vainqueur avance)

**Affichage des Groupes (format groupes+KO)** :
- Widget `GroupsTableView` avec un tableau par groupe
- Colonnes : Position, Joueur, J (matchs joués), V, N, D, BP (buts pour), BC (buts contre), Diff, Pts
- Top X qualifiés : ligne en vert, badge "QUALIFIÉ"
- Tri auto par : Pts → Diff → BP

**Affichage Round Robin** :
- Widget `RoundRobinTableView` similaire aux groupes mais avec tous les joueurs
- Plus une matrice "Tous contre tous" (style championnat) en option, scrollable

**Composants Flutter à créer** :
- `BracketView` : container scrollable horizontal qui orchestre les rounds
- `BracketRound` : colonne d'un round (titre + matchs)
- `BracketMatchCard` : carte de match dans le bracket (taille fixe, animations)
- `BracketConnectionLines` : `CustomPainter` qui dessine les lignes entre matchs
- `GroupsTableView` : pour les groupes
- `MatchDetailSheet` : bottom sheet de détails

**Test** : créer 2-3 compétitions manuellement dans Supabase avec différents formats (single elim 8 joueurs, groupes 16 joueurs, round robin 6 joueurs), elles s'affichent correctement dans les 3 onglets dédiés.

---

### **PHASE 5 — Système Match Room (eFootball) (2-3h)**

**Objectif** : flow domicile/extérieur avec partage de code.

**Écrans :**
- `MatchRoomPage` (variants HOME et AWAY)
- Stepper 5 étapes (Match confirmé → **Config (si phase groupes)** → Créer/Recevoir room → Partager/Rejoindre → Lancer enregistrement)

**Logique :**
- `match_repository.dart` : `setRoomCode`, `confirmJoined`, `updateStatus`, `confirmGroupPhaseConfig`
- Le code room saisi par HOME est envoyé via Agora RTM (phase 6) ET sauvegardé dans `matches.room_code`
- AWAY le reçoit via subscription realtime

**Note** : on utilise Supabase Realtime ici plutôt qu'Agora RTM pour ne pas dépendre du chat tout de suite. Le chat Agora arrive en phase 6.

**🆕 ÉTAPE SPÉCIALE — Configuration pour phase de groupes uniquement**

> ⚠️ **POURQUOI** : En phase de groupes (et Round Robin), les matchs nuls sont valides et rapportent des points (V=3, N=1, D=0). Si eFootball passe automatiquement en prolongations puis tirs au but, le match nul devient impossible et fausse le classement.

**Logique conditionnelle** :
- Si `phase.type == 'groups'` OU `phase.type == 'round_robin'` → afficher l'étape "Configuration"
- Si `phase.type == 'knockout'` (élimination directe) → **sauter cette étape** (les prolongations + TAB sont nécessaires pour départager)

**Écran "Configuration phase de groupes"** (variant HOME uniquement) :

```
┌──────────────────────────────────────────────────┐
│  ⚙️ CONFIGURATION DU MATCH                       │
│                                                  │
│  ⚠️ Phase de groupes — matchs nuls autorisés    │
│                                                  │
│  Avant de créer la room dans eFootball, tu dois │
│  désactiver les options suivantes :              │
│                                                  │
│  ☐ Prolongations désactivées                    │
│     (Pas d'extra time après 90 min)             │
│                                                  │
│  ☐ Tirs au but désactivés                       │
│     (Le match peut finir sur un score nul)      │
│                                                  │
│  💡 Dans eFootball : Match → Match avec Ami →   │
│     Paramètres → Type de match                   │
│                                                  │
│  [   CRÉER LA ROOM   ]  ← désactivé tant que    │
│                          les 2 cases ne sont    │
│                          pas cochées             │
└──────────────────────────────────────────────────┘
```

**Comportement UI** :
- Le bouton "CRÉER LA ROOM" est **désactivé (opacity 0.4, non cliquable)** tant que les 2 cases ne sont pas cochées
- Quand les 2 cases sont cochées → le bouton devient actif (opacity 1, cliquable, animation pulse subtile)
- Au clic sur "CRÉER LA ROOM", on stocke la confirmation dans la DB :
  ```dart
  await supabase.from('matches').update({
    'match_config': {
      'extra_time_disabled': true,
      'penalties_disabled': true,
      'confirmed_by_home': true,
      'confirmed_by_home_at': DateTime.now().toIso8601String(),
    }
  }).eq('id', matchId);
  ```

**Côté AWAY** : pas de checkbox, mais affichage informatif après que HOME a confirmé :
```
✓ HOME a confirmé la configuration du match
   (Prolongations + TAB désactivés)
```

**Logique anti-litige** :
- La confirmation est stockée dans `matches.match_config` (jsonb)
- Si litige plus tard (un joueur affirme que l'autre a triché), l'admin peut :
  1. Vérifier `match_config.confirmed_by_home_at` (timestamp précis)
  2. Croiser avec le recording vidéo (PHASE 8)
  3. Décider d'annuler le résultat ou sanctionner

**Mise à jour SQL** : ajouter le champ `match_config` à la table `matches` :
```sql
alter table matches add column match_config jsonb default '{}';
-- Le champ contient (selon les cas) :
-- {
--   "extra_time_disabled": true,    // Phase groupes/round robin
--   "penalties_disabled": true,
--   "confirmed_by_home": true,
--   "confirmed_by_home_at": "2026-05-04T19:30:00Z",
--   "confirmed_by_away": true,      // optionnel V2
--   "confirmed_by_away_at": "..."
-- }
```

**Test** : 
1. Créer un match en phase de groupes (entre 2 joueurs)
2. Le joueur HOME ouvre Match Room → l'étape "Configuration" apparaît
3. Le bouton "CRÉER LA ROOM" est grisé
4. Cocher la 1ère case → toujours grisé
5. Cocher la 2ème case → bouton devient actif
6. Cliquer "CRÉER LA ROOM" → vérifier que `matches.match_config.confirmed_by_home = true` dans Supabase
7. Le joueur AWAY voit le message "✓ HOME a confirmé la configuration"
8. Refaire le test avec un match en phase KO → l'étape "Configuration" est SAUTÉE (passage direct à "Créer la room")

**Test additionnel** : ouvrir l'app sur 2 émulateurs (ou émulateur + device), créer un match entre les 2 joueurs, l'un crée une room et envoie le code, l'autre le reçoit en temps réel.

---

### **PHASE 6 — Chat hybride Supabase + Agora RTM (3-4h)**

> 🎯 **ARCHITECTURE HYBRIDE INTELLIGENTE** : on utilise le meilleur des 2 mondes.
> - **Supabase Realtime** = persistance des messages (table `chat_messages`) + livraison temps réel
> - **Agora RTM** = présence riche (online/offline, "typing...") via channels présence
>
> **Pourquoi ce choix ?**
> - Supabase = gratuit, message stocké en DB (consultable historique), pas de limite MAU
> - Agora RTM = présence ultra-fluide, gratuit jusqu'à 100k MAU
> - Les 2 sont gratuits pour V1.0, on combine leurs forces

**Objectif** : chat 1-on-1 entre adversaires + canaux compétition + présence riche.

**Écrans :**
- `MessagesInboxPage` (conversations directes + canaux)
- `ChatPage` (1-on-1 avec UI de bulles + indicateurs présence)

**Architecture technique :**

```
┌─────────────────────────────────────────────┐
│  CHAT MESSAGE TEXT                          │
│                                             │
│  Joueur A tape un message                   │
│         ↓                                   │
│  INSERT dans chat_messages (Supabase)       │
│         ↓                                   │
│  Trigger Realtime → Joueur B reçoit         │
│         ↓                                   │
│  Affiché instantanément (latence 200ms)     │
└─────────────────────────────────────────────┘

┌─────────────────────────────────────────────┐
│  PRÉSENCE RICHE                             │
│                                             │
│  Joueur A ouvre l'app                       │
│         ↓                                   │
│  Login Agora RTM avec uid = Supabase id     │
│         ↓                                   │
│  Joueur B voit "Joueur A est en ligne"      │
│         ↓                                   │
│  Joueur A commence à taper                  │
│         ↓                                   │
│  Agora RTM channel attribute "typing"       │
│         ↓                                   │
│  Joueur B voit "Joueur A est en train       │
│  d'écrire..." (latence 50ms)                │
└─────────────────────────────────────────────┘
```

**Logique :**

**a) Service `chat_service.dart` (Supabase Realtime)** — pour les messages

```dart
class ChatService {
  Future<void> sendMessage(String channelId, String content, String type) async {
    await supabase.from('chat_messages').insert({
      'channel_id': channelId,
      'sender_id': currentUserId,
      'message_type': type,           // 'text' | 'room_code' | 'system'
      'content': content,
    });
  }
  
  Stream<List<ChatMessage>> watchMessages(String channelId) {
    return supabase
      .from('chat_messages')
      .stream(primaryKey: ['id'])
      .eq('channel_id', channelId)
      .order('created_at')
      .map((data) => data.map(ChatMessage.fromJson).toList());
  }
}
```

**b) Service `presence_service.dart` (Agora RTM)** — pour la présence

```dart
class PresenceService {
  late RtmClient _rtmClient;
  
  Future<void> initialize() async {
    _rtmClient = await AgoraRtmClient.createInstance(appId);
    
    // Login avec UID Supabase pour cohérence
    final token = await _getRtmToken(currentUserId);
    await _rtmClient.login(token: token, uid: currentUserId);
  }
  
  // Joindre un channel de présence pour un match
  Future<RtmChannel> joinPresenceChannel(String matchId) async {
    final channel = await _rtmClient.createChannel('presence:match:$matchId');
    await channel.join();
    
    // Écouter les events de présence
    channel.onMemberJoined = (member) {
      // Notifier "X est en ligne"
    };
    
    channel.onMemberLeft = (member) {
      // Notifier "X est hors ligne"
    };
    
    channel.onAttributesUpdated = (attributes) {
      // Décoder "typing", "online", etc.
    };
    
    return channel;
  }
  
  // Indicateur "typing"
  Future<void> setTyping(RtmChannel channel, bool isTyping) async {
    await channel.setLocalUserAttributes([
      RtmAttribute(key: 'typing', value: isTyping.toString()),
    ]);
  }
  
  // Statut online/offline (auto avec login/logout)
}
```

**c) UI ChatPage**

L'UI combine les 2 streams :
```dart
StreamBuilder(
  stream: chatService.watchMessages(channelId),  // Messages Supabase
  builder: (context, messageSnapshot) {
    return StreamBuilder(
      stream: presenceService.watchPresence(channelId),  // Présence Agora
      builder: (context, presenceSnapshot) {
        return Column(
          children: [
            ChatHeader(
              userName: 'NeonKing',
              isOnline: presenceSnapshot.data?.isOnline ?? false,
              isTyping: presenceSnapshot.data?.isTyping ?? false,
            ),
            ChatBubblesList(messages: messageSnapshot.data ?? []),
            ChatInput(
              onTyping: (isTyping) => presenceService.setTyping(channel, isTyping),
              onSend: (text) => chatService.sendMessage(channelId, text, 'text'),
            ),
          ],
        );
      },
    );
  },
)
```

**Type de message spécial `room_code`** : rendu cyan dans l'UI (existant).

**Avantages de cette architecture** :
- 💰 **0 $/mois** : les 2 services sont gratuits à V1.0
- 📜 **Historique persistant** : tous les messages sont en DB (consultables a posteriori)
- ⚡ **Présence ultra-fluide** : Agora RTM est optimisé pour ça (latence 50ms vs 300ms Supabase)
- 🔄 **Failover** : si Agora RTM tombe, les messages continuent (Supabase indépendant)

**Test** : 
1. 2 joueurs s'envoient des messages texte → reçus en realtime
2. 1 joueur ouvre l'app → l'autre voit "online"
3. 1 joueur commence à taper → l'autre voit "typing..."
4. 1 joueur ferme l'app → l'autre voit "offline" après 30s
5. Messages historiques chargés depuis DB (scroll vers le haut)

---

### **PHASE 7 — ❌ SUPPRIMÉE (Appels vidéo Agora RTC)**

> 🗑️ **Cette phase a été retirée du projet** pour des raisons de coût et de simplicité. Les appels vidéo entre joueurs ne sont pas considérés comme essentiels pour ARENA V1.0. Les joueurs communiquent via le chat texte (PHASE 6) et peuvent partager leur numéro WhatsApp si besoin de communication vocale.
>
> **Économie réalisée** : ~24$/mois sur Agora RTC + 2h de développement.

---

### **PHASE 8 — Enregistrement écran + Bouton flottant anti-triche + Streaming Agora sélectif (6-7h, la plus complexe)**

> ⚠️ **PHASE LA PLUS DIFFICILE DU PROJET.** Tu (Claude) dois :
> 1. Prévenir l'utilisateur que cette phase nécessite du code natif (Kotlin Android + Swift iOS)
> 2. Avancer **étape par étape** en testant après chaque sous-étape
> 3. Ne pas hésiter à utiliser `web_search` pour vérifier les API natives (elles changent vite)

#### 🎯 Objectif fonctionnel

Le joueur lance l'app **eFootball / FIFA / FC Mobile** depuis ARENA. Pendant qu'il joue :
- **Android** : un bouton flottant **REC compact** (~80x80dp) reste visible par-dessus le jeu, affichant un point rouge pulsant + le timer MM:SS
- **iOS** : impossible techniquement (Apple bloque les overlays système). À la place : **Live Activity** (notification persistante en haut de l'écran verrouillé / Dynamic Island sur iPhone 14 Pro+) avec timer + indicateur REC
- L'enregistrement d'écran tourne en arrière-plan via service foreground (Android) ou Broadcast Upload Extension (iOS)
- Le joueur **ne peut pas** arrêter l'enregistrement librement → tap sur le bouton STOP déclenche un **dialogue de verrouillage** (voir section anti-triche ci-dessous)

#### 📋 Sous-phases à exécuter dans cet ordre

---

**SOUS-PHASE 8.1 — Permissions et configuration native (1h)**

Configurer les permissions critiques. Sans ça, rien ne marche.

**Android** (`android/app/src/main/AndroidManifest.xml`) :
```xml
<!-- Overlay par-dessus autres apps -->
<uses-permission android:name="android.permission.SYSTEM_ALERT_WINDOW"/>
<!-- Foreground service pour enregistrement -->
<uses-permission android:name="android.permission.FOREGROUND_SERVICE"/>
<uses-permission android:name="android.permission.FOREGROUND_SERVICE_MEDIA_PROJECTION"/>
<!-- Capture écran -->
<uses-permission android:name="android.permission.RECORD_AUDIO"/>
<!-- Détection apps installées et lancées (Android 11+) -->
<uses-permission android:name="android.permission.PACKAGE_USAGE_STATS" tools:ignore="ProtectedPermissions"/>
<uses-permission android:name="android.permission.QUERY_ALL_PACKAGES" tools:ignore="QueryAllPackagesPermission"/>
<!-- Notifications persistantes -->
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
<!-- Empêcher kill de l'app -->
<uses-permission android:name="android.permission.WAKE_LOCK"/>
```

Déclarer le **Foreground Service** dans `<application>` :
```xml
<service
    android:name="com.pravera.flutter_foreground_task.service.ForegroundService"
    android:foregroundServiceType="mediaProjection|microphone"
    android:exported="false"/>
```

**iOS** (`ios/Runner/Info.plist`) :
```xml
<key>NSCameraUsageDescription</key>
<string>ARENA a besoin de la caméra pour les appels vidéo entre joueurs</string>
<key>NSMicrophoneUsageDescription</key>
<string>ARENA enregistre l'audio pendant les matchs pour vérification anti-triche</string>
<key>UIBackgroundModes</key>
<array>
    <string>audio</string>
    <string>voip</string>
</array>
```

Pour iOS, créer en plus une **Broadcast Upload Extension** dans Xcode (target iOS 14+). Claude doit guider l'utilisateur étape par étape dans Xcode (File → New → Target → Broadcast Upload Extension).

**Test 8.1** : permissions accordées dans les Settings du device, app n'est pas crashée au lancement.

---

**SOUS-PHASE 8.2 — Détection du lancement du jeu (1h)**

Avant de lancer l'enregistrement, ARENA doit savoir **quel jeu** le joueur va lancer.

**Logique** :
- Sur la `MatchRoomPage`, un bouton "🎮 LANCER LE JEU" apparaît à l'étape "Lancer enregistrement"
- Au tap, l'app :
  1. Vérifie que le jeu est installé (via `installed_apps`)
  2. Démarre l'enregistrement écran ET l'overlay flottant
  3. Lance l'app du jeu via son intent (Android) ou URL scheme (iOS)

**Mapping des packages jeux** (à mettre dans `core/constants.dart`) :
```dart
class GamePackages {
  static const efootballAndroid = 'jp.konami.pesam';
  static const efootballIos = 'efootball://';
  static const fifaAndroid = 'com.ea.gp.fifamobile';
  static const fifaIos = 'fifamobile://';
  static const fcMobileAndroid = 'com.ea.gp.fcmobile';
  static const fcMobileIos = 'eafcmobile://';
}
```

**Code clé** (`game_launch_detector.dart`) :
```dart
Future<bool> isGameInstalled(GameType game) async {
  final apps = await InstalledApps.getInstalledApps(true, true);
  final pkg = _getPackageName(game);
  return apps.any((app) => app.packageName == pkg);
}

Future<void> launchGame(GameType game) async {
  if (Platform.isAndroid) {
    await LaunchApp.openApp(androidPackageName: _getPackageName(game));
  } else {
    final url = Uri.parse(_getUrlScheme(game));
    if (await canLaunchUrl(url)) await launchUrl(url);
  }
}
```

**Test 8.2** : tap sur "Lancer le jeu" → eFootball/FIFA s'ouvre correctement.

---

**SOUS-PHASE 8.3 — Service Foreground + enregistrement écran (1.5h)**

Démarrer l'enregistrement **avant** de lancer le jeu, et le maintenir actif même quand ARENA passe en arrière-plan.

**Logique** :
- Utiliser `flutter_foreground_task` qui crée un service Android avec notification persistante
- Le service contient le `RecordingTaskHandler` qui :
  1. Démarre `flutter_screen_recording` au début
  2. Streame les chunks vers Agora RTC (channel = match_id)
  3. Met à jour le timer toutes les secondes (envoyé à l'overlay)
  4. Détecte la pause/arrêt → notifie l'admin via Supabase Realtime

**Code minimal** (`foreground_recording_task.dart`) :
```dart
class RecordingTaskHandler extends TaskHandler {
  DateTime? _startedAt;
  Timer? _timer;

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    _startedAt = timestamp;
    await FlutterScreenRecording.startRecordScreenAndAudio('arena_match');
    // Si streaming RTMP activé (sous-phase 8.7), démarrer aussi le push RTMP ici
    // RtmpStreamingService.instance.startStream(...) si activé
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      final elapsed = DateTime.now().difference(_startedAt!);
      FlutterForegroundTask.sendDataToMain({'elapsed': elapsed.inSeconds});
      // Mettre à jour aussi l'overlay
      FlutterOverlayWindow.shareData({'elapsed': elapsed.inSeconds});
    });
  }

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {
    _timer?.cancel();
    await FlutterScreenRecording.stopRecordScreen;
  }

  @override
  void onRepeatEvent(DateTime timestamp) {}
}
```

**Test 8.3** : démarrer l'enregistrement → lock l'écran du téléphone → l'enregistrement continue → unlock → toujours en cours.

---

**SOUS-PHASE 8.4 — Bouton flottant Android (overlay window) (1.5h)**

Créer le bouton flottant compact qui reste visible par-dessus toutes les apps.

**Spec UI** (selon ton choix : compact) :
- Taille : 72dp × 72dp (cercle parfait)
- Background : gradient rouge (`#FF2D55` → `#FF6A1A`) avec glow
- Contenu : point rouge pulsant + timer JetBrains Mono "MM:SS"
- Glissable (l'utilisateur peut le déplacer où il veut)
- Tap court → ouvre ARENA en premier plan
- Tap long → demande de stop (déclenche dialogue de verrouillage)
- Sticky aux bords de l'écran

**Implémentation** :
- `flutter_overlay_window` permet d'enregistrer une seconde "entrypoint" Flutter qui tourne dans le contexte overlay
- Dans `main.dart`, ajouter :
```dart
@pragma("vm:entry-point")
void overlayMain() {
  runApp(const ArenaOverlayApp()); // UI minimaliste du bouton
}
```

**Code de l'overlay** (`overlay_widget.dart`) :
```dart
class ArenaRecOverlay extends StatefulWidget {
  @override
  State<ArenaRecOverlay> createState() => _ArenaRecOverlayState();
}

class _ArenaRecOverlayState extends State<ArenaRecOverlay> {
  int _elapsed = 0;
  late StreamSubscription _sub;

  @override
  void initState() {
    super.initState();
    // Reçoit les updates depuis le foreground task
    _sub = FlutterOverlayWindow.overlayListener.listen((data) {
      if (data is Map && data['elapsed'] != null) {
        setState(() => _elapsed = data['elapsed']);
      }
    });
  }

  String get _timerText {
    final m = (_elapsed ~/ 60).toString().padLeft(2, '0');
    final s = (_elapsed % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: GestureDetector(
        onTap: () => FlutterOverlayWindow.closeOverlay(), // ramène ARENA en focus
        onLongPress: _requestStop,
        child: Container(
          width: 72, height: 72,
          decoration: BoxDecoration(
            shape: BoxShape.CIRCLE,
            gradient: LinearGradient(colors: [Color(0xFFFF2D55), Color(0xFFFF6A1A)]),
            boxShadow: [BoxShadow(color: Color(0xFFFF2D55).withOpacity(0.6), blurRadius: 20)],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _PulsingDot(),
              const SizedBox(height: 4),
              Text(_timerText, style: TextStyle(
                fontFamily: 'FiraCode',
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              )),
            ],
          ),
        ),
      ),
    );
  }

  void _requestStop() async {
    // Envoie un message à l'app principale pour déclencher le dialogue
    await FlutterOverlayWindow.shareData({'action': 'request_stop'});
  }
}
```

**Démarrage de l'overlay** :
```dart
// Avant de lancer le jeu
final granted = await FlutterOverlayWindow.isPermissionGranted();
if (!granted) {
  await FlutterOverlayWindow.requestPermission();
  return;
}
await FlutterOverlayWindow.showOverlay(
  enableDrag: true,
  overlayTitle: "ARENA REC",
  overlayContent: 'Match en cours',
  flag: OverlayFlag.defaultFlag,
  visibility: NotificationVisibility.visibilityPublic,
  positionGravity: PositionGravity.right, // Snap au bord droit
  height: 220, // Pour permettre l'expansion future
  width: 220,
  startPosition: const OverlayPosition(0, 200),
);
```

**Test 8.4** : démarrer l'enregistrement depuis ARENA → le bouton flottant apparaît → ouvrir eFootball → le bouton reste visible par-dessus le jeu → le timer s'incrémente correctement.

---

**SOUS-PHASE 8.5 — Verrouillage de l'arrêt (anti-triche) (1h)**

Le joueur ne doit **PAS pouvoir arrêter librement** l'enregistrement pendant un match live.

**Règles** :
- Tap court sur l'overlay → ouvre ARENA (pas de stop)
- Tap long → dialogue "Voulez-vous vraiment arrêter ?" avec 3 options :
  1. **Continuer le match** (par défaut, focus auto après 5s)
  2. **Demander permission à l'admin** → envoie une requête, l'admin reçoit une notif, peut autoriser ou refuser
  3. **Forcer l'arrêt** (rouge) → log d'événement suspect dans `match_events`, alerte admin, possible disqualification

**Détection des contournements** (à implémenter dans `RecordingTaskHandler`) :
- L'app détecte les tentatives suspectes :
  - Permission overlay révoquée → alerte
  - Foreground service tué (force stop dans Settings) → alerte au redémarrage
  - Permission MediaProjection révoquée → alerte
  - Mode avion activé pendant un match → alerte
- Toute anomalie déclenche :
  ```dart
  await supabase.from('match_events').insert({
    'match_id': matchId,
    'type': 'recording_anomaly',
    'metadata': {'reason': reason, 'severity': 'high'},
  });
  ```
- L'admin voit l'alerte en temps réel (subscription realtime sur `match_events`)
- Tu (Claude) DOIS prévenir l'utilisateur : sur Android, un utilisateur déterminé peut tuer le service via les paramètres système. La détection a posteriori est ce qu'on peut faire de mieux côté Flutter.

**Test 8.5** : essayer de stopper l'enregistrement via le bouton flottant → dialogue apparaît → admin reçoit l'alerte si "Forcer l'arrêt" est cliqué.

---

**SOUS-PHASE 8.6 — iOS Live Activity (1h)**

Sur iOS, on remplace le bouton flottant par une Live Activity (iOS 16.1+).

**Spec** :
- Notification persistante en haut de l'écran de verrouillage
- Sur iPhone 14 Pro+ : apparaît dans la Dynamic Island
- Affiche : timer + indicateur REC + nom du match
- Tap → ouvre ARENA

**Implémentation** :
- Utiliser le package `live_activities`
- Créer un Widget Extension dans Xcode (Swift/SwiftUI)
- Démarrer la Live Activity au début du match :
```dart
final activityId = await liveActivities.createActivity({
  'matchCode': 'R3M009',
  'opponentName': 'NeonKing',
  'startedAt': DateTime.now().toIso8601String(),
});
```

**Limitation iOS importante** : sur iOS, l'utilisateur peut quitter ARENA, lancer eFootball, et il n'y a **AUCUN moyen** d'afficher un bouton par-dessus. La Live Activity sur le lockscreen est le maximum possible. La Broadcast Upload Extension capture le screen via ReplayKit (l'utilisateur l'active manuellement depuis le Control Center → Screen Recording → ARENA).

**Test 8.6** : sur iPhone, démarrer l'enregistrement → la Live Activity apparaît dans la Dynamic Island → l'utilisateur lance eFootball → l'enregistrement continue (via ReplayKit).

---

#### 📊 Architecture finale du flow d'enregistrement

```
[Joueur sur MatchRoomPage]
        ↓ tap "🎮 LANCER LE JEU"
[Vérifie permissions overlay + capture écran]
        ↓ OK
[Démarre Foreground Service]
        ↓
[Service démarre flutter_screen_recording + Agora screen capture]
        ↓
   ┌────────────────┬───────────────────┐
   ↓                                    ↓
[Android]                            [iOS]
[Affiche overlay flottant]    [Démarre Live Activity]
        ↓                                    ↓
[Lance le jeu via intent]      [Lance le jeu via URL scheme]
        ↓                                    ↓
[Joueur joue, overlay visible]   [Joueur joue, Live Activity visible]
        ↓                                    ↓
        └─────────────┬──────────────────────┘
                      ↓
            [Match terminé : admin valide score]
                      ↓
            [Service stoppe → cleanup]
```

---

**SOUS-PHASE 8.7 — Streaming Agora RTC sélectif (3-4h)**

> 🎬 **STREAMING SÉLECTIF** : seuls les matchs **désignés par l'admin** sont streamés en direct via Agora RTC. Les **finales sont auto-streamées** (logique métier), l'admin peut **ajouter manuellement** d'autres matchs (quarts, demis, ou matchs spéciaux). Tous les utilisateurs ARENA peuvent regarder.

#### 🎯 Objectif fonctionnel

- ✅ **Auto-streaming des finales** : trigger SQL/Edge Function active automatiquement le streaming sur les matchs identifiés comme finales
- ✅ **Sélection manuelle admin** : interface dans `AdminCompetitionPage` pour cocher des matchs à streamer
- ✅ **Capture écran intégrée** : utilise le même `MediaProjection` Android / `ReplayKit` iOS que le recording (PHASE 8.3)
- ✅ **Spectateurs ARENA only** : authentification requise pour regarder
- ✅ **Page "Lives en cours"** : tous les streams actifs visibles dans une section dédiée

#### 📦 Stack technique

```yaml
# pubspec.yaml (à ajouter)
dependencies:
  agora_rtc_engine: ^6.3.0  # Streaming RTC + screen capture
```

#### 🛠️ Architecture du streaming

```
┌─────────────────────────────────────────────────────┐
│  TRIGGER : match.is_streamed = true                 │
└─────────────────────────────────────────────────────┘
                         ↓
        ┌────────────────┴────────────────┐
        ↓                                  ↓
┌──────────────────┐            ┌──────────────────┐
│  AUTO            │            │  MANUEL          │
│  Finales         │            │  Admin coche     │
│  (round = max)   │            │  un match        │
└──────────────────┘            └──────────────────┘
        ↓                                  ↓
        └────────────────┬─────────────────┘
                         ↓
┌─────────────────────────────────────────────────────┐
│  Notification au joueur HOME : "Ton match est       │
│  sélectionné pour être streamé en direct"           │
└─────────────────────────────────────────────────────┘
                         ↓
┌─────────────────────────────────────────────────────┐
│  Match commence → Service capture écran démarre     │
│  → Push vers Agora RTC channel agora_stream_channel │
└─────────────────────────────────────────────────────┘
                         ↓
┌─────────────────────────────────────────────────────┐
│  Spectateurs ARENA → join channel as audience       │
│  → Voient le live en HD                             │
└─────────────────────────────────────────────────────┘
```

#### 🔧 Étapes d'implémentation

**Étape 1 — Logique d'auto-streaming des finales**

Dans la génération du bracket (PHASE 11.5), marquer automatiquement la finale comme `is_streamed = true` :

```dart
// Dans bracket_generators/single_elimination_generator.dart
List<Match> generateMatches(List<Player> players) {
  final matches = <Match>[];
  // ... génération des rounds ...
  
  // La finale est le dernier match du dernier round
  final finalMatch = matches.last;
  finalMatch.isStreamed = true;
  finalMatch.streamingActivationType = 'auto_final';
  finalMatch.agoraStreamChannel = 'final-${competitionId}';
  
  return matches;
}
```

**Étape 2 — UI admin : sélection manuelle des matchs à streamer**

Dans `AdminBracketManagementPage`, chaque carte de match a un bouton supplémentaire :

```
┌────────────────────────────────────────────┐
│ ⚡ QUART DE FINALE 1                       │
│ NeonKing 🇨🇲 vs SkyHigh 🇬🇦              │
│                                            │
│ Score : à venir · Code : M01               │
│                                            │
│ [✏️ Valider score]  [📺 Streamer ce match] │
└────────────────────────────────────────────┘
```

Tap sur "📺 Streamer ce match" → confirmation → update DB :

```dart
await supabase.from('matches').update({
  'is_streamed': true,
  'streaming_activation_type': 'manual_admin',
  'streaming_activated_by_admin_id': currentAdminId,
  'streaming_activated_at': DateTime.now().toIso8601String(),
  'agora_stream_channel': 'manual-${matchId}',
}).eq('id', matchId);
```

Pour les finales (auto), le bouton affiche "🔒 Streamé automatiquement (finale)" en lecture seule.

**Étape 3 — Service Flutter de streaming (côté joueur HOME)**

Quand un match avec `is_streamed = true` démarre (le HOME est le broadcaster) :

```dart
// lib/core/services/agora_streaming_service.dart
class AgoraStreamingService {
  late RtcEngine _engine;
  
  Future<void> initialize() async {
    _engine = createAgoraRtcEngine();
    await _engine.initialize(RtcEngineContext(
      appId: dotenv.env['AGORA_APP_ID']!,
    ));
    
    // Permissions caméra + audio (déjà demandées PHASE 8.1)
    await _engine.enableVideo();
    await _engine.setClientRole(role: ClientRoleType.clientRoleBroadcaster);
  }
  
  Future<void> startStreamingMatch(String channelName) async {
    // Récupérer le token Agora via Edge Function (sécurité)
    final token = await supabase.functions.invoke('get_agora_token', body: {
      'channel': channelName,
      'role': 'broadcaster',
    });
    
    // Démarrer le screen capture
    await _engine.startScreenCapture(const ScreenCaptureParameters2(
      captureVideo: true,
      captureAudio: true,
      videoParams: ScreenVideoParameters(
        dimensions: VideoDimensions(width: 1280, height: 720),
        frameRate: 30,
        bitrate: 1500,
      ),
    ));
    
    // Joindre le channel comme broadcaster
    await _engine.joinChannel(
      token: token.data['token'],
      channelId: channelName,
      uid: 0,
      options: const ChannelMediaOptions(
        clientRoleType: ClientRoleType.clientRoleBroadcaster,
        publishCameraTrack: false,        // pas la cam, juste l'écran
        publishScreenTrack: true,
        publishMicrophoneTrack: true,     // pour l'audio
      ),
    );
    
    // Update DB : stream est live
    await supabase.from('matches').update({
      'stream_status': 'live',
      'stream_started_at': DateTime.now().toIso8601String(),
    }).eq('id', matchId);
  }
  
  Future<void> stopStreaming() async {
    await _engine.stopScreenCapture();
    await _engine.leaveChannel();
    
    await supabase.from('matches').update({
      'stream_status': 'ended',
      'stream_ended_at': DateTime.now().toIso8601String(),
    }).eq('id', matchId);
  }
}
```

**Étape 4 — Edge Function `get_agora_token`**

Génère un token Agora sécurisé côté serveur (ne jamais exposer l'App Certificate côté client).

```typescript
// supabase/functions/get_agora_token/index.ts
import { RtcTokenBuilder, RtcRole } from 'agora-token';

serve(async (req) => {
  const { channel, role } = await req.json();
  
  const appId = Deno.env.get('AGORA_APP_ID');
  const appCertificate = Deno.env.get('AGORA_APP_CERTIFICATE');
  
  // Vérifier que l'utilisateur est autorisé (broadcaster ou audience)
  const user = await verifyUser(req);
  
  // Si broadcaster : vérifier que c'est bien le HOME du match
  if (role === 'broadcaster') {
    const match = await getMatchByChannel(channel);
    if (match.home_player_id !== user.id) {
      return new Response('Unauthorized', { status: 403 });
    }
  }
  
  const tokenRole = role === 'broadcaster'
    ? RtcRole.PUBLISHER
    : RtcRole.SUBSCRIBER;
  
  const token = RtcTokenBuilder.buildTokenWithUid(
    appId, appCertificate, channel, 0, tokenRole, 
    Math.floor(Date.now() / 1000) + 3600
  );
  
  return new Response(JSON.stringify({ token }));
});
```

**Étape 5 — Page User `LiveStreamsPage`** ⭐ NOUVEAU

Page accessible depuis le menu principal qui liste tous les matchs en live :

```
┌──────────────────────────────────────────────────┐
│  📺 LIVES EN COURS                               │
│                                                  │
│  ┌──────────────────────────────────────────┐  │
│  │ 🔴 LIVE · CAMEROON CUP · FINALE         │  │
│  │ NeonKing 🇨🇲 vs RedBull 🇸🇳            │  │
│  │ ⏱️ Début il y a 12 min · 👀 47 spectateurs│  │
│  │                                            │  │
│  │ [▶️ REGARDER]                            │  │
│  └──────────────────────────────────────────┘  │
│                                                  │
│  ┌──────────────────────────────────────────┐  │
│  │ 🔴 LIVE · YAOUNDÉ TOURNEY · DEMI         │  │
│  │ FireKing 🇨🇮 vs IceMan 🇧🇯              │  │
│  │ ⏱️ Début il y a 5 min · 👀 23 spectateurs │  │
│  │                                            │  │
│  │ [▶️ REGARDER]                            │  │
│  └──────────────────────────────────────────┘  │
│                                                  │
│  💡 Aucun autre match streamé pour le moment    │
└──────────────────────────────────────────────────┘
```

**Étape 6 — Page User `WatchStreamPage`** ⭐ NOUVEAU

Quand le user clique sur "REGARDER" :

```dart
// Joindre le channel Agora comme audience
await _engine.setClientRole(role: ClientRoleType.clientRoleAudience);
final token = await getAgoraToken(channelName, 'audience');
await _engine.joinChannel(
  token: token,
  channelId: channelName,
  uid: 0,
  options: const ChannelMediaOptions(
    clientRoleType: ClientRoleType.clientRoleAudience,
    autoSubscribeVideo: true,
    autoSubscribeAudio: true,
  ),
);

// Incrémenter compteur viewers
await supabase.from('matches').update({
  'current_viewers_count': supabase.raw('current_viewers_count + 1'),
}).eq('id', matchId);
```

UI :
```
┌──────────────────────────────────────────────────┐
│  ← Retour                            🔴 LIVE     │
│                                                  │
│  ┌──────────────────────────────────────────┐  │
│  │                                            │  │
│  │      [Vidéo HD du match en cours]         │  │
│  │      (capture écran du joueur HOME)       │  │
│  │                                            │  │
│  │                            👀 47          │  │
│  └──────────────────────────────────────────┘  │
│                                                  │
│  CAMEROON CUP · FINALE                           │
│  NeonKing 🇨🇲 vs RedBull 🇸🇳                    │
│  ⏱️ 12:34 · 🎮 eFootball                        │
│                                                  │
│  💬 CHAT SPECTATEURS                             │
│  ┌────────────────────────────────────────┐    │
│  │ Player3 : Allez NeonKing ! 🔥          │    │
│  │ Player7 : Quel match incroyable        │    │
│  │ Player2 : RedBull va gagner            │    │
│  └────────────────────────────────────────┘    │
│                                                  │
│  [Tape un message...]                            │
└──────────────────────────────────────────────────┘
```

**Étape 7 — Notification au joueur HOME**

Quand un match est marqué comme à streamer (auto ou manuel), le joueur HOME reçoit une notification :

```
🔔 Ton match va être streamé en direct !
NeonKing vs SkyHigh sera diffusé à tous les utilisateurs ARENA.
Assure-toi d'avoir une bonne connexion (>3 Mbps).
```

#### ⚠️ Considérations importantes

**1. Coût Agora maîtrisé**
- Pas tous les matchs sont streamés (sélection admin)
- Volume estimé V1.0 : ~50-100 streams/mois
- Coût Agora estimé : 30-100 $/mois selon traction

**2. Performance du téléphone HOME**
- Encoder + jouer eFootball + bouton flottant = beaucoup de CPU/RAM
- ARENA détecte les téléphones bas de gamme (RAM < 4 GB) et **ne propose pas le streaming** en sélection auto
- L'admin reçoit un warning : "Le HOME a un téléphone bas de gamme, le streaming pourrait laguer"

**3. Sécurité des tokens**
- Token Agora généré côté Edge Function (jamais l'App Certificate exposé)
- Token expire après 1h, renouvelé si nécessaire
- Vérification : seul le HOME peut être broadcaster, audience uniquement pour les autres

**4. Réutilisation du screen capture**
- Le `MediaProjection` Android / `ReplayKit` iOS est **partagé** entre :
  - Recording local (PHASE 8.3) : enregistrement vers fichier local
  - Streaming Agora (PHASE 8.7) : push RTC au channel
- Code natif partagé pour éviter les conflits

#### 🧪 Tests

1. **Test auto-streaming** : créer une compétition 8 joueurs → générer bracket → vérifier que la finale a `is_streamed = true`
2. **Test manuel admin** : aller sur AdminBracketManagementPage → cocher un quart → vérifier `is_streamed = true` + `streaming_activation_type = 'manual_admin'`
3. **Test broadcaster non autorisé** : un joueur AWAY tente de devenir broadcaster → token refusé par Edge Function
4. **Test viewers** : 3 spectateurs joignent → vérifier `current_viewers_count` à jour
5. **Test phone bas de gamme** : émulateur 2 GB RAM → vérifier le warning admin

---

#### ✅ Critères d'acceptation de la PHASE 8

- [ ] Sur Android : bouton flottant rouge visible par-dessus eFootball, timer MM:SS qui tourne
- [ ] Glisser le bouton fonctionne, il reste collé aux bords
- [ ] Tap court ramène ARENA en focus
- [ ] Tap long ouvre le dialogue de verrouillage avec 3 options
- [ ] Forcer l'arrêt déclenche une alerte admin en temps réel
- [ ] L'enregistrement continue quand l'écran est verrouillé/déverrouillé
- [ ] Sur iOS : Live Activity visible avec timer
- [ ] Le recording local est sauvegardé sur Supabase Storage à la fin du match
- [ ] L'enregistrement s'arrête automatiquement quand l'admin valide le score
- [ ] **🆕 Streaming Agora sélectif (sous-phase 8.7)** :
  - [ ] Auto-streaming activé pour les finales (logique métier)
  - [ ] Admin peut activer manuellement le streaming sur n'importe quel match
  - [ ] Notification au joueur HOME quand son match est sélectionné
  - [ ] Token Agora généré côté Edge Function (sécurité)
  - [ ] Stream démarre quand le match commence (côté HOME)
  - [ ] Page `LiveStreamsPage` liste tous les matchs en live
  - [ ] Page `WatchStreamPage` permet de regarder un stream
  - [ ] Compteur `current_viewers_count` à jour en temps réel
  - [ ] Stream s'arrête automatiquement à la fin du match
  - [ ] Détection téléphone bas de gamme (RAM < 4 GB) → warning admin

---

### **PHASE 9 — Profil joueur + Paramètres + Suppression compte (3h)** ⭐ **ENRICHIE**

**Objectif** : page profil avec stats, paramètres, **suppression de compte (RGPD)**.

**Écrans :**
- `PlayerProfilePage` (existait : stats, achievements, historique)
- `EditProfileScreen` (existait)
- `SettingsPage` ⭐ **NOUVEAU** (langue, devise, notifications, privacy, "Revoir l'introduction")
- `DeleteAccountPage` ⭐ **NOUVEAU** (workflow RGPD complet)
- `AboutPage` ⭐ **NOUVEAU** (À propos, version app, mentions légales, CGU, Privacy)

#### 🛠️ SOUS-PHASE 9.1 — Page Profil + Édition (1h)

(Existait déjà : stats, avatar, edit profile)

#### ⚙️ SOUS-PHASE 9.2 — Page Settings (1h) ⭐ NOUVEAU

```
┌──────────────────────────────────────┐
│  ⚙️ PARAMÈTRES                       │
│                                      │
│  PRÉFÉRENCES                         │
│  🌍 Langue                Français > │
│  💱 Devise                XAF >      │
│  🔔 Notifications         ⚙️ >        │
│                                      │
│  COMPTE                              │
│  📧 Changer email                  > │
│  🔑 Changer mot de passe           > │
│  🔗 Méthodes de connexion          > │
│                                      │
│  CONFIDENTIALITÉ                     │
│  📥 Télécharger mes données        > │
│  🗑️ Supprimer mon compte           > │
│                                      │
│  AIDE & INFOS                        │
│  📖 Revoir l'introduction          > │
│  ❓ Aide & Support                 > │
│  ℹ️ À propos                       > │
│                                      │
│  [    SE DÉCONNECTER    ]            │
└──────────────────────────────────────┘
```

#### 🗑️ SOUS-PHASE 9.3 — Suppression de compte (1h) ⭐ NOUVEAU

> 🔴 **OBLIGATOIRE LÉGALEMENT** : RGPD (UE) + Cameroun loi 2010-012 + Apple/Google App Store guidelines depuis 2022.

**Workflow en 4 étapes** :

**Étape 1 — Avertissement** :
```
┌──────────────────────────────────────┐
│  ⚠️ SUPPRIMER MON COMPTE             │
│                                      │
│  Avant de continuer, sache que :     │
│                                      │
│  ❌ Tu perdras :                     │
│  • Toutes tes statistiques           │
│  • Ton historique de matchs          │
│  • Tes trophées et achievements      │
│  • Ton classement                    │
│                                      │
│  ⚠️ Tu ne pourras pas récupérer ces  │
│  données après la suppression.       │
│                                      │
│  ℹ️ Ton compte sera désactivé        │
│  immédiatement, puis supprimé        │
│  définitivement après 30 jours.      │
│                                      │
│  [ANNULER]    [CONTINUER →]          │
└──────────────────────────────────────┘
```

**Étape 2 — Vérification gains en attente** :
```
┌──────────────────────────────────────┐
│  ⚠️ ATTENTION                        │
│                                      │
│  Tu as 25 000 XAF de gains en        │
│  attente de versement.               │
│                                      │
│  Si tu supprimes ton compte          │
│  maintenant, ces gains seront        │
│  PERDUS.                             │
│                                      │
│  [VÉRIFIER MES GAINS]                │
│  [J'ACCEPTE LA PERTE, CONTINUER →]   │
└──────────────────────────────────────┘
```

**Étape 3 — Confirmation par mot de passe ou OAuth** :
```
┌──────────────────────────────────────┐
│  🔒 CONFIRMATION                     │
│                                      │
│  Pour confirmer la suppression de    │
│  ton compte, saisis ton mot de       │
│  passe :                             │
│                                      │
│  🔑 Mot de passe                     │
│  [_________________________]  👁️     │
│                                      │
│  Ou tape "SUPPRIMER" en majuscules : │
│  [_________________________]         │
│                                      │
│  Raison (optionnel) :                │
│  ○ Je n'utilise plus l'app           │
│  ○ Je rencontre des problèmes        │
│  ○ Préoccupations vie privée         │
│  ○ Autre                             │
│                                      │
│  [ANNULER]    [SUPPRIMER MON COMPTE] │
└──────────────────────────────────────┘
```

**Étape 4 — Suppression effective** :

```dart
class AccountDeletionService {
  Future<void> requestDeletion({
    required String userId,
    String? reason,
  }) async {
    // 1. Marquer le compte comme deletion_requested
    await supabase.from('profiles').update({
      'account_deletion_requested_at': DateTime.now().toIso8601String(),
      'account_deletion_reason': reason,
      'is_active': false,
    }).eq('id', userId);
    
    // 2. Annuler les inscriptions aux compétitions futures (rembourser)
    await _cancelFutureRegistrations(userId);
    
    // 3. Marquer les paiements en cours comme à annuler
    await _flagPendingPayments(userId);
    
    // 4. Logger l'action pour audit
    await supabase.from('admin_audit_log').insert({
      'action': 'user_account_deletion_requested',
      'user_id': userId,
      'reason': reason,
      'metadata': {'requested_at': DateTime.now().toIso8601String()},
    });
    
    // 5. Déconnecter l'utilisateur
    await supabase.auth.signOut();
    
    // 6. Email de confirmation au user (Edge Function)
    await supabase.functions.invoke('send_deletion_email', body: {
      'user_id': userId,
      'deletion_date': DateTime.now().add(Duration(days: 30)).toIso8601String(),
    });
  }
}
```

**Edge Function `cleanup_deleted_accounts` (cron quotidien)** :

Anonymise les comptes 30 jours après la demande :

```typescript
// supabase/functions/cleanup_deleted_accounts/index.ts
serve(async (req) => {
  // Trouver les comptes à anonymiser (deletion request > 30 jours)
  const { data: profiles } = await supabase
    .from('profiles')
    .select('id, email')
    .lt('account_deletion_requested_at', 
        new Date(Date.now() - 30 * 24 * 60 * 60 * 1000).toISOString())
    .is('deleted_at', null);
  
  for (const profile of profiles) {
    // Anonymisation : on garde l'ID pour l'intégrité référentielle
    // mais on remplace toutes les données personnelles
    await supabase.from('profiles').update({
      username: `deleted_${profile.id.substring(0, 8)}`,
      email: `deleted_${profile.id.substring(0, 8)}@deleted.arena`,
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
    
    // Notification admin
    await logAdminAction('account_anonymized', profile.id);
  }
});
```

**Cron pg_cron** :
```sql
select cron.schedule(
  'cleanup-deleted-accounts',
  '0 3 * * *',  -- Tous les jours à 3h du matin
  $$ select net.http_post(
    url := 'https://[PROJECT].supabase.co/functions/v1/cleanup_deleted_accounts',
    headers := '{"Authorization": "Bearer [SERVICE_ROLE_KEY]"}'::jsonb
  ); $$
);
```

**Pourquoi un délai de 30 jours ?**
- Permet à l'utilisateur de **changer d'avis** dans le mois
- Permet de gérer les **paiements en cours** (CinetPay peut renvoyer un webhook après 7 jours)
- Conforme aux **bonnes pratiques GDPR** (révocation possible)
- Permet à l'admin d'**enquêter** si l'utilisateur a un litige ouvert

**Cas particuliers à gérer** :
- ⚠️ Si litige ouvert → bloquer la suppression jusqu'à résolution
- ⚠️ Si match en cours → bloquer jusqu'à fin du match
- ⚠️ Si payouts en attente → message warning "Tu vas perdre X XAF"

#### 📥 SOUS-PHASE 9.4 — Export des données (30 min, optionnel V1.0)

Page "Télécharger mes données" :
```
[GÉNÉRER MON ARCHIVE]
```

Edge Function génère un ZIP avec :
- `profile.json` (ses infos)
- `matches.json` (historique matchs)
- `payments.json` (paiements)
- `chat_messages.json` (messages envoyés)

Email avec lien temporaire (valide 24h) vers le ZIP sur Supabase Storage.

**Test PHASE 9 complète** :
- Modifier username/avatar → mis à jour
- Settings → changer langue → app passe en anglais
- Demander suppression compte → flow 4 étapes → compte désactivé
- Vérifier en DB : `account_deletion_requested_at` rempli
- Attendre 30 jours (ou simuler) → cleanup function → données anonymisées



---

### **PHASE 10 — Notifications (2h)**

**Objectif** : notifs push FCM + center in-app + toasts.

**Logique :**
- `notification_service.dart` : init FCM, sauvegarde token dans `profiles.fcm_token`
- Edge function Supabase qui déclenche FCM sur INSERT dans `notifications`
- `flutter_local_notifications` pour les notifs in-app (foreground)
- Page `NotificationsPage` avec liste + "Tout marquer comme lu"

**Test** : une notif insérée dans Supabase déclenche un push sur le device.

---

### **PHASE 11 — Espace Admin (4-5h, gros morceau)**

**Objectif** : tout l'espace admin compétition.

> 💡 **Important** : à ce stade, l'admin peut **créer et gérer des compétitions complètes en mode gratuit** (`entry_fee = 0`). C'est volontaire : on valide tout le workflow admin (création compet → matchs → validation scores → bracket auto) **avant** d'ajouter la couche paiement (PHASE 11 BIS juste après). L'étape "Paiement" du `CreateCompetitionPage` est codée dès maintenant mais affiche par défaut le toggle sur "Gratuite" et désactive l'option "Payante" avec le message "Disponible après activation des paiements (PHASE 11 BIS)".

> 💰 **CONTRÔLE FINANCIER STRICT** : aucune automatisation des paiements aux gagnants. L'admin garde le **contrôle total** : définition des gains à la création, validation manuelle de chaque payout en fin de compétition. Les vérifications sont automatisées (KYC, anti-cheat, etc.) mais la **décision finale est toujours humaine**.

**Écrans :**
- `AdminDashboardPage`
- `AdminCompetitionPage` (gestion d'une compétition : phases, matchs, scores, brackets)
- `AdminMatchDetailPage`
- `AdminStreamModerationPage` ⭐ **NOUVEAU** (sélection matchs à streamer + grille live des matchs en cours + stats viewers)
- `AdminRoomTrackerPage` (suivi des rooms en cours)
- `AdminBracketManagementPage` (génération + visualisation bracket)
- `AdminPayoutsPage` ⭐ **NOUVEAU** (centre de validation manuelle des paiements gagnants)
- `CreateCompetitionPage` (6 étapes : Infos / Jeu+Format / Paiement / **Gains** / Options / Confirmation)

**🆕 Étape "Gains" du CreateCompetitionPage (DÉTAIL)**

Cette étape est **CRITIQUE** : l'admin définit ici exactement ce que recevront les **4 premiers** de la compétition.

**UI de l'étape "Gains"** :

```
┌──────────────────────────────────────────────────────────┐
│  💰 GAINS DES VAINQUEURS                                 │
│                                                          │
│  Comment veux-tu définir les gains ?                     │
│  ⦿ Pourcentage de la cagnotte                            │
│  ⦾ Montants fixes                                        │
│                                                          │
│  ┌──────────────────────────────────────────────────┐   │
│  │ 🥇 1ère place (Champion)                          │   │
│  │ [____50___] %    ≈ 75 000 XAF                     │   │
│  │                                                    │   │
│  │ 🥈 2ème place                                     │   │
│  │ [____25___] %    ≈ 37 500 XAF                     │   │
│  │                                                    │   │
│  │ 🥉 3ème place                                     │   │
│  │ [____15___] %    ≈ 22 500 XAF                     │   │
│  │                                                    │   │
│  │ 4ème place                                        │   │
│  │ [____10___] %    ≈ 15 000 XAF                     │   │
│  └──────────────────────────────────────────────────┘   │
│                                                          │
│  Total redistribué : 100% ✓                              │
│  Cagnotte estimée : 150 000 XAF                          │
│  (32 joueurs × 5 000 XAF − 15% commission)               │
│                                                          │
│  💰 Bonus sponsoring (optionnel)                         │
│  [_______0_______] XAF                                   │
│  Augmente la cagnotte au-delà des inscriptions           │
│                                                          │
│  [   CONTINUER   ]                                       │
└──────────────────────────────────────────────────────────┘
```

**Mode "Pourcentage"** :
- 4 inputs % pour positions 1, 2, 3, 4
- Validation temps réel : somme(%) = 100% (sinon le bouton "CONTINUER" est désactivé + warning)
- Affichage en temps réel du montant équivalent dans la devise admin
- Le calcul réel se fera à la fin de la compétition selon la cagnotte effective

**Mode "Fixe"** :
- 4 inputs montants en devise locale (XAF/XOF/USD)
- Affichage du total alloué en bas
- Si total alloué > cagnotte estimée → warning rouge "Tu dépasses la cagnotte. Ajoute du sponsoring ou ajuste les gains."
- Si total < cagnotte → message vert "Solde restant : X XAF (sera ajouté à la commission plateforme)"

**Bonus sponsoring (optionnel)** :
- Input pour ajouter un montant **en plus** de la cagnotte des inscriptions
- Cas d'usage : compétitions sponsorisées par une marque (ex: Orange offre 100 000 XAF)
- Stocké dans `competitions.sponsored_amount_usd`
- Affiché publiquement aux joueurs comme "💎 Cagnotte boostée par [sponsor]"

**Logique de calcul à la fin de la compétition** :
- Si mode = `percentage` : calcul auto : `prize_amount = (entry_fees × players − commission + sponsoring) × percentage / 100`
- Si mode = `fixed` : montants définis à la création utilisés tels quels
- Le résultat est stocké dans `prizes.amount_usd` au moment de la clôture

**Étape Paiement (préparée, activée en PHASE 11 BIS)** :
- Toggle "Compétition gratuite ou payante" — en PHASE 11, le toggle "Payante" est **désactivé** (greyed out + message "Disponible après PHASE 11 BIS")
- En PHASE 11 BIS, le toggle devient cliquable et permet :
  - Input frais d'inscription + sélecteur devise (XAF / XOF / USD)
  - Slider commission plateforme (0-30%, défaut 15%)
  - Date limite d'inscription (les paiements sont bloqués après)
  - Méthodes acceptées (checkboxes) : MoMo / Crypto
- **Note** : la répartition pourcentages 1er/2e/3e est maintenant gérée à l'étape **"Gains"** ci-dessus avec le top 4

**🆕 SOUS-PHASE 11.6 — AdminPayoutsPage (Centre de validation manuelle, 1.5h)**

> 🔴 **AUCUNE AUTOMATISATION FINANCIÈRE** : tous les paiements aux gagnants nécessitent une **validation manuelle de l'admin**. C'est volontaire pour protéger la plateforme contre les bugs, tricheurs détectés tardivement, et litiges complexes.

**Workflow général** :
1. Une compétition se termine (statut → `completed`)
2. Le système crée automatiquement les **entrées de payout en attente** (1 par gagnant, donc 4 par compétition)
3. **Notification push à l'admin** : "Compétition X terminée — 4 payouts à valider"
4. L'admin va sur `AdminPayoutsPage` pour valider

**UI `AdminPayoutsPage`** :

État liste (vue principale) :
```
┌──────────────────────────────────────────────────────────┐
│  💰 CENTRE DE VALIDATION PAIEMENTS                       │
│                                                          │
│  Filtres : [Tous ▼] [Pending] [Validés] [Refusés]       │
│                                                          │
│  ┌─ COMPÉTITION TERMINÉE LE 04/05/2026 ──────────────┐  │
│  │ Cameroon eFootball Cup · 32 joueurs              │  │
│  │ Cagnotte : 150 000 XAF                            │  │
│  │ ⚠️ 4 payouts pending                              │  │
│  │                                                    │  │
│  │ 🥇 NeonKing 🇨🇲    75 000 XAF  [✓ KYC] [✓ Anti-cheat] [Voir →] │
│  │ 🥈 RedBull 🇸🇳     37 500 XAF  [✓ KYC] [✓ Anti-cheat] [Voir →] │
│  │ 🥉 IceMan 🇧🇯      22 500 XAF  [⚠️ KYC] [✓ Anti-cheat] [Voir →] │
│  │ 4️⃣ DarkLord 🇹🇬    15 000 XAF  [✓ KYC] [⚠️ Litige] [Voir →]   │
│  │                                                    │  │
│  │ [VALIDER LE BATCH (2/4 prêts)]  [TOUT REFUSER]   │  │
│  └────────────────────────────────────────────────────┘  │
└──────────────────────────────────────────────────────────┘
```

État détail d'un payout (pour validation 1 par 1) :
```
┌──────────────────────────────────────────────────────────┐
│  ← Retour                                                │
│                                                          │
│  💰 PAYOUT — NeonKing                                    │
│                                                          │
│  Compétition : Cameroon eFootball Cup                    │
│  Position : 🥇 1ère place (Champion)                     │
│  Montant : 75 000 XAF (≈ 125 USD)                        │
│  Méthode joueur : MTN Mobile Money 6XX XXX XXX           │
│                                                          │
│  ✅ VÉRIFICATIONS AUTO                                   │
│  ✓ KYC vérifié                                           │
│  ✓ Pas de litige ouvert                                  │
│  ✓ Pas d'anomalie anti-cheat                             │
│  ✓ Compte actif (non banni)                              │
│  ✓ Données paiement complètes                            │
│                                                          │
│  📺 VÉRIFICATIONS HUMAINES                               │
│  [▶️ Voir le recording de la finale (28 min)]            │
│  [📊 Voir l'historique des matchs]                       │
│  [💬 Voir le chat du tournoi]                            │
│                                                          │
│  📝 Justification (obligatoire)                          │
│  [_____Validation après revue manuelle_____]             │
│                                                          │
│  [✓ VALIDER LE PAIEMENT]  [✗ REFUSER]  [⏸ METTRE EN ATTENTE] │
└──────────────────────────────────────────────────────────┘
```

**Validation BATCH (par défaut)** :
- Bouton "VALIDER LE BATCH" actif si **tous les payouts** de la compétition passent les vérifications auto
- Si certains ont des warnings (KYC manquant, litige) → seuls les autres sont validés en batch, l'admin doit traiter les warnings 1 par 1
- Confirmation forte : modal "Tu vas valider 4 paiements totalisant 150 000 XAF. Saisis le montant total pour confirmer : [______]" (anti-erreur typique)
- Une fois validé : appel à l'Edge Function `execute_validated_payout` pour CHAQUE payout

**Validation 1 par 1 (cas litige)** :
- Pour les payouts avec warnings, l'admin doit :
  1. Cliquer "Voir →"
  2. Examiner les preuves (recording vidéo, chat, scores)
  3. Saisir une **justification écrite** (champ obligatoire)
  4. Décider : Valider / Refuser / Mettre en attente

**Actions possibles** :
- **VALIDER** : déclenche le payout via CinetPay/NowPayments
- **REFUSER** : payout annulé, l'argent reste dans la cagnotte plateforme (commission), notification au joueur avec raison
- **METTRE EN ATTENTE** : payout reporté, peut être rouvert plus tard

**Audit trail (CRITIQUE)** :
Chaque action enregistre dans la table `admin_audit_log` :
- ID admin qui a validé
- Timestamp précis
- IP et user-agent
- Justification écrite (champ obligatoire pour Refuser/Reporter)
- Snapshot des vérifications auto au moment de la décision

**Note** : la sous-phase 11.5 (Gestion des Brackets) reste inchangée.

**🏆 SOUS-PHASE 11.5 — Gestion des Brackets (1.5h)**

C'est le coeur de l'admin. À implémenter dans `features_admin/competition_management/bracket/`.

**Algorithmes à coder** dans `core/utils/bracket_generators/` :
- `single_elimination_generator.dart` (rounds, matchs, byes si nombre non puissance de 2)
- `groups_then_knockout_generator.dart` (génère phase groupes + phase KO liées)
- `round_robin_generator.dart` (circle method, classement par points)

**Écran `AdminBracketManagementPage`** (workflow admin pour générer un bracket) :

État 1 — Avant génération (statut compétition = `registration` ou `closed`) :
- Affichage : nombre d'inscrits / capacité (ex : "23/32 joueurs")
- Bouton "FERMER LES INSCRIPTIONS" (si encore ouvertes)
- Bouton "GÉNÉRER LE BRACKET" (rouge, gros, central)
- Tap → confirmation modale "Cette action est irréversible. Êtes-vous sûr ?"
- Si moins de 8 joueurs : warning + impossibilité de générer

État 2 — Génération en cours (1-2 secondes) :
- Animation : joueurs qui s'organisent dans l'arbre avec un effet "shuffle"
- Toast "Bracket généré avec succès"

État 3 — Bracket généré (statut = `active`) :
- Affichage du bracket complet (même style que côté User)
- **Différence clé** : chaque carte de match a un bouton "✏️ Valider score" en haut à droite
- Tap sur le bouton → bottom sheet de validation :
  - Inputs scores joueur 1 / joueur 2
  - Bouton "VALIDER" (rouge)
  - Bouton "ANNULER MATCH" (gris, pour cas exceptionnels)
- Validation déclenche :
  1. Update `matches` (scores, winner_id, finished_at)
  2. Update `bracket_nodes.next_node_id` du round suivant (le vainqueur est inscrit)
  3. Update stats des 2 joueurs
  4. Notifications push aux 2 joueurs
  5. Si dernier match : compétition passée en `completed`

**Bouton de secours "RESET BRACKET"** (caché derrière un long press de 3s) :
- Confirmation forte "⚠️ DANGER : Tous les scores seront perdus"
- Permet de regénérer un bracket en cas de bug

**Visualisation pour les groupes** :
- Tableau par groupe avec scores live
- Colonne "Action" avec bouton de validation match par match
- Quand groupe terminé : badge "QUALIFIÉ" sur les top X joueurs

**Logique :**
- Génération automatique des poules + bracket (algos dans `core/utils/bracket_generators/`)
- Validation de score → mise à jour stats joueurs + progression bracket auto via la table `bracket_nodes`
- Bottom sheet de saisie de score
- Détection anomalies anti-cheat (basique : alerte si recording stoppé pendant match live)
- Realtime : tous les changements sont propagés instantanément à l'app User

**Test** : un admin crée une compétition gratuite de 8 joueurs en single elimination, clique sur "Générer le bracket", l'arbre apparaît avec 4 matchs round 1, 2 matchs demi-finale (vides), 1 finale (vide). Il valide les scores des matchs 1 par 1. À chaque validation, les vainqueurs montent automatiquement au round suivant. Quand la finale est validée, la compétition passe en `completed` et le champion est annoncé.

---

### **PHASE 11 BIS — Paiements CinetPay + Crypto (5-6h, sensible)**

> 📍 **Position dans le roadmap** : cette phase a été délibérément placée **après la PHASE 11 (Admin)** plutôt qu'avant, pour permettre de valider tout le gameplay (compétitions, matchs, gestion admin) **avant d'ajouter la couche monétisation**. À ce stade, l'admin peut déjà créer/gérer des compétitions complètes en mode gratuit ; on active maintenant le paiement.

> ⚠️ **PHASE CRITIQUE — argent réel en jeu.** Tu (Claude) dois :
> 1. **Ne JAMAIS exposer les clés API providers côté Flutter** → tout passe par des Edge Functions Supabase
> 2. **Toujours valider les webhooks** côté serveur (signature HMAC) avant de marquer un paiement comme `completed`
> 3. **Idempotence** : un même webhook reçu 2 fois ne doit pas créditer 2 fois
> 4. **Audit trail complet** : tout dans `payment_webhook_log`
> 5. Avancer sous-phase par sous-phase et **tester avec les sandboxes** des providers avant tout passage en prod

> 💡 **Avant cette phase** : les compétitions ont un `entry_fee_amount_usd` mis à `0` par défaut. Le code Flutter affiche un message "Paiement bientôt disponible" si `entry_fee > 0`. Une fois cette phase complétée, l'admin peut activer les paiements via les feature flags Supabase.

#### 🎯 Objectif fonctionnel

Quand un joueur veut s'inscrire à une compétition payante :
1. Il tape sur "S'INSCRIRE" → écran de choix méthode (Mobile Money / Carte / Crypto)
2. Selon le choix, il saisit son numéro MoMo OU est redirigé vers une WebView (carte/crypto)
3. Une fois le paiement confirmé par le provider (webhook), il est automatiquement inscrit à la compétition
4. À la fin de la compétition, le top 3 reçoit ses gains via payout (Mobile Money de retour, carte = remboursement, crypto = transfer)
5. La plateforme garde sa commission (configurable par compet, défaut 15%)

#### 💰 Modèle financier

```
Inscription : 5000 XAF par joueur × 16 joueurs = 80 000 XAF collectés
Commission plateforme (15%)                     = 12 000 XAF (revenue)
Cagnotte distribuée                              = 68 000 XAF
  → 1er (60%) : 40 800 XAF
  → 2e (25%)  : 17 000 XAF
  → 3e (15%)  : 10 200 XAF
```

#### 📋 Sous-phases

---

**SOUS-PHASE 10B.1 — Création des comptes providers V1.0 (45min)**

Pour le **V1.0 (Afrique francophone)**, l'utilisateur ne crée que **2 comptes providers** :

1. **CinetPay** (https://cinetpay.com) — Afrique francophone (CEMAC + UEMOA)
   - Compte marchand, mode **SANDBOX**
   - Couvre : MoMo MTN/Orange/Moov/Airtel, Wave, Free Money, T-Money, Flooz
   - Récupérer : `API_KEY`, `SITE_ID`, `SECRET_KEY`
   - Webhook : `https://[ton-projet].supabase.co/functions/v1/cinetpay-webhook`

2. **NowPayments** (https://nowpayments.io) — Crypto fallback (mondial)
   - Compte, récupérer `API_KEY` + `IPN_SECRET_KEY`
   - IPN : `https://[ton-projet].supabase.co/functions/v1/nowpayments-webhook`

**À FAIRE PLUS TARD** (V1.1 et V1.2, ne pas créer les comptes maintenant) :
- ⏸️ Flutterwave (V1.1 — quand on étendra à NG, GH, KE, ZA)
- ⏸️ Paymob, Paymee, CMI (V1.2 — quand on étendra au Maghreb)

**Configuration Supabase Secrets** :
```bash
supabase secrets set CINETPAY_API_KEY=...
supabase secrets set CINETPAY_SITE_ID=...
supabase secrets set CINETPAY_SECRET_KEY=...
supabase secrets set NOWPAYMENTS_API_KEY=...
supabase secrets set NOWPAYMENTS_IPN_SECRET=...
```

**Côté Flutter** (`.env`) — rien à ajouter pour V1.0, tout passe par les Edge Functions.

**Vérification** : 2 dashboards accessibles, mode test/sandbox confirmé.

---

**SOUS-PHASE 10B.1.5 — Provider Router avec feature flags (45min)**

Le Router supporte tous les providers V1.0/V1.1/V1.2 mais **gate par les feature flags**. En V1.0, seuls CinetPay et NowPayments sont actifs.

```dart
class PaymentProviderRouter {
  /// Retourne les providers disponibles selon pays + feature flags actifs
  static List<PaymentProvider> getAvailableProviders(
    String countryCode,
    FeatureFlagsState flags,
  ) {
    final providers = <PaymentProvider>[];

    // ═══ V1.0 — Afrique francophone ═══
    const cinetpayCountries = {
      'CM', 'GA', 'CG', 'TD', 'CF', 'GQ',  // CEMAC
      'CI', 'SN', 'BJ', 'TG', 'BF', 'ML', 'NE',  // UEMOA
      'MG', 'KM', 'DJ',
    };
    if (flags.cinetpayEnabled && cinetpayCountries.contains(countryCode)) {
      providers.add(PaymentProvider.cinetpay);
    }

    // ═══ V1.1 — Afrique anglophone (gated) ═══
    if (flags.flutterwaveEnabled) {
      const flutterwaveCountries = {
        'NG', 'GH', 'KE', 'ZA', 'UG', 'RW', 'ZM', 'TZ',
      };
      if (flutterwaveCountries.contains(countryCode)) {
        providers.add(PaymentProvider.flutterwave);
      }
    }

    // ═══ V1.2 — Maghreb (gated) ═══
    if (flags.maghrebEnabled) {
      switch (countryCode) {
        case 'MA':
          if (flags.cmiEnabled) providers.add(PaymentProvider.cmi);
          break;
        case 'DZ':
          if (flags.satimEnabled) providers.add(PaymentProvider.satim);
          break;
        case 'TN':
          if (flags.paymeeEnabled) providers.add(PaymentProvider.paymee);
          break;
        case 'EG':
          if (flags.paymobEnabled) providers.add(PaymentProvider.paymob);
          break;
      }
    }

    // ═══ V1.0 — Crypto fallback (toujours disponible) ═══
    if (flags.nowpaymentsEnabled) {
      providers.add(PaymentProvider.nowpayments);
    }

    return providers;
  }

  /// Méthodes de paiement spécifiques selon provider et pays
  static List<PaymentMethodType> getMethodsFor(
    PaymentProvider provider,
    String countryCode,
  ) {
    switch (provider) {
      case PaymentProvider.cinetpay:
        return _getCinetPayMethodsForCountry(countryCode);
      case PaymentProvider.flutterwave:
        return _getFlutterwaveMethodsForCountry(countryCode);  // Stub V1.0
      case PaymentProvider.cmi:
      case PaymentProvider.satim:
      case PaymentProvider.paymee:
      case PaymentProvider.paymob:
        return _getMaghrebMethodsForCountry(countryCode);  // Stub V1.0
      case PaymentProvider.nowpayments:
        return [
          PaymentMethodType.cryptoUsdtTrc20,
          PaymentMethodType.cryptoBtc,
          PaymentMethodType.cryptoEth,
        ];
    }
  }

  static List<PaymentMethodType> _getCinetPayMethodsForCountry(String country) {
    switch (country) {
      case 'CM':
        return [PaymentMethodType.mtnMomoCm, PaymentMethodType.orangeMoneyCm];
      case 'CI':
        return [
          PaymentMethodType.mtnMomoCi, PaymentMethodType.orangeMoneyCi,
          PaymentMethodType.moovMoneyCi, PaymentMethodType.waveCi,
        ];
      case 'SN':
        return [
          PaymentMethodType.orangeMoneySn, PaymentMethodType.waveSn,
          PaymentMethodType.freeMoneySn,
        ];
      case 'BJ':
        return [PaymentMethodType.mtnMomoBj, PaymentMethodType.moovMoneyBj];
      case 'TG':
        return [PaymentMethodType.tmoneyTg, PaymentMethodType.floozTg];
      case 'BF':
        return [PaymentMethodType.orangeMoneyBf, PaymentMethodType.moovMoneyBf];
      case 'ML':
        return [PaymentMethodType.orangeMoneyMl, PaymentMethodType.moovMoneyMl];
      case 'GA':
        return [PaymentMethodType.airtelMoneyGa, PaymentMethodType.moovMoneyGa];
      case 'CG':
        return [PaymentMethodType.mtnMomoCg, PaymentMethodType.airtelMoneyCg];
      case 'TD':
        return [PaymentMethodType.airtelMoneyTd];
      default:
        return [];
    }
  }

  // Stubs V1.0 (vides), seront implémentés en V1.1 et V1.2
  static List<PaymentMethodType> _getFlutterwaveMethodsForCountry(String country) => [];
  static List<PaymentMethodType> _getMaghrebMethodsForCountry(String country) => [];
}
```

**Test 10B.1.5** :
- Tester avec différents `countryCode` (CM, CI, SN) → bonnes options CinetPay
- Activer `provider_flutterwave_enabled = true` dans Supabase → testCM devient CinetPay + Flutterwave
- Désactiver → seul CinetPay revient

---

**SOUS-PHASE 10B.2 — Edge Functions Supabase V1.0 (1.5h)**

Pour le V1.0, on ne crée que **3 Edge Functions Deno** (CinetPay + Crypto). Flutterwave/Maghreb seront ajoutées en V1.1/V1.2.

**`create-payment`** — Initie un paiement avec router selon provider et feature flags
```typescript
serve(async (req) => {
  const { competitionId, method, currencyLocal } = await req.json();

  // 1. Auth user
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return new Response('Unauthorized', { status: 401 });

  // 2. Charger feature flags depuis app_config
  const { data: flagsRows } = await supabase.from('app_config').select('*');
  const flags = parseFlags(flagsRows);

  // 3. Vérifier que le pays est dans allowed_countries
  const { data: profile } = await supabase
    .from('profiles')
    .select('country_code, preferred_currency')
    .eq('id', user.id)
    .single();
  if (!flags.allowed_countries_v1.includes(profile.country_code)) {
    return new Response('Country not yet supported', { status: 403 });
  }

  // 4. Vérifier compet (status = registration, pas déjà payé)
  // 5. Calculer amount_local depuis amount_usd × exchange_rate
  // 6. Créer payment en DB (status: pending)

  // 7. Router vers le bon provider
  const provider = determineProvider(profile.country_code, method, flags);
  switch (provider) {
    case 'cinetpay':
      if (!flags.provider_cinetpay_enabled) return error('Disabled');
      return await createCinetPayCharge(payment);
    case 'nowpayments':
      if (!flags.provider_nowpayments_enabled) return error('Disabled');
      return await createNowPaymentsCharge(payment);
    // V1.1+ (gated par flags)
    case 'flutterwave':
      if (!flags.provider_flutterwave_enabled) return error('V1.1 not active yet');
      return await createFlutterwaveCharge(payment);
    default:
      return error('Provider not supported');
  }
});
```

**`cinetpay-webhook`** — Reçoit confirmations CinetPay
```typescript
serve(async (req) => {
  const body = await req.json();
  const signature = req.headers.get('x-token');
  // 1. Logger payload brut dans payment_webhook_log
  // 2. Valider signature HMAC avec CINETPAY_SECRET_KEY
  // 3. Idempotence : déjà traité ?
  // 4. Update payment status, créer registration si completed
  // 5. Notifier le user via insert dans notifications
});
```

**`nowpayments-webhook`** — Idem NowPayments avec validation IPN signature

**Déploiement V1.0** :
```bash
supabase functions deploy create-payment
supabase functions deploy cinetpay-webhook --no-verify-jwt
supabase functions deploy nowpayments-webhook --no-verify-jwt
```

**Pour V1.1 (plus tard)** : `flutterwave-webhook`. Pour V1.2 : `paymob-webhook`, `paymee-webhook`, `cmi-webhook`. Architecture déjà prête côté Flutter et `create-payment`.

**Test 10B.2** : déclencher un paiement test CinetPay sandbox → payment passe en `completed` et registration créée. Tester aussi NowPayments avec USDT TRC20 sandbox.

---

**SOUS-PHASE 10B.3 — UI PaymentMethodPicker adaptatif (1h)**

**Écran `PaymentMethodPicker`** — affiche dynamiquement les options selon le pays détecté :

```
[Header]
PAIEMENT INSCRIPTION
[Montant en gros, dans la devise locale du joueur]
ex: "4,65 €"  (avec sous-titre "≈ 5 USD" en petit)

[Section Méthodes — adaptative]
Si countryCode = 'CM':
  ─ "Mobile Money" (titre traduit selon langue) ─
    🟧 MTN Mobile Money
    🟥 Orange Money
    🟦 Wave
  ─ "Carte bancaire" ─
    💳 Visa / Mastercard / Carte locale
  ─ "Crypto" ─
    💎 USDT / BTC / ETH

Si countryCode = 'IN':
  ─ "UPI & Banks" ─
    📱 UPI (BHIM, GPay, PhonePe...)
    💳 RuPay / Visa / Mastercard
    🏦 NetBanking
    🟦 Paytm
  ─ "Crypto" ─

Si countryCode = 'FR' ou autres:
  ─ "Card & Wallets" ─
    💳 Visa / Mastercard / Amex
    🍎 Apple Pay  (si iOS)
    🟢 Google Pay (si Android)
  ─ "Crypto" ─

[Footer]
"Frais service : 15% — Cagnotte estimée : [LocalizedAmount]"
"Méthodes affichées selon votre pays. Crypto disponible partout."
```

**Logique** :
```dart
class PaymentMethodPicker extends ConsumerWidget {
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final providers = PaymentProviderRouter.getAvailableProviders(user.countryCode);

    return Scaffold(
      body: ListView(
        children: [
          _PaymentHeader(amount: amountUsd),
          for (final provider in providers)
            _ProviderSection(
              provider: provider,
              methods: PaymentProviderRouter.getMethodsFor(provider, user.countryCode),
              onMethodSelected: (method) => _handleMethodTap(context, method),
            ),
        ],
      ),
    );
  }

  void _handleMethodTap(BuildContext context, PaymentMethodType method) {
    switch (method.provider) {
      case PaymentProvider.cinetpay:
        // → MobileMoneyScreen
      case PaymentProvider.stripe:
        // → StripePaymentScreen (PaymentSheet natif)
      case PaymentProvider.razorpay:
        // → RazorpayPaymentScreen
      case PaymentProvider.nowpayments:
        // → CryptoPaymentScreen
    }
  }
}
```

**Test 10B.3** : changer le `countryCode` du profil (CM, IN, FR) → l'écran affiche les bonnes options à chaque fois.

---

**SOUS-PHASE 10B.3.1 — Mobile Money CinetPay (Afrique) (1h)**

**Écran `MobileMoneyScreen`** :
- Logo opérateur sélectionné (grand)
- Input "Numéro de téléphone" avec auto-format selon pays :
  - CM : `6XX XXX XXX` (9 chiffres, commence par 6)
  - CI : `XX XX XX XX XX` (10 chiffres)
  - SN : `7X XXX XX XX` (9 chiffres)
- Validation côté client + serveur
- Bouton "PAYER" affichant le montant en devise locale
- Au tap : appel à l'Edge Function `create-payment`
- Dialog d'instructions USSD (texte traduit par opérateur)
- Polling du statut toutes les 3s pendant 5 min

**Test 10B.3.1** : sandbox CinetPay → paiement test avec MTN MoMo CM.


**SOUS-PHASE 10B.4 — UI Crypto (NowPayments, mondial) (1h)**

**Écran `CryptoPaymentScreen`** :
- Sélecteur réseau : USDT (TRC20 recommandé pour frais bas), BTC, ETH
- Une fois choisi, l'app appelle `create-payment` qui retourne :
  - L'adresse crypto à payer
  - Le montant exact (avec conversion USD → crypto au cours du moment)
  - Un QR code de l'adresse
- L'écran affiche :
  - QR code (gros, scannable depuis un autre wallet)
  - Adresse cliquable (tap = copy)
  - Montant à envoyer en gros (`52.34 USDT`)
  - **Countdown 30 min** avant expiration
  - Statut en bas : "En attente de la transaction…"
- NowPayments confirme par webhook quand la blockchain confirme (1-3 confirmations selon coin)

**⚠️ Détail technique** : NowPayments envoie plusieurs webhooks pour un même paiement :
- `waiting` → user n'a pas envoyé
- `confirming` → tx vue, en attente de confirmations
- `confirmed` → confirmée mais pas encore créditée
- `finished` → fonds reçus, c'est seulement à ce moment qu'on marque `completed`
- `failed` / `expired` → échec

**Test 10B.5** : avec NowPayments sandbox, faire un paiement USDT TRC20 avec une adresse de test.

---

**SOUS-PHASE 10B.5 — Écrans de statut (success / failed / processing) (30min)**

**`PaymentProcessingScreen`** :
- Animation : 3 dots qui pulsent
- "Vérification du paiement…"
- Stream realtime sur le payment → bascule auto quand status change
- Bouton "ANNULER" qui passe le payment en `cancelled`

**`PaymentSuccessScreen`** :
- Checkmark vert animé
- "INSCRIPTION CONFIRMÉE !"
- Récap : compétition, montant, méthode
- Bouton "VOIR LA COMPÉTITION" → navigue vers `CompetitionDetailPage`

**`PaymentFailedScreen`** :
- Icône X rouge
- Raison de l'échec (depuis `payments.failure_reason`)
- Bouton "RÉESSAYER" et "ANNULER"

**Test 10B.5** : flow complet d'inscription, voir l'animation success.

---

**SOUS-PHASE 10B.6 — Page d'historique paiements (30min)**

**`PaymentHistoryScreen`** (accessible depuis le profil) :
- Liste de tous les paiements du user
- Filtres : Tous / Réussis / En attente / Échoués
- Chaque ligne : icône méthode, compétition, montant, date, statut pill
- Tap → bottom sheet avec détails complets + bouton "Télécharger reçu PDF"

---

**SOUS-PHASE 10B.7 — Système de Payout (versement aux gagnants) (1h)**

Quand une compétition se termine, le système doit créer automatiquement les payouts pour le top 3.

**Edge Function `finalize-competition`** :
- Déclenchée quand la finale est validée par l'admin
- Lit `competitions.prize_distribution` pour connaître les pourcentages
- Crée 3 lignes dans `payouts` avec status `pending`
- Crée notification "Tu as gagné X XAF ! Réclame ton prix" pour chaque gagnant

**Écran `PayoutRequestScreen`** (côté gagnant) :
- "🏆 Félicitations ! Tu as gagné X XAF"
- Sélecteur méthode de réception (mêmes options que paiement)
- Saisie destination (numéro MoMo / IBAN / adresse crypto)
- Bouton "DEMANDER LE VERSEMENT"
- Le payout passe `pending` → `processing` après validation super-admin

**Côté Super-Admin** (à intégrer en phase 12) :
- Page "Payouts en attente" avec liste
- Bouton "Approuver" → déclenche le transfer via API CinetPay/NowPayments
- Bouton "Rejeter" avec raison (anti-fraude : ex. compte louche)

**⚠️ Manuel pour la V1** : le super-admin valide chaque payout. La V2 pourra automatiser.

**Test 10B.7** : terminer une compet test, voir les payouts générés, faire le flow de demande, voir le super-admin approuver.

---

#### ✅ Critères d'acceptation de la phase 11 BIS

- [ ] Aucune clé API provider n'est dans le code Flutter (juste appels Edge Functions)
- [ ] Webhook CinetPay valide la signature HMAC avant traitement
- [ ] Webhook NowPayments valide l'IPN secret
- [ ] Idempotence vérifiée : envoyer 2x le même webhook ne double pas l'inscription
- [ ] Un paiement échoué redirige bien vers `PaymentFailedScreen`
- [ ] Un paiement réussi crée automatiquement la registration
- [ ] La prize_pool de la compétition se met à jour automatiquement
- [ ] La commission plateforme est correctement calculée et stockée dans `platform_revenue`
- [ ] Le payout vers le gagnant fonctionne en sandbox (au moins MoMo)
- [ ] L'historique des paiements affiche tous les statuts correctement

#### 🚨 Considérations légales (à discuter avec un avocat avant prod)

- **Licence** : organiser des compétitions payantes peut être qualifié de jeu d'argent dans certains pays. Au Cameroun, vérifier auprès de la **CONAC** (Commission Nationale Anti-Corruption) et la réglementation sur les loteries/jeux.
- **KYC** : pour les payouts > 100 000 XAF, prévoir validation d'identité (pièce d'identité + selfie)
- **CGU/CGV** : rédiger un document clair sur frais, conditions de remboursement, litiges
- **RGPD** : si tu cibles aussi l'Europe, ajouter consentement traitement données + droit à l'oubli

---

### **PHASE 12 — Espace Super-Admin (2h)**

**Objectif** : dashboard global + gestion admins.

**Écrans :**
- `SuperAdminDashboardPage` (stats globales)
- `SuperAdminCompetitionListPage`
- `SuperAdminAdminManagementPage` (créer/assigner/suspendre admins)

**Test** : un super-admin crée une nouvelle compétition et assigne un admin.

---

### **PHASE 12.5 — Automatisation & Orchestration (10-12h, gros morceau)**

> 🤖 **PHASE CRITIQUE pour la scalabilité.** À ce stade, l'app fonctionne avec admin manuel partout. On va maintenant **automatiser 80% des tâches** via Edge Functions Supabase + cron jobs + triggers SQL. Cette phase transforme ARENA d'un outil manuel en une **plateforme auto-gérée**.

**Objectif** : 90% de réduction de la charge admin par compétition.

**Pré-requis** : tout le reste (PHASE 0 à 12) doit fonctionner. Cette phase est une **couche d'automatisation** par-dessus l'existant, pas une refonte.

#### 📋 Sous-phases à exécuter dans cet ordre

---

**SOUS-PHASE 12.5.1 — Setup Edge Functions Supabase (1h)**

Configuration de l'environnement Edge Functions.

**Étapes** :
1. Installer Supabase CLI : `npm install -g supabase`
2. Login : `supabase login`
3. Link au projet : `supabase link --project-ref [project-ref]`
4. Créer la structure :
   ```
   supabase/
   └── functions/
       ├── _shared/
       │   ├── cors.ts
       │   ├── supabase-client.ts
       │   └── fcm.ts
       └── [12 fonctions à créer]
   ```
5. Configurer les secrets : `SERVICE_ROLE_KEY`, `FCM_SERVER_KEY`
6. Tester déploiement avec `supabase functions deploy hello-world`

**Test 12.5.1** : déployer une Edge Function "hello-world" et la tester via curl.

---

**SOUS-PHASE 12.5.2 — Orchestration auto compétitions (2h)**

Création des 4 Edge Functions d'orchestration :

**1. `auto_close_registrations`** (cron 1min)
- Trouve les compétitions où `registration_closes_at < now()` ET `status = 'registration'`
- Vérifie le min_players (défaut 8)
- Si OK → status = 'closed', notification admin
- Si pas assez → status = 'cancelled', remboursements auto déclenchés

**2. `auto_generate_bracket`** (cron 5min)
- Trouve les compétitions `status = 'closed'` ET pas encore de bracket
- Appelle l'algorithme de génération (Single Elim / Groupes+KO / Round Robin)
- Insère matches + bracket_nodes en transaction
- Status → 'ready_to_start'
- Notifications push à tous les inscrits

**3. `auto_start_competition`** (cron 1min)
- Trouve les compétitions `status = 'ready_to_start'` ET `starts_at <= now()`
- Status → 'active'
- Notifications "La compétition commence !"

**4. `auto_complete_competition`** (trigger SQL)
- Déclenché par le trigger `trg_on_final_match_finished`
- Statut → 'completed'
- Calcul gagnants + cagnotte
- Déclenche payouts auto

**Test 12.5.2** : créer une compétition test avec dates serrées, observer la progression auto.

---

**SOUS-PHASE 12.5.3 — Communication intelligente (1.5h)**

**Edge Function `send_match_reminders`** (cron 5min) :

Logique :
```typescript
// Pseudo-code
const now = new Date();
const matches = await supabase
  .from('matches')
  .select('*, players')
  .eq('status', 'pending')
  .gte('scheduled_at', now)
  .lte('scheduled_at', new Date(now.getTime() + 3600000)); // 1h max

for (const match of matches) {
  const minutesUntil = (match.scheduled_at - now) / 60000;
  
  // J-1 : 1440min avant
  if (minutesUntil > 1430 && minutesUntil < 1440) {
    await sendNotif(match.player1_id, 'match_reminder_24h', ...);
    await sendNotif(match.player2_id, 'match_reminder_24h', ...);
  }
  // H-1 : 60min avant
  else if (minutesUntil > 55 && minutesUntil < 60) {
    await sendNotif(match.player1_id, 'match_reminder_1h', ...);
    await sendNotif(match.player2_id, 'match_reminder_1h', ...);
  }
  // M-30 : 30min avant
  else if (minutesUntil > 25 && minutesUntil < 30) {
    await sendNotif(match.player1_id, 'match_reminder_30min', ...);
    await sendNotif(match.player2_id, 'match_reminder_30min', ...);
  }
  // M-5 : 5min avant
  else if (minutesUntil > 0 && minutesUntil < 5) {
    await sendNotif(match.player1_id, 'match_starting_soon', ...);
    await sendNotif(match.player2_id, 'match_starting_soon', ...);
  }
  
  // Logger dans auto_actions_log
}
```

**Smart features** :
- Throttling : max 1 notif/5min par joueur (table `notifications` + check)
- Multi-langue : utiliser `profile.language` pour i18n
- Pas de notif si joueur actif dans l'app dans les 5 dernières minutes

**Test 12.5.3** : créer un match dans 35 min, attendre, vérifier que la notif M-30 arrive.

---

**SOUS-PHASE 12.5.4 — Validation collaborative scores (1.5h)**

**Edge Function `submit_score_collaborative`** (HTTP) :

Endpoint : POST `/submit_score`
Body : `{ matchId, score1, score2, submittedBy }`

Logique :
```typescript
// Récupérer le match
const match = await getMatch(matchId);

// Vérifier autorisations
if (match.player1_id !== submittedBy && match.player2_id !== submittedBy) {
  return error('Not authorized');
}

// Stocker la soumission dans match_config.score_submissions
const submission = {
  by: submittedBy,
  score1: score1,
  score2: score2,
  at: new Date().toISOString()
};

await updateMatch(matchId, {
  match_config: {
    ...match.match_config,
    score_submissions: [
      ...(match.match_config.score_submissions || []),
      submission
    ]
  }
});

// Si les 2 ont soumis
const submissions = match.match_config.score_submissions;
if (submissions.length === 2) {
  const [s1, s2] = submissions;
  
  // Concordance ? (même score)
  if (s1.score1 === s2.score1 && s1.score2 === s2.score2) {
    // Validation auto !
    await validateMatch(matchId, s1.score1, s1.score2);
    await sendNotifs(match.player1_id, match.player2_id, 'score_validated_auto');
    return success({ status: 'validated', auto: true });
  } else {
    // Discordance → créer un litige
    await createDispute(matchId, s1, s2);
    await sendChatBotMessage(matchId, 'dispute_evidence_request');
    return success({ status: 'dispute_created' });
  }
}

return success({ status: 'awaiting_other_player' });
```

**Test 12.5.4** : 2 joueurs soumettent le même score → match validé auto. Soumettent des scores différents → litige créé.

---

**SOUS-PHASE 12.5.5 — Gestion auto litiges niveau 1-2 (2h)**

**Edge Function `process_dispute`** (cron 5min) :

Logique :
```typescript
// Récupérer les litiges 'open' avec evidence_deadline dépassée
const disputes = await getDisputesNeedingProcessing();

for (const dispute of disputes) {
  // Niveau 0 : Auto-résolution simple
  if (dispute.escalation_level === 0) {
    // Cas auto-résolvables
    if (oneSidedScoreSubmission(dispute)) {
      // Un seul a soumis, l'autre n'a pas répondu après 30 min
      await resolveDispute(dispute.id, 'player_who_submitted_wins');
      continue;
    }
    
    if (matchAbandoned(dispute)) {
      // Un joueur a abandonné en cours
      await resolveDispute(dispute.id, 'other_player_wins_forfeit');
      continue;
    }
    
    // Pas auto-résolvable → niveau 1
    await escalateToBotLevel(dispute.id);
  }
  
  // Niveau 1 : Bot dans le chat (envoyé automatiquement quand dispute créée)
  // Vérifier si évidence soumise
  if (dispute.escalation_level === 1) {
    if (bothEvidenceSubmitted(dispute)) {
      // Niveau 2 : Analyse des preuves
      await escalateToLevel2(dispute.id);
    } else if (deadline_passed) {
      // Pas de preuve dans 30 min → niveau 3 (admin)
      await escalateToAdmin(dispute.id);
    }
  }
  
  // Niveau 2 : Tentative résolution semi-auto
  if (dispute.escalation_level === 2) {
    const result = analyzeEvidence(dispute);
    
    if (result.confidence > 0.8) {
      // Résolution claire
      await resolveDispute(dispute.id, result.winner);
    } else {
      // Pas clair → admin
      await escalateToAdmin(dispute.id);
    }
  }
}
```

**Note V1.0** : sans IA, l'analyse des preuves est limitée :
- Vérification que les 2 preuves uploadées montrent le même score (basé sur métadonnées si possible)
- Sinon, escalade niveau 3 (admin)

**En V1.5+** : on ajoutera GPT-4 Vision pour analyser visuellement les screenshots.

**Bot dans le chat** :
- Quand un litige est créé, l'Edge Function poste automatiquement un message dans le canal Agora RTM avec un user_id spécial "ARENA_BOT"
- Le message inclut le numéro du litige et les instructions

**Test 12.5.5** : créer un litige, attendre 30 min, vérifier escalade auto.

---

**SOUS-PHASE 12.5.6 — Modération chat basique (1.5h)**

**Edge Function `moderate_chat_message`** (HTTP) :

Appelée **avant** chaque envoi de message dans le chat (ChatPage.dart).

Logique :
```typescript
// Récupérer le message + user_id
const { message, userId, channelId } = await req.json();

// 1. Vérifier mots interdits
const banned = await checkBannedWords(message);
if (banned.length > 0) {
  // Sanction selon severity
  const action = await applySanction(userId, banned[0].severity);
  
  // Logger
  await logModerationAction(userId, message, banned, action);
  
  return {
    allowed: false,
    reason: 'banned_word',
    action: action  // 'warning' | 'mute_5min' | 'mute_1h' | 'ban_24h'
  };
}

// 2. Vérifier patterns
const patterns = checkPatterns(message);
// - Numéros téléphone (regex \d{8,})
// - URLs externes (sauf whitelist)
// - Caps lock excessif
// - Spam (même message > 3 fois en 5min)

if (patterns.suspicious) {
  // Idem sanctions progressives
}

// 3. Vérifier mute en cours
const userStatus = await getUserModerationStatus(userId);
if (userStatus.muted_until > now()) {
  return { allowed: false, reason: 'muted', until: userStatus.muted_until };
}

// 4. OK, message autorisé
return { allowed: true };
```

**Côté Flutter** : avant `agora.sendChannelMessage()`, appeler `moderate_chat_message`. Si `allowed: false`, afficher un toast "Message bloqué : [raison]".

**Sanctions progressives** (table `profiles.moderation_status` jsonb) :
```json
{
  "warnings_count": 0,
  "muted_until": null,
  "ban_until": null,
  "violation_history": [...]
}
```

**Test 12.5.6** : envoyer un message contenant un mot interdit → bloqué + warning. Renvoyer 2 fois → mute 5 min.

---

**SOUS-PHASE 12.5.7 — Détection forfaits + Préparation paiements (manuel admin) (1.5h)**

> 🔴 **PAS D'AUTOMATISATION FINANCIÈRE** : cette sous-phase prépare les paiements mais NE les exécute PAS automatiquement. L'admin doit valider manuellement chaque payout via `AdminPayoutsPage` (PHASE 11.6).

**Edge Function `check_match_forfeits`** (cron 1min) :

Si un joueur ne se connecte pas dans les **15 min suivant le scheduled_at**, forfait automatique.

```typescript
const matches = await getMatchesNeedingForfeitCheck();
// matches.scheduled_at < (now - 15min) ET status = 'pending'

for (const match of matches) {
  const player1Active = wasActiveRecently(match.player1_id, '15min');
  const player2Active = wasActiveRecently(match.player2_id, '15min');
  
  if (!player1Active && !player2Active) {
    // Aucun n'est venu → match annulé
    await cancelMatch(match.id, 'both_no_show');
  } else if (!player1Active) {
    // Player1 absent → forfait, player2 gagne 3-0
    await applyForfeit(match.id, winner: match.player2_id);
  } else if (!player2Active) {
    await applyForfeit(match.id, winner: match.player1_id);
  }
}
```

**Edge Function `prepare_payouts_for_competition`** (trigger sur `competition.status = 'completed'`) :

> ⚠️ Cette fonction NE FAIT PAS le paiement. Elle prépare juste les entrées en attente de validation admin.

```typescript
// Quand une compétition passe en 'completed' :

// 1. Récupérer les top 4 du classement final (depuis bracket_nodes ou groups)
const top4 = await getTop4Finalists(competitionId);

// 2. Récupérer les prizes définis à la création
const prizes = await getPrizes(competitionId);

// 3. Pour chaque gagnant, calculer le montant final (selon mode)
const cagnotteFinale = await calculateFinalPrizePool(competitionId);
// cagnotteFinale = inscriptions × frais − commission + sponsoring

for (const [position, player] of top4.entries()) {
  const prize = prizes.find(p => p.position === position + 1);
  
  let amountUsd: number;
  if (prize.mode === 'percentage') {
    amountUsd = cagnotteFinale * prize.percentage_value / 100;
  } else { // mode = 'fixed'
    amountUsd = prize.amount_usd;
  }
  
  // 4. Créer une entrée payout en attente
  await supabase.from('payouts').insert({
    competition_id: competitionId,
    player_id: player.id,
    position: position + 1,
    amount_usd: amountUsd,
    status: 'pending_admin_validation',  // ⚠️ NÉCESSITE VALIDATION ADMIN
    auto_checks: {
      kyc_verified: player.kyc_verified,
      no_disputes: !await hasOpenDisputes(player.id),
      no_anti_cheat_anomalies: !await hasAntiCheatAnomalies(player.id, competitionId),
      not_banned: !player.is_banned,
      payment_data_complete: hasPaymentData(player)
    }
  });
}

// 5. Notification ADMIN (pas au joueur !)
await notifyAdmin('pending_payouts', {
  competition_id: competitionId,
  count: top4.length,
  total_amount: top4.reduce((sum, p) => sum + p.amount_usd, 0)
});
```

**Edge Function `execute_validated_payout`** (HTTP, appelée par admin) :

Cette fonction est appelée **uniquement** depuis `AdminPayoutsPage` après validation manuelle.

```typescript
// Body: { payoutId, adminId, justification }

// 1. Récupérer le payout
const payout = await getPayout(payoutId);
if (payout.status !== 'pending_admin_validation') {
  return error('Payout not in valid state');
}

// 2. Vérifier que l'admin a bien les permissions
const admin = await verifyAdmin(adminId);
if (!admin) return error('Unauthorized');

// 3. Logger dans audit
await logAuditAction({
  admin_id: adminId,
  action: 'payout_validated',
  entity_id: payoutId,
  justification: justification,
  ip: getClientIP(req),
  snapshot: payout
});

// 4. Exécuter le paiement réel via CinetPay ou NowPayments
const provider = payout.payment_method === 'momo' ? 'cinetpay' : 'nowpayments';
const result = await sendMoney({
  provider: provider,
  recipient: payout.player.payment_data,
  amount: payout.amount_usd,
  currency: payout.currency,
  reference: `PAYOUT-${payout.id}`
});

// 5. Update statut payout
await updatePayout(payoutId, {
  status: result.success ? 'completed' : 'failed',
  validated_by_admin_id: adminId,
  validated_at: new Date(),
  provider_transaction_id: result.transactionId
});

// 6. Notification au gagnant
if (result.success) {
  await sendNotif(payout.player_id, 'payout_received', {
    amount: payout.amount_usd,
    competition: payout.competition.name
  });
}

return { success: result.success };
```

**Edge Function `notify_admin_pending_payouts`** (cron 5min) :

Rappel à l'admin si des payouts sont en attente depuis plus d'1h. Évite l'oubli.

```typescript
// Trouver les payouts pending depuis > 1h
const stalePayouts = await getStalePayouts('1 hour');

if (stalePayouts.length > 0) {
  // Grouper par compétition
  const byComp = groupBy(stalePayouts, 'competition_id');
  
  for (const compId of Object.keys(byComp)) {
    const payouts = byComp[compId];
    
    await sendNotifToAdmins('payouts_pending_reminder', {
      competition_id: compId,
      count: payouts.length,
      total_amount: payouts.reduce((sum, p) => sum + p.amount_usd, 0),
      oldest_age: getOldestAge(payouts)
    });
  }
}
```

**Test 12.5.7** : 
1. Simuler un match forfait → vérifier l'application auto du forfait ✓
2. Terminer une compétition → vérifier que les 4 entrées payouts sont créées en `pending_admin_validation` ✓
3. Vérifier qu'AUCUN paiement n'a été envoyé (CinetPay sandbox vide) ✓
4. Aller sur `AdminPayoutsPage`, valider 1 payout manuellement → vérifier le paiement reçu ✓
5. Attendre 1h+ → vérifier le rappel admin ✓



---

#### ✅ Critères d'acceptation de la PHASE 12.5

- [ ] Les 12 Edge Functions sont déployées et fonctionnelles
- [ ] Les cron jobs pg_cron tournent correctement (visible dans Supabase Dashboard)
- [ ] Les triggers SQL réagissent aux changements de matches/competitions
- [ ] Une compétition test peut être créée et gérée **sans aucune intervention admin** (sauf litiges)
- [ ] Le `auto_actions_log` enregistre toutes les actions auto avec leur statut
- [ ] Le dashboard admin affiche les statistiques d'automatisation
- [ ] Les sanctions chat progressives fonctionnent (warning → mute → ban)
- [ ] Les notifications arrivent aux bons moments (J-1, H-1, M-30, M-5)

#### 📊 Métriques de succès

À mesurer après 1 mois en production :
- Pourcentage de matchs validés sans admin → cible : **>80%**
- Pourcentage de litiges résolus auto → cible : **>50%**
- Taux de notifications envoyées (vs prévues) → cible : **>95%**
- Charge admin par compétition → cible : **<30 min**

---

### **PHASE 13 — Polish + Tests automatisés + Lancement V1.0 (5-6h)** ⭐ **ENRICHIE**

> 🎯 **Objectif** : préparer l'app pour le lancement avec une qualité production.

#### ✨ SOUS-PHASE 13.1 — Polish UI (1-2h)
- Animations Hero entre écrans
- Loading states partout (shimmer effect)
- Empty states avec illustrations (Lottie ou SVG)
- Gestion d'erreurs réseau (retry button + offline banner)
- Animations de transition entre les phases du tournoi
- Sons et vibrations (optionnel) pour les événements importants

#### 🧪 SOUS-PHASE 13.2 — Tests automatisés (3-4h) ⭐ NOUVEAU

> 🛡️ **CRITIQUE** : sans tests, chaque modification risque de casser quelque chose. Pour un projet qui gère de l'argent, c'est inacceptable.

**Stack tests** :
- `flutter_test` (SDK Flutter) : tests unitaires + widgets
- `mocktail` ^1.0 : mocking des dépendances
- `integration_test` (SDK Flutter) : tests bout en bout

**Setup `test/` directory** :
```
test/
├── unit/                          # Tests unitaires
│   ├── auth/
│   │   ├── auth_repository_test.dart
│   │   └── password_validator_test.dart
│   ├── brackets/
│   │   ├── single_elim_generator_test.dart
│   │   ├── round_robin_generator_test.dart
│   │   └── groups_ko_generator_test.dart
│   ├── payments/
│   │   ├── currency_converter_test.dart
│   │   └── prize_calculator_test.dart
│   └── automation/
│       └── score_validation_test.dart
├── widget/                        # Tests widgets
│   ├── auth/
│   │   ├── login_page_test.dart
│   │   ├── register_page_test.dart
│   │   └── forgot_password_test.dart
│   ├── match_room/
│   │   └── match_room_page_test.dart
│   └── widgets_shared/
│       └── arena_button_test.dart
└── integration/                   # Tests E2E
    ├── auth_flow_test.dart        # Inscription → Login → Logout
    ├── join_competition_test.dart # Rejoindre compet → match → score
    └── payment_flow_test.dart     # Paiement → confirmation
```

**Tests UNITAIRES prioritaires** :

**1. Brackets generators** (critique pour la logique métier) :
```dart
// test/unit/brackets/single_elim_generator_test.dart
void main() {
  group('SingleEliminationGenerator', () {
    test('génère 7 matches pour 8 joueurs', () {
      final players = List.generate(8, (i) => Player(id: 'p$i', username: 'P$i'));
      final generator = SingleEliminationGenerator();
      final matches = generator.generate(players);
      
      expect(matches.length, equals(7)); // 4 + 2 + 1
      expect(matches.where((m) => m.round == 1).length, equals(4));
      expect(matches.where((m) => m.round == 2).length, equals(2));
      expect(matches.where((m) => m.round == 3).length, equals(1));
    });
    
    test('ajoute des byes pour nombres non puissance de 2', () {
      final players = List.generate(13, (i) => Player(id: 'p$i'));
      final matches = SingleEliminationGenerator().generate(players);
      
      // 13 joueurs → next pow2 = 16 → 3 byes
      expect(matches.where((m) => m.isBye).length, equals(3));
    });
    
    test('chaque next_match_id pointe correctement', () {
      final matches = SingleEliminationGenerator().generate(_8Players);
      
      for (final match in matches.where((m) => m.round != 3)) {
        expect(match.nextMatchId, isNotNull);
      }
      // La finale n'a pas de next_match_id
      expect(matches.firstWhere((m) => m.round == 3).nextMatchId, isNull);
    });
  });
}
```

**2. Calculateur de prix** (critique pour les paiements) :
```dart
// test/unit/payments/prize_calculator_test.dart
void main() {
  group('PrizeCalculator', () {
    test('calcule correctement les prix en mode pourcentage', () {
      final calc = PrizeCalculator();
      final prizes = [
        Prize(position: 1, mode: 'percentage', percentageValue: 50),
        Prize(position: 2, mode: 'percentage', percentageValue: 25),
        Prize(position: 3, mode: 'percentage', percentageValue: 15),
        Prize(position: 4, mode: 'percentage', percentageValue: 10),
      ];
      
      final result = calc.calculate(
        prizePool: 150000,
        sponsoring: 0,
        commission: 0,
        prizes: prizes,
      );
      
      expect(result[0].finalAmount, equals(75000));
      expect(result[1].finalAmount, equals(37500));
      expect(result[2].finalAmount, equals(22500));
      expect(result[3].finalAmount, equals(15000));
      expect(result.fold(0.0, (sum, p) => sum + p.finalAmount), equals(150000));
    });
    
    test('mode fixe ne dépasse pas la cagnotte', () {
      // Test que le système alerte si fixed prizes > pool
    });
  });
}
```

**Tests WIDGETS prioritaires** :

**1. Login page** :
```dart
// test/widget/auth/login_page_test.dart
void main() {
  testWidgets('LoginPage affiche tous les boutons sociaux', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: LoginUserScreen()),
    );
    
    expect(find.text('Continuer avec Google'), findsOneWidget);
    expect(find.text('Continuer avec Apple'), findsOneWidget);
    expect(find.text('Mot de passe oublié ?'), findsOneWidget);
  });
  
  testWidgets('LoginPage valide le format email', (tester) async {
    await tester.pumpWidget(MaterialApp(home: LoginUserScreen()));
    
    await tester.enterText(find.byKey(Key('email_field')), 'invalid-email');
    await tester.tap(find.text('SE CONNECTER'));
    await tester.pump();
    
    expect(find.text('Email invalide'), findsOneWidget);
  });
}
```

**Tests d'INTÉGRATION (E2E) prioritaires** :

**1. Flux d'inscription complet** :
```dart
// test/integration/auth_flow_test.dart
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  
  testWidgets('Inscription complète user', (tester) async {
    // Lance l'app
    await tester.pumpWidget(ArenaUserApp());
    await tester.pumpAndSettle();
    
    // Onboarding (4 écrans)
    for (int i = 0; i < 4; i++) {
      await tester.tap(find.text('SUIVANT →'));
      await tester.pumpAndSettle();
    }
    
    // Inscription
    await tester.tap(find.text('Rejoindre'));
    await tester.pumpAndSettle();
    
    // Step 1 — Compte
    await tester.enterText(find.byKey(Key('email_field')), 'test@arena.app');
    await tester.enterText(find.byKey(Key('password_field')), 'TestPass123!');
    await tester.tap(find.text('SUIVANT'));
    
    // Step 2 — Profil
    await tester.enterText(find.byKey(Key('username_field')), 'TestUser');
    await tester.tap(find.text('🇨🇲 Cameroun'));
    await tester.tap(find.byKey(Key('cgu_checkbox')));
    await tester.tap(find.byKey(Key('privacy_checkbox')));
    await tester.tap(find.text('CRÉER MON COMPTE'));
    
    await tester.pumpAndSettle();
    
    // Vérifier qu'on est sur HomePage
    expect(find.text('Bienvenue, TestUser'), findsOneWidget);
  });
}
```

**Couverture minimale V1.0** :
- ✅ Brackets generators (logique métier complexe)
- ✅ Prize calculator (gestion argent)
- ✅ Auth flow (login/signup/forgot password)
- ✅ Score validation (cas concorde + discordance)
- ✅ Currency conversion (multi-devises)
- ✅ Match Room (étapes critiques du flux)

**Coverage cible** : 60% sur le code métier critique (pas besoin 100%, perte de temps)

**Lancer les tests** :
```bash
# Tests unitaires + widgets
flutter test

# Tests intégration sur device
flutter test integration_test

# Coverage
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html  # Voir le rapport
```

#### 📦 SOUS-PHASE 13.3 — Build production (1h)

- Build release Android (`flutter build apk --release --flavor user`)
- Build release Android Bundle (`flutter build appbundle --release --flavor user`)
- Build release iOS (`flutter build ipa --release --flavor user`)
- Configurer les certificats de signing Android (keystore)
- Configurer les profils de provisioning iOS
- Tester les builds release sur appareils physiques (différent du debug)

#### 📋 SOUS-PHASE 13.4 — Documentation et lancement (30 min)

- README projet propre avec instructions de setup
- Captures d'écran pour les stores (8 par plateforme minimum)
- Description marketing (FR pour V1.0)
- Politique de confidentialité publiée (URL accessible)
- CGU publiées (URL accessible)
- Page "Status" si possible (status.arena-app.com via UptimeRobot, gratuit)

#### 🚀 LANCEMENT V1.0 :
- 13 pays Afrique francophone (Cameroun, Sénégal, Côte d'Ivoire, Gabon, Bénin, Togo, Burkina, Mali, Niger, Tchad, Guinée, RDC, Madagascar)
- Langue : FR uniquement
- Paiements : CinetPay (MoMo) + NowPayments (crypto)
- Apps : Play Store + App Store

À ce stade, l'app est complète et fonctionnelle pour la V1.0. Les phases 14 et 15 ci-dessous sont à réaliser **3-12 mois après le V1.0**, après avoir validé la traction sur le marché francophone.

---

### **PHASE 14 — Extension V1.1 (Afrique anglophone) (5-6h, optionnel/futur)**

> 🕐 **À faire 3-6 mois après V1.0**, quand tu as validé la traction et que tu veux étendre.

#### 🎯 Objectif

Activer Flutterwave + langue Anglais + 7 nouvelles devises (NGN, GHS, KES, ZAR, UGX, RWF, TZS).

#### 📋 Sous-phases

**SOUS-PHASE 14.1 — Création compte Flutterwave (30min)**

- Créer compte sur https://flutterwave.com
- Mode TEST d'abord
- Récupérer `PUBLIC_KEY`, `SECRET_KEY`, `ENCRYPTION_KEY`, `WEBHOOK_HASH`
- Configurer webhook : `https://[ton-projet].supabase.co/functions/v1/flutterwave-webhook`
- Ajouter dans Supabase Secrets

**SOUS-PHASE 14.2 — Edge Function `flutterwave-webhook` (1h)**

```typescript
serve(async (req) => {
  const body = await req.json();
  const signature = req.headers.get('verif-hash');
  // 1. Logger payload
  // 2. Valider hash avec FLUTTERWAVE_WEBHOOK_HASH
  // 3. Vérifier event type (charge.completed)
  // 4. RE-VÉRIFIER côté API serveur (anti-fraude Nigeria spécifique) :
  //    appeler https://api.flutterwave.com/v3/transactions/:id/verify
  //    Confirmer status='successful' ET amount=expected
  // 5. Update payment + créer registration
});
```

⚠️ **Spécificité Flutterwave Nigeria** : pour les paiements en NGN, prévoir `verify_transaction` côté serveur pour confirmer le montant. Flutterwave a connu des fraudes par manipulation côté client. Ne JAMAIS faire confiance au statut envoyé par le client.

**SOUS-PHASE 14.3 — Écran `FlutterwavePaymentScreen` (1.5h)**

```dart
import 'package:flutterwave_standard/flutterwave.dart';

Future<void> _handleFlutterwavePayment() async {
  final response = await supabase.functions.invoke('create-payment', body: {
    'competitionId': competitionId,
    'method': 'flutterwave',
    'currency': user.preferredCurrency,
  });
  final txRef = response.data['transactionRef'];
  final amount = response.data['amountLocal'];

  final flutterwave = Flutterwave(
    context: context,
    publicKey: dotenv.env['FLUTTERWAVE_PUBLIC_KEY']!,
    currency: user.preferredCurrency,
    amount: amount.toString(),
    txRef: txRef,
    customer: Customer(
      name: user.username,
      email: user.email,
      phoneNumber: user.phoneNumber,
    ),
    paymentOptions: _getPaymentOptionsForCountry(user.countryCode),
    customization: Customization(
      title: 'ARENA',
      description: 'Inscription compétition',
      logo: 'https://[ton-domaine]/arena-logo.png',
    ),
    isTestMode: true,
  );

  final response = await flutterwave.charge();
  if (response.success == true) {
    // Naviguer vers PaymentProcessingScreen (poll webhook)
  }
}

String _getPaymentOptionsForCountry(String country) {
  switch (country) {
    case 'NG':  return 'card,banktransfer,ussd';
    case 'KE':  return 'card,mpesa';
    case 'GH':  return 'card,mobilemoneyghana';
    case 'ZA':  return 'card';
    case 'UG':  return 'card,mobilemoneyuganda';
    case 'RW':  return 'card,mobilemoneyrwanda';
    case 'TZ':  return 'card,mobilemoneytanzania';
    default:    return 'card';
  }
}
```

**SOUS-PHASE 14.4 — Spécificités M-Pesa Kenya (45min)**

Le marché kényan est dominé par M-Pesa avec ses spécificités :
- STK Push : le joueur **confirme sur son téléphone** (popup Safaricom)
- Délai d'expiration : 2 minutes (court !)
- Numéro format `254XXXXXXXXX`
- Polling status toutes les 5s

**UI dédiée M-Pesa** :
- Input "Numéro M-Pesa" auto-formaté
- Bouton "ENVOYER LA REQUÊTE M-PESA"
- Modal d'attente : "📱 Vérifie ton téléphone et entre ton PIN M-Pesa"
- Countdown 2 minutes

**SOUS-PHASE 14.5 — Traduction stricte EN + activation feature flags (1h)**

1. Remplir intégralement `app_en.arb` (relire et traduire toutes les strings du V1.0)
2. Idéalement : faire relire par un anglophone natif
3. Activer dans Supabase :
   ```sql
   update app_config set value='true'::jsonb where key='lang_en_enabled';
   update app_config set value='true'::jsonb where key='provider_flutterwave_enabled';
   update app_config set value='["CM","GA","CG","TD","CF","GQ","CI","SN","BJ","TG","BF","ML","NE","MG","KM","DJ","NG","GH","KE","ZA","UG","RW","ZM","TZ"]'::jsonb where key='allowed_countries_v1';
   update app_config set value='["XAF","XOF","NGN","GHS","KES","ZAR","UGX","RWF","TZS","USD"]'::jsonb where key='active_currencies_v1';
   ```
4. L'app détecte instantanément les changements via realtime

**SOUS-PHASE 14.6 — Lancement Pilot V1.1 (1h)**

- Tester avec une cohorte de joueurs sur un seul pays anglophone (ex: Nigeria) avant d'ouvrir aux autres
- Monitorer payments + erreurs Flutterwave en sandbox/prod
- Ajuster avant ouverture totale

**Test 14.x** : un joueur nigerian test paye via USSD Flutterwave → registration créée. Un joueur kenyan test paye via M-Pesa → STK Push reçu, validation OK.

---

### **PHASE 15 — Extension V1.2 (Maghreb) (6-8h, optionnel/futur)**

> 🕐 **À faire 6-12 mois après V1.0**, quand tu veux conquérir le Maghreb (énorme marché : 100M+ utilisateurs).

#### 🎯 Objectif

Activer Arabe (RTL) + 4 nouvelles devises (MAD, DZD, TND, EGP) + 4 providers locaux.

#### ⚠️ Complexité accrue

Le Maghreb est **plus difficile** que les autres extensions :
- Aucun provider mondial ne couvre vraiment bien
- Nécessite un compte marchand par pays (parfois entité juridique locale requise)
- Documentation API souvent en arabe + français
- Réglementation jeux d'argent stricte (Maroc, Algérie : prohibition possible)
- Charia : adapter le wording (frais service ≠ mise)

#### 📋 Sous-phases

**SOUS-PHASE 15.1 — Création comptes providers (2h)**

| Pays | Provider recommandé | URL | Notes |
|---|---|---|---|
| 🇲🇦 Maroc | **CMI** (Centre Monétique Interbancaire) | https://www.cmi.co.ma | Obligatoire pour merchants marocains. Alternative : PayTabs, YouCan Pay |
| 🇩🇿 Algérie | **SATIM** | https://www.satim.dz | API limitée, considérer CIB Pay aussi |
| 🇹🇳 Tunisie | **Paymee** | https://www.paymee.tn | Le plus simple à intégrer. Alternative : Konnect, Clictopay |
| 🇪🇬 Égypte | **Paymob** | https://paymob.com | Le plus moderne. Couvre cards + Fawry + wallets |

**Action critique** : se renseigner pays par pays sur la **régulation jeux d'argent** AVANT d'ouvrir l'inscription payante. Au Maroc, les tournois esport peuvent nécessiter une autorisation spécifique du Ministère de l'Intérieur.

**SOUS-PHASE 15.2 — Edge Functions par provider (2h)**

Une Edge Function par provider Maghreb :
- `cmi-webhook` (Maroc)
- `satim-webhook` (Algérie)
- `paymee-webhook` (Tunisie)
- `paymob-webhook` (Égypte)

Chacune avec sa logique de validation HMAC propre.

**SOUS-PHASE 15.3 — Écrans paiement Maghreb (1.5h)**

CMI et SATIM utilisent des **WebViews** (pas de SDK Flutter natif). Paymee et Paymob ont des SDKs disponibles.

**SOUS-PHASE 15.4 — Traduction AR complète + validation RTL (2h)**

1. Remplir `app_ar.arb` intégralement
2. **Faire valider par un arabophone natif** (les nuances dialecte vs MSA importent)
3. Tester chaque écran en RTL
4. Vérifier que les polices Cairo/Tajawal s'affichent correctement
5. Corriger les bugs RTL spécifiques (widgets custom)

**SOUS-PHASE 15.5 — Activation feature flags V1.2 (30min)**

```sql
update app_config set value='true'::jsonb where key='lang_ar_enabled';
update app_config set value='true'::jsonb where key='provider_cmi_enabled';
update app_config set value='true'::jsonb where key='provider_satim_enabled';
update app_config set value='true'::jsonb where key='provider_paymee_enabled';
update app_config set value='true'::jsonb where key='provider_paymob_enabled';
-- Ajouter MA, DZ, TN, EG à allowed_countries
-- Ajouter MAD, DZD, TND, EGP à active_currencies
```

**Test 15.x** : tester l'app en arabe complet, faire un paiement test depuis chacun des 4 pays Maghreb.

---

## ⚖️ CONFORMITÉ LÉGALE — À PRÉPARER AVANT LE LANCEMENT

> 🚨 **CRITIQUE** : ces documents sont **OBLIGATOIRES** pour Apple App Store et Google Play Store. Sans eux, ton app sera **rejetée**. À préparer en parallèle du dev (pas dans Cursor, mais essentiel).

### 📋 Documents légaux requis

#### 1. Conditions Générales d'Utilisation (CGU)

**Quoi** : contrat entre toi (ARENA) et l'utilisateur. Définit les règles d'usage, les droits/obligations, les sanctions possibles.

**Sections obligatoires** :
- Présentation de l'éditeur (toi, identité légale, RCCM Cameroun)
- Description du service ARENA
- Inscription et compte utilisateur (conditions d'âge : 13+)
- Règles de comportement (anti-triche, anti-harassement)
- Sanctions (warnings, mute, ban)
- Paiements et gains (frais d'inscription, payouts, fiscalité)
- Propriété intellectuelle (Konami, EA Sports — marques tierces)
- Limitation de responsabilité
- Droit applicable (droit camerounais OHADA)
- Tribunaux compétents (Cameroun)

**Outils recommandés** :
- **Termly** (https://termly.io) : 11 $/mois, génère CGU adaptées
- **iubenda** (https://iubenda.com) : 27 $/mois, plus complet, multilingue
- **Avocat camerounais** : 200 000 - 500 000 XAF (le plus sûr)

#### 2. Politique de Confidentialité (Privacy Policy)

**Quoi** : explique comment tu collectes, stockes, utilises, et partages les données utilisateur.

**Sections obligatoires** :
- Identité du responsable de traitement (toi)
- Données collectées (email, username, pays, paiements, etc.)
- Finalités (organiser les tournois, traiter les paiements, etc.)
- Base légale (consentement, contrat, intérêt légitime)
- Tiers (Supabase, Agora, CinetPay, Firebase, Sentry)
- Durée de conservation
- Droits utilisateur (accès, rectification, suppression, portabilité)
- Cookies/Tracking
- Transferts internationaux (Supabase = USA)
- Contact DPO (si applicable)

**RGPD** : si tu vises l'Europe en V2, tu dois être conforme RGPD. Les utilisateurs africains ne sont pas couverts mais autant respecter les standards.

**Loi camerounaise** : loi n° 2010-012 sur la cybersécurité et cybercriminalité.

#### 3. Mentions légales

**Obligatoires au Cameroun pour le e-commerce** (loi 2010/021 sur le commerce électronique) :
- Nom de l'éditeur (personne physique ou morale)
- Adresse complète
- Numéro de téléphone et email
- RCCM (Registre de Commerce)
- Numéro de TVA si assujetti
- Hébergeur (Supabase Inc., Delaware, USA)

#### 4. Code de conduite communautaire

**Recommandé** (pas obligatoire mais bonne pratique) :
- Comportements attendus (fair-play, respect, anti-triche)
- Comportements interdits (insultes, harassment, spam, multi-comptes)
- Sanctions progressives
- Procédure d'appel

### 🔧 Implémentation technique

**Page d'inscription** : 2 cases à cocher obligatoires (CGU + Privacy) + 1 optionnelle (marketing).

**Stockage** :
- `profiles.cgu_accepted_at` + `cgu_version_accepted` (ex: 'v1.0')
- `profiles.privacy_policy_accepted_at`
- `profiles.marketing_consent`

**Re-acceptation** : si tu modifies les CGU, force tous les users à les re-accepter au prochain login.

**Pages dans l'app** :
- Section Settings → "📜 CGU" (WebView vers ton site)
- Section Settings → "🔐 Politique de confidentialité"
- Section Settings → "ℹ️ Mentions légales"
- Page "À propos" avec ces 3 liens

### 🚨 Attention spécifique : ARENA est-il un "jeu d'argent" ?

**Question juridique critique** : ton service tombe-t-il sous la **réglementation des jeux d'argent et de hasard** ?

**Au Cameroun** :
- Ordonnance n° 90/006 sur les loteries
- Décret n° 90/1359 réglementant les jeux de hasard
- **Si ton service est qualifié "jeu de hasard"** → licence obligatoire MINFI

**Argument pro-ARENA (pas un jeu de hasard)** :
- ✅ **Tournois de skill** : le résultat dépend de la compétence du joueur, pas du hasard
- ✅ **Le joueur paye pour participer**, pas pour parier
- ✅ **Modèle similaire** aux tournois de tennis ou échecs payants
- ⚠️ **Mais** : nuancé selon les juridictions

**Recommandations** :
1. **Consulter un avocat camerounais spécialisé** (essentiel)
2. **Déclarer comme "plateforme de tournois e-sport"** (pas "paris en ligne")
3. **Frais d'inscription = participation**, pas mise
4. **Gains = prix de compétition**, pas gains de pari
5. **Pas de "cote", "odds"**, ou autre vocabulaire de pari sportif
6. **Limitation des jeux** aux jeux vidéo de skill (pas roulette, etc.)

**Si en doute** : commencer en compétitions **gratuites** uniquement (V1.0 sans paiement) pour valider le concept avant d'introduire des frais d'inscription.

### 💰 Fiscalité et obligations comptables

**Taxes à anticiper** :
- **TVA** au Cameroun : 19,25% (si CA > 50M XAF/an)
- **Impôt sur le revenu** : selon ton statut (auto-entrepreneur, SARL, etc.)
- **Retenues sur les gains des joueurs** : pas obligatoire en dessous d'un seuil

**Bonnes pratiques** :
- Gardez la trace de **tous les paiements** entrants/sortants
- Conserver les **reçus CinetPay/NowPayments**
- Avoir un **comptable** dès le 6e mois (200 000 XAF/an minimum)
- Ouvrir un **compte bancaire pro** (pas perso pour les flux ARENA)

---

## 🛡️ RÈGLES DE SÉCURITÉ NON-NÉGOCIABLES

1. **Aucune clé API en dur dans le code** → toujours via `.env` (utilise `flutter_dotenv`)
2. **RLS Supabase activé sur toutes les tables**
3. **Validation côté serveur** (RLS policies) ET côté client
4. **Tokens Agora générés côté serveur** via Edge Function (jamais le certificate côté client)
5. **OTP 2FA obligatoire** pour admin/super-admin (via Supabase Auth `verifyOtp`)
6. **Logs sensibles désactivés en release** (utilise `kDebugMode`)
7. **Permissions runtime demandées au moment opportun**, pas au lancement
8. **PAIEMENTS — règles strictes** :
   - JAMAIS de clé API provider (CinetPay, NowPayments) dans Flutter → uniquement dans Edge Functions Supabase
   - JAMAIS de numéro de carte saisi dans Flutter → toujours WebView vers page hébergée du provider
   - TOUJOURS valider la signature HMAC/IPN des webhooks avant action
   - TOUJOURS être idempotent (un webhook peut arriver 2 fois, ne pas créditer 2 fois)
   - TOUJOURS logger le payload brut dans `payment_webhook_log` AVANT de le traiter (audit)
   - Le statut payment côté Flutter ne fait JAMAIS foi → seul le webhook serveur valide
   - Les payouts doivent être validés manuellement par un super-admin en V1
9. **AUTHENTIFICATION ADMIN — règles strictes** :
   - TOTP obligatoire pour tous les admins, pas de bypass possible
   - Inscription admin uniquement avec code d'invitation valide et non expiré
   - Codes d'invitation à usage unique, expiration max 30 jours
   - Anti-replay TOTP (refuser un code déjà utilisé dans les 30 dernières secondes)
   - 3 échecs login = blocage du compte 30 min
   - Session admin expire après 30 min d'inactivité (vs 7 jours pour user)
   - Re-vérification TOTP pour actions sensibles (suspension, payout approval, modification feature flags)
   - JAMAIS d'écran admin accessible depuis l'app User (filtre côté serveur ET client)
   - Toutes les actions admin tracées dans `admin_audit_log`
10. **SÉPARATION DES APPS** :
    - L'app User refuse les sessions de comptes `role IN ('admin', 'super_admin')`
    - L'app Admin refuse les sessions de comptes `role = 'player'`
    - Les RLS policies Supabase respectent strictement les rôles
    - Le code dans `features_user/` n'importe JAMAIS depuis `features_admin/` et vice-versa

---

## 📋 CHECKLIST DE QUALITÉ (à chaque phase)

Avant de dire "phase X terminée", Claude doit vérifier :

- [ ] Le code compile sans warning
- [ ] `flutter analyze` retourne 0 issue
- [ ] Les noms de fichiers/classes suivent les conventions Dart (snake_case fichiers, PascalCase classes)
- [ ] Aucune logique métier dans les widgets
- [ ] Tous les `async` ont un try/catch
- [ ] Les `BuildContext` ne traversent pas d'`async gap` sans `mounted` check
- [ ] Les listes utilisent `ListView.builder` (pas `Column` + `for`)
- [ ] Pas de `print()` → utiliser `debugPrint` ou un logger
- [ ] Tous les strings UI sont en français
- [ ] Le code touchant Supabase a un fallback en cas d'erreur réseau

---

## 💬 COMMENT INTERAGIR AVEC L'UTILISATEUR

L'utilisateur est **débutant Flutter** mais pas débutant en informatique. Donc :

✅ **Faire** :
- Expliquer les concepts Flutter nouveaux (Widget, BuildContext, State, Provider) la première fois qu'ils apparaissent
- Donner les commandes exactes à taper (`flutter pub add ...`, `flutter run`)
- Anticiper les erreurs fréquentes ("Si tu vois `MissingPluginException`, fais `flutter clean && flutter pub get`")
- Faire des pauses régulières pour valider la compréhension
- Suggérer des points de commit Git après chaque phase ("`git commit -m 'phase 2: auth complete'`")

❌ **Ne pas faire** :
- Balancer 15 fichiers d'un coup sans explication
- Utiliser du jargon non expliqué (BLoC, Repository pattern, DI, etc.)
- Sauter directement à du code complexe (extension methods, generics avancés) au début
- Modifier silencieusement des fichiers déjà créés sans le dire

---

## 🎬 DÉMARRAGE

Quand l'utilisateur dit "**Lis ARENA_PROMPT.md et commence par la PHASE 0**" :

1. Tu confirmes que tu as lu le doc en résumant en 5 lignes le projet
2. Tu listes les **prérequis utilisateur** pour la phase 0 (Flutter installé, comptes Supabase/Firebase/Agora créés)
3. Tu attends "go" avant de créer le moindre fichier
4. Tu avances étape par étape dans la phase 0 en demandant validation à chaque étape

---

**Bon courage. ARENA va être 🔥.**
