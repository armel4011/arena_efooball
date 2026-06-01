// ============================================================================
// ARENA — Design System Theme (v2 — fidélité maximale)
// ============================================================================
// Source de vérité : ARENA_DESIGN_KIT.md + arena_v2.html (preview HTML mai 2026)
// Tous les tokens sont dérivés DIRECTEMENT du CSS :root de la preview.
//
// ⚠️ ATTENTION — FIDÉLITÉ ABSOLUE
// L'utilisateur a demandé une reproduction PIXEL-PERFECT incluant :
//   - couleurs et tokens exacts
//   - polices Bebas Neue / Space Grotesk
//   - layouts pixel-perfect
//   - animations et micro-interactions
//
// Ne JAMAIS hardcoder une valeur qui n'est pas dans ce fichier.
// Si une valeur manque, lis arena_v2.html pour la trouver, puis
// ajoute-la ici avec un commentaire de référence.
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

// ────────────────────────────────────────────────────────────────────────────
// COULEURS
// ────────────────────────────────────────────────────────────────────────────
class ArenaColors {
  ArenaColors._();

  // ─── Backgrounds ──────────────────────────────────────────────────────────
  static const Color void_ = Color(0xFF0A0A0F);          // --void
  static const Color carbon = Color(0xFF14141C);         // --carbon
  static const Color carbon2 = Color(0xFF1C1C26);        // --carbon-2

  // ─── Text ─────────────────────────────────────────────────────────────────
  static const Color bone = Color(0xFFF5F5F0);           // --bone (texte principal)
  static const Color silver = Color(0xFF8B8B95);         // --silver (texte secondaire)
  static const Color silverDim = Color(0xFF5A5A65);      // --silver-dim (texte tertiaire)

  // ─── Brand ────────────────────────────────────────────────────────────────
  static const Color signalBlue = Color(0xFF4C7AFF);     // --signal-blue (USER primary)
  static const Color neonRed = Color(0xFFFF2D55);        // --neon-red (ADMIN/LIVE)

  // ─── Status ───────────────────────────────────────────────────────────────
  static const Color statusOk = Color(0xFF00C896);
  static const Color statusOkDeep = Color(0xFF00A878);   // gradient compagnon (success badges)
  static const Color statusWarn = Color(0xFFFFB020);
  static const Color statusDangerDeep = Color(0xFF8B0020); // gradient compagnon de neonRed (failure badges)

  // ─── Game colors (par jeu) ────────────────────────────────────────────────
  static const Color gameEfoot = Color(0xFF00B4D8);      // eFootball
  static const Color gameFifa = Color(0xFF06D6A0);       // FIFA Mobile
  static const Color gameFc = Color(0xFFF77F00);         // EA SPORTS FC Mobile

  // ─── Borders ──────────────────────────────────────────────────────────────
  static const Color border = Color(0x0FFFFFFF);         // 6% white
  static const Color borderHi = Color(0x1FFFFFFF);       // 12% white

  // ─── Avatars (gradients) ──────────────────────────────────────────────────
  static const LinearGradient avBlue = LinearGradient(
    colors: [Color(0xFF4C7AFF), Color(0xFF2C5AFF)],
    begin: Alignment.topLeft, end: Alignment.bottomRight,
  );
  static const LinearGradient avRed = LinearGradient(
    colors: [Color(0xFFFF2D55), Color(0xFFDD0035)],
    begin: Alignment.topLeft, end: Alignment.bottomRight,
  );
  static const LinearGradient avGreen = LinearGradient(
    colors: [Color(0xFF00C896), Color(0xFF00A878)],
    begin: Alignment.topLeft, end: Alignment.bottomRight,
  );
  static const LinearGradient avOrange = LinearGradient(
    colors: [Color(0xFFF77F00), Color(0xFFE56500)],
    begin: Alignment.topLeft, end: Alignment.bottomRight,
  );
  static const LinearGradient avCyan = LinearGradient(
    colors: [Color(0xFF00B4D8), Color(0xFF0096B8)],
    begin: Alignment.topLeft, end: Alignment.bottomRight,
  );
  static const LinearGradient avPurple = LinearGradient(
    colors: [Color(0xFF9D4EDD), Color(0xFF7B2CBF)],
    begin: Alignment.topLeft, end: Alignment.bottomRight,
  );
  static const LinearGradient avPink = LinearGradient(
    colors: [Color(0xFFFF6B9D), Color(0xFFE63967)],
    begin: Alignment.topLeft, end: Alignment.bottomRight,
  );
  static const LinearGradient avYellow = LinearGradient(
    colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
    begin: Alignment.topLeft, end: Alignment.bottomRight,
  );

