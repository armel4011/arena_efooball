import 'package:arena/core/services/match_recording_coordinator.dart';
import 'package:arena/core/services/permissions_service.dart';
import 'package:arena/core/theme/arena_theme.dart';
import 'package:arena/data/models/arena_match.dart';
import 'package:arena/data/models/match_status.dart';
import 'package:arena/features_user/match_room/widgets/match_recording_actions_sheet.dart';
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kDebugMode, kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// True only on a real Android device. False on web (where `dart:io` is
/// unsupported) and on every other platform — recording is Android-only.
bool get _isAndroidNative =>
    !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

/// Glue between `MatchRoomPage` and PHASE 8's anti-cheat coordinator.
///
/// Listens to the match's status and:
///   * starts [MatchRecordingCoordinator] when the seated player enters
///     `in_progress` for the first time,
///   * lets it run while the player navigates back to the bracket and
///     re-enters the room (the coordinator state is owned at the
///     provider scope, so a remount doesn't restart anything),
///   * cleanly stops on terminal status transitions (`completed`,
///     `cancelled`, `forfeited`) — `disputed` is left running because
///     the dispute admin still wants the live recording footage.
///
/// Renders a slim "Recording…" banner so the user can see we're
/// actively recording. The banner stays empty for observers and on
/// non-Android platforms (recording is Android-only by design).
class MatchRecordingLifecycle extends ConsumerStatefulWidget {
  const MatchRecordingLifecycle({
    required this.match,
    required this.selfId,
    super.key,
  });

  final ArenaMatch match;

  /// Current Supabase user id, or null if logged out / observer.
  final String? selfId;

  @override
  ConsumerState<MatchRecordingLifecycle> createState() =>
      _MatchRecordingLifecycleState();
}

