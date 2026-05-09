# 🎨 ARENA — Guide UI/UX & Design System

> **Document de référence visuelle** pour Claude Code afin de garantir la cohérence UI/UX sur tous les écrans du projet ARENA.
>
> **Version** : 2.0 (mai 2026) — *migration tokens DESIGN_KIT canonique + 54 écrans*
> **Cohérent avec** : `ARENA_MASTER_PROMPT.md` v2.0 + `ARENA_54_ECRANS.md` v2.0 + `arena_v2.html` (preview)

> **Changelog v2.0** :
> - Polices migrées : Bebas Neue + Space Grotesk + JetBrains Mono (avant : Orbitron + Nunito + Fira Code)
> - Couleurs migrées vers DESIGN_KIT : void #0A0A0F, carbon #14141C, signalBlue #4C7AFF, neonRed #FF2D55, statusOk #00C896
> - Décompte écrans : 47 → 54

---

## 📖 SOMMAIRE

1. [Philosophie de design](#1-philosophie-de-design)
2. [Palette de couleurs](#2-palette-de-couleurs)
3. [Typographie](#3-typographie)
4. [Spacing & Layout](#4-spacing--layout)
5. [Composants core (widgets de base)](#5-composants-core)
6. [Patterns & règles d'écran](#6-patterns--règles-décran)
7. [Animations & micro-interactions](#7-animations--micro-interactions)
8. [Loading, Empty, Error states](#8-loading-empty-error-states)
9. [Iconographie](#9-iconographie)
10. [Accessibilité](#10-accessibilité)
11. [Différences User vs Admin](#11-différences-user-vs-admin)
12. [Anti-patterns (À NE JAMAIS FAIRE)](#12-anti-patterns)

---

# 1. Philosophie de design

## 🎯 ADN visuel d'ARENA

ARENA est une plateforme **e-sport panafricaine**. Son design doit refléter :

| Émotion à transmettre | Comment |
|----------------------|---------|
| **Compétition** | Couleurs vives, typo géométrique, énergie |
| **Premium** | Dark theme exclusif, animations soignées |
| **Sérieux financier** | Hiérarchie claire, pas de fioritures sur les paiements |
| **Africain moderne** | Palette pas de stéréotypes, inspirée du gaming mondial |
| **Mobile-first** | Tout pensé pour pouce d'1 main, écrans 5-7 pouces |

## 🎮 Inspirations visuelles

- **Discord** : dark theme, bulles chat, présence en ligne
- **Twitch** : streaming layout, viewers count, modération
- **FIFA Mobile / eFootball** : couleurs vibrantes par jeu
- **Stripe** : clarté financière (paiements, payouts)
- **Linear** : minimalisme, hiérarchie typographique

## ⚖️ Règles fondamentales

1. **Toujours dark theme** (jamais de light theme V1.0)
2. **Toujours mobile-first** (web admin = adaptive)
3. **Toujours 60 FPS** (pas d'animations qui ramentent)
4. **Toujours accessible** (contraste min 4.5:1 sur le texte)
5. **Toujours testable** (loading, empty, error)
6. **Toujours cohérent** (un bouton bleu = action primaire, partout)

---

# 2. Palette de couleurs

## 🎨 Couleurs principales

### Backgrounds (du plus sombre au plus clair)

```dart
class ArenaColors {
  // === BACKGROUNDS ===
  static const bg = Color(0xFF0A0A0F);          // Scaffold (très sombre)
  static const surface = Color(0xFF14141C);     // Cards standard
  static const surfaceLight = Color(0xFF1C1C26); // Cards elevées (modals, dropdowns)
  static const surfaceDark = Color(0xFF050609); // Sections distinctes (very dark)
}
```

**Usage visuel** :

```
┌─────────────────────────────────────┐
│ Scaffold bg = #0A0A0F (très sombre) │
│  ┌───────────────────────────────┐  │
│  │ Card surface = #14141C        │  │
│  │  ┌─────────────────────────┐  │  │
│  │  │ Modal #1A1D2A (elevée) │  │  │
│  │  └─────────────────────────┘  │  │
│  └───────────────────────────────┘  │
└─────────────────────────────────────┘
```

### Brand colors

```dart
// === BRAND ===
static const primary = Color(0xFF4C7AFF);     // Bleu (User app principal)
static const primaryDark = Color(0xFF2952CC); // Hover/pressed primary
static const primaryLight = Color(0xFF7B9FFF); // Disabled primary

static const secondary = Color(0xFFFF2D55);   // Rouge (Admin app + LIVE indicators)
static const secondaryDark = Color(0xFFCC2945); 
```

**Règle d'usage** :
- 🔵 **Bleu (primary)** = action principale dans l'app **User**
- 🔴 **Rouge (secondary)** = action principale dans l'app **Admin** + indicateurs LIVE/danger

### Game colors (par jeu)

```dart
// === GAME COLORS (couleurs identifiantes par jeu) ===
static const efootball = Color(0xFF00B4D8);   // Cyan vibrant
static const fifa = Color(0xFFFFB020);        // Orange chaleureux
static const fcMobile = Color(0xFFFF6A1A);    // Orange-rouge
```

**Usage** : couleur de bordure/accent pour distinguer visuellement les compétitions par jeu.

```
┌─────────────────────────────┐
│ ▎ eFootball Tournament      │ ← bordure cyan #18E8D4
│   8 joueurs / 16 places     │
└─────────────────────────────┘

┌─────────────────────────────┐
│ ▎ FIFA Mobile Cup           │ ← bordure orange #FFAA00
│   12 joueurs / 16 places    │
└─────────────────────────────┘
```

### State colors (sémantiques)

```dart
// === STATES ===
static const success = Color(0xFF00C896);     // Vert vif (succès, validations)
static const successBg = Color(0x1A00C896);   // Vert 10% (backgrounds badges)

static const warning = Color(0xFFFFB020);     // Orange (attention)
static const warningBg = Color(0x1AFFAA00);   

static const danger = Color(0xFFFF2D55);      // Rouge (erreurs, destructif)
static const dangerBg = Color(0x1AFF2D55);    

static const info = Color(0xFF4C7AFF);        // Bleu (info)
static const infoBg = Color(0x1A4C7AFF);      
```

**Tableau d'usage** :

| Contexte | Couleur | Exemple |
|----------|---------|---------|
| Match validé | success | "✓ Score validé" |
| Paiement reçu | success | "✓ +5 000 XAF" |
| Match en cours | info (bleu) | "● En cours..." |
| Match en attente | warning | "⏳ En attente" |
| Match perdu | textMuted | Style atténué |
| Litige ouvert | danger | "⚠ Litige" |
| LIVE streaming | danger (pulsant) | "🔴 LIVE" |

### Texte

```dart
// === TEXT ===
static const text = Color(0xFFF5F5F0);        // Blanc cassé (texte principal)
static const textMuted = Color(0xFF8B8B95);   // Gris clair (secondaire)
static const textFaint = Color(0xFF5A5A65);   // Gris foncé (tertiaire, placeholders)
static const textDisabled = Color(0xFF3A3F4D); // Texte désactivé
```

**Hiérarchie typographique** :

```
HEADER : text (blanc cassé)        ← Titres importants
Body : text (blanc cassé)          ← Texte principal
Description : textMuted (gris)     ← Secondaire
Hint : textFaint (gris foncé)      ← Placeholders, footers
Disabled : textDisabled            ← Champs désactivés
```

### Borders & Dividers

```dart
// === BORDERS ===
static const border = Color(0x264C7AFF);      // Bleu 15% (bordures cards primary)
static const borderMuted = Color(0x1A8A93A6); // Gris 10% (dividers neutres)
static const borderStrong = Color(0xFF2A2D3A); // Gris foncé (séparateurs visibles)
```

## 🌈 Couleurs d'avatar (générées)

8 couleurs prédéfinies pour les avatars utilisateurs :

```dart
static const avatarColors = [
  Color(0xFF4C7AFF), // Blue
  Color(0xFFFF2D55), // Red
  Color(0xFF00C896), // Green
  Color(0xFFFFB020), // Orange
  Color(0xFF00B4D8), // Cyan
  Color(0xFFB45CFF), // Purple
  Color(0xFFFF6A1A), // Orange-red
  Color(0xFFFFE629), // Yellow
];
```

L'utilisateur choisit sa couleur à l'inscription. Stockée dans `profiles.avatar_color`.

---

# 3. Typographie

## 🔤 Polices imposées (3 fonts seulement)

```dart
// pubspec.yaml
dependencies:
  google_fonts: ^6.1.0
```

```dart
import 'package:google_fonts/google_fonts.dart';

class ArenaTypography {
  // === ORBITRON — Headers, titres impactants ===
  static TextStyle displayLarge = GoogleFonts.orbitron(
    fontSize: 32,
    fontWeight: FontWeight.w800,
    letterSpacing: 3,
    color: ArenaColors.text,
  );
  
  static TextStyle headlineLarge = GoogleFonts.orbitron(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    letterSpacing: 2,
    color: ArenaColors.text,
  );
  
  static TextStyle headlineMedium = GoogleFonts.orbitron(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    letterSpacing: 1.5,
    color: ArenaColors.text,
  );
  
  // === NUNITO — Body, paragraphes, boutons ===
  static TextStyle titleLarge = GoogleFonts.nunito(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    color: ArenaColors.text,
  );
  
  static TextStyle titleMedium = GoogleFonts.nunito(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: ArenaColors.text,
  );
  
  static TextStyle bodyLarge = GoogleFonts.nunito(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: ArenaColors.text,
    height: 1.5,
  );
  
  static TextStyle bodyMedium = GoogleFonts.nunito(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: ArenaColors.text,
    height: 1.4,
  );
  
  static TextStyle bodySmall = GoogleFonts.nunito(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: ArenaColors.textMuted,
    height: 1.3,
  );
  
  static TextStyle labelLarge = GoogleFonts.nunito(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.5,
    color: ArenaColors.text,
  );
  
  // === FIRA CODE — Codes room, codes invitation, scores numériques ===
  static TextStyle codeRoom = GoogleFonts.firaCode(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    letterSpacing: 4,
    color: ArenaColors.efootball, // Cyan pour codes room
  );
  
  static TextStyle invitationCode = GoogleFonts.firaCode(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    letterSpacing: 2,
    color: ArenaColors.text,
  );
  
  static TextStyle scoreLarge = GoogleFonts.firaCode(
    fontSize: 48,
    fontWeight: FontWeight.w800,
    color: ArenaColors.text,
  );
}
```

## 📏 Tableau d'usage

| Style | Police | Taille | Poids | Usage |
|-------|--------|--------|-------|-------|
| `displayLarge` | Bebas Neue | 32 | 800 | Splash logo, gros impacts |
| `headlineLarge` | Bebas Neue | 28 | 700 | Titres pages principales |
| `headlineMedium` | Bebas Neue | 22 | 700 | Titres sections |
| `titleLarge` | Space Grotesk | 20 | 700 | Titres cards |
| `titleMedium` | Space Grotesk | 16 | 600 | Sous-titres |
| `bodyLarge` | Space Grotesk | 16 | 400 | Texte principal |
| `bodyMedium` | Space Grotesk | 14 | 400 | Descriptions, paragraphes |
| `bodySmall` | Space Grotesk | 12 | 400 | Captions, footers, hints |
| `labelLarge` | Space Grotesk | 14 | 700 | Boutons, labels CTA |
| `codeRoom` | JetBrains Mono | 24 | 700 | **Codes room cyan** |
| `invitationCode` | JetBrains Mono | 16 | 600 | Codes admin invitation |
| `scoreLarge` | JetBrains Mono | 48 | 800 | Scores match (3-2) |

## 🚫 Règles strictes

- ❌ **JAMAIS d'autres polices** que Bebas Neue, Space Grotesk, JetBrains Mono
- ❌ **JAMAIS de tailles arbitraires** (toujours utiliser les styles définis)
- ❌ **JAMAIS de underline** (sauf liens explicites)
- ❌ **JAMAIS de italic** (gardé pour citations exceptionnelles)
- ✅ **Letter-spacing positif** sur Bebas Neue (look futuriste)
- ✅ **Line-height 1.4-1.5** sur Space Grotesk (lisibilité)

---

# 4. Spacing & Layout

## 📐 Système d'espacement (multiples de 4)

```dart
class ArenaSpacing {
  static const double xxs = 2;
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;  // Standard
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
  static const double xxxl = 64;
}
```

## 🎯 Règles d'usage

| Contexte | Spacing |
|----------|---------|
| Padding intérieur card | `md` (16) |
| Padding écran (horizontal) | `md` (16) |
| Padding entre sections | `lg` (24) |
| Marge entre 2 cards verticales | `md` (16) |
| Marge entre 2 boutons | `sm` (8) |
| Padding haut écran (sous AppBar) | `lg` (24) |
| Padding bas écran (au-dessus BottomNav) | `xxl` (48) |
| Hauteur boutons | 48 ou 56 |
| Hauteur AppBar | 56 |

## 📦 Border Radius

```dart
class ArenaRadius {
  static const double sm = 8;     // Petits éléments (chips, badges)
  static const double md = 12;    // Boutons, inputs
  static const double lg = 16;    // Cards
  static const double xl = 24;    // Modals, sheets
  static const double round = 999; // Avatars, pills
}
```

## 📱 Layout grid

```
┌──────────────────────────────────────┐
│ Status bar                       │
├──────────────────────────────────────┤
│ AppBar (56dp)                        │
├──────────────────────────────────────┤
│ ◀── 16dp padding horizontal ─▶      │
│                                      │
│  [Section 1]                         │
│                                      │
│  ◀ 24dp gap ▶                       │
│                                      │
│  [Section 2]                         │
│                                      │
│  ◀ 24dp gap ▶                       │
│                                      │
│  [Section 3]                         │
│                                      │
├──────────────────────────────────────┤
│ Bottom Navigation (60dp)             │
├──────────────────────────────────────┤
│ Safe area iOS                        │
└──────────────────────────────────────┘
```

---

# 5. Composants core

## 🔘 Boutons

### `ArenaButton` — Bouton principal

3 variants stricts :

```dart
enum ArenaButtonVariant { primary, secondary, danger }

// Primary (bouton principal action)
ArenaButton(
  label: 'Se connecter',
  variant: ArenaButtonVariant.primary,
  onPressed: () {},
)
```

**Specs visuelles** :

| Variant | Background | Text | Border | Use case |
|---------|-----------|------|--------|----------|
| **Primary** | `primary` (#4C7AFF) | white | none | Action principale (Submit, Continue, S'inscrire) |
| **Secondary** | transparent | `primary` | 1.5px `primary` | Action secondaire (Annuler, Voir plus) |
| **Danger** | `danger` (#FF2D55) | white | none | Action destructive (Supprimer, Forfait) |
| **Ghost** | transparent | `text` | none | Action légère (Skip, Annuler dans modal) |

**Specs dimensionnelles** :
- Hauteur : **48dp** (standard) ou **56dp** (call-to-action important)
- Padding horizontal : **24dp**
- Border radius : **12dp** (md)
- Font : `labelLarge` (Space Grotesk 14, 700)
- Min width : 120dp
- Disabled : opacity 0.5

**États** :
- **Normal** : couleur de base
- **Hover** (pas mobile mais web admin) : -10% lightness
- **Pressed** : scale 0.95 + opacity 0.8
- **Loading** : remplace texte par `CircularProgressIndicator` (size 20)
- **Disabled** : opacity 0.5, pas de pressed feedback

### Code template

```dart
class ArenaButton extends StatelessWidget {
  final String label;
  final ArenaButtonVariant variant;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final double height;
  
  const ArenaButton({
    super.key,
    required this.label,
    required this.variant,
    this.onPressed,
    this.isLoading = false,
    this.icon,
    this.height = 48,
  });
  
  @override
  Widget build(BuildContext context) {
    // Implementation selon variant
  }
}
```

## 🃏 Cards

### `ArenaCard` — Card standard

**Specs** :
- Background : `surface` (#14141C)
- Border radius : `lg` (16dp)
- Padding intérieur : `md` (16dp)
- Border : optionnelle, `border` (#264C7AFF)
- Shadow : aucune (dark theme = pas de shadow)
- Margin externe : géré par le parent (jamais dans le widget)

```dart
ArenaCard(
  child: Column(...),
)

ArenaCard.outlined( // avec bordure subtile
  child: Column(...),
)

ArenaCard.elevated( // surface plus claire
  child: Column(...),
)
```

### Cards spécialisées

#### `CompetitionCard`
- Bordure gauche **4dp** colorée selon le jeu (cyan/orange/orange-red)
- Image jeu en background (opacity 30%)
- Nom + status badge

```
┌──────────────────────────────────────┐
│ ▎ ★ Cameroon eFootball Cup         │ ← bordure cyan
│ ▎ 12/16 joueurs                    │
│ ▎ 25 000 XAF cagnotte              │
│ ▎ [Open for registration] badge     │
└──────────────────────────────────────┘
```

#### `MatchCard`
- 2 avatars + scores
- Status (pending, in_progress, validated, disputed)
- Action contextuelle

```
┌──────────────────────────────────────┐
│  🔵 Joueur1    3 - 2    Joueur2 🔴  │
│      [✓ Validé]                      │
└──────────────────────────────────────┘
```

#### `StreamCard`
- Preview thumbnail
- Badge "🔴 LIVE" + viewers count
- Joueurs vs joueurs

## 📝 Inputs

### `ArenaTextField`

**Specs** :
- Background : `surfaceLight` (#1A1D2A)
- Border : 1px `borderMuted` au repos, 2px `primary` au focus
- Border radius : `md` (12dp)
- Padding : 16dp horizontal, 14dp vertical
- Hauteur : 52dp
- Font : `bodyLarge` (Space Grotesk 16, 400)
- Placeholder : `textFaint`

**États** :
- **Empty** : placeholder affiché, label flottant en haut au focus
- **Focused** : border `primary` 2px
- **Filled** : valeur affichée
- **Error** : border `danger` + message rouge sous le champ
- **Disabled** : opacity 0.5

```dart
ArenaTextField(
  label: 'Email',
  hintText: 'tonemail@exemple.com',
  controller: _emailController,
  validator: (value) => /* ... */,
  prefixIcon: Icons.email_outlined,
)
```

### Variants spéciaux

- `ArenaPasswordField` : avec icône oeil pour show/hide
- `ArenaSearchField` : avec icône loupe à gauche + clear à droite
- `ArenaPhoneField` : avec préfixe pays + flag
- `ArenaCodeField` : pour OTP (6 cases séparées)

## 🏷️ Badges & Chips

### `StatusBadge`

```dart
StatusBadge(
  label: 'En cours',
  type: BadgeType.info,
)
```

**Variants** :

| Type | Background | Text | Usage |
|------|-----------|------|-------|
| `success` | `successBg` (10%) | `success` | "Validé", "Versé" |
| `info` | `infoBg` | `info` | "En cours", "Inscrit" |
| `warning` | `warningBg` | `warning` | "En attente" |
| `danger` | `dangerBg` | `danger` | "Litige", "Échec" |
| `live` | `dangerBg` + animation pulse | `danger` | "🔴 LIVE" |
| `neutral` | `borderMuted` | `textMuted` | "Terminé", "Annulé" |

**Specs** :
- Padding : 8 horizontal, 4 vertical
- Border radius : `sm` (8dp)
- Font : `bodySmall` (Space Grotesk 12, 600)
- Text-transform : uppercase

## 👤 Avatar

```dart
ArenaAvatar(
  username: 'Player1',
  color: '#4C7AFF',
  size: AvatarSize.md,
  showOnlineIndicator: true, // Point vert si online
)
```

**Tailles** :
- `sm` : 32dp (chats, listes)
- `md` : 48dp (cards standards)
- `lg` : 80dp (header profile)
- `xl` : 120dp (detail profile)

**Logique** :
- Pas de photo en V1.0 (juste couleur)
- Affiche initiale du username (1ère lettre majuscule)
- Background = `avatar_color` du profile
- Texte blanc
- Border radius : `round` (cercle parfait)

## 🎯 Boutons spéciaux

### `FloatingAntiCheatButton` — Le bouton flottant anti-triche

**LE bouton iconique d'ARENA** (PHASE 8). Affiché par-dessus eFootball pendant un match.

**Specs visuelles** :
- Forme : cercle parfait
- Taille : **72dp**
- Background : gradient radial `danger` → `secondaryDark`
- Border : 2dp `text` (blanc cassé)
- Logo ARENA centré (blanc, 32dp)
- Timer MM:SS sous le logo (JetBrains Mono, 12, 700)
- Animation : pulsation rouge subtile (0.95 → 1.0 toutes les 2s)
- Shadow : `0 0 16px rgba(255, 61, 90, 0.5)` (lueur rouge)

**Specs comportementales** :
- Position initiale : right + center vertical
- Drag : se colle au bord le plus proche (snap)
- Tap court : ramène ARENA en focus
- Tap long : dialogue 3 options

```
       ╭─────────╮
      ╱           ╲
     │   ⚔ ARENA  │   ← Logo blanc centré
     │   05:42    │   ← Timer en JetBrains Mono
      ╲           ╱
       ╰─────────╯
       ↑ pulsation
```

---

# 6. Patterns & règles d'écran

## 📱 Structure standard d'un écran

```dart
Scaffold(
  backgroundColor: ArenaColors.bg,        // Toujours bg
  appBar: ArenaAppBar(...),              // Custom AppBar
  body: SafeArea(
    child: Padding(
      padding: EdgeInsets.symmetric(horizontal: ArenaSpacing.md),
      child: ListView(  // ou Column avec SingleChildScrollView
        children: [
          SizedBox(height: ArenaSpacing.lg),
          // Sections
        ],
      ),
    ),
  ),
  bottomNavigationBar: showBottomNav ? ArenaBottomNavBar() : null,
)
```

## 🎨 AppBar standard

**Specs** :
- Hauteur : 56dp
- Background : `bg` (transparent visuel)
- Title : `headlineMedium` (Bebas Neue 22, 700)
- Icons : 24dp, color `text`
- Pas de shadow
- Pas de border bottom

```dart
ArenaAppBar(
  title: 'Compétitions',
  leading: IconButton(  // ou null sur HomePage
    icon: Icon(Icons.arrow_back),
    onPressed: () => context.pop(),
  ),
  actions: [
    IconButton(
      icon: Icon(Icons.search),
      onPressed: () {},
    ),
  ],
)
```

## 🧭 Bottom Navigation Bar

**Visible sur** : HomePage, CompetitionsListPage, MessagesInboxPage, PlayerProfilePage (4 tabs uniquement)

**Specs** :
- Hauteur : 60dp + safe area
- Background : `surface` (#14141C)
- Border top : 1px `borderMuted`
- 4 items :
  1. Home (icône `home_rounded`)
  2. Compétitions (icône `emoji_events`)
  3. Chat (icône `chat_bubble_rounded`) + badge unread
  4. Profil (avatar du user)

**Active state** :
- Icône color : `primary`
- Label color : `primary`
- Background : transparent (pas de pill)

**Inactive state** :
- Icône color : `textMuted`
- Label color : `textMuted`

## 📋 Listes

### Pattern liste verticale standard

```dart
ListView.separated(
  padding: EdgeInsets.symmetric(vertical: ArenaSpacing.md),
  itemCount: items.length,
  separatorBuilder: (_, __) => SizedBox(height: ArenaSpacing.md), // 16dp
  itemBuilder: (context, index) => CompetitionCard(...),
)
```

**Règles** :
- Toujours `separatorBuilder` (jamais Padding manuel dans les items)
- Toujours pull-to-refresh sur les listes principales
- Toujours empty state si liste vide
- Toujours skeleton loader pendant le chargement initial

## 📐 Forms

### Pattern form standard

```dart
Form(
  key: _formKey,
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      ArenaTextField(label: 'Email', ...),
      SizedBox(height: ArenaSpacing.md),  // 16dp entre champs
      
      ArenaPasswordField(label: 'Mot de passe', ...),
      SizedBox(height: ArenaSpacing.lg),  // 24dp avant bouton
      
      ArenaButton(
        label: 'Se connecter',
        variant: ArenaButtonVariant.primary,
        height: 56,  // Bouton final = 56dp
        onPressed: _onSubmit,
      ),
    ],
  ),
)
```

**Règles** :
- Toujours validation à la soumission (pas pendant la saisie sauf email)
- Toujours `autovalidateMode: AutovalidateMode.onUserInteraction`
- Toujours désactiver bouton submit si form invalide
- Toujours `loading state` sur le bouton pendant la requête

## 🎬 Modals & Dialogs

### `ArenaDialog` standard

```dart
showArenaDialog(
  context: context,
  title: 'Confirmer la suppression',
  description: 'Cette action est irréversible.',
  confirmLabel: 'Supprimer',
  confirmVariant: ArenaButtonVariant.danger,
  cancelLabel: 'Annuler',
  onConfirm: () {},
)
```

**Specs** :
- Background : `surfaceLight` (#1A1D2A)
- Border radius : `xl` (24dp)
- Padding : 24dp
- Largeur max : 400dp (limite sur web admin)
- Backdrop : `bg.withOpacity(0.7)` + blur 8px
- Animation : scale 0.95 → 1.0 + fade

### Bottom Sheet

```dart
showArenaBottomSheet(
  context: context,
  child: PaymentMethodPicker(),
)
```

**Specs** :
- Background : `surface`
- Border radius top : `xl` (24dp)
- Drag handle : 40x4dp gris en haut
- Padding : 24dp
- Max height : 80% écran

---

# 7. Animations & micro-interactions

## ⚡ Règles globales

| Règle | Valeur |
|-------|--------|
| Durée standard | **200ms** |
| Durée modale | **300ms** |
| Durée transitions de page | **350ms** |
| Curve standard | `Curves.easeOutCubic` |
| Curve bouncy (rare) | `Curves.elasticOut` |
| FPS cible | **60 FPS** (jamais en dessous) |

## 🎭 Animations recommandées

### Boutons
- **Tap** : scale 1.0 → 0.95 (100ms in) → 1.0 (100ms out)
- **Loading** : remplace label par spinner (fade 200ms)

### Cards
- **Tap** : scale 1.0 → 0.97 → 1.0
- **Apparition liste** : staggered slide-up + fade (50ms delay par item, max 8 items)

### Page transitions
- Default : slide horizontal (depuis la droite)
- Modal : slide vertical (depuis le bas)
- Tab switch : fade + slide subtil

### Indicateurs LIVE
- Badge "🔴 LIVE" : pulsation infinie (1.0 → 1.1 → 1.0, 2s)
- Background pulse : opacity 0.3 → 0.7 → 0.3

### Bouton flottant anti-cheat
- Pulsation continue : scale 0.95 → 1.0 (2s loop)
- Drag : suit le doigt avec inertia
- Snap to edge : 250ms easeOutCubic

## 🚫 Animations à BANNIR

- ❌ Bounce excessif (pas Disney)
- ❌ Animations > 500ms (sauf intro splash)
- ❌ Multiple animations simultanées (max 2)
- ❌ Animations qui bloquent l'interaction

---

# 8. Loading, Empty, Error states

## ⏳ Loading

### Loading global (initial)

```dart
ArenaLoadingIndicator(
  message: 'Chargement des compétitions...',
)
```

- Spinner `primary` (24dp)
- Message en `bodyMedium`
- Centré dans l'écran

### Skeleton loader (recommandé pour listes)

```dart
ArenaSkeleton(
  count: 5,
  itemHeight: 80,
)
```

- Shimmer effect : `surface` → `surfaceLight` → `surface`
- Durée : 1.5s loop
- Forme respecte la card finale

### Loading dans un bouton

Le bouton remplace son label par un `CircularProgressIndicator` 20dp blanc.

## 📭 Empty state

```dart
EmptyState(
  icon: Icons.emoji_events_outlined,
  title: 'Aucune compétition',
  description: 'Reviens bientôt, on en prépare !',
  actionLabel: 'Rafraîchir',
  onAction: () => _refresh(),
)
```

**Specs** :
- Icône : 80dp, `textFaint`
- Title : `titleLarge`, `text`
- Description : `bodyMedium`, `textMuted`
- Bouton : `secondary` variant
- Centré verticalement
- Margin horizontal 32dp

## ❌ Error state

```dart
ErrorState(
  message: 'Une erreur est survenue',
  errorDetail: e.toString(), // optionnel
  onRetry: () => _retry(),
)
```

**Specs** :
- Icône : `Icons.error_outline_rounded`, 80dp, `danger`
- Message principal : `titleLarge`
- Détail (optionnel) : `bodySmall`, `textFaint`
- Bouton "Réessayer" : `primary` variant

## 🌐 No internet state

```dart
NoInternetBanner() // affiché en haut de l'app
```

- Background : `warning`
- Icône wifi off
- Message "Connexion perdue"
- Auto-disparaît quand reconnexion

---

# 9. Iconographie

## 🎨 Bibliothèque d'icônes

**Une seule source** : Material Icons (Flutter natif).

**Pourquoi** :
- ✅ Disponible offline
- ✅ Cohérent
- ✅ Léger
- ✅ Rich library

## 📏 Tailles standard

| Contexte | Taille |
|----------|--------|
| AppBar actions | 24dp |
| Bottom Nav | 28dp |
| Boutons (avec icône) | 20dp |
| Cards | 24dp |
| Empty states | 80dp |
| Tabs | 20dp |
| Badge counts | 16dp |

## 🎯 Mapping icônes par contexte

```dart
class ArenaIcons {
  // Navigation
  static const home = Icons.home_rounded;
  static const compete = Icons.emoji_events_rounded;
  static const chat = Icons.chat_bubble_rounded;
  static const profile = Icons.person_rounded;
  
  // Actions
  static const back = Icons.arrow_back_rounded;
  static const close = Icons.close_rounded;
  static const search = Icons.search_rounded;
  static const filter = Icons.tune_rounded;
  static const more = Icons.more_vert_rounded;
  static const edit = Icons.edit_rounded;
  static const delete = Icons.delete_outline_rounded;
  
  // States
  static const success = Icons.check_circle_rounded;
  static const error = Icons.error_rounded;
  static const warning = Icons.warning_rounded;
  static const info = Icons.info_rounded;
  static const live = Icons.live_tv_rounded;
  
  // Auth
  static const email = Icons.email_outlined;
  static const lock = Icons.lock_outline_rounded;
  static const visibilityOn = Icons.visibility_rounded;
  static const visibilityOff = Icons.visibility_off_rounded;
  
  // Match
  static const trophy = Icons.emoji_events_rounded;
  static const recording = Icons.fiber_manual_record_rounded;
  static const stream = Icons.live_tv_rounded;
  static const score = Icons.scoreboard_rounded;
  
  // Money
  static const wallet = Icons.account_balance_wallet_rounded;
  static const moneyIn = Icons.add_circle_rounded;
  static const moneyOut = Icons.remove_circle_rounded;
  static const card = Icons.credit_card_rounded;
  static const mobileMoney = Icons.phone_android_rounded;
  static const crypto = Icons.currency_bitcoin_rounded;
  
  // Settings
  static const settings = Icons.settings_rounded;
  static const language = Icons.language_rounded;
  static const notifications = Icons.notifications_rounded;
  static const privacy = Icons.privacy_tip_rounded;
  static const logout = Icons.logout_rounded;
}
```

## 🚫 Règles

- ❌ **JAMAIS d'emojis** dans le code (sauf "🔴 LIVE", "✓", "✗")
- ❌ **JAMAIS de PNG/SVG** custom (sauf pour le logo ARENA)
- ✅ **TOUJOURS** utiliser `_rounded` ou `_outlined` (cohérence)
- ✅ **TOUJOURS** importer depuis `ArenaIcons` (centralisation)

---

# 10. Accessibilité

## ♿ Règles WCAG 2.1 AA minimum

### Contraste
- ✅ Texte sur background : ratio min **4.5:1**
- ✅ Texte large (18+) : ratio min **3:1**

**Vérification rapide** :
- `text` (#F5F5F0) sur `bg` (#0A0A0F) = **15:1** ✅
- `textMuted` (#8B8B95) sur `bg` (#0A0A0F) = **6:1** ✅
- `textFaint` (#5A5A65) sur `bg` (#0A0A0F) = **2.8:1** ❌ (uniquement pour décoration)

### Touch targets
- Min **44x44dp** pour tous les éléments tappables (Apple guideline)
- Boutons : 48dp minimum
- IconButtons : 48dp (même si l'icône est 24dp)

### Semantics

```dart
Semantics(
  label: 'Bouton se connecter',
  hint: 'Double-tap pour vous connecter',
  child: ArenaButton(...),
)
```

**Règles** :
- Tous les boutons doivent avoir un `label` accessible
- Toutes les icônes-only doivent avoir une description
- Tous les états (loading, error) doivent être annoncés

### Tailles texte

- Respecter le **text scale factor** du device (sans casser le layout)
- Utiliser `MediaQuery.textScaleFactor` quand nécessaire
- Tester avec scale 1.5x

---

# 11. Différences User vs Admin

## 🔵 App User

| Aspect | Valeur |
|--------|--------|
| Couleur primary | `primary` (#4C7AFF — bleu) |
| Logo | ARENA (bleu) |
| Bottom nav | Visible (4 tabs) |
| Densité info | Légère (focus action) |
| Animations | Présentes (engagement) |
| Tone copy | Friendly, encourageant |

## 🔴 App Admin

| Aspect | Valeur |
|--------|--------|
| Couleur primary | `secondary` (#FF2D55 — rouge) |
| Logo | ARENA Admin (rouge) |
| Bottom nav | ❌ Pas de bottom nav (sidebar sur web) |
| Densité info | Élevée (data-heavy) |
| Animations | Réduites (pro tool) |
| Tone copy | Direct, factuel |

### Adaptations web admin

L'app Admin est responsive (mobile + web) via `flutter_adaptive_scaffold` :

```dart
AdaptiveScaffold(
  destinations: [
    NavigationDestination(icon: Icon(...), label: 'Dashboard'),
    // ...
  ],
  body: (context) => MainContent(),
  smallBody: (context) => MainContent(), // Mobile : pleine largeur
)
```

**Layout web (>900dp)** :
- Sidebar gauche fixe (250dp)
- Contenu principal scrollable
- Tables avec plus de colonnes
- Modals plus larges (600dp max)

**Layout mobile (<600dp)** :
- Pas de sidebar (drawer)
- Scrolling vertical
- Tables → cards verticales

---

# 12. Anti-patterns (À NE JAMAIS FAIRE)

## 🚫 Couleurs

- ❌ **Hardcoder une couleur** : `Color(0xFFFF0000)` → utiliser `ArenaColors.danger`
- ❌ **Mélanger primary user et admin** : pas de bleu dans l'admin (sauf info badges)
- ❌ **Light theme** : ARENA est dark exclusive V1.0
- ❌ **Couleur game sur autre chose** : cyan eFootball uniquement pour eFootball, pas pour les boutons

## 🚫 Typographie

- ❌ **Utiliser une autre police** : seulement Bebas Neue, Space Grotesk, JetBrains Mono
- ❌ **Tailles arbitraires** : `fontSize: 17` → utiliser un style de `ArenaTypography`
- ❌ **Bold sur Bebas Neue** : déjà épais, pas besoin de doubler
- ❌ **Italic** : interdit (sauf citations rares)

## 🚫 Layout

- ❌ **Padding négatif** : signe d'un mauvais layout
- ❌ **Hardcoder du spacing** : `SizedBox(height: 17)` → `ArenaSpacing.md`
- ❌ **Listes sans séparateur** : utiliser `ListView.separated`
- ❌ **Stack pour empilement vertical** : utiliser `Column`

## 🚫 Composants

- ❌ **Créer un nouveau bouton custom** : utiliser `ArenaButton` (étendre si nécessaire)
- ❌ **Background blanc** : tout est dark, jamais de blanc en background
- ❌ **Shadows sur dark theme** : ne se voient pas, pas utile
- ❌ **Borders sur tout** : épure, juste là où c'est nécessaire

## 🚫 UX

- ❌ **Naviguer sans loading state** : toujours montrer qu'il se passe quelque chose
- ❌ **Boutons "OK" / "Cancel"** : toujours des verbes d'action ("Supprimer", "Confirmer", "Réessayer")
- ❌ **Erreurs techniques user** : "Error 500" → "Impossible de charger. Réessaie."
- ❌ **Modals à 3 niveaux** : max 1 modal ouvert à la fois
- ❌ **Confirmer 2x sur des actions non destructives** : "Veux-tu vraiment ouvrir cette page ?" non

## 🚫 Code

- ❌ **Couleurs en string** : `'#4C7AFF'` → utiliser `Color`
- ❌ **Magic numbers** : `EdgeInsets.all(13)` → constantes
- ❌ **InlineStyles partout** : créer des widgets réutilisables si pattern répété 2x+

---

# 📋 Checklist UI pour chaque écran

À cocher AVANT de marquer un écran comme "fini" :

## Visual
- [ ] Background = `ArenaColors.bg`
- [ ] Aucune couleur hardcodée (toutes via `ArenaColors`)
- [ ] Polices respectent le système (3 polices uniquement)
- [ ] Border radius cohérents (sm/md/lg/xl)
- [ ] Spacing utilise `ArenaSpacing` (pas de magic numbers)

## Composants
- [ ] Boutons utilisent `ArenaButton` (avec bon variant)
- [ ] Cards utilisent `ArenaCard` ou variants
- [ ] Inputs utilisent `ArenaTextField`
- [ ] Avatars utilisent `ArenaAvatar`
- [ ] Badges utilisent `StatusBadge`

## States
- [ ] Loading state implémenté (spinner ou skeleton)
- [ ] Empty state implémenté (avec icône + message + CTA)
- [ ] Error state implémenté (avec retry)
- [ ] Disabled states correct

## Interactions
- [ ] Animations respectent les durées (200ms standard)
- [ ] Tap feedback présent sur tous les éléments interactifs
- [ ] Pull-to-refresh sur listes
- [ ] Scroll smooth (pas de jank)

## Accessibilité
- [ ] Contraste min 4.5:1 sur le texte
- [ ] Touch targets min 44dp
- [ ] Semantics labels sur boutons icon-only
- [ ] Compatible avec text scale factor

## Responsive
- [ ] Testé sur petit écran (375dp width)
- [ ] Testé sur grand écran (414dp width)
- [ ] Pas d'overflow visible

## Cohérence
- [ ] Respect de l'app (User=bleu, Admin=rouge)
- [ ] Tone copy cohérent (FR pour V1.0)
- [ ] Icons depuis `ArenaIcons`

---

# 🎯 Comment utiliser ce document avec Claude Code

## Cas 1 — Création d'un nouvel écran

```
Salut Claude.

📚 Lectures obligatoires :
1. ARENA_UI_GUIDE.md (CE DOCUMENT)
2. ARENA_54_ECRANS.md section "Écran #X"

🎯 Crée l'écran [XxxPage] en respectant STRICTEMENT le design system.

⚠️ Règles non négociables :
- Toutes les couleurs depuis ArenaColors
- Toutes les polices depuis ArenaTypography
- Tous les spacing depuis ArenaSpacing
- Boutons via ArenaButton
- Cards via ArenaCard
- Inputs via ArenaTextField
- Loading + Empty + Error states obligatoires

Avant de coder, dis-moi :
1. Quels composants tu vas utiliser
2. Quels states (loading, empty, error) tu prévois
3. Demande-moi mon GO
```

## Cas 2 — Audit visuel d'un écran existant

```
Salut Claude.

📚 Lis ARENA_UI_GUIDE.md (sections "Anti-patterns" + "Checklist UI")

🎯 Audit visuel de [path/to/screen.dart]

Vérifie :
1. Couleurs hardcodées (Color(0xFFXXX) au lieu de ArenaColors.X)
2. Polices non standard
3. Magic numbers (spacings, sizes)
4. Composants custom au lieu des widgets de base
5. States manquants (loading, empty, error)
6. Anti-patterns détectés

Rapport-moi les violations sans modifier.
```

## Cas 3 — Création des widgets de base

```
Salut Claude.

📚 Lis ARENA_UI_GUIDE.md sections 5 et 6

🎯 Crée tous les widgets de base d'ARENA :
- lib/core/theme/arena_colors.dart
- lib/core/theme/arena_typography.dart
- lib/core/theme/arena_spacing.dart
- lib/core/theme/arena_radius.dart
- lib/core/theme/arena_icons.dart
- lib/core/theme/arena_theme.dart

- lib/features_shared/widgets/arena_button.dart
- lib/features_shared/widgets/arena_card.dart
- lib/features_shared/widgets/arena_text_field.dart
- lib/features_shared/widgets/arena_avatar.dart
- lib/features_shared/widgets/status_badge.dart
- lib/features_shared/widgets/arena_app_bar.dart
- lib/features_shared/widgets/empty_state.dart
- lib/features_shared/widgets/error_state.dart
- lib/features_shared/widgets/arena_loading_indicator.dart

Crée aussi une page de "preview" pour tester visuellement tous les widgets.
Procède widget par widget, demande-moi de tester avant de continuer.
```

## Cas 4 — Refonte d'un écran existant

```
Salut Claude.

📚 Lis ARENA_UI_GUIDE.md + ARENA_54_ECRANS.md section "Écran #X"

🎯 Refonte complète de [path/to/screen.dart] pour aligner sur le design system.

Étapes :
1. Identifier tous les anti-patterns (sans modifier)
2. Me lister les changements proposés
3. Demander mon GO
4. Refactoriser
5. Tester avec moi

Préserve la logique métier, change uniquement l'UI.
```

---

# 🎨 Appendix — Exemples visuels

## Exemple 1 — HomePage layout

```
┌──────────────────────────────────────┐
│  ⚔ ARENA              🔔 (3)         │ ← AppBar (Bebas Neue 22)
│                                      │
│  Salut, Player1 !                    │ ← headlineMedium
│  Tu as 1 match dans 5 min ⚡          │ ← bodyMedium textMuted
├──────────────────────────────────────┤
│                                      │ ← gap lg (24)
│  📅 PROCHAINS MATCHS                 │ ← labelLarge uppercase
│  ╔══════════════════════════════╗   │
│  ║  🔵 Toi vs 🔴 Adversaire    ║   │ ← MatchCard
│  ║  eFootball · dans 5 min      ║   │
│  ╚══════════════════════════════╝   │
│                                      │ ← gap lg
│  🔴 LIVE EN COURS                    │
│  ╔══════════════════════════════╗   │
│  ║  ▶ Cameroon Cup Finale       ║   │ ← StreamCard
│  ║  👁 245 viewers              ║   │
│  ╚══════════════════════════════╝   │
│                                      │
│  🏆 COMPÉTITIONS ACTIVES             │
│  ┌────────────────────────────┐    │
│  │ ▎eFootball Tournament      │    │ ← CompetitionCard
│  │ ▎12/16 · 25 000 XAF        │    │
│  └────────────────────────────┘    │
│  ┌────────────────────────────┐    │
│  │ ▎FIFA Mobile Cup           │    │
│  │ ▎8/16 · 15 000 XAF         │    │
│  └────────────────────────────┘    │
│                                      │
├──────────────────────────────────────┤
│  🏠   🏆   💬(3)   👤              │ ← Bottom Nav
└──────────────────────────────────────┘
```

## Exemple 2 — MatchRoomPage étape 1

```
┌──────────────────────────────────────┐
│  ←  Match Room              ⚙       │
├──────────────────────────────────────┤
│                                      │
│  Étape 1 / 4 — Code Room            │ ← labelLarge primary
│  ●─○─○─○                             │ ← Stepper visual
│                                      │
│  ┌──────────────────────────────┐  │
│  │  🔵 Player1 (Toi - HOME)     │  │ ← User card
│  │     Crée la room eFootball   │  │
│  └──────────────────────────────┘  │
│                                      │
│         VS                          │
│                                      │
│  ┌──────────────────────────────┐  │
│  │  🔴 Adversaire (AWAY)        │  │
│  │     En attente du code...    │  │
│  └──────────────────────────────┘  │
│                                      │
│  ⏱ Temps restant : 04:32           │ ← Timer warning
│                                      │
│  Code room eFootball :              │
│  ┌──────────────────────────────┐  │
│  │  XYZ123                       │  │ ← codeRoom (JetBrains Mono 24, cyan)
│  └──────────────────────────────┘  │
│                                      │
│  [   ENVOYER LE CODE   ]            │ ← ArenaButton primary 56h
│                                      │
└──────────────────────────────────────┘
```

## Exemple 3 — AdminPayoutsPage

```
┌──────────────────────────────────────┐
│  ←  Validation Payouts        🔔    │
├──────────────────────────────────────┤
│                                      │
│  ⚠ 4 payouts en attente             │
│  Total : 100 000 XAF                │
│                                      │
│  ┌────────────────────────────────┐│
│  │ 🟦 Player1 — Cameroon Cup      ││
│  │ Position : 1er                  ││
│  │ Montant : 50 000 XAF            ││
│  │ ─────────────────────────────  ││
│  │ ✓ KYC vérifié                   ││
│  │ ✓ Pas de litige                 ││
│  │ ✓ Pas d'alerte anti-cheat       ││
│  │ ✓ Compte actif                  ││
│  │ ✓ MoMo valide                   ││
│  │ ─────────────────────────────  ││
│  │ [   VALIDER   ]                 ││ ← ArenaButton success
│  └────────────────────────────────┘│
│                                      │
│  ┌────────────────────────────────┐│
│  │ 🟥 Player2 — FIFA Cup          ││
│  │ ⚠ KYC en attente               ││
│  │ [VOIR LE PROBLÈME]              ││
│  └────────────────────────────────┘│
│                                      │
│  ─────────── BATCH MODE ──────────  │
│  ☑ Sélectionner tout                │
│  [VALIDER 3 PAYOUTS - 75 000 XAF]   │
│                                      │
└──────────────────────────────────────┘
```

---

> 📝 **Document généré** : mai 2026
> 🔄 **Cohérent avec** : ARENA_MASTER_PROMPT.md v1.1, ARENA_54_ECRANS.md v1.0
> 🎨 **Total règles UI** : 200+
> 🚀 **Objectif** : garantir une UX cohérente sur les 54 écrans

---

# 🎁 BONUS — Code starter pour les widgets de base

Pour t'éviter d'attendre, voici les **fichiers de design system prêts à copier** :

## `lib/core/theme/arena_colors.dart`

```dart
import 'package:flutter/material.dart';

class ArenaColors {
  // Backgrounds
  static const bg = Color(0xFF0A0A0F);
  static const surface = Color(0xFF14141C);
  static const surfaceLight = Color(0xFF1C1C26);
  static const surfaceDark = Color(0xFF050609);
  
  // Brand
  static const primary = Color(0xFF4C7AFF);
  static const primaryDark = Color(0xFF2952CC);
  static const primaryLight = Color(0xFF7B9FFF);
  static const secondary = Color(0xFFFF2D55);
  static const secondaryDark = Color(0xFFCC2945);
  
  // Game colors
  static const efootball = Color(0xFF00B4D8);
  static const fifa = Color(0xFFFFB020);
  static const fcMobile = Color(0xFFFF6A1A);
  
  // States
  static const success = Color(0xFF00C896);
  static const successBg = Color(0x1A00C896);
  static const warning = Color(0xFFFFB020);
  static const warningBg = Color(0x1AFFAA00);
  static const danger = Color(0xFFFF2D55);
  static const dangerBg = Color(0x1AFF2D55);
  static const info = Color(0xFF4C7AFF);
  static const infoBg = Color(0x1A4C7AFF);
  
  // Text
  static const text = Color(0xFFF5F5F0);
  static const textMuted = Color(0xFF8B8B95);
  static const textFaint = Color(0xFF5A5A65);
  static const textDisabled = Color(0xFF3A3F4D);
  
  // Borders
  static const border = Color(0x264C7AFF);
  static const borderMuted = Color(0x1A8A93A6);
  static const borderStrong = Color(0xFF2A2D3A);
  
  // Avatars
  static const avatarColors = [
    Color(0xFF4C7AFF),
    Color(0xFFFF2D55),
    Color(0xFF00C896),
    Color(0xFFFFB020),
    Color(0xFF00B4D8),
    Color(0xFFB45CFF),
    Color(0xFFFF6A1A),
    Color(0xFFFFE629),
  ];
}
```

## `lib/core/theme/arena_spacing.dart`

```dart
class ArenaSpacing {
  static const double xxs = 2;
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
  static const double xxxl = 64;
}

class ArenaRadius {
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double round = 999;
}
```

Demande à Claude Code de générer le reste en se basant sur les sections détaillées de ce document.
