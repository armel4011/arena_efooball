# 🤖 ARENA — Prompt MASTER pour Claude Code

> **Copier-coller ce prompt entier dans Claude Code** pour qu'il intègre automatiquement les icônes et le splash screen dans le projet ARENA.

---

## 📋 Prompt à copier-coller

```
Claude, tu vas intégrer le BRANDING PACK ARENA dans le projet Flutter.
On a 2 livrables : icônes (Vector Strike F2) + splash screen (Cinématique D).

═══════════════════════════════════════════════════════════════════════
🎯 OBJECTIF
═══════════════════════════════════════════════════════════════════════

Intégrer dans le projet ARENA :
1. Icônes USER (bleu) et ADMIN (rouge) pour iOS, Android, Adaptive Icons
2. Splash screen animé cinématique 5.3 secondes (5 phases)
3. Détection automatique du 1er lancement (splash long vs court)
4. Compatible flavors USER + ADMIN

═══════════════════════════════════════════════════════════════════════
📦 SOURCES DISPONIBLES (déjà fournies)
═══════════════════════════════════════════════════════════════════════

Le pack arena_branding_pack/ contient :

flutter_project/                       ← À COPIER directement dans le projet
├── assets/
│   ├── icons/
│   │   ├── arena_user_1024.png        Icône USER 1024×1024 avec texte
│   │   ├── arena_admin_1024.png       Icône ADMIN 1024×1024 avec texte
│   │   ├── arena_user_compact_1024.png   Sans texte (pour splash + petites tailles)
│   │   ├── arena_admin_compact_1024.png
│   │   └── adaptive/
│   │       ├── user/
│   │       │   ├── ic_launcher_background.png
│   │       │   ├── ic_launcher_foreground.png
│   │       │   └── ic_launcher_monochrome.png
│   │       └── admin/   (idem)
│   └── splash/
│       ├── splash_user.png            Plein écran USER (dégradé + logo)
│       ├── splash_admin.png           Plein écran ADMIN
│       ├── splash_icon_user.png       Logo transparent (Android 12+)
│       └── splash_icon_admin.png
└── lib/
    └── features/
        └── splash/
            ├── splash_screen.dart     Widget animé 5 phases
            └── splash_router.dart     Wrapper Riverpod + 1er lancement

═══════════════════════════════════════════════════════════════════════
🎨 IDENTITÉ VISUELLE (tokens DESIGN_KIT à respecter)
═══════════════════════════════════════════════════════════════════════

Couleurs :
  --signal-blue : #4C7AFF  (USER primary)
  --neon-red    : #FF2D55  (ADMIN + LIVE indicators)
  --void        : #0A0A0F  (Fond principal)
  --carbon      : #14141C  (Surface dark)
  --bone        : #F5F5F0  (Texte principal)

Polices (Google Fonts) :
  - Bebas Neue       : Headers, texte ARENA/ADMIN
  - Instrument Serif : Tagline italique
  - Space Grotesk    : Body
  - JetBrains Mono   : Codes, IDs

Tagline : "SEUL LE TALENT EST RÉCOMPENSÉ..."

═══════════════════════════════════════════════════════════════════════
🚀 ACTIONS À EXÉCUTER (dans l'ordre)
═══════════════════════════════════════════════════════════════════════

ÉTAPE 1 — SAUVEGARDER L'ÉTAT ACTUEL
1.1. Git status
1.2. Si modifications non commitées, propose un commit "WIP avant branding"
1.3. Créer un tag de sécurité : git tag pre-branding-pack
1.4. Créer une branche : git checkout -b feature/branding-pack

ÉTAPE 2 — STRUCTURE DOSSIERS
2.1. Vérifier que assets/ existe à la racine du projet
2.2. Créer (si manquant) :
     - assets/icons/
     - assets/icons/adaptive/user/
     - assets/icons/adaptive/admin/
     - assets/splash/
     - lib/features/splash/

ÉTAPE 3 — COPIE DES ASSETS
3.1. Copier depuis arena_branding_pack/flutter_project/ vers le projet :
     - Tous les fichiers de assets/icons/ → assets/icons/ du projet
     - Tous les fichiers de assets/splash/ → assets/splash/ du projet
     - splash_screen.dart → lib/features/splash/
     - splash_router.dart → lib/features/splash/
3.2. Vérifier que tous les fichiers sont bien à leur place (ls -la)

ÉTAPE 4 — MISE À JOUR pubspec.yaml
4.1. Lire le pubspec.yaml actuel
4.2. Ajouter dans dependencies (si pas déjà présent) :
     - flutter_riverpod: ^2.4.10
     - shared_preferences: ^2.2.2
     - google_fonts: ^6.2.1
4.3. Ajouter dans dev_dependencies :
     - flutter_launcher_icons: ^0.13.1
     - flutter_native_splash: ^2.4.1
4.4. Ajouter au niveau racine la section flutter_launcher_icons :
     (config USER par défaut, image_path = assets/icons/arena_user_1024.png)
4.5. Ajouter au niveau racine la section flutter_native_splash :
     (config USER par défaut, image = assets/splash/splash_user.png)
4.6. Ajouter dans flutter.assets :
     - assets/icons/
     - assets/icons/adaptive/user/
     - assets/icons/adaptive/admin/
     - assets/splash/
4.7. Voir docs/pubspec_config.yaml pour les valeurs exactes

ÉTAPE 5 — CRÉATION DES FICHIERS ADMIN
5.1. Créer à la racine flutter_launcher_icons-admin.yaml
     (config ADMIN, image_path = assets/icons/arena_admin_1024.png)
5.2. Créer à la racine flutter_native_splash-admin.yaml
     (config ADMIN, image = assets/splash/splash_admin.png, color #FF2D55)

ÉTAPE 6 — GÉNÉRATION DES ICÔNES & SPLASH
6.1. flutter pub get
6.2. flutter pub run flutter_launcher_icons
6.3. flutter pub run flutter_launcher_icons -f flutter_launcher_icons-admin.yaml
6.4. flutter pub run flutter_native_splash:create
6.5. flutter pub run flutter_native_splash:create --path=flutter_native_splash-admin.yaml
6.6. Vérifier la génération :
     - android/app/src/main/res/mipmap-*/ic_launcher.png (5 densités)
     - android/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml
     - ios/Runner/Assets.xcassets/AppIcon.appiconset/ (13 fichiers)

ÉTAPE 7 — CÂBLAGE DANS main.dart
7.1. Lire le main.dart actuel
7.2. Ajouter en haut :
     import 'package:flutter/services.dart';
     import 'package:flutter_native_splash/flutter_native_splash.dart';
     import 'features/splash/splash_router.dart';
7.3. Dans la fonction main() :
     - Capturer widgetsBinding
     - Appeler FlutterNativeSplash.preserve(widgetsBinding)
     - Forcer orientation portrait
     - APRÈS toutes les initialisations (Supabase, etc.), runApp(...)
     - À la fin : FlutterNativeSplash.remove()
7.4. Dans le widget principal (MaterialApp) :
     - home: const SplashPage(isAdmin: false, nextRoute: '/login')
     - Adapter nextRoute selon le routing existant (GoRouter, etc.)

ÉTAPE 8 — VÉRIFICATION
8.1. flutter analyze (0 warnings)
8.2. flutter clean
8.3. flutter pub get
8.4. flutter build apk --debug (vérifier compilation Android)
8.5. flutter build ios --no-codesign (vérifier compilation iOS)

ÉTAPE 9 — TESTS MANUELS (instructions pour le dev)
9.1. flutter run --flavor user (ou flutter run si pas de flavors)
9.2. Vérifier visuellement :
     ☐ Icône bleue ARENA sur l'écran d'accueil
     ☐ Splash : fond bleu → spark → logo → texte ARENA + tagline → 3 jeux
     ☐ Navigation vers LoginPage après ~5.3s au 1er lancement
     ☐ Au 2e lancement : splash plus court (~1.5s)
9.3. Idem pour le flavor admin :
     ☐ Icône rouge ADMIN
     ☐ Splash rouge avec chevrons bleus inversés
     ☐ Texte "ADMIN" + tagline "CONSOLE DE GESTION ARENA"

ÉTAPE 10 — DOCUMENTATION
10.1. Mettre à jour docs/SETUP.md (ou créer si absent) avec :
      - Section "Identité visuelle"
      - Comment changer la tagline
      - Comment régénérer les icônes après modifications
      - Commandes utiles
10.2. git add . && git commit -m "feat(branding): icônes Vector Strike F2 + splash cinématique D"
10.3. NE PAS pusher avant validation manuelle sur device

═══════════════════════════════════════════════════════════════════════
⚠️ RÈGLES IMPORTANTES
═══════════════════════════════════════════════════════════════════════

DO :
  ✅ Lire chaque fichier avant de le modifier (pubspec.yaml, main.dart)
  ✅ Préserver tous les imports et configs existants
  ✅ Tester la compilation avant de passer à la suite
  ✅ Demander confirmation avant les actions destructives (git reset, rm -rf)
  ✅ Préserver les flavors USER/ADMIN existants
  ✅ Respecter les tokens DESIGN_KIT (pas inventer des couleurs)

DON'T :
  ❌ NE PAS remplacer le pubspec.yaml entier — ajouter seulement les sections
  ❌ NE PAS écraser le main.dart — adapter les sections nécessaires
  ❌ NE PAS supprimer les anciennes icônes/splash sans demander
  ❌ NE PAS pusher en main sans validation
  ❌ NE PAS modifier les SVG ou PNG sources (raw_sources/)
  ❌ NE PAS introduire de dépendances non listées dans pubspec_config.yaml

═══════════════════════════════════════════════════════════════════════
📊 PROTOCOLE
═══════════════════════════════════════════════════════════════════════

1. Lance l'ÉTAPE 1 immédiatement (sauvegarde git)
2. Rapporte-moi l'état actuel du projet (présence/absence des dossiers, 
   version Flutter, contenu pubspec, etc.)
3. Donne-moi ton plan d'exécution pour les étapes 2-10
4. Attends mon "GO" explicite avant de lancer les étapes 2+
5. Exécute les étapes en séquence sans interruption (sauf erreur bloquante)
6. À la fin, rapport synthétique :
   - Fichiers modifiés
   - Commandes exécutées
   - Tests à faire manuellement
   - Problèmes rencontrés (s'il y en a)

═══════════════════════════════════════════════════════════════════════
🎯 RÉSULTAT ATTENDU
═══════════════════════════════════════════════════════════════════════

À la fin, je devrais pouvoir :
✓ flutter run → voir le splash cinématique de 5.3s puis LoginPage
✓ Voir l'icône bleue ARENA sur mon écran d'accueil
✓ Switcher flavor admin → voir icône rouge ADMIN et splash rouge
✓ Au 2e lancement → splash court 1.5s (pas la version complète)
✓ Sur App Store Connect, l'icône 1024 acceptée sans warning alpha
✓ Sur Android 13, l'icône s'adapte au thème dynamique du système

GO pour ÉTAPE 1.
```

