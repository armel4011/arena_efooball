import 'package:flutter/painting.dart';

/// Single source of truth for ARENA's color palette.
/// Mirrors the spec in `ARENA_MASTER_PROMPT.md` § Identité visuelle.
abstract final class ArenaColors {
  // Backgrounds
  static const bg = Color(0xFF07080F);
  static const surface = Color(0xFF11131C);
  static const surfaceLight = Color(0xFF1A1D2A);

  // Brand
  static const primary = Color(0xFF4C7AFF); // User app
  static const secondary = Color(0xFFFF3D5A); // Admin / live red

  // Game colors
  static const efootball = Color(0xFF18E8D4);
  static const fifa = Color(0xFFFFAA00);
  static const fcMobile = Color(0xFFFF6A1A);

  // States
  static const success = Color(0xFF0FE893);
  static const warning = Color(0xFFFFAA00);
  static const danger = Color(0xFFFF3D5A);

  // Text
  static const text = Color(0xFFEEF1F8);
  static const textMuted = Color(0xFF8A93A6);
  static const textFaint = Color(0xFF555B6E);

  // Borders
  static const border = Color(0x264C7AFF); // 15% opacity primary
}
