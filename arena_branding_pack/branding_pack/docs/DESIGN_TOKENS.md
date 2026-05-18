# 🎨 ARENA — Design Tokens

> Référence officielle des couleurs, polices, et règles de marque ARENA.
> Cette doc accompagne le branding pack icônes + splash.

---

## 🌈 Couleurs

### Couleurs principales

| Token | Hex | RGB | Usage |
|---|---|---|---|
| `--signal-blue` | `#4C7AFF` | rgb(76, 122, 255) | USER primary, CTAs, liens |
| `--neon-red` | `#FF2D55` | rgb(255, 45, 85) | ADMIN, LIVE indicators, alerts |
| `--void` | `#0A0A0F` | rgb(10, 10, 15) | Fond principal de l'app |
| `--carbon` | `#14141C` | rgb(20, 20, 28) | Surfaces, cards |
| `--carbon-2` | `#1C1C26` | rgb(28, 28, 38) | Surfaces élevées |
| `--bone` | `#F5F5F0` | rgb(245, 245, 240) | Texte principal |
| `--silver` | `#8B8B95` | rgb(139, 139, 149) | Texte secondaire |
| `--silver-dim` | `#5A5A65` | rgb(90, 90, 101) | Texte tertiaire |

### Couleurs gradient (pour icônes & splash)

Pour le **dégradé F2** USER :
```
#4C7AFF (0%) → #1A2D5C (55%) → #0A0A0F (100%)
```

Pour le **dégradé F2** ADMIN (inversion) :
```
#FF2D55 (0%) → #5C1A2D (55%) → #0A0A0F (100%)
```

### Couleurs status

| Token | Hex | Usage |
|---|---|---|
| `--status-ok` | `#00C896` | Success, validation |
| `--status-warn` | `#FFB020` | Warning, attention |
| `--status-error` | `#FF2D55` | Error (= neon-red) |

### Couleurs jeux

| Token | Hex | Jeu |
|---|---|---|
| `--game-efoot` | `#00B4D8` | eFootball Mobile |
| `--game-fifa` | `#06D6A0` | FIFA Mobile |
| `--game-fc` | `#F77F00` | EA SPORTS FC Mobile |

---

## ✏️ Typographie

### Polices Google Fonts

| Police | Poids | Usage |
|---|---|---|
| **Bebas Neue** | Regular (400), Bold (700) | Headers, texte ARENA/ADMIN, titres écrans, badges |
| **Instrument Serif** | Regular, **Italic** | Taglines, citations, mises en italique |
| **Space Grotesk** | Regular, Medium (500), Bold (700) | Body text, paragraphes, labels boutons |
| **JetBrains Mono** | Regular, Medium, Bold | Codes, IDs, montants numériques, timestamps |

### Tailles standard

| Usage | Police | Size | Weight |
|---|---|---|---|
| Splash brand name | Bebas Neue | 44 | 700 |
| Page title | Bebas Neue | 32 | 700 |
| Section header | Bebas Neue | 24 | 700 |
| Body | Space Grotesk | 14 | 400 |
| Body bold | Space Grotesk | 14 | 600 |
| Tagline italic | Instrument Serif | 13 | Italic |
| Caption | Space Grotesk | 11 | 400 |
| Numbers/codes | JetBrains Mono | 14 | 500 |

### Letter-spacing

- Bebas Neue : `letter-spacing: 8` pour le texte ARENA (44px)
- Bebas Neue : `letter-spacing: 4` pour les autres headers
- Instrument Serif : `letter-spacing: 1.5` pour la tagline

---

## 🎯 Identité visuelle ARENA

### Tagline officielle

```
SEUL LE TALENT EST RÉCOMPENSÉ...
```

**Sens stratégique** :
- Insiste sur le **mérite** et non sur la chance (argument juridique)
- Valorise le skill du joueur (positionnement esport)
- Format universel (traduisible en EN, AR pour V1.1 et V1.2)
- Les "..." créent un effet de suspense, ouvrent à l'interprétation

**Traductions V1.1 et V1.2** :
- 🇬🇧 EN : `ONLY TALENT IS REWARDED...`
- 🇸🇦 AR : `الموهبة وحدها تكافأ...`

### Symbole : Vector Strike

**Description** : 3 chevrons orientés vers la droite, formant une rafale offensive.
- Chevron 1 (arrière) : blanc plein
- Chevron 2 (milieu) : neon-red (USER) ou signal-blue (ADMIN), pleine opacité
- Chevron 3 (avant) : blanc translucide 55%

**Speed dots** : 5 points blancs en demi-cercle à gauche du chevron principal, opacité 40%. Suggèrent une trainée de vitesse / signal radio.