---

## 💡 Astuces pour utiliser ce prompt avec Claude Code

### 1. Lance Claude Code avec Opus

```bash
claude --model opus
```

L'intégration touche au pubspec et au main.dart : il faut un modèle robuste pour éviter les erreurs.

### 2. Pré-place le pack dans le projet

Avant de coller le prompt :

```bash
# À la racine de ton projet ARENA
cp -r ~/Downloads/arena_branding_pack ./
```

Claude Code aura accès aux fichiers `arena_branding_pack/flutter_project/`.

### 3. Vérifie le rapport après chaque étape

Le prompt demande à Claude Code de **te rapporter** après chaque étape critique. Ne le laisse pas enchaîner les 10 étapes en aveugle — valide au moins après les étapes 4 (pubspec), 6 (génération), 7 (main.dart).

### 4. Si une étape échoue

Réponds simplement :
> "L'étape X a échoué avec l'erreur suivante : [coller l'erreur]. Corrige et relance."

Claude Code analysera et proposera une correction.

### 5. Compaction de session

Si tu enchaînes avec d'autres prompts après le branding (Phase 10, écrans, etc.), pense à faire `/compact` entre chaque grosse étape pour libérer du contexte.

---

## 🔄 Variante : prompt étape par étape

Si tu préfères contrôler chaque étape **manuellement** au lieu d'un prompt unique, voici le mode "step by step" :