  // ─── Banners (par jeu) ────────────────────────────────────────────────────
  static const LinearGradient bannerEfoot = LinearGradient(
    colors: [Color(0xFF00B4D8), Color(0xFF023E8A)],
    begin: Alignment.topLeft, end: Alignment.bottomRight,
  );
  static const LinearGradient bannerFifa = LinearGradient(
    colors: [Color(0xFF06D6A0), Color(0xFF0F5132)],
    begin: Alignment.topLeft, end: Alignment.bottomRight,
  );
  static const LinearGradient bannerFc = LinearGradient(
    colors: [Color(0xFFF77F00), Color(0xFF6A040F)],
    begin: Alignment.topLeft, end: Alignment.bottomRight,
  );

  // ─── Tier badges ──────────────────────────────────────────────────────────
  static const Color tierBronze = Color(0xFFCD7F32);
  static const Color tierGold = Color(0xFFFFD700);       // or pur (super admin, role highlights)
  static const Color tierGoldWarm = Color(0xFFFFC93C);   // or chaud (competition premium card)
  static const Color tierGoldDeep = Color(0xFFCB9A1F);   // or sombre (gradient compagnon de tierGoldWarm)

  // ─── Brand mobile money (paiement P2P) ───────────────────────────────────
  static const Color brandMtnMomo = Color(0xFFFFA500);     // jaune-orange MTN MoMo
  static const Color brandOrangeMoney = Color(0xFFFF6B00); // orange vif Orange Money

  // ─── Premium accents (charte 2026-05-25) ─────────────────────────────────
  // Tokens additionnels du design system « magazine sportif premium » —
  // utilisés pour les highlights, les états d'accent et les game palettes
  // étendues. Coexistent avec les tokens v1/v2 ; aucune valeur existante
  // n'est modifiée pour ne pas casser le visuel des écrans déjà restylés.
  static const Color acidGreen = Color(0xFFB8FF3D);  // highlight CTA secondaire
  static const Color hotCoral = Color(0xFFFF6A1A);   // accent chaud
  static const Color iceCyan = Color(0xFF18E8D4);    // accent froid (eFoot alt)
  static const Color pearl = Color(0xFFB8B8C8);      // texte secondaire premium
  static const Color graphite = Color(0xFF1F1F2A);   // surface élevée
  static const Color steel = Color(0xFF2A2A38);      // bordure forte
  static const Color blackPure = Color(0xFF0A0A0E);  // noir absolu (logos, photos)
  static const Color gold = tierGold;                // alias officiel premium

  // Companion shades pour les gradients m-btn-primary/danger du mockup
  static const Color signalBlueDark = Color(0xFF2952CC);
  static const Color neonRedDark = Color(0xFFCC2945);

  // Stops médians des dégradés cinématiques du splash (USER bleu / ADMIN
  // rouge). Le stop USER #1A2D5C est aussi le fond natif (cf. pubspec
  // flutter_native_splash). Cf. SplashScreen.
  static const Color splashUserDeep = Color(0xFF1A2D5C);
  static const Color splashAdminDeep = Color(0xFF5C1A2D);

