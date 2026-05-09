import 'package:arena/core/theme/arena_colors.dart';
import 'package:arena/core/theme/arena_typography.dart';
import 'package:flutter/material.dart';

/// ARENA design tokens — spacing & radii.
///
/// Mirrors `ARENA_MASTER_PROMPT.md` § Identité visuelle.
abstract final class ArenaSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
}

abstract final class ArenaRadius {
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const Radius radiusMd = Radius.circular(md);
  static const Radius radiusLg = Radius.circular(lg);
  static const BorderRadius card = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius button = BorderRadius.all(Radius.circular(md));
  static const BorderRadius pill = BorderRadius.all(Radius.circular(28));
}

/// ThemeData shared between user and admin flavors.
///
/// `seedColor` differs between flavors — use [arenaUserTheme] vs
/// [arenaAdminTheme] to get the right primary tint.
ThemeData _buildTheme(Color primary) {
  final scheme = ColorScheme.fromSeed(
    brightness: Brightness.dark,
    seedColor: primary,
    primary: primary,
    onPrimary: Colors.white,
    secondary: ArenaColors.efootball,
    surface: ArenaColors.surface,
    onSurface: ArenaColors.text,
    error: ArenaColors.danger,
  );

  final textTheme = ArenaTypography.buildTextTheme();

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: scheme,
    scaffoldBackgroundColor: ArenaColors.bg,
    canvasColor: ArenaColors.bg,
    textTheme: textTheme,
    primaryTextTheme: textTheme,
    iconTheme: const IconThemeData(color: ArenaColors.text),

    appBarTheme: AppBarTheme(
      backgroundColor: ArenaColors.bg,
      foregroundColor: ArenaColors.text,
      elevation: 10,
      shadowColor: primary.withValues(alpha: 0.55),
      surfaceTintColor: Colors.transparent,
      scrolledUnderElevation: 10,
      centerTitle: false,
      titleTextStyle: ArenaTypography.headlineMedium,
      iconTheme: const IconThemeData(color: ArenaColors.text),
    ),

    cardTheme: const CardThemeData(
      color: ArenaColors.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: ArenaRadius.card),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: ArenaColors.surfaceLight,
      hintStyle: ArenaTypography.bodyMedium.copyWith(
        color: ArenaColors.textFaint,
      ),
      labelStyle: ArenaTypography.labelMedium,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: ArenaSpacing.md,
        vertical: ArenaSpacing.md,
      ),
      border: const OutlineInputBorder(
        borderRadius: ArenaRadius.button,
        borderSide: BorderSide.none,
      ),
      enabledBorder: const OutlineInputBorder(
        borderRadius: ArenaRadius.button,
        borderSide: BorderSide(color: ArenaColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: ArenaRadius.button,
        borderSide: BorderSide(color: primary, width: 1.5),
      ),
      errorBorder: const OutlineInputBorder(
        borderRadius: ArenaRadius.button,
        borderSide: BorderSide(color: ArenaColors.danger),
      ),
      focusedErrorBorder: const OutlineInputBorder(
        borderRadius: ArenaRadius.button,
        borderSide: BorderSide(color: ArenaColors.danger, width: 1.5),
      ),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(
          horizontal: ArenaSpacing.lg,
          vertical: ArenaSpacing.md,
        ),
        shape: const RoundedRectangleBorder(borderRadius: ArenaRadius.button),
        textStyle: ArenaTypography.labelLarge,
      ),
    ),

    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(
          horizontal: ArenaSpacing.lg,
          vertical: ArenaSpacing.md,
        ),
        shape: const RoundedRectangleBorder(borderRadius: ArenaRadius.button),
        textStyle: ArenaTypography.labelLarge,
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: ArenaColors.text,
        side: const BorderSide(color: ArenaColors.border),
        padding: const EdgeInsets.symmetric(
          horizontal: ArenaSpacing.lg,
          vertical: ArenaSpacing.md,
        ),
        shape: const RoundedRectangleBorder(borderRadius: ArenaRadius.button),
        textStyle: ArenaTypography.labelLarge,
      ),
    ),

    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primary,
        textStyle: ArenaTypography.labelLarge,
      ),
    ),

    snackBarTheme: SnackBarThemeData(
      backgroundColor: ArenaColors.surfaceLight,
      contentTextStyle: ArenaTypography.bodyMedium,
      behavior: SnackBarBehavior.floating,
      shape: const RoundedRectangleBorder(borderRadius: ArenaRadius.card),
      actionTextColor: primary,
    ),

    dividerTheme: const DividerThemeData(
      color: ArenaColors.border,
      thickness: 1,
      space: 1,
    ),

    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: primary,
      linearTrackColor: ArenaColors.surfaceLight,
      circularTrackColor: ArenaColors.surfaceLight,
    ),
  );
}

ThemeData get arenaUserTheme => _buildTheme(ArenaColors.primary);
ThemeData get arenaAdminTheme => _buildTheme(ArenaColors.secondary);
