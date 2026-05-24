/// IPC message vocabulary used between the main app isolate and the
/// overlay isolate (PHASE 8.4 — `flutter_overlay_window`).
///
/// `flutter_overlay_window` exposes a single bidirectional channel
/// (`shareData` / `overlayListener`) that ferries arbitrary JSON
/// payloads. We wrap it in a typed pair so a typo in a string literal
/// doesn't silently break the overlay → main wiring.
abstract final class RecordingOverlayMessages {
  /// Name under which the main isolate registers a `ReceivePort` in
  /// `IsolateNameServer`. The overlay isolate looks the port up and
  /// uses `SendPort.send` to deliver action strings (`ask_pause`,
  /// `ask_screenshot`, …) — this works on MIUI / Android 12+ where
  /// `flutter_overlay_window`'s `shareData → overlayListener` channel
  /// silently drops events once the main activity is paused.
  static const String mainPortName = 'arena_overlay_actions_main';

  /// `main → overlay` — push the elapsed recording duration in
  /// seconds. The overlay re-renders MM:SS each tick.
  static const String tickType = 'tick';

  /// `main → overlay` — flag that the auto-stop deadline is near
  /// (< 30 s). UI can pulse / change color.
  static const String warnType = 'warn';

  /// `main → overlay` — recording is paused. Overlay freezes its
  /// MM:SS counter and switches to a yellow "PAUSE" face.
  static const String pausedType = 'paused';

  /// `overlay → main` — the user tapped the overlay (short tap).
  /// Triggers "bring ARENA to front" if a method channel is wired,
  /// or simply closes the overlay otherwise.
  static const String focusMainType = 'focus_main';

  /// `overlay → main` — the user picked "Pause" in the expanded
  /// menu. Main app freezes the auto-stop timer for the grace
  /// window (Q5 = 2 min) and pauses the chronometer.
  static const String askPauseType = 'ask_pause';

  /// `overlay → main` — the user picked "Continuer" — resume the
  /// recording chronometer.
  static const String askResumeType = 'ask_resume';

  /// `overlay → main` — the user picked "Arrêter (forfait)". Main
  /// app stops the recording, marks the player as forfeit, alerts
  /// the admin.
  static const String askForfeitType = 'ask_forfeit';

  /// `overlay → main` — the user picked "Enregistrer et arrêter".
  /// Main app cleanly stops the recording and exports the resulting
  /// MP4 to Download/ARENA/.
  static const String askSaveStopType = 'ask_save_stop';

  /// `overlay → main` — l'utilisateur tape la 5ᵉ mini "Live" affichée
  /// uniquement quand l'admin a flag ce match pour la diffusion.
  /// Main stoppe d'abord le recording proprement (Android 14+ refuse
  /// 2 MediaProjection simultanées, voir mémoire mediaprojection_
  /// constraints), exporte le MP4 puis appelle joinAsBroadcaster.
  static const String askGoLiveType = 'ask_go_live';

  /// Builds a tick payload. Kept as a free function so both ends
  /// agree on the JSON shape.
  ///
  /// `liveAvailable` propage l'éligibilité du match au streaming
  /// (admin a flagué une row streams `is_public + is_active` ownée
  /// par le user). L'overlay affiche/cache son 5ᵉ mini button "Live"
  /// en fonction de ce flag — l'isolate overlay ne lit pas les
  /// providers Riverpod du main directement.
  static Map<String, dynamic> tick({
    required int elapsedSeconds,
    required bool warning,
    bool paused = false,
    bool liveAvailable = false,
  }) {
    final type = paused
        ? pausedType
        : warning
            ? warnType
            : tickType;
    return {
      'type': type,
      'elapsed': elapsedSeconds,
      'liveAvailable': liveAvailable,
    };
  }
}

/// Parsed payload of a tick — guards against malformed messages
/// crossing the IPC boundary.
class OverlayTick {
  const OverlayTick({
    required this.elapsedSeconds,
    required this.isWarning,
    this.isPaused = false,
    this.isLiveAvailable = false,
  });

  factory OverlayTick.fromMap(Object? raw) {
    if (raw is! Map) {
      return const OverlayTick(elapsedSeconds: 0, isWarning: false);
    }
    final type = raw['type'];
    final elapsed = raw['elapsed'];
    final liveAvailable = raw['liveAvailable'];
    return OverlayTick(
      elapsedSeconds: elapsed is int ? elapsed : 0,
      isWarning: type == RecordingOverlayMessages.warnType,
      isPaused: type == RecordingOverlayMessages.pausedType,
      isLiveAvailable: liveAvailable == true,
    );
  }

  final int elapsedSeconds;
  final bool isWarning;
  final bool isPaused;
  final bool isLiveAvailable;

  String get formatted {
    final m = (elapsedSeconds ~/ 60).toString().padLeft(2, '0');
    final s = (elapsedSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}
