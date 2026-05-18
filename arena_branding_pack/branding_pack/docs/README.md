# 🎨 ARENA — Branding Pack complet (Icônes + Splash)

> **Pack tout-en-un** pour intégrer l'identité visuelle ARENA dans le projet Flutter.
> Conçu pour être donné directement à **Claude Code** comme contexte de tâche.

---

## 📦 Ce que contient ce pack

```
arena_branding_pack/
│
├── 📁 flutter_project/          ← À COPIER DIRECTEMENT dans ton projet
│   ├── assets/
│   │   ├── icons/
│   │   │   ├── arena_user_1024.png             Icône USER (avec texte ARENA)
│   │   │   ├── arena_admin_1024.png            Icône ADMIN (avec texte ADMIN)
│   │   │   ├── arena_user_compact_1024.png     Icône USER (sans texte, splash)
│   │   │   ├── arena_admin_compact_1024.png    Icône ADMIN (sans texte, splash)
│   │   │   └── adaptive/
│   │   │       ├── user/                       Adaptive icons Android 8+
│   │   │       │   ├── ic_launcher_background.png
│   │   │       │   ├── ic_launcher_foreground.png
│   │   │       │   └── ic_launcher_monochrome.png
│   │   │       └── admin/                       Idem pour ADMIN
│   │   └── splash/
│   │       ├── splash_user.png                 Plein écran USER (dégradé + logo)
│   │       ├── splash_admin.png                Plein écran ADMIN
│   │       ├── splash_icon_user.png            Logo transparent (Android 12+)
│   │       └── splash_icon_admin.png
│   └── lib/
│       └── features/
│           └── splash/
│               ├── splash_screen.dart          Widget animé 5 phases (5.3s)
│               └── splash_router.dart          Wrapper Riverpod + 1er lancement
│
├── 📁 raw_sources/                ← Sources brutes (à archiver, pas à copier)
│   ├── svg_sources/                4 SVG éditables (USER, ADMIN, compacts)
│   ├── icons_ios/                  13 PNG iOS toutes tailles USER
│   ├── icons_ios_admin/            13 PNG iOS toutes tailles ADMIN
│   ├── icons_android/              6 PNG Android USER + Play Store
│   └── icons_android_admin/        Idem ADMIN
│
├── 📁 docs/                        ← Documentation
│   ├── README.md                   Ce fichier
│   ├── pubspec_config.yaml         Config complète à copier dans pubspec.yaml
│   ├── DESIGN_TOKENS.md            Couleurs et règles de marque
│   └── PROMPT_CLAUDE_CODE.md       Prompt prêt-à-coller pour Claude Code
│
└── 📁 previews/                    ← Aperçus visuels HTML
    ├── icon_preview.html           Toutes les tailles d'icônes
    └── splash_preview.html         Animation splash en boucle
```

---

## 🎯 Identité visuelle (résumé)

### Couleurs DESIGN_KIT

| Token | Hex | Usage |
|---|---|---|
| `--signal-blue` | `#4C7AFF` | USER (primary) |
| `--neon-red` | `#FF2D55` | ADMIN, LIVE indicators |
| `--void` | `#0A0A0F` | Fond principal |
| `--bone` | `#F5F5F0` | Texte principal |

### Polices Google Fonts

| Police | Usage |
|---|---|
| **Bebas Neue** | Texte "ARENA" / "ADMIN", headers |
| **Instrument Serif (italic)** | Tagline "SEUL LE TALENT EST RÉCOMPENSÉ..." |
| **Space Grotesk** | Corps de texte |
| **JetBrains Mono** | Codes, IDs, montants |

### Concept Vector Strike F2

- **Forme** : 3 chevrons orientés vers la droite (rafale offensive)
- **Speed dots** : 5 points en demi-cercle à gauche (trainée de vitesse)
- **Fond** : dégradé diagonal (couleur principale → couleur mid → void noir)
- **Inversion chromatique** USER ↔ ADMIN

---

## 🚀 Installation rapide (15 minutes)

### Pour humain qui suit le guide

