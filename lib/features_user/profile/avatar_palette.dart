import 'package:arena/core/theme/arena_theme.dart';
import 'package:flutter/material.dart';

/// Palette of 12 hex colors offered for the avatar background on the
/// profile-edit screen (PHASE 9.1).
///
/// We keep the values as `String` (e.g. `"#4C7AFF"`) because the
/// `profiles.avatar_color` column stores hex strings — round-tripping
/// through [Color] would lose information on opaque-vs-transparent
/// edge cases for nothing.
class AvatarPalette {
  const AvatarPalette._();

  static const colors = <String>[
    '#4C7AFF', // primary brand
    '#FF6B6B',
    '#FFA94D',
    '#F4D03F',
    '#69DB7C',
    '#3BC9DB',
    '#9775FA',
    '#F783AC',
    '#94D82D',
    '#15AABF',
    '#845EF7',
    '#E03131',
  ];

  /// Maps a stored hex string to a Flutter [Color]. Falls back to the
  /// brand primary on any malformed input so we never crash a UI render
  /// on a corrupted profile row.
  static Color colorFromHex(String hex) {
    final cleaned = hex.replaceAll('#', '').trim();
    if (cleaned.length != 6) return ArenaColors.signalBlue;
    final v = int.tryParse(cleaned, radix: 16);
    if (v == null) return ArenaColors.signalBlue;
    return Color(0xFF000000 | v);
  }
}