class _MatchRecordingLifecycleState
    extends ConsumerState<MatchRecordingLifecycle> {
  bool _startAttempted = false;
  String? _startError;

  bool get _isPlayer =>
      widget.selfId != null &&
      (widget.selfId == widget.match.player1Id ||
          widget.selfId == widget.match.player2Id);

  String? get _opponentId {
    if (widget.selfId == widget.match.player1Id) return widget.match.player2Id;
    if (widget.selfId == widget.match.player2Id) return widget.match.player1Id;
    return null;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeReact());
  }

  @override
  void didUpdateWidget(MatchRecordingLifecycle old) {
    super.didUpdateWidget(old);
    if (old.match.status != widget.match.status) {
      _maybeReact();
    }
  }

  Future<void> _maybeReact() async {
    if (!_isAndroidNative) return;
    if (!_isPlayer) return;
    final coord = ref.read(matchRecordingCoordinatorProvider);

    final status = widget.match.status;
    final isLive = status == MatchStatus.inProgress ||
        status == MatchStatus.scorePending ||
        status == MatchStatus.awaitingValidation;
    final isTerminal = status == MatchStatus.completed ||
        status == MatchStatus.cancelled ||
        status == MatchStatus.forfeited;

    if (isLive && !_startAttempted) {
      _startAttempted = true;
      var opp = _opponentId;
      // Debug-only fallback for solo BYE testing on the emulator: without
      // a real opponent the coordinator bails before MediaProjection. A
      // synthetic UUID lets the native recorder + overlay come up; the
      // forfeit auto-flow will FK-fail at markForfeit() if the pause grace
      // ever expires — fine, debug data only.
      if (opp == null && kDebugMode) {
        opp = '00000000-0000-0000-0000-000000000000';
      }
      if (opp == null) return;

      // Request runtime permissions BEFORE handing off to the native
      // recorder. Without RECORD_AUDIO the audio track is silently
      // dropped; without POST_NOTIFICATIONS (Android 13+) the foreground
      // service notification can't show and the OS kills the FGS in ~5s.
      final permissions = ref.read(permissionsServiceProvider);
      final bundle = await permissions.requestRecordingBundle();
      if (!bundle.allGranted) {
        if (mounted) {
          setState(() => _startError = _bundleErrorMessage(bundle));
        }
        return;
      }

      // SYSTEM_ALERT_WINDOW for the floating anti-cheat button. Sends the
      // user to a full-screen settings page on Android 6+, so handle it
      // explicitly here — RecordingOverlayController.start() also checks
      // but bails silently on denial, which hides the failure.
      final overlay = await permissions.requestOverlay();
      if (!overlay.isGranted) {
        if (mounted) {
          setState(() => _startError = _overlayErrorMessage(overlay));
        }
        return;
      }

      try {
        await coord.startForMatch(
          matchId: widget.match.id,
          playerId: widget.selfId!,
          opponentId: opp,
        );
      } catch (e) {
        if (mounted) {
          setState(() => _startError = e.toString());
        }
      }
      return;
    }

    if (isTerminal && coord.state is! CoordinatorIdle) {
      try {
        await coord.stopCleanly();
      } catch (_) {/* best-effort */}
    }
  }

  String _bundleErrorMessage(RecordingPermissionsBundle bundle) {
    final missing = <String>[];
    if (!bundle.microphone.isGranted) missing.add('micro');
    if (!bundle.notifications.isGranted) missing.add('notifications');
    final list = missing.join(' + ');
    if (bundle.microphone.needsSettings ||
        bundle.notifications.needsSettings) {
      return 'Autorise $list dans Paramètres > Apps > ARENA';
    }
    return 'Autorisation $list refusée — retape JE SUIS DANS LA ROOM';
  }

  String _overlayErrorMessage(PermissionOutcome outcome) {
    if (outcome.needsSettings) {
      return 'Active "Afficher au-dessus des autres apps" pour ARENA '
          'dans Paramètres > Apps > Accès spécial';
    }
    return 'Overlay refusé — retape JE SUIS DANS LA ROOM après activation';
  }

  @override
  Widget build(BuildContext context) {
    if (!_isAndroidNative || !_isPlayer) {
      return const SizedBox.shrink();
    }

    // Open the actions sheet when the overlay sends a focusMain (tap on
    // the floating button).
    ref.listen(coordinatorFocusRequestsProvider, (_, __) {
      if (!mounted) return;
      MatchRecordingActionsSheet.show(context);
    });

    if (_startError != null) {
      return _LifecycleBanner(
        icon: Icons.warning_amber_rounded,
        color: ArenaColors.warning,
        text: 'Recording indisponible — $_startError\nTape ici pour réessayer.',
        onTap: () {
          setState(() {
            _startError = null;
            _startAttempted = false;
          });
          _maybeReact();
        },
      );
    }

    final asyncState = ref.watch(coordinatorStateProvider);
    final coordState = asyncState.value ?? const CoordinatorIdle();

    void openSheet() {
      MatchRecordingActionsSheet.show(context);
    }

    return switch (coordState) {
      CoordinatorRecording() => _LifecycleBanner(
          icon: Icons.fiber_manual_record,
          color: ArenaColors.danger,
          text: 'Enregistrement anti-triche en cours\nTape pour les actions',
          onTap: openSheet,
        ),
      CoordinatorPaused() => _LifecycleBanner(
          icon: Icons.pause_circle_outline,
          color: ArenaColors.warning,
          text: 'Match en pause — tape pour reprendre ou arrêter',
          onTap: openSheet,
        ),
      CoordinatorForfeited(reason: final r) => _LifecycleBanner(
          icon: Icons.flag_outlined,
          color: ArenaColors.danger,
          text: r == 'pause_grace_expired'
              ? 'Forfait : pause dépassée'
              : 'Forfait déclaré',
        ),
      _ => const SizedBox.shrink(),
    };
  }
}

class _LifecycleBanner extends StatelessWidget {
  const _LifecycleBanner({
    required this.icon,
    required this.color,
    required this.text,
    this.onTap,
  });

  final IconData icon;
  final Color color;
  final String text;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final inner = Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: ArenaSpacing.md,
        vertical: ArenaSpacing.sm,
      ),
      color: color.withValues(alpha: 0.16),
      child: Row(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: ArenaSpacing.sm),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );

    if (onTap == null) return inner;
    return Material(
      color: Colors.transparent,
      child: InkWell(onTap: onTap, child: inner),
    );
  }
}