**Signification** :
- Mouvement, momentum, attaque offensive
- Évoque le "skill click" en gaming
- Les 3 chevrons = les 3 jeux supportés (eFootball, FIFA, EA FC)

### Inversion chromatique USER ↔ ADMIN

| Élément | USER | ADMIN |
|---|---|---|
| Fond | Bleu (#4C7AFF → noir) | Rouge (#FF2D55 → noir) |
| Chevron accent | Rouge (#FF2D55) | Bleu (#4C7AFF) |
| Texte | "ARENA" en blanc | "ADMIN" en blanc |
| Tagline USER | "SEUL LE TALENT EST RÉCOMPENSÉ..." | "CONSOLE DE GESTION ARENA" |
| Spark glow (splash) | Bleu | Rouge |

---

## 📐 Règles d'usage

### Icônes — Safe zone

Le symbole **doit toujours rester dans la safe zone centrale** (66% du canvas) pour rester visible avec les masques Android (cercle, squircle, etc.).

### Splash — Timing

- 1er lancement : animation cinématique complète **5.3 secondes**
- Lancements suivants : splash court **1.5 secondes**
- Ne JAMAIS rallonger au-delà de 6 secondes (frustration utilisateur)

### Quand utiliser ARENA (USER) vs ADMIN

| Contexte | Icône à utiliser |
|---|---|
| App joueurs (com.arena.app) | USER (bleu) |
| App admin (com.arena.admin) | ADMIN (rouge) |
| Site web officiel | USER |
| Présentations investisseurs | USER |
| Documentation interne staff | ADMIN |
| Marketing public | USER |

---

## 🔒 Cohérence avec ton code existant

### Pour Flutter — Théme

```dart
class ArenaColors {
  static const signalBlue = Color(0xFF4C7AFF);
  static const neonRed = Color(0xFFFF2D55);
  static const void_ = Color(0xFF0A0A0F);
  static const carbon = Color(0xFF14141C);
  static const bone = Color(0xFFF5F5F0);
  // ... etc
}

class ArenaText {
  static TextStyle get brand => GoogleFonts.bebasNeue(
    fontSize: 44,
    letterSpacing: 8,
    fontWeight: FontWeight.w700,
    color: ArenaColors.bone,
  );

  static TextStyle get tagline => GoogleFonts.instrumentSerif(
    fontSize: 13,
    fontStyle: FontStyle.italic,
    letterSpacing: 1.5,
    color: ArenaColors.bone.withValues(alpha: 0.7),
  );
  // ... etc
}
```

### Pour CSS (si site web/landing)

```css
:root {
  --signal-blue: #4C7AFF;
  --neon-red: #FF2D55;
  --void: #0A0A0F;
  --bone: #F5F5F0;
  
  --font-brand: 'Bebas Neue', sans-serif;
  --font-tagline: 'Instrument Serif', serif;
  --font-body: 'Space Grotesk', sans-serif;
  --font-mono: 'JetBrains Mono', monospace;
}
```

---

## ⚠️ Ce qu'il NE FAUT PAS faire

❌ **Inverser le bleu et le rouge** → USER doit toujours être bleu, ADMIN toujours rouge
❌ **Changer la tagline officielle** sans validation
❌ **Utiliser un dégradé différent du F2** (bleu plein → void)
❌ **Mettre des effets 3D, bumps, glows excessifs** sur les chevrons
❌ **Mélanger Bebas Neue et d'autres polices header** (Impact, Oswald...)
❌ **Utiliser des couleurs hors palette** (rose, violet, jaune...)
❌ **Modifier les proportions des chevrons** dans l'icône

---

## ✅ Variations autorisées

✅ **Saisonnier** : changer le fond pour Ramadan (vert/or), Coupe du Monde (couleurs équipe)
✅ **Événement** : ajouter un overlay temporaire (logo CAN, World Cup)
✅ **Skin** : version monochrome pour certains contextes (printable, billboard)
✅ **Animation** : variations de timing pour le splash selon contexte (premier lancement vs récurrent)

---

## 📊 Audit visuel rapide

Avant de pusher une feature qui touche au design, vérifie :

- [ ] Les couleurs respectent les tokens ci-dessus
- [ ] La police principale est Bebas Neue (pas Impact ou autre)
- [ ] La tagline est exacte : "SEUL LE TALENT EST RÉCOMPENSÉ..."
- [ ] L'icône USER est bleue, l'icône ADMIN est rouge
- [ ] Les chevrons gardent leur orientation droite (jamais inversés)
- [ ] Le contraste texte/fond passe WCAG AA (au moins 4.5:1)
