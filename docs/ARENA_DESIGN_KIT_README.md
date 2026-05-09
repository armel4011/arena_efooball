# 🎨 ARENA Design Kit Flutter

> Kit complet pour reproduire **pixel-perfect** le design d'arena_premium.html dans ton app Flutter.

## 📦 Contenu

```
lib/
├── core/design/                          ← Design system
│   ├── arena_tokens.dart                 (couleurs, spacing, radius, shadows)
│   ├── arena_typography.dart             (4 polices : Bebas/Space Grotesk/Instrument/JBM)
│   ├── arena_gradients.dart              (gradients premium)
│   └── arena_theme.dart                  (ThemeData global)
│
├── features_shared/widgets/              ← 15 widgets premium
│   ├── arena_app_bar.dart
│   ├── arena_avatar.dart
│   ├── arena_badge.dart
│   ├── arena_banner.dart
│   ├── arena_bottom_nav.dart
│   ├── arena_button.dart
│   ├── arena_card.dart
│   ├── arena_dialog.dart
│   ├── arena_divider.dart
│   ├── arena_empty_state.dart
│   ├── arena_floating_button.dart        (LE bouton iconique anti-cheat)
│   ├── arena_loading.dart
│   ├── arena_phone_frame.dart            (cadre iPhone pour previews)
│   ├── arena_stepper.dart
│   └── arena_text_field.dart
│
└── dev/
    └── widget_preview_page.dart          ← ⭐ Page de validation visuelle
```

## 🚀 Installation rapide (5 min)

### 1. Ajoute les dépendances

Dans `pubspec.yaml` :

```yaml
dependencies:
  flutter:
    sdk: flutter
  google_fonts: ^6.2.1
```

Puis : `flutter pub get`

### 2. Copie tous les fichiers

Copie exactement la structure dans ton projet sous `lib/`.

### 3. Active le theme dans main.dart

```dart
import 'package:arena/core/design/arena_theme.dart';
import 'package:arena/dev/widget_preview_page.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ARENA',
      theme: ArenaTheme.dark,
      home: const WidgetPreviewPage(), // ← Pour valider visuellement
      debugShowCheckedModeBanner: false,
    );
  }
}
```

### 4. Lance l'app

```bash
flutter run
```

### 5. Compare avec arena_premium.html

Ouvre `arena_premium.html` dans Chrome **côte à côte** avec ton émulateur Flutter.

✅ Si tout matche visuellement → tu peux commencer à construire les écrans !

## 🎯 Comment utiliser pour les écrans réels

Pour **chaque écran**, donne ce prompt à Claude Code :

```
Salut Claude.

📚 LECTURES OBLIGATOIRES :
1. arena_premium.html (la référence visuelle)
2. lib/core/design/arena_tokens.dart
3. lib/core/design/arena_typography.dart
4. lib/features_shared/widgets/* (les 15 widgets)
5. ARENA_47_ECRANS.md (specs de l'écran #X)

🎯 Implémente l'écran [NomPage].

⚠️ RÈGLES STRICTES :
- ZÉRO valeur hardcodée → utilise ArenaTokens
- ZÉRO TextStyle inline → utilise ArenaTypography
- ZÉRO bouton custom → utilise ArenaButton.X()
- ZÉRO card custom → utilise ArenaCard.X()

PROCÉDURE :
1. Identifie le mockup correspondant dans arena_premium.html
2. Liste les widgets que tu vas utiliser
3. Demande mon GO
4. Implémente
5. Demande-moi de comparer avec le HTML

GO ?
```

## ✅ Checklist avant de coder un écran

- [ ] J'ai lu le mockup HTML correspondant
- [ ] J'ai identifié tous les composants utilisés
- [ ] Je n'utilise QUE des widgets `ArenaXxx`
- [ ] Toutes mes couleurs sont depuis `ArenaTokens`
- [ ] Toutes mes typographies sont depuis `ArenaTypography`
- [ ] J'ai des states loading/empty/error

## 📞 Si Claude Code dérive du design

```
STOP. Ce n'est pas conforme à arena_premium.html.

Re-lis le mockup section [écran X].
Compare ton code ligne par ligne.
Liste les écarts précis.
Corrige UN écart à la fois.
```

---

> 💎 Le secret : **WidgetPreviewPage est ta validation visuelle**.
> Si elle ne ressemble pas à arena_premium.html, ne code pas d'écrans.
