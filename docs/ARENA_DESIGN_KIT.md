# 🎨 ARENA Design Kit Flutter — Guide Complet

> **Mission** : Reproduire **pixel-perfect** le design de `arena_premium.html` dans l'app Flutter ARENA.
>
> **Version** : 1.0
> **Cohérent avec** : `arena_premium.html`, `ARENA_UI_GUIDE.md`, `ARENA_47_ECRANS.md` v1.1

---

## 📦 Contenu du kit

```
lib/
├── core/
│   └── design/
│       ├── arena_tokens.dart         ← Design tokens (couleurs, spacing, radius, shadows)
│       ├── arena_typography.dart     ← Système typographique (4 polices)
│       ├── arena_gradients.dart      ← Gradients premium (game banners, glow)
│       └── arena_theme.dart          ← ThemeData global Flutter
│
├── features_shared/
│   └── widgets/
│       ├── arena_button.dart            ← 4 variants (primary/danger/secondary/ghost)
│       ├── arena_card.dart              ← 5 variants (default/glow/success/danger/warning)
│       ├── arena_text_field.dart        ← Input premium avec focus glow
│       ├── arena_avatar.dart            ← 4 sizes × 6 colors
│       ├── arena_badge.dart             ← Badges status (live, success, warn...)
│       ├── arena_app_bar.dart           ← AppBar custom avec actions
│       ├── arena_bottom_nav.dart        ← Bottom nav 4 tabs avec glow
│       ├── arena_phone_frame.dart       ← Cadre iPhone (pour previews)
│       ├── arena_stepper.dart           ← Stepper horizontal coloré
│       ├── arena_banner.dart            ← Banner gradient par jeu
│       ├── arena_floating_button.dart   ← LE bouton iconique anti-cheat
│       ├── arena_divider.dart           ← Divider subtle
│       ├── arena_loading.dart           ← Spinner + skeleton
│       ├── arena_empty_state.dart       ← Placeholder design
│       └── arena_dialog.dart            ← Modal avec backdrop blur
│
└── dev/
    └── widget_preview_page.dart      ← Page de validation visuelle (CRUCIAL)
```

---

## 🚀 Procédure d'installation (à donner à Claude Code)

### Étape 1 — Installer les dépendances

Ajoute dans `pubspec.yaml` :

```yaml
dependencies:
  flutter:
    sdk: flutter
  google_fonts: ^6.2.1
  flutter_svg: ^2.0.10
```

Puis : `flutter pub get`

### Étape 2 — Copier les fichiers du kit

Copie **tous les fichiers** ci-dessus dans la structure indiquée.

### Étape 3 — Importer le theme

Dans `main.dart` :

```dart
import 'package:arena/core/design/arena_theme.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ArenaTheme.dark, // ← LE theme premium
      // ...
    );
  }
}
```

### Étape 4 — Valider visuellement

Lance `WidgetPreviewPage` et compare avec `arena_premium.html` côte à côte.

### Étape 5 — Construire les écrans

Utilise **uniquement** ces widgets pour construire les 53 écrans.

---

## 🎯 Workflow Claude Code (LE prompt magique)

```
Salut Claude.

📚 LECTURES OBLIGATOIRES :
1. arena_premium.html (ouvert dans Chrome)
2. lib/core/design/arena_tokens.dart
3. lib/core/design/arena_typography.dart
4. ARENA_47_ECRANS.md → section "Écran #X"

🎯 Mission : Implémenter [NomPage] en Flutter.

⚠️ RÈGLES PIXEL-PERFECT :

1. AVANT de coder :
   - Identifie le mockup correspondant dans arena_premium.html
   - Liste TOUS les composants visibles (m-card, m-btn-primary, m-banner...)
   - Identifie les détails clés (gradients, glow, animations)

2. PROPOSE :
   - Quels widgets de lib/features_shared/widgets/ tu vas utiliser
   - Quels états gérer (loading, empty, error)
   - Quels providers Riverpod

3. ATTEND mon GO

4. IMPLÉMENTE en utilisant :
   ❌ AUCUNE valeur hardcodée (Color(0xFF...), fontSize: 16, padding: 12)
   ✅ TOUJOURS depuis ArenaTokens / ArenaTypography
   ❌ AUCUN widget Material custom
   ✅ TOUJOURS les widgets ArenaXxx

5. AJOUTE l'écran à WidgetPreviewPage pour validation

6. ME DEMANDE de comparer côte à côte avec arena_premium.html

7. ITÈRE jusqu'au match parfait

GO ?
```

---

## 📊 Tableau de correspondance HTML → Flutter

Pour traduire un mockup HTML en Flutter, voici les mappings :