```
Prompt étape 1 :
"Claude, sauvegarde l'état du projet ARENA : git status, commit WIP si nécessaire, 
tag pre-branding-pack, branche feature/branding-pack. Rapporte-moi avant de continuer."

Prompt étape 2 :
"OK. Maintenant copie les fichiers de arena_branding_pack/flutter_project/ vers les bons 
dossiers du projet. Crée les dossiers manquants si besoin."

Prompt étape 3 :
"Mets à jour pubspec.yaml avec les sections de docs/pubspec_config.yaml. 
Lis-le d'abord, puis ajoute uniquement les sections manquantes."

... etc
```

Plus de contrôle mais plus lent. À toi de voir.

---

## 📝 Adaptations selon ton routing

Le prompt suppose que tu utilises **Navigator 1.0** standard avec `home:` dans `MaterialApp`. Si tu utilises autre chose, adapte la phrase "nextRoute = '/login'" :

| Routing | Adaptation |
|---|---|
| **Navigator 1.0** (par défaut) | `Navigator.of(context).pushReplacementNamed('/login')` |
| **GoRouter** | `context.go('/login')` (à modifier dans splash_router.dart) |
| **Auto Route** | `context.replaceRoute(LoginRoute())` |
| **Beamer** | `context.beamToReplacementNamed('/login')` |

Dans `splash_router.dart` ligne ~75, modifie la fonction `_navigate()` selon ton choix.

---

## 🚦 Quand tu auras lancé Claude Code

Reviens me dire :

- ✅ "Ça marche, tout est intégré" → on enchaîne sur Phase 10 ou autre
- ⚠️ "J'ai cette erreur : [erreur]" → on debug ensemble  
- ❓ "Tel point n'est pas clair : [...]" → je clarifie

Bonne chance ! 🚀