  // Glows (utilisables tels quels dans BoxShadow.color)
  static const Color signalBlueGlow = Color(0x804C7AFF); // signalBlue @ 50 %
  static const Color neonRedGlow = Color(0x80FF2D55);    // neonRed @ 50 %
  static const Color acidGreenGlow = Color(0x66B8FF3D);  // acidGreen @ 40 %
  static const Color hotCoralGlow = Color(0x66FF6A1A);   // hotCoral @ 40 %
  static const Color iceCyanGlow = Color(0x6618E8D4);    // iceCyan @ 40 %
  static const Color goldGlow = Color(0x66FFD700);       // gold @ 40 %

  // Alias sémantique : LIVE indicator (= neonRed pulsant)
  static const Color statusLive = neonRed;

  // ─── Competition tier gradients ──────────────────────────────────────────
  // Remplacent le gradient game-themed sur les banners liste + home pour
  // que le tier (payant/gratuit+gain/gratuit pur) soit identifiable en un
  // coup d'oeil. Top-left = ton vif (couleur de l'accent), bottom-right =
  // ton sombre profond pour donner de la profondeur sans masquer le texte.
  static const LinearGradient compTierPaid = LinearGradient(
    begin: Alignment.topLeft, end: Alignment.bottomRight,
    colors: [tierGoldWarm, tierGoldDeep], // or chaud → or sombre
  );
  static const LinearGradient compTierFreePrize = LinearGradient(
    begin: Alignment.topLeft, end: Alignment.bottomRight,
    colors: [iceCyan, Color(0xFF0A3A4A)], // turquoise → bleu profond
  );
  static const LinearGradient compTierFreePure = LinearGradient(
    begin: Alignment.topLeft, end: Alignment.bottomRight,
    colors: [statusOk, Color(0xFF0F5132)], // vert vif → vert forêt
  );

  // ─── Stream moderation gradients (admin grille 6 slots) ─────────────────
  static const LinearGradient streamSlot1Gradient = LinearGradient(
    begin: Alignment.topLeft, end: Alignment.bottomRight,
    colors: [Color(0xFF1A3A6C), Color(0xFF2C0A1F)], // blue → deep magenta
  );
  static const LinearGradient streamSlot2Gradient = LinearGradient(
    begin: Alignment.topLeft, end: Alignment.bottomRight,
    colors: [Color(0xFF1A3A1A), Color(0xFF0A1A0A)], // forest green dark
  );
  static const LinearGradient streamSlot3Gradient = LinearGradient(
    begin: Alignment.topLeft, end: Alignment.bottomRight,
    colors: [Color(0xFF3A2200), Color(0xFF1A0A00)], // burnt orange
  );
  static const LinearGradient streamSlot4Gradient = LinearGradient(
    begin: Alignment.topLeft, end: Alignment.bottomRight,
    colors: [Color(0xFF3A0A6C), Color(0xFF1A0A30)], // royal purple
  );

  // ─── Brand text gradient (ARENA logo) ─────────────────────────────────────
  static const LinearGradient brandTextGradient = LinearGradient(
    colors: [Color(0xFF4C7AFF), Color(0xFFFF2D55)],
    begin: Alignment.topLeft, end: Alignment.bottomRight,
  );

  // ──────────────────────────────────────────────────────────────────────────
  // LEGACY ALIASES — transitional layer (removed at end of wave 4)
  // ──────────────────────────────────────────────────────────────────────────
  // These names come from the v1 design system (Orbitron/Nunito era) and are
  // preserved so existing Phase 0–9 code keeps compiling while waves 1–4
  // refactor each screen onto v2 tokens (carbon/bone/signalBlue/…).
  // Visual values are taken from v2 — referencing legacy names now picks up
  // the v2 colors automatically.
  static const Color bg = void_;
  static const Color surface = carbon;
  static const Color surfaceLight = carbon2;
  static const Color primary = signalBlue;
  static const Color secondary = neonRed;
  static const Color efootball = gameEfoot;
  static const Color fifa = gameFifa;
  static const Color fcMobile = gameFc;
  static const Color success = statusOk;
  static const Color warning = statusWarn;
  static const Color danger = neonRed;
  static const Color text = bone;
  static const Color textMuted = silver;
  static const Color textFaint = silverDim;
}

