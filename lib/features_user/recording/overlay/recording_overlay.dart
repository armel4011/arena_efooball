import 'dart:ui';

import 'package:arena/core/theme/arena_colors.dart';
import 'package:arena/features_user/recording/overlay/recording_overlay_messages.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';

/// Floating button rendered on top of eFootball / FIFA during a
/// recorded match. Lives in its own Flutter isolate spawned by
/// `flutter_overlay_window` — it cannot read providers from the
/// main app, so all state arrives through `FlutterOverlayWindow.shareData`.
///
/// Gestures — collapsed:
///   - tap → expand into a 4-mini-button cardinal cluster
///     (N pause / E open ARENA / S save+stop / W forfeit).
///
/// Gestures — expanded:
///   - tap on the main button → collapse,
///   - tap on a mini → send the action and auto-collapse.
///
/// Taps are wired through `Listener.onPointerDown` rather than
/// `GestureDetector.onTap`: the native drag handler in
/// `flutter_overlay_window` claims ACTION_MOVE on any micro-jitter,
/// which makes Flutter's gesture arena cancel `onTap` before it can
/// fire. `Listener` sits below the arena and receives `PointerDownEvent`
/// synchronously on every touch — so the action fires on touch-down,
/// before drag tracking can steal the gesture.
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
  static const double _mainSize = 72;
  // Distance between the main button center and a mini button center.
  // The overlay window is 220×220 — a 40 dp mini at radius 64 around a
  // 72 dp main fits with a 14 dp gutter to the window edge.
  static const double _miniRadius = 64;

  OverlayTick _tick = const OverlayTick(elapsedSeconds: 0, isWarning: false);
  bool _expanded = false;

  @override
  void initState() {
    super.initState();
    FlutterOverlayWindow.overlayListener.listen((event) {
      if (!mounted) return;
      setState(() => _tick = OverlayTick.fromMap(event));
    });
  }

  void _onMainTap() {
    setState(() => _expanded = !_expanded);
  }

  Future<void> _onMiniTap(String message) async {
    setState(() => _expanded = false);
    // Primary route — Dart-native SendPort. Reliable even when the
    // main activity is paused (MIUI / Android 12+).
    final port =
        IsolateNameServer.lookupPortByName(RecordingOverlayMessages.mainPortName);
    if (port != null) {
      port.send(message);
    } else if (kDebugMode) {
      debugPrint('[overlay] main port not registered, falling back');
    }
    // Belt-and-braces — also push via the plugin's channel. Harmless if
    // the main side ignores duplicate events (parser maps both routes
    // to the same OverlayAction and the coordinator's handlers are
    // idempotent).
    await FlutterOverlayWindow.shareData(message);
  }

  Color get _mainColor {
    if (_tick.isPaused) return ArenaColors.warning;
    if (_tick.isWarning) return ArenaColors.warning;
    return ArenaColors.danger;
  }

  IconData get _mainIcon {
    if (_tick.isPaused) return Icons.pause;
    return Icons.fiber_manual_record;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      height: 220,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 4 cardinals — N pause / E focus / S save+stop / W forfeit.
          // IgnorePointer + opacity 0 while collapsed so they don't eat
          // touches around the main button.
          _MiniButton(
            visible: _expanded,
            offset: const Offset(0, -_miniRadius),
            icon: _tick.isPaused ? Icons.play_arrow : Icons.pause,
            color: _tick.isPaused ? ArenaColors.success : ArenaColors.warning,
            onTap: () => _onMiniTap(
              _tick.isPaused
                  ? RecordingOverlayMessages.askResumeType
                  : RecordingOverlayMessages.askPauseType,
            ),
          ),
          _MiniButton(
            visible: _expanded,
            offset: const Offset(_miniRadius, 0),
            icon: Icons.open_in_new,
            color: ArenaColors.signalBlue,
            onTap: () => _onMiniTap(RecordingOverlayMessages.focusMainType),
          ),
          _MiniButton(
            visible: _expanded,
            offset: const Offset(0, _miniRadius),
            icon: Icons.save_alt,
            color: ArenaColors.success,
            onTap: () => _onMiniTap(RecordingOverlayMessages.askSaveStopType),
          ),
          _MiniButton(
            visible: _expanded,
            offset: const Offset(-_miniRadius, 0),
            icon: Icons.stop_circle_outlined,
            color: ArenaColors.danger,
            onTap: () => _onMiniTap(RecordingOverlayMessages.askForfeitType),
          ),
          // Main button stays on top so the cardinals don't capture
          // a touch aimed at the chrono.
          // HitTestBehavior.opaque is REQUIRED inside an overlay isolate:
          // the default `deferToChild` defers to Container's hit test,
          // and Container with `decoration` (no `color` field) doesn't
          // declare a hit area on every Flutter version — touches then
          // bubble up to nothing and the Listener never fires.
          Listener(
            behavior: HitTestBehavior.opaque,
            onPointerDown: (_) => _onMainTap(),
            child: Container(
              width: _mainSize,
              height: _mainSize,
              decoration: BoxDecoration(
                color: _mainColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: _mainColor.withValues(alpha: 0.45),
                    blurRadius: 12,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(_mainIcon, color: Colors.white, size: 14),
                    const SizedBox(height: 2),
                    Text(
                      _tick.formatted,
                      // KEEP : ce widget tourne dans un isolate Flutter
                      // détaché (flutter_overlay_window). GoogleFonts
                      // n'est pas initialisé côté isolate, donc on
                      // garde un TextStyle natif minimal au lieu
                      // d'`ArenaText.small`.
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
          ),
        ],
      ),
    );
  }
}

class _MiniButton extends StatelessWidget {
  const _MiniButton({
    required this.visible,
    required this.offset,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final bool visible;
  final Offset offset;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const size = 40.0;
    return AnimatedSlide(
      duration: const Duration(milliseconds: 160),
      curve: Curves.easeOutCubic,
      offset: visible ? Offset(offset.dx / size, offset.dy / size) : Offset.zero,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 160),
        opacity: visible ? 1 : 0,
        child: IgnorePointer(
          ignoring: !visible,
          child: Listener(
            behavior: HitTestBehavior.opaque,
            onPointerDown: (_) => onTap(),
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.5),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Icon(icon, color: Colors.white, size: 20),
            ),
          ),
        ),
      ),
    );
  }
}
