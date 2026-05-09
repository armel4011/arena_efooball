// ─────────────────────────────────────────────────────────────────────────
// LEGACY SHIM — `ArenaColors` lives in `arena_theme.dart` (v2). Existing
// imports keep working through this re-export until each wave migrates its
// screens onto v2 token names (carbon/bone/signalBlue/…).
// Removed at the end of wave 4.
// ─────────────────────────────────────────────────────────────────────────
export 'package:arena/core/theme/arena_theme.dart' show ArenaColors;