// ────────────────────────────────────────────────────────────────────────────
// SPACING (mappage exact des paddings/margins du CSS)
// ────────────────────────────────────────────────────────────────────────────
class ArenaSpacing {
  ArenaSpacing._();
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;     // padding standard
  static const double xl = 20;
  static const double xxl = 24;    // padding sections
  static const double xxxl = 32;
}

class ArenaRadius {
  ArenaRadius._();
  static const double sm = 8;     // --r-sm
  static const double md = 12;    // --r-md (boutons)
  static const double lg = 16;    // --r-lg (cards)
  static const double xl = 20;    // --r-xl
  static const double round = 999;

  // ─── Legacy BorderRadius aliases (transitional) ─────────────────────────
  static const BorderRadius button = BorderRadius.all(Radius.circular(md));
  static const BorderRadius card = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius pill = BorderRadius.all(Radius.circular(round));
}

// ────────────────────────────────────────────────────────────────────────────
// DURATIONS (animations — tirées de la preview HTML)
// ────────────────────────────────────────────────────────────────────────────
class ArenaDurations {
  ArenaDurations._();
  static const Duration micro = Duration(milliseconds: 120);
  static const Duration short = Duration(milliseconds: 200);
  static const Duration medium = Duration(milliseconds: 300);
  static const Duration long = Duration(milliseconds: 500);
  static const Duration pulse = Duration(milliseconds: 1500);   // @keyframes pulse
  static const Duration spin = Duration(seconds: 1);            // loaders
}

// ────────────────────────────────────────────────────────────────────────────
// TYPOGRAPHIE
// ────────────────────────────────────────────────────────────────────────────
class ArenaText {
  ArenaText._();

  // ─── Bebas Neue — headers, titres, scores ────────────────────────────────
  static TextStyle hero = GoogleFonts.bebasNeue(
    fontSize: 60, letterSpacing: 8, color: ArenaColors.bone, height: 1,
  );
  static TextStyle h1 = GoogleFonts.bebasNeue(
    fontSize: 26, letterSpacing: 2, height: 1.1, color: ArenaColors.bone,
  );
  static TextStyle h2 = GoogleFonts.bebasNeue(
    fontSize: 18, letterSpacing: 1.5, color: ArenaColors.bone,
  );
  static TextStyle appBarTitle = GoogleFonts.bebasNeue(
    fontSize: 14, letterSpacing: 2, color: ArenaColors.bone,
  );
  // Styles cinématiques du splash (couleur appliquée par l'appelant via
  // copyWith — ces glyphes sont sur dégradé). Centralisés ici pour qu'aucun
  // `GoogleFonts.*` inline ne subsiste dans features/splash.
  static TextStyle splashBrand = GoogleFonts.bebasNeue(
    fontSize: 44, letterSpacing: 8, fontWeight: FontWeight.w700,
  );
  static TextStyle splashTagline = GoogleFonts.instrumentSerif(
    fontSize: 13, fontStyle: FontStyle.italic, letterSpacing: 1.5,
  );
  static TextStyle splashBadge = GoogleFonts.bebasNeue(
    fontSize: 12, letterSpacing: 1,
  );
  static TextStyle bigNumber = GoogleFonts.bebasNeue(
    fontSize: 30, letterSpacing: 2, color: ArenaColors.bone,
  );
  static TextStyle statValue = GoogleFonts.bebasNeue(
    fontSize: 20, color: ArenaColors.signalBlue,
  );

