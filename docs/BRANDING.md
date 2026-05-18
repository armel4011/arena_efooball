# ARENA — Branding pack v2

Source : `arena_branding_pack/branding_pack/` (importé 2026-05-18).
Identité visuelle « Vector Strike F2 » + Splash D cinématique.

## Tokens

### Couleurs
| Token | Hex | Usage |
|---|---|---|
| `signalBlue` | `#4C7AFF` | USER primary, CTAs |
| `neonRed` | `#FF2D55` | ADMIN, LIVE indicators |
| `void_` | `#0A0A0F` | Fond principal |
| `userMid` | `#1A2D5C` | Stop 55 % du dégradé USER (utilisé par SplashPage) |
| `adminMid` | `#5C1A2D` | Stop 55 % du dégradé ADMIN |
| `bone` | `#F5F5F0` | Texte principal |

Dégradé F2 :
```
USER  : #4C7AFF (0%) → #1A2D5C (55%) → #0A0A0F (100%)
ADMIN : #FF2D55 (0%) → #5C1A2D (55%) → #0A0A0F (100%)
```

### Typographie (Google Fonts déjà câblées dans `arena_theme.dart`)
- **Bebas Neue** — headers, ARENA wordmark, splash brand name (44px / letter-spacing 8)
- **Instrument Serif italic** — taglines
- **Space Grotesk** — body text, boutons
- **JetBrains Mono** — codes, montants

### Tagline officielle
`SEUL LE TALENT EST RÉCOMPENSÉ...`

## Splash D — timings 6.3s / 3.5s

| Lancement | Composant | Durée |
|---|---|---|
| 1er | `SplashScreen` cinématique (spark → logo → texte → 3 jeux → fade-out) | **6.3s** |
| Récurrent | `_ShortSplashScreen` (fade-in chevrons) | **3.5s** |

Détection via SharedPreferences clé `has_seen_splash_v1`.

## Régénération des assets

### Icônes
```bash
# USER (config flutter_launcher_icons-user.yaml + pubspec section)
flutter pub run flutter_launcher_icons -f flutter_launcher_icons-user.yaml

# ADMIN
flutter pub run flutter_launcher_icons -f flutter_launcher_icons-admin.yaml

# Les deux d'un coup (flutter_launcher_icons v0.13 détecte les flavors)
flutter pub run flutter_launcher_icons
```

### Splash natif
```bash
# USER
flutter pub run flutter_native_splash:create

# ADMIN
flutter pub run flutter_native_splash:create --path=flutter_native_splash-admin.yaml
```

⚠️ **flutter_native_splash écrit dans `android/app/src/main/res/`** sans
flavor awareness. Pour ARENA on déplace manuellement après chaque génération :
- USER splash → `android/app/src/user/res/`
- ADMIN splash → `android/app/src/admin/res/`
- `main/res/` ne garde que les placeholders Flutter d'origine (cf. tag
  `pre-branding-pack-v2`).

Ordre recommandé pour une re-génération propre :
1. `flutter pub run flutter_native_splash:create --path=flutter_native_splash-admin.yaml`
2. Move `main/res/{drawable*,values*}/*` → `admin/res/`
3. `flutter pub run flutter_native_splash:create`
4. Move `main/res/{drawable*,values*}/*` → `user/res/`
5. `git checkout pre-branding-pack-v2 -- android/app/src/main/res/{drawable,drawable-v21,values,values-night}` pour restaurer les placeholders.

## Architecture Dart

- `lib/features/splash/splash_router.dart` : `SplashPage` (ConsumerWidget),
  `firstLaunchProvider`, `_ShortSplashScreen`, `_SplashLoadingState`.
- `lib/features/splash/splash_screen.dart` : `SplashScreen` cinématique
  6.3s (5 phases, TweenSequence).
- `lib/core/services/bootstrap.dart` : `FlutterNativeSplash.preserve` au
  démarrage, `.remove()` après `runApp` pour passer le relais à `SplashPage`.
- Route `/intro` dans `user_router.dart` et `admin_router.dart` avec
  `initialLocation: UserRoutes.intro` (resp. `AdminRoutes.intro`).
  Le redirect chain exempte `/intro` ; le callback `onComplete` route
  vers `UserRoutes.home` ou `AdminRoutes.splash`.

## Tests

`test/golden_path_test.dart` et `test/widget_test.dart` court-circuitent
le splash cinématique en pré-remplissant `has_seen_splash_v1: true` puis
appelant `_pumpPastSplash(tester)` qui avance le temps de 3.6s pour
franchir le `Future.delayed(3500ms)` du short splash.

## Sources brutes

Conservées dans `arena_branding_pack/branding_pack/` :
- `raw_sources/svg_sources/` — 4 SVG (USER+ADMIN, full+compact)
- `raw_sources/icons_{android,android_admin,ios,ios_admin}/` — pré-générés
- `docs/DESIGN_TOKENS.md` — référence officielle
- `previews/splash_preview.html` — preview standalone

## Inversion chromatique USER ↔ ADMIN

| Élément | USER | ADMIN |
|---|---|---|
| Fond gradient | Bleu (`#4C7AFF` → noir) | Rouge (`#FF2D55` → noir) |
| Chevron accent | Rouge (`#FF2D55`) | Bleu (`#4C7AFF`) |
| Wordmark | « ARENA » bone | « ADMIN » bone |