| HTML/CSS class | Widget Flutter |
|----------------|----------------|
| `m-btn-primary` | `ArenaButton.primary()` |
| `m-btn-danger` | `ArenaButton.danger()` |
| `m-btn-secondary` | `ArenaButton.secondary()` |
| `m-btn-ghost` | `ArenaButton.ghost()` |
| `m-card` | `ArenaCard.default_()` |
| `m-card-glow` | `ArenaCard.glow()` |
| `m-card-success` | `ArenaCard.success()` |
| `m-card-danger` | `ArenaCard.danger()` |
| `m-card-warning` | `ArenaCard.warning()` |
| `m-input` | `ArenaTextField()` |
| `m-input.focused` | `ArenaTextField(autofocus: true)` |
| `m-avatar` | `ArenaAvatar()` |
| `m-avatar.sm/md/lg/xl` | `ArenaAvatarSize.sm/md/lg/xl` |
| `m-avatar-blue/red/green/orange/cyan/purple` | `ArenaAvatarColor.X` |
| `m-badge-success/info/warning/danger/live` | `ArenaBadge.success/info/...` |
| `m-banner.efoot/fifa/fc` | `ArenaBanner.efoot/fifa/fc` |
| `m-stepper` + `m-step.active/done` | `ArenaStepper(activeStep, doneSteps)` |
| `m-floating-btn` | `ArenaFloatingButton()` |
| `app-header` (avec back) | `ArenaAppBar(back: true)` |
| `bottom-nav` | `ArenaBottomNav(activeTab: ...)` |

---

## 🎨 Mapping HTML → Tokens

| HTML CSS variable | Flutter token |
|-------------------|---------------|
| `var(--bg)` / `--void` | `ArenaTokens.void_` |
| `var(--surface)` / `--carbon` | `ArenaTokens.carbon` |
| `var(--text)` / `--bone` | `ArenaTokens.bone` |
| `var(--text-muted)` / `--silver` | `ArenaTokens.silver` |
| `var(--primary)` / `--signal-blue` | `ArenaTokens.signalBlue` |
| `var(--secondary)` / `--neon-red` | `ArenaTokens.neonRed` |
| `var(--success)` / `--status-ok` | `ArenaTokens.statusOk` |
| `--game-efoot/fifa/fc` | `ArenaTokens.gameEfoot/Fifa/Fc` |

---

## 🚫 Règles strictes

### ❌ Ce qu'il NE FAUT JAMAIS faire

```dart
// ❌ MAUVAIS — couleurs hardcodées
Container(
  color: Color(0xFF4C7AFF),
  padding: EdgeInsets.all(12),
)

// ❌ MAUVAIS — boutons custom
ElevatedButton(
  onPressed: () {},
  child: Text('Sign In'),
)

// ❌ MAUVAIS — typo Material par défaut
Text('Hello', style: TextStyle(fontSize: 16))
```

### ✅ Ce qu'il FAUT TOUJOURS faire

```dart
// ✅ BON — tokens systématiques
Container(
  color: ArenaTokens.signalBlue,
  padding: EdgeInsets.all(ArenaTokens.space12),
)

// ✅ BON — widgets Arena
ArenaButton.primary(
  label: 'Sign In',
  onPressed: () {},
)

// ✅ BON — typography system
Text('Hello', style: ArenaTypography.bodyMedium)
```

---

## ✅ Checklist pixel-perfect par écran

Avant de marquer un écran "fini", coche :

- [ ] Toutes les couleurs viennent d'`ArenaTokens`
- [ ] Toutes les polices viennent d'`ArenaTypography`
- [ ] Tous les espacements viennent d'`ArenaTokens.spaceX`
- [ ] Tous les radius viennent d'`ArenaTokens.radiusX`
- [ ] Boutons = `ArenaButton.X()` uniquement
- [ ] Cards = `ArenaCard.X()` uniquement
- [ ] Inputs = `ArenaTextField()` uniquement
- [ ] Avatars = `ArenaAvatar()` avec size + color enum
- [ ] Loading state implémenté
- [ ] Empty state implémenté (si liste)
- [ ] Error state implémenté
- [ ] Comparé visuellement avec `arena_premium.html`

---

## 📞 Que faire si Claude Code dérive du design ?

Si à un moment Claude Code créé du Flutter qui ne ressemble pas au HTML :

```
STOP. Ce que tu fais ne correspond pas au design.

📚 Re-lis arena_premium.html section [écran X].

Compare ligne par ligne :
- Couleur de fond
- Padding intérieur
- Border radius
- Typographie utilisée
- Ombres/glow

Liste-moi les écarts précis (avec numéro de ligne du HTML + ton code).
Puis corrige UN écart à la fois et montre-moi le résultat.
```

---

## 🎯 Pour démarrer maintenant (action immédiate)

### 1. Crée la structure de dossiers

```bash
mkdir -p lib/core/design
mkdir -p lib/features_shared/widgets
mkdir -p lib/dev
```

### 2. Copie les fichiers du kit

Copie tous les `.dart` fournis (16 fichiers).

### 3. Lance la page de preview

Ajoute temporairement dans ton `main.dart` :

```dart
home: WidgetPreviewPage(),
```

Lance `flutter run` et **compare avec `arena_premium.html`**.

### 4. Si le rendu match → tu peux attaquer les écrans !

---

> 💎 **Le secret du pixel-perfect** : la **WidgetPreviewPage** est ta validation visuelle.
> Tant qu'elle ne ressemble pas exactement au HTML, **n'avance PAS** sur les écrans.