  // ─── Space Grotesk — body, paragraphes, boutons ──────────────────────────
  static TextStyle h3 = GoogleFonts.spaceGrotesk(
    fontSize: 13, fontWeight: FontWeight.w700, color: ArenaColors.bone,
  );
  static TextStyle body = GoogleFonts.spaceGrotesk(
    fontSize: 12, color: ArenaColors.bone, height: 1.5,
  );
  static TextStyle bodyMuted = GoogleFonts.spaceGrotesk(
    fontSize: 11, color: ArenaColors.silver, height: 1.5,
  );
  static TextStyle small = GoogleFonts.spaceGrotesk(
    fontSize: 10, color: ArenaColors.silverDim,
  );
  static TextStyle button = GoogleFonts.spaceGrotesk(
    fontSize: 12, fontWeight: FontWeight.w600,
  );
  static TextStyle inputLabel = GoogleFonts.spaceGrotesk(
    fontSize: 10, fontWeight: FontWeight.w600,
    color: ArenaColors.silver, letterSpacing: 1,
  );
  static TextStyle badge = GoogleFonts.spaceGrotesk(
    fontSize: 9, fontWeight: FontWeight.w700,
    letterSpacing: 0.5,
  );
  static TextStyle navLabel = GoogleFonts.spaceGrotesk(
    fontSize: 9, fontWeight: FontWeight.w600,
  );

  // ─── Instrument Serif italic — accents typographiques (taglines) ─────────
  static TextStyle serifAccent = GoogleFonts.instrumentSerif(
    fontStyle: FontStyle.italic, fontSize: 14, color: ArenaColors.silver,
  );
  static TextStyle serifTagline = GoogleFonts.instrumentSerif(
    fontStyle: FontStyle.italic, fontSize: 13, color: ArenaColors.silver,
  );

  // ─── JetBrains Mono — codes, numéros, scores, montants ──────────────────
  static TextStyle mono = GoogleFonts.jetBrainsMono(
    fontSize: 12, color: ArenaColors.bone,
  );
  static TextStyle monoSmall = GoogleFonts.jetBrainsMono(
    fontSize: 10, color: ArenaColors.silver,
  );
  static TextStyle monoLg = GoogleFonts.jetBrainsMono(
    fontSize: 16, fontWeight: FontWeight.w700, color: ArenaColors.bone,
  );
  static TextStyle roomCode = GoogleFonts.jetBrainsMono(
    fontSize: 24, fontWeight: FontWeight.w700,
    color: ArenaColors.gameEfoot, letterSpacing: 4,
  );
  static TextStyle invitCode = GoogleFonts.jetBrainsMono(
    fontSize: 13, fontWeight: FontWeight.w700,
    color: ArenaColors.bone, letterSpacing: 2,
  );
  static TextStyle totpDigit = GoogleFonts.jetBrainsMono(
    fontSize: 16, fontWeight: FontWeight.w700, color: ArenaColors.bone,
  );
}

// ────────────────────────────────────────────────────────────────────────────
// LEGACY TYPOGRAPHY (transitional — kept compiling Phase 0–9 code on v2)
// ────────────────────────────────────────────────────────────────────────────
// The v1 design system used Orbitron / Nunito / Fira Code with names like
// `displayLarge`, `headlineLarge`, `bodyMedium`, `codeLarge`. v2 uses Bebas
// Neue / Space Grotesk / JetBrains Mono via [ArenaText]. Each wave migrates
// callers over; until then this class re-emits v2 fonts under v1 names so
// nothing breaks. Removed at end of wave 4.
class ArenaTypography {
  ArenaTypography._();

  // ─── Display / Headlines (Bebas Neue replaces Orbitron) ────────────────
  static TextStyle get displayLarge => GoogleFonts.bebasNeue(
        fontSize: 36, fontWeight: FontWeight.w700, letterSpacing: 4,
        color: ArenaColors.bone,
      );
  static TextStyle get displayMedium => GoogleFonts.bebasNeue(
        fontSize: 28, fontWeight: FontWeight.w700, letterSpacing: 3,
        color: ArenaColors.bone,
      );
  static TextStyle get headlineLarge => GoogleFonts.bebasNeue(
        fontSize: 24, fontWeight: FontWeight.w700, letterSpacing: 2,
        color: ArenaColors.bone,
      );
  static TextStyle get headlineMedium => GoogleFonts.bebasNeue(
        fontSize: 20, fontWeight: FontWeight.w700, letterSpacing: 1.5,
        color: ArenaColors.bone,
      );

