import 'package:arena/core/theme/arena_colors.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Centralised text styles for ARENA.
///
/// - **Orbitron** → display, headlines (game/futuristic feel)
/// - **Nunito**   → body copy and labels (legible at small sizes)
/// - **Fira Code** → numerical/monospace bits (room codes, scores)
abstract final class ArenaTypography {
  static TextStyle get _orbitron => GoogleFonts.orbitron();
  static TextStyle get _nunito => GoogleFonts.nunito();
  static TextStyle get _firaCode => GoogleFonts.firaCode();

  // Display (very large headers, splash, key marketing)
  static TextStyle get displayLarge => _orbitron.copyWith(
        fontSize: 36,
        fontWeight: FontWeight.w800,
        letterSpacing: 4,
        color: ArenaColors.text,
      );

  static TextStyle get displayMedium => _orbitron.copyWith(
        fontSize: 28,
        fontWeight: FontWeight.w800,
        letterSpacing: 3,
        color: ArenaColors.text,
      );

  // Headlines (page/section titles)
  static TextStyle get headlineLarge => _orbitron.copyWith(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        letterSpacing: 2,
        color: ArenaColors.text,
      );

  static TextStyle get headlineMedium => _orbitron.copyWith(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.5,
        color: ArenaColors.text,
      );

  // Titles (card headers, dialog titles)
  static TextStyle get titleLarge => _nunito.copyWith(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: ArenaColors.text,
      );

  static TextStyle get titleMedium => _nunito.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: ArenaColors.text,
      );

  static TextStyle get titleSmall => _nunito.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: ArenaColors.text,
      );

  // Body
  static TextStyle get bodyLarge => _nunito.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 1.5,
        color: ArenaColors.text,
      );

  static TextStyle get bodyMedium => _nunito.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.5,
        color: ArenaColors.text,
      );

  static TextStyle get bodySmall => _nunito.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        height: 1.4,
        color: ArenaColors.textMuted,
      );

  // Labels (buttons, chips, tags)
  static TextStyle get labelLarge => _nunito.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        letterSpacing: 1,
        color: ArenaColors.text,
      );

  static TextStyle get labelMedium => _nunito.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.8,
        color: ArenaColors.textMuted,
      );

  static TextStyle get labelSmall => _nunito.copyWith(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
        color: ArenaColors.textMuted,
      );

  // Monospace (room codes, scores, IDs)
  static TextStyle get codeLarge => _firaCode.copyWith(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        letterSpacing: 6,
        color: ArenaColors.text,
      );

  static TextStyle get codeMedium => _firaCode.copyWith(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        letterSpacing: 3,
        color: ArenaColors.text,
      );

  static TextTheme buildTextTheme() {
    return TextTheme(
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
}