```bash
# 1. Dans ton projet ARENA, copier la structure flutter_project/
cd ton-projet-arena
cp -r ../arena_branding_pack/flutter_project/* .

# 2. Mettre à jour pubspec.yaml (voir docs/pubspec_config.yaml)
# Ajouter sections : dependencies, flutter_launcher_icons, 
# flutter_native_splash, flutter.assets

# 3. Créer flutter_launcher_icons-admin.yaml et 
#    flutter_native_splash-admin.yaml (voir docs/pubspec_config.yaml)

# 4. Installer dépendances
flutter pub get

# 5. Générer les icônes USER + ADMIN
flutter pub run flutter_launcher_icons
flutter pub run flutter_launcher_icons -f flutter_launcher_icons-admin.yaml

# 6. Générer les splash USER + ADMIN
flutter pub run flutter_native_splash:create
flutter pub run flutter_native_splash:create --path=flutter_native_splash-admin.yaml

# 7. Câbler dans main.dart (import SplashPage, mettre en home:)
# Voir lib/features/splash/splash_router.dart

# 8. Nettoyer et tester
flutter clean
flutter pub get
flutter run
```

### Pour Claude Code (automatique)

Utiliser le prompt prêt-à-coller dans `docs/PROMPT_CLAUDE_CODE.md`.

---

## 🎨 Détails techniques

### Icônes — Stratégie de tailles

| Taille | Usage | Avec texte ? |
|---|---|---|
| **1024×1024** | App Store, Play Store, source maître | ✅ Oui |
| **180×180** | iPhone @3x sur écran d'accueil | ✅ Oui |
| **120×120** | iPhone @2x | ✅ Oui |
| **96×96** | Android xhdpi | ✅ Oui |
| **48×48** | Android mdpi, miniatures Play Store | ❌ Non (version compacte) |

**Logic** : sous 96px, le texte "ARENA" devient illisible, donc on utilise automatiquement la version compacte (chevrons agrandis sans texte).

### Splash — Timeline animation

```
T=0.0s  → Splash NATIF (200ms instantané, Android/iOS)
T=0.3s  → Phase 1 : Spark blanc grandit au centre
T=1.3s  → Phase 2 : Logo emerge avec rebond élastique
T=2.3s  → Phase 3 : Texte ARENA + tagline italique
T=3.1s  → Phase 4 : 3 jeux EFB/FIFA/FC en cascade
T=4.0s  → Pause d'admiration
T=4.7s  → Phase 5 : Fade-out global
T=5.3s  → Navigation vers LoginPage
```

**Smart detection** : au 1er lancement → animation complète. Aux suivants → splash court 1.5s.

### Adaptive Icons Android 8+

- **Foreground** : chevrons + dots sur fond transparent (centré dans safe zone 432×432)
- **Background** : dégradé F2 plein
- **Monochrome** : silhouette blanche pour Android 13+ themed icons

---

## ⚠️ Choses importantes

### Ce qui est dans `flutter_project/`

✅ **À COPIER** directement dans le projet Flutter — c'est l'état final voulu.

### Ce qui est dans `raw_sources/`

📦 **Sources de référence** générées par les scripts Python. Tu n'as **PAS besoin** de les copier dans le projet — `flutter_launcher_icons` les régénère automatiquement à partir de l'image 1024×1024.

Garde-les comme **archive** si tu veux modifier les couleurs ou les chevrons plus tard sans avoir à tout regénérer.

### iOS App Store : pas d'alpha !

Les PNG iOS **NE DOIVENT PAS** avoir de transparence (sinon Apple rejette l'icône au moment de la soumission). C'est garanti par `remove_alpha_ios: true` dans la config.

---

## 📝 Crédits techniques

- **Concept icône** : Vector Strike F2 (chevrons + dégradé)
- **Concept splash** : Cinématique D (spark → logo → tagline → jeux → fade)
- **Tagline** : "SEUL LE TALENT EST RÉCOMPENSÉ..."
- **Couleurs** : DESIGN_KIT canonique ARENA
- **Génération** : Python + Pillow (PIL) pour les PNG, SVG pour les sources éditables
- **Animation Flutter** : 5 AnimationControllers avec TickerProviderStateMixin

---

## 🚦 Prochaines étapes après installation

Une fois icônes + splash en place dans le projet ARENA :

1. **Test sur device** : vérifier l'animation sur Android (entry-level Samsung A03s, Tecno Spark) et iOS
2. **App Store Connect** : uploader l'icône 1024×1024 pour validation
3. **Play Console** : uploader le 512×512 (`raw_sources/icons_android/playstore-icon.png`)
4. **Marketing** : utiliser les SVG de `raw_sources/svg_sources/` pour les posters, banners, social media
5. **Variantes futures** : Ramadan, Coupe du Monde, événements esport (basé sur les SVG)

---

Tu peux maintenant **continuer** vers les étapes suivantes du projet ARENA (Phase 10 notifications, paiements, etc.).