  // ─── Titles (Space Grotesk replaces Nunito) ────────────────────────────
  static TextStyle get titleLarge => GoogleFonts.spaceGrotesk(
        fontSize: 18, fontWeight: FontWeight.w700, color: ArenaColors.bone,
      );
  static TextStyle get titleMedium => GoogleFonts.spaceGrotesk(
        fontSize: 16, fontWeight: FontWeight.w700, color: ArenaColors.bone,
      );
  static TextStyle get titleSmall => GoogleFonts.spaceGrotesk(
        fontSize: 14, fontWeight: FontWeight.w700, color: ArenaColors.bone,
      );

  // ─── Body ──────────────────────────────────────────────────────────────
  static TextStyle get bodyLarge => GoogleFonts.spaceGrotesk(
        fontSize: 16, fontWeight: FontWeight.w400, height: 1.5,
        color: ArenaColors.bone,
      );
  static TextStyle get bodyMedium => GoogleFonts.spaceGrotesk(
        fontSize: 14, fontWeight: FontWeight.w400, height: 1.5,
        color: ArenaColors.bone,
      );
  static TextStyle get bodySmall => GoogleFonts.spaceGrotesk(
        fontSize: 12, fontWeight: FontWeight.w400, height: 1.4,
        color: ArenaColors.silver,
      );

  // ─── Labels ────────────────────────────────────────────────────────────
  static TextStyle get labelLarge => GoogleFonts.spaceGrotesk(
        fontSize: 14, fontWeight: FontWeight.w700, letterSpacing: 1,
        color: ArenaColors.bone,
      );
  static TextStyle get labelMedium => GoogleFonts.spaceGrotesk(
        fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.8,
        color: ArenaColors.silver,
      );
  static TextStyle get labelSmall => GoogleFonts.spaceGrotesk(
        fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.5,
        color: ArenaColors.silver,
      );

  // ─── Mono (JetBrains Mono replaces Fira Code) ──────────────────────────
  static TextStyle get codeLarge => GoogleFonts.jetBrainsMono(
        fontSize: 28, fontWeight: FontWeight.w700, letterSpacing: 6,
        color: ArenaColors.bone,
      );
  static TextStyle get codeMedium => GoogleFonts.jetBrainsMono(
        fontSize: 18, fontWeight: FontWeight.w600, letterSpacing: 3,
        color: ArenaColors.bone,
      );

  static TextTheme buildTextTheme() => TextTheme(
        displayLarge: displayLarge,
        displayMedium: displayMedium,
        displaySmall: displayMedium,
        headlineLarge: headlineLarge,
        headlineMedium: headlineMedium,
        headlineSmall: headlineMedium,
        titleLarge: titleLarge,
        titleMedium: titleMedium,
        titleSmall: titleSmall,
        bodyLarge: bodyLarge,
        bodyMedium: bodyMedium,
        bodySmall: bodySmall,
        labelLarge: labelLarge,
        labelMedium: labelMedium,
        labelSmall: labelSmall,
      );
}

// ────────────────────────────────────────────────────────────────────────────
// SHADOWS (les "glow" de la preview)
// ────────────────────────────────────────────────────────────────────────────
class ArenaShadows {
  ArenaShadows._();

  static List<BoxShadow> blueGlow({double blur = 16}) => [
    BoxShadow(
      color: ArenaColors.signalBlue.withValues(alpha: 0.4),
      blurRadius: blur,
    ),
  ];

  static List<BoxShadow> redGlow({double blur = 16}) => [
    BoxShadow(
      color: ArenaColors.neonRed.withValues(alpha: 0.4),
      blurRadius: blur,
    ),
  ];

