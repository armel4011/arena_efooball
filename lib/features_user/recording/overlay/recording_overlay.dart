import 'package:arena/core/theme/arena_colors.dart';
import 'package:arena/features_user/recording/overlay/recording_overlay_messages.dart';
import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';

/// Floating button rendered on top of eFootball / FIFA during a
/// recorded match. Lives in its own Flutter isolate spawned by
/// `flutter_overlay_window` — it cannot read providers from the
/// main app, so all state arrives through `FlutterOverlayWindow.shareData`.
///
/// Layout (matches the PHASE 8.4 brief):
///   - 72 dp circular red button,
///   - white "REC" timer text MM:SS in the middle,
///   - drag-to-side baked in via `PositionGravity.auto` (set by the
///     main app when it calls `showOverlay`),
///   - short tap → ask the main app to bring ARENA to front,
///   - long press → in-overlay sheet with 3 options
///     (Continuer / Pause / Arrêter forfait).
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

  Future<void> _onLongPress() async {
    final ctx = context;
    if (!ctx.mounted) return;
    final result = await showModalBottomSheet<String>(
      context: ctx,
      backgroundColor: ArenaColors.surface,
      isDismissible: true,
      builder: (sheetCtx) => _LongPressMenu(),
    );
    if (result == null) return;
    await FlutterOverlayWindow.shareData(result);
  }

  @override
  Widget build(BuildContext context) {
    const size = 72.0;
    final color = _tick.isWarning ? ArenaColors.warning : ArenaColors.danger;

    return GestureDetector(
      onTap: _onTap,
      onLongPress: _onLongPress,
      child: Container(
        width: size,
        height: size,
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

class _LongPressMenu extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _MenuTile(
              label: 'Continuer',
              icon: Icons.play_arrow,
              color: ArenaColors.success,
              onTap: () => Navigator.pop(context, RecordingOverlayMessages.askResumeType),
            ),
            _MenuTile(
              label: 'Pause (max 2 min)',
              icon: Icons.pause,
              color: ArenaColors.warning,
              onTap: () => Navigator.pop(context, RecordingOverlayMessages.askPauseType),
            ),
            _MenuTile(
              label: 'Arrêter (forfait)',
              icon: Icons.stop,
              color: ArenaColors.danger,
              onTap: () => Navigator.pop(context, RecordingOverlayMessages.askForfeitType),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(label, style: const TextStyle(color: ArenaColors.text)),
      onTap: onTap,
    );
  }
}
