# 🎨 ARENA — Branding Pack Complet
> **Icônes + Splash Screen** — Tout-en-un pour ton projet Flutter ARENA  
> Version 2.0 (mai 2026) — Vector Strike F2 + Splash Cinématique D

---

## 📋 Table des matières

1. [Vue d'ensemble](#vue-densemble)
2. [Structure du pack](#structure-du-pack)
3. [Identité visuelle](#identité-visuelle)
4. [Installation rapide (15 min)](#installation-rapide)
5. [Installation détaillée](#installation-détaillée)
6. [Personnalisation](#personnalisation)
7. [Dépannage](#dépannage)
8. [Spécifications techniques](#spécifications-techniques)

---

## 🎯 Vue d'ensemble

Ce pack contient **tout le branding visuel d'ARENA** :

| Élément | USER (bleu) | ADMIN (rouge) |
|---|---|---|
| **Icône d'app** | Dégradé bleu + chevrons blanc/rouge + ARENA | Dégradé rouge + chevrons blanc/bleu + ADMIN |
| **Splash natif** | Image plein écran avec logo | Idem rouge |
| **Splash animé** | 5 phases cinématiques 5.3s | Idem rouge |
| **Adaptive icon** | Foreground + Background séparés | Idem |
| **Tagline** | *"SEUL LE TALENT EST RÉCOMPENSÉ..."* | *"CONSOLE DE GESTION ARENA"* |

**Concept créatif** : **Vector Strike F2** — 3 chevrons orientés à droite suggérant le momentum offensif, sur fond dégradé évoquant une ambiance "stade nuit", avec des speed dots latéraux suggérant la trainée de vitesse.

---

## 📦 Structure du pack

```
arena_branding_pack/
│
├── 📁 flutter_project/              ← À COPIER DANS TON PROJET ARENA
│   ├── assets/
│   │   ├── icons/
│   │   │   ├── arena_user_1024.png          (1024×1024 avec texte ARENA)
│   │   │   ├── arena_admin_1024.png         (1024×1024 avec texte ADMIN)
│   │   │   ├── adaptive_user/               (3 PNG : bg + fg + monochrome)
│   │   │   └── adaptive_admin/              (3 PNG : bg + fg + monochrome)
│   │   └── splash/
│   │       ├── splash_user.png              (1024×1024 plein écran)
│   │       ├── splash_admin.png             (1024×1024 plein écran)
│   │       ├── splash_icon_user.png         (1024×1024 transparent Android 12+)
│   │       └── splash_icon_admin.png        (1024×1024 transparent Android 12+)
│   └── lib_features/
│       └── splash/
│           ├── splash_screen.dart           (widget animé 5 phases)
│           └── splash_router.dart           (wrapper avec détection 1er lancement)
│
├── 📁 raw_sources/                  ← POUR MODIFICATIONS FUTURES
│   ├── svg/                                 (4 SVG éditables Figma/Illustrator)
│   ├── scripts/                             (3 scripts Python pour régénérer)
│   └── png_all_sizes/                       (38 PNG iOS + Android toutes tailles)
│
└── 📁 docs/
    └── README.md                            (ce fichier)
```

---

## 🎨 Identité visuelle

### Design Tokens

```dart
// Couleurs (DESIGN_KIT canonique)
static const void_         = Color(0xFF0A0A0F);  // Fond profond
static const carbon        = Color(0xFF14141C);  // Surface cards
static const signalBlue    = Color(0xFF4C7AFF);  // USER primary
static const neonRed       = Color(0xFFFF2D55);  // ADMIN primary
static const userMid       = Color(0xFF1A2D5C);  // Gradient mid USER
static const adminMid      = Color(0xFF5C1A2D);  // Gradient mid ADMIN

// Polices
- Bebas Neue       → "ARENA" / "ADMIN" (titres impact)
- Instrument Serif → tagline italique
- Space Grotesk    → labels UI
- JetBrains Mono   → codes, IDs, scores
```

### Composition du logo

```
┌─────────────────────────────────────┐
│  Fond : dégradé F2                  │
│  USER  : bleu  → noir (135°)        │
│  ADMIN : rouge → noir (135°)        │
│                                     │
│  Symbole : 3 chevrons               │
│  ──── ──── (5 speed dots à gauche)  │
│   ▶▶▶   (chevrons orientés droite)  │
│                                     │
│  Chevron 1 : blanc plein            │
│  Chevron 2 : accent (rouge/bleu)    │
│  Chevron 3 : blanc 55% transparent  │
│                                     │
│  Texte : ARENA / ADMIN (Bebas Neue) │
│  Tagline : italique (Instrument)    │
└─────────────────────────────────────┘
```

### L'inversion USER ↔ ADMIN

C'est la signature de l'identité ARENA :

| | Fond | Chevron accent |
|---|---|---|
| **USER** | Bleu | Rouge |
| **ADMIN** | Rouge | Bleu |

Cette inversion chromatique crée une cohérence forte entre les 2 apps tout en les différenciant clairement.

---

## ⚡ Installation rapide (15 min)

### 1. Place les fichiers (3 min)

```bash
cd ton-projet-arena

# Crée la structure
mkdir -p assets/icons/adaptive_user assets/icons/adaptive_admin
mkdir -p assets/splash
mkdir -p lib/features/splash

# Copie tout depuis le pack
cp -r arena_branding_pack/flutter_project/assets/* assets/
cp arena_branding_pack/flutter_project/lib_features/splash/* lib/features/splash/
```

### 2. Mets à jour pubspec.yaml (2 min)

Ajoute (sans casser l'existant) :

```yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_riverpod: ^2.4.10
  shared_preferences: ^2.2.2
  google_fonts: ^6.2.1

dev_dependencies:
  flutter_launcher_icons: ^0.13.1
  flutter_native_splash: ^2.4.1

# Section icônes USER
flutter_launcher_icons:
  android: "ic_launcher"
  ios: true
  image_path: "assets/icons/arena_user_1024.png"
  adaptive_icon_background: "assets/icons/adaptive_user/ic_launcher_background.png"
  adaptive_icon_foreground: "assets/icons/adaptive_user/ic_launcher_foreground.png"
  adaptive_icon_monochrome: "assets/icons/adaptive_user/ic_launcher_monochrome.png"
  remove_alpha_ios: true

# Section splash USER
flutter_native_splash:
  color: "#4C7AFF"
  image: "assets/splash/splash_user.png"
  android_12:
    image: "assets/splash/splash_icon_user.png"
    color: "#0A0A0F"
    icon_background_color: "#4C7AFF"
  ios: true
  ios_content_mode: scaleAspectFill
  android: true
  android_gravity: fill
  fullscreen: true

# Déclare les assets
flutter:
  assets:
    - assets/icons/
    - assets/splash/
```

### 3. Crée les fichiers ADMIN (1 min)

À la racine de ton projet :

**`flutter_launcher_icons-admin.yaml`** :
```yaml
flutter_launcher_icons:
  android: "ic_launcher"
  ios: true
  image_path: "assets/icons/arena_admin_1024.png"
  adaptive_icon_background: "assets/icons/adaptive_admin/ic_launcher_background.png"
  adaptive_icon_foreground: "assets/icons/adaptive_admin/ic_launcher_foreground.png"
  adaptive_icon_monochrome: "assets/icons/adaptive_admin/ic_launcher_monochrome.png"
  remove_alpha_ios: true
```

**`flutter_native_splash-admin.yaml`** :
```yaml
flutter_native_splash:
  color: "#FF2D55"
  image: "assets/splash/splash_admin.png"
  android_12:
    image: "assets/splash/splash_icon_admin.png"
    color: "#0A0A0F"
    icon_background_color: "#FF2D55"
  ios: true
  ios_content_mode: scaleAspectFill
  android: true
  android_gravity: fill
  fullscreen: true
```

### 4. Câble le splash dans main.dart (3 min)

```dart
import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'features/splash/splash_router.dart';

void main() async {
  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  
  // Préserve le splash NATIF pendant l'init
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  
  // ... tes initialisations (Supabase, Firebase, etc.)
  
  runApp(const ProviderScope(child: ArenaApp()));
  
  // Le widget Splash prend le relais
  FlutterNativeSplash.remove();
}

class ArenaApp extends StatelessWidget {
  const ArenaApp({super.key});
  
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // ... ta config existante
      home: const SplashPage(
        isAdmin: false,         // ou true selon le flavor
        nextRoute: '/login',
      ),
    );
  }
}
```

### 5. Génère et teste (5 min)

```bash
# Récupère les dépendances
flutter pub get

# Génère les icônes
flutter pub run flutter_launcher_icons
flutter pub run flutter_launcher_icons -f flutter_launcher_icons-admin.yaml

# Génère les splash natifs
flutter pub run flutter_native_splash:create
flutter pub run flutter_native_splash:create --path=flutter_native_splash-admin.yaml

# Nettoie et teste
flutter clean
flutter pub get
flutter run
```

🎉 **Tu devrais voir :**
1. Le splash natif (200ms)
2. L'animation cinématique 5 phases (5.3s)
3. Atterrissage sur LoginPage

---

## 🔍 Installation détaillée

### Comment fonctionne l'animation splash (5 phases)

```
T=0.0s ─── ⭐ Spark blanc grandit au centre + halo bleu
T=1.0s ─── ⚡ Logo emerge avec rebond élastique
T=2.2s ─── 📝 Texte ARENA + tagline italique apparaissent
T=3.0s ─── 🎮 3 jeux (EFB cyan, FIFA vert, FC orange) en cascade
T=4.0s ─── ⏸ Pause d'admiration (700ms)
T=4.7s ─── 🌫 Fade-out global
T=5.3s ─── 🏠 Navigation vers /login
```

### Détection du premier lancement (intelligente)

Le widget `SplashRouter` utilise `SharedPreferences` :

```dart
// Au 1er lancement
prefs.getBool('has_seen_splash_v1') == null
  → animation COMPLÈTE 5.3s (le "wow")
  → on note has_seen_splash_v1 = true

// Aux lancements suivants
prefs.getBool('has_seen_splash_v1') == true
  → splash COURT 1.5s (rapidité quotidienne)
```

**Pourquoi c'est important** : aucun utilisateur ne veut attendre 5 secondes 10 fois par jour. Mais au premier lancement, l'effet "wow" justifie l'attente.

### Tailles générées automatiquement

**iOS** (par `flutter_launcher_icons`) :
- 1024×1024 (App Store)
- 180×180 (iPhone @3x)
- 167×167 (iPad Pro)
- 152×152 (iPad @2x)
- 120, 87, 80, 76, 60, 58, 40, 29, 20 (autres)

**Android** (par `flutter_launcher_icons`) :
- 512×512 (Play Store)
- 192 xxxhdpi, 144 xxhdpi, 96 xhdpi, 72 hdpi, 48 mdpi
- **Adaptive icons** (Android 8+) avec foreground + background séparés
- **Themed icon monochrome** (Android 13+)

**Splash** (par `flutter_native_splash`) :
- iPhone Pro Max, iPhone Pro, iPad, Android xxhdpi/xhdpi/hdpi/mdpi
- Toutes tailles configurées automatiquement

---

## 🎨 Personnalisation

### Modifier la tagline

Dans `lib/features/splash/splash_screen.dart`, cherche ligne ~340 :

```dart
Text(
  "SEUL LE TALENT EST RÉCOMPENSÉ...",  // ← change ici
  style: GoogleFonts.instrumentSerif(...)
),
```

Suggestions de taglines :
- `"PROVE YOUR SKILL"`
- `"PLAY • COMPETE • WIN"`
- `"OÙ LE TALENT TROUVE SON ARÈNE"`

### Modifier la durée totale

Dans `_runSequence()` (splash_screen.dart), ajuste les `Future.delayed` :

| Phase | Délai actuel | Pour 3s total | Pour 7s total |
|---|---|---|---|
| Phase 1 → 2 | 1000ms | 600ms | 1500ms |
| Phase 2 → 3 | 1000ms | 600ms | 1500ms |
| Phase 3 → 4 | 800ms | 500ms | 1200ms |
| Pause | 700ms | 400ms | 1200ms |

### Désactiver une phase

Si tu ne veux pas afficher les 3 jeux (Phase 4), commente cette ligne dans `build()` :

```dart
// _buildGamesRow(),  // ← commenter = supprimer
```

Et raccourcis le timing en conséquence.

### Forcer le splash long à chaque lancement (mode dev)

Dans `splash_router.dart`, dans le provider :

```dart
final firstLaunchProvider = FutureProvider<bool>((ref) async {
  return true;  // ← forcer toujours premier lancement
  // ↑ N'OUBLIE PAS de remettre la vraie logique en release !
});
```

### Modifier les couleurs (au cas où)

Tout est dans `splash_screen.dart` lignes 184-189 :

```dart
Color get _accentColor => widget.isAdmin 
    ? const Color(0xFFFF2D55)   // ADMIN
    : const Color(0xFF4C7AFF);  // USER
```

---

## 🐛 Dépannage

| Symptôme | Solution |
|---|---|
| Icône Android pas à jour | `flutter clean`, désinstaller l'app, rebuild |
| App Store rejette l'icône | Vérifier `remove_alpha_ios: true` |
| Splash blanc au démarrage | Vérifier `FlutterNativeSplash.preserve()` dans main.dart |
| Animation saccadée | Tester en `--profile`, vérifier pas de StatefulWidget inutile |
| Polices Bebas absentes | `flutter pub get`, vérifier `google_fonts` |
| Splash ADMIN identique USER | Régénérer avec `--path=flutter_native_splash-admin.yaml` |
| Adaptive icon coupée | Le symbole doit être dans la **safe zone** centrale (66%) |
| `SharedPreferences` error | `flutter pub get`, `flutter clean` |

---

## ⚙️ Spécifications techniques

### Adaptive icons Android (détail)

| Fichier | Rôle |
|---|---|
| `ic_launcher_background.png` | Couche de fond, prise par le système |
| `ic_launcher_foreground.png` | Couche supérieure avec le symbole (fond transparent) |
| `ic_launcher_monochrome.png` | Pour Android 13+ themed icons (silhouette blanche) |

**Safe zone** : sur Android 8+, seuls les 432×432 pixels centraux du fichier 1024×1024 sont **garantis** visibles. Le système peut couper les bords pour appliquer des masques (cercle, squircle, carré arrondi, etc.).

### Splash natif vs widget Flutter

Il y a **deux splashs successifs** :

```
1. SPLASH NATIF (Android/iOS, ~200ms)
   ├── Android : drawable static (couleur + image)
   └── iOS : LaunchScreen.storyboard
   
   ⬇ Flutter engine prêt
   
2. WIDGET SPLASH (Dart, 5.3s)
   ├── SplashScreen (animations)
   └── Navigation vers /login
```

Le splash NATIF doit visuellement **matcher** le widget Flutter (mêmes couleurs, même logo position) pour éviter le flash de transition.

### Performance attendue

| Device | FPS attendu | Notes |
|---|---|---|
| iPhone 13+ | 60 FPS constant | Aucun ralentissement |
| Samsung S22+ | 60 FPS constant | Aucun ralentissement |
| Tecno Spark 10 | 50-60 FPS | Quelques saccades sur Phase 1 |
| Samsung A03s | 40-50 FPS | Animations plus saccadées |

**Pour optimiser les vieux Android** : raccourcir Phase 1 de 1200ms à 800ms.

---

## 📊 Récap des éléments fournis

| Catégorie | Quantité |
|---|---|
| Icônes app finales (PNG) | 38 fichiers (19 iOS + 6 Android × 2 rôles + 7 stores) |
| Adaptive icons Android | 6 fichiers (3 layers × 2 rôles) |
| Splash natifs | 4 fichiers (USER/ADMIN × plein/icon) |
| Code Flutter | 2 fichiers (splash_screen.dart, splash_router.dart) |
| Sources SVG éditables | 4 fichiers |
| Scripts Python (régénération) | 3 fichiers |
| Documentation | Ce README + commentaires inline |

**Total** : ~60 fichiers, ~2 MB.

---

## 🚀 Prochaines étapes recommandées

Une fois ce pack installé :

1. **Test sur device réel** (pas que simulateur) — iOS et Android
2. **Captures Play Store / App Store** : utilise les images du pack `raw_sources/png_all_sizes/`
3. **Marketing assets** : posters, bannières Instagram peuvent réutiliser les SVG
4. **Mode sombre** : ARENA est déjà en mode sombre par défaut, mais vérifie la cohérence

---

**Bonne installation, et bon lancement ARENA !** 🚀

> Pack généré le 15 mai 2026 pour le projet ARENA — Plateforme e-sport panafricaine.