  static List<BoxShadow> phoneShadow = const [
    BoxShadow(color: Color(0x99000000), blurRadius: 50, offset: Offset(0, 20)),
  ];
}

// ────────────────────────────────────────────────────────────────────────────
// MAIN THEME
// ────────────────────────────────────────────────────────────────────────────

/// Top-level alias kept for legacy `MaterialApp(theme: arenaUserTheme)`
/// usage in `main_user.dart` and tests. Wave 1 keeps both apps on the same
/// theme; admin red primary differentiation lands in wave 3.
final ThemeData arenaUserTheme = buildArenaTheme();

/// Same alias, admin entry point. Wave 3 will diverge the admin theme to
/// swap `signalBlue` → `neonRed` as the primary brand colour.
final ThemeData arenaAdminTheme = buildArenaTheme();

ThemeData buildArenaTheme() {
  return ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: ArenaColors.void_,
    primaryColor: ArenaColors.signalBlue,
    colorScheme: const ColorScheme.dark(
      primary: ArenaColors.signalBlue,
      secondary: ArenaColors.neonRed,
      surface: ArenaColors.carbon,
      error: ArenaColors.neonRed,
      onPrimary: ArenaColors.bone,
      onSecondary: ArenaColors.bone,
      onSurface: ArenaColors.bone,
    ),
    textTheme: GoogleFonts.spaceGroteskTextTheme(ThemeData.dark().textTheme),
    appBarTheme: AppBarTheme(
      backgroundColor: ArenaColors.void_,
      foregroundColor: ArenaColors.bone,
      elevation: 0,
      titleTextStyle: ArenaText.appBarTitle,
      systemOverlayStyle: SystemUiOverlayStyle.light,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: ArenaColors.signalBlue,
        foregroundColor: ArenaColors.bone,
        textStyle: ArenaText.button,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ArenaRadius.md),
        ),
        minimumSize: const Size.fromHeight(44),
        elevation: 0,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: ArenaColors.carbon,
      contentPadding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
      hintStyle: ArenaText.body.copyWith(color: ArenaColors.silver),
      labelStyle: ArenaText.inputLabel,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(ArenaRadius.md),
        borderSide: const BorderSide(color: ArenaColors.borderHi),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(ArenaRadius.md),
        borderSide: const BorderSide(color: ArenaColors.borderHi),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(ArenaRadius.md),
        borderSide: const BorderSide(color: ArenaColors.signalBlue, width: 1.5),
      ),
    ),
    cardTheme: CardThemeData(
      color: ArenaColors.carbon,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(ArenaRadius.lg),
        side: const BorderSide(color: ArenaColors.border),
      ),
      margin: const EdgeInsets.only(bottom: 10),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: ArenaColors.carbon,
      selectedItemColor: ArenaColors.signalBlue,
      unselectedItemColor: ArenaColors.silverDim,
      selectedLabelStyle: TextStyle(fontSize: 9, fontWeight: FontWeight.w600),
      unselectedLabelStyle: TextStyle(fontSize: 9, fontWeight: FontWeight.w600),
      type: BottomNavigationBarType.fixed,
    ),
    dividerColor: ArenaColors.border,
  );
}

// ============================================================================
// HELPERS — DECORATIONS RÉUTILISABLES
// ============================================================================

/// Card glow signature (USER) — bordure bleue + ombre bleue diffuse
BoxDecoration arenaGlowCardDecoration() => BoxDecoration(
  borderRadius: BorderRadius.circular(ArenaRadius.lg),
  gradient: LinearGradient(
    colors: [
      ArenaColors.signalBlue.withValues(alpha: 0.08),
      ArenaColors.carbon.withValues(alpha: 0.95),
    ],
    begin: Alignment.topLeft, end: Alignment.bottomRight,
  ),
  border: Border.all(color: ArenaColors.signalBlue.withValues(alpha: 0.3)),
  boxShadow: [
    BoxShadow(
      color: ArenaColors.signalBlue.withValues(alpha: 0.12),
      blurRadius: 20,
    ),
  ],
);

