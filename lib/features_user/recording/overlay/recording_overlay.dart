import 'package:arena/core/theme/arena_colors.dart';
import 'package:arena/features_user/recording/overlay/recording_overlay_messages.dart';
import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';

/// Floating button rendered on top of eFootball / FIFA during a
/// recorded match. Lives in its own Flutter isolate spawned by
/// `flutter_overlay_window` — it cannot read providers from the
/// main app, so all state arrives through `FlutterOverlayWindow.shareData`.
///
/// Layout:
///   - 72 dp circular red button,
///   - white "REC" timer text MM:SS in the middle,
///   - drag-to-side baked in via `PositionGravity.auto`,
///   - tap → ask the main app to bring ARENA to front (focusMain).
///
/// All non-trivial actions (pause / resume / stop / forfeit) live in
/// ARENA itself, not in the overlay isolate. Reasons:
///   * Bottom sheets + resizeOverlay are fragile inside an overlay
///     isolate, especially on MIUI / OxygenOS.
///   * Long-press events are eaten by the underlying app on those OEMs.
///   * `MatchRecordingLifecycle` already exposes a tap-to-stop banner
///     inside the match room, which is what the user reaches after a
///     focusMain tap.
class RecordingOverlayApp extends StatelessWidget {
  const RecordingOverlayApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Material(
        color: Colors.transparent,
        child: Center(child: RecordingOverlayButton()),
      ),
    );
  }
}

class RecordingOverlayButton extends StatefulWidget {
  const RecordingOverlayButton({super.key});

  @override
  State<RecordingOverlayButton> createState() => _RecordingOverlayButtonState();
}

class _RecordingOverlayButtonState extends State<RecordingOverlayButton> {
  static const double _buttonSize = 72;

  OverlayTick _tick = const OverlayTick(elapsedSeconds: 0, isWarning: false);

  @override
  void initState() {
    super.initState();
    FlutterOverlayWindow.overlayListener.listen((event) {
      if (!mounted) return;
      setState(() => _tick = OverlayTick.fromMap(event));
    });
  }

  Future<void> _onTap() async {
    await FlutterOverlayWindow.shareData(
      RecordingOverlayMessages.focusMainType,
    );
  }

  @override
  Widget build(BuildContext context) {
    final color = _tick.isWarning ? ArenaColors.warning : ArenaColors.danger;
    return GestureDetector(
      onTap: _onTap,
      child: Container(
        width: _buttonSize,
        height: _buttonSize,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.45),
              blurRadius: 12,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.fiber_manual_record, color: Colors.white, size: 14),
              const SizedBox(height: 2),
              Text(
                _tick.formatted,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
