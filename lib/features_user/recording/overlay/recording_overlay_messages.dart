/// IPC message vocabulary used between the main app isolate and the
/// overlay isolate (PHASE 8.4 — `flutter_overlay_window`).
///
/// `flutter_overlay_window` exposes a single bidirectional channel
/// (`shareData` / `overlayListener`) that ferries arbitrary JSON
/// payloads. We wrap it in a typed pair so a typo in a string literal
/// doesn't silently break the overlay → main wiring.
abstract final class RecordingOverlayMessages {
  /// `main → overlay` — push the elapsed recording duration in
  /// seconds. The overlay re-renders MM:SS each tick.
  static const String tickType = 'tick';

  /// `main → overlay` — flag that the auto-stop deadline is near
  /// (< 30 s). UI can pulse / change color.
  static const String warnType = 'warn';

  /// `overlay → main` — the user tapped the overlay (short tap).
  /// Triggers "bring ARENA to front" if a method channel is wired,
  /// or simply closes the overlay otherwise.
  static const String focusMainType = 'focus_main';

  /// `overlay → main` — the user picked "Pause" in the long-press
  /// dialog. Main app freezes the auto-stop timer for the grace
  /// window (Q5 = 2 min).
  static const String askPauseType = 'ask_pause';

  /// `overlay → main` — the user picked "Continuer" — explicit
  /// dismissal of the long-press dialog.
  static const String askResumeType = 'ask_resume';

  /// `overlay → main` — the user picked "Arrêter (forfait)". Main
  /// app stops the recording, marks the player as forfeit, alerts
  /// the admin.
  static const String askForfeitType = 'ask_forfeit';

  /// Builds a tick payload. Kept as a free function so both ends
  /// agree on the JSON shape.
  static Map<String, dynamic> tick({required int elapsedSeconds, required bool warning}) {
    return {
      'type': warning ? warnType : tickType,
      'elapsed': elapsedSeconds,
    };
  }
}

/// Parsed payload of a tick — guards against malformed messages
/// crossing the IPC boundary.
class OverlayTick {
  const OverlayTick({required this.elapsedSeconds, required this.isWarning});

  factory OverlayTick.fromMap(Object? raw) {
    if (raw is! Map) {
      return const OverlayTick(elapsedSeconds: 0, isWarning: false);
    }
    final type = raw['type'];
    final elapsed = raw['elapsed'];
    return OverlayTick(
      elapsedSeconds: elapsed is int ? elapsed : 0,
      isWarning: type == RecordingOverlayMessages.warnType,
    );
  }

  final int elapsedSeconds;
  final bool isWarning;

  String get formatted {
    final m = (elapsedSeconds ~/ 60).toString().padLeft(2, '0');
    final s = (elapsedSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}