/// Card danger (ADMIN/LIVE) — bordure rouge
BoxDecoration arenaDangerCardDecoration() => BoxDecoration(
  borderRadius: BorderRadius.circular(ArenaRadius.lg),
  gradient: LinearGradient(
    colors: [
      ArenaColors.neonRed.withValues(alpha: 0.08),
      ArenaColors.carbon.withValues(alpha: 0.95),
    ],
    begin: Alignment.topLeft, end: Alignment.bottomRight,
  ),
  border: Border.all(color: ArenaColors.neonRed.withValues(alpha: 0.3)),
);

/// Card success — bordure verte
BoxDecoration arenaSuccessCardDecoration() => BoxDecoration(
  borderRadius: BorderRadius.circular(ArenaRadius.lg),
  gradient: LinearGradient(
    colors: [
      ArenaColors.statusOk.withValues(alpha: 0.08),
      ArenaColors.carbon.withValues(alpha: 0.95),
    ],
    begin: Alignment.topLeft, end: Alignment.bottomRight,
  ),
  border: Border.all(color: ArenaColors.statusOk.withValues(alpha: 0.3)),
);

/// Card warning — bordure orange
BoxDecoration arenaWarningCardDecoration() => BoxDecoration(
  borderRadius: BorderRadius.circular(ArenaRadius.lg),
  gradient: LinearGradient(
    colors: [
      ArenaColors.statusWarn.withValues(alpha: 0.08),
      ArenaColors.carbon.withValues(alpha: 0.95),
    ],
    begin: Alignment.topLeft, end: Alignment.bottomRight,
  ),
  border: Border.all(color: ArenaColors.statusWarn.withValues(alpha: 0.3)),
);

/// Bouton avec glow bleu (CTA primaire signature)
BoxDecoration arenaPrimaryButtonDecoration() => BoxDecoration(
  color: ArenaColors.signalBlue,
  borderRadius: BorderRadius.circular(ArenaRadius.md),
  boxShadow: ArenaShadows.blueGlow(),
);

/// Bouton avec glow rouge (CTA danger admin)
BoxDecoration arenaDangerButtonDecoration() => BoxDecoration(
  color: ArenaColors.neonRed,
  borderRadius: BorderRadius.circular(ArenaRadius.md),
  boxShadow: ArenaShadows.redGlow(),
);

// ============================================================================
// LOGO ARENA — Texte avec gradient (ShaderMask)
// ============================================================================
class ArenaLogo extends StatelessWidget {
  const ArenaLogo({super.key, this.fontSize = 60, this.letterSpacing = 8});
  final double fontSize;
  final double letterSpacing;

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (bounds) =>
          ArenaColors.brandTextGradient.createShader(bounds),
      child: Text(
        'ARENA',
        style: GoogleFonts.bebasNeue(
          fontSize: fontSize,
          letterSpacing: letterSpacing,
          color: Colors.white, // sera masqué par le ShaderMask
          shadows: [
            BoxShadow(
              color: ArenaColors.signalBlue.withValues(alpha: 0.4),
              blurRadius: 60,
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// PULSE ANIMATION (#17 floating button + LIVE badge)
// ============================================================================
class ArenaPulseDot extends StatefulWidget {
  const ArenaPulseDot({
    super.key,
    this.color = ArenaColors.neonRed,
    this.size = 8,
  });
  final Color color;
  final double size;

  @override
  State<ArenaPulseDot> createState() => _ArenaPulseDotState();
}

class _ArenaPulseDotState extends State<ArenaPulseDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: ArenaDurations.pulse,
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        final t = _ctrl.value;
        return Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: widget.size + (t * 12),
              height: widget.size + (t * 12),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.color.withValues(alpha: (1 - t) * 0.6),
              ),
            ),
            Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.color,
              ),
            ),
          ],
        );
      },
    );
  }
}
