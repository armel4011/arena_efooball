import 'package:arena/core/theme/arena_theme.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:google_fonts/google_fonts.dart';

/// Thème Fluent UI (Windows 11) de l'app ARENA Admin Desktop.
///
/// Garde l'identité Arena (fond carbone, accent néon rouge, polices
/// Bebas Neue / Space Grotesk) dans le langage Fluent : mode sombre,
/// accent color dérivé de [ArenaColors.neonRed], surfaces mica-like.
///
/// Les écrans desktop utilisent les contrôles Fluent (TextBox, Button,
/// ContentDialog, InfoBar...) — jamais les widgets Material.
abstract final class ArenaFluentTheme {
  /// Accent néon rouge Arena décliné en nuancier Fluent.
  static final AccentColor accent = AccentColor.swatch(const {
    'darkest': Color(0xFF8B0020),
    'darker': Color(0xFFB3173A),
    'dark': ArenaColors.neonRedDark,
    'normal': ArenaColors.neonRed,
    'light': Color(0xFFFF5C7A),
    'lighter': Color(0xFFFF8CA1),
    'lightest': Color(0xFFFFBCC8),
  });

  /// Thème sombre principal (le seul mode supporté en V1 — l'identité
  /// Arena est sombre par design).
  static FluentThemeData dark() {
    final base = FluentThemeData(
      brightness: Brightness.dark,
      accentColor: accent,
      scaffoldBackgroundColor: ArenaColors.void_,
      cardColor: ArenaColors.carbon,
      menuColor: ArenaColors.carbon2,
      shadowColor: Colors.black,
    );

    return base.copyWith(
      navigationPaneTheme: NavigationPaneThemeData(
        backgroundColor: ArenaColors.carbon,
        highlightColor: ArenaColors.neonRed,
        selectedIconColor: WidgetStateProperty.all(ArenaColors.neonRed),
        unselectedIconColor: WidgetStateProperty.all(ArenaColors.silver),
        selectedTextStyle: WidgetStateProperty.all(
          GoogleFonts.spaceGrotesk(
            color: ArenaColors.bone,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        unselectedTextStyle: WidgetStateProperty.all(
          GoogleFonts.spaceGrotesk(
            color: ArenaColors.silver,
            fontSize: 14,
          ),
        ),
      ),
      typography: Typography.fromBrightness(
        brightness: Brightness.dark,
        color: ArenaColors.bone,
      ).merge(
        Typography.raw(
          // Titres de pages — Bebas Neue, l'identité Arena.
          title: GoogleFonts.bebasNeue(
            fontSize: 28,
            color: ArenaColors.bone,
            letterSpacing: 1.2,
          ),
          subtitle: GoogleFonts.bebasNeue(
            fontSize: 20,
            color: ArenaColors.bone,
            letterSpacing: 1,
          ),
          // Corps de texte — Space Grotesk.
          body: GoogleFonts.spaceGrotesk(
            fontSize: 14,
            color: ArenaColors.bone,
          ),
          bodyStrong: GoogleFonts.spaceGrotesk(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: ArenaColors.bone,
          ),
          bodyLarge: GoogleFonts.spaceGrotesk(
            fontSize: 16,
            color: ArenaColors.bone,
          ),
          caption: GoogleFonts.spaceGrotesk(
            fontSize: 12,
            color: ArenaColors.silver,
          ),
          display: GoogleFonts.bebasNeue(
            fontSize: 48,
            color: ArenaColors.bone,
            letterSpacing: 1.5,
          ),
          titleLarge: GoogleFonts.bebasNeue(
            fontSize: 36,
            color: ArenaColors.bone,
            letterSpacing: 1.2,
          ),
        ),
      ),
    );
  }
}

/// Constantes de mise en page desktop.
abstract final class ArenaDesktop {
  /// Largeur minimale de la fenêtre.
  static const double minWindowWidth = 1100;

  /// Hauteur minimale de la fenêtre.
  static const double minWindowHeight = 700;

  /// Taille de fenêtre par défaut au premier lancement.
  static const double defaultWindowWidth = 1440;

  /// Hauteur par défaut au premier lancement.
  static const double defaultWindowHeight = 900;

  /// Padding standard du contenu d'une page.
  static const double pagePadding = 24;

  /// Largeur maximale du contenu centré (formulaires).
  static const double formMaxWidth = 480;

  /// Espacement entre les cartes KPI.
  static const double cardGap = 16;
}
