import 'dart:io';

import 'package:arena/core/services/match_recording_coordinator.dart';
import 'package:arena/core/theme/arena_colors.dart';
import 'package:arena/core/theme/arena_theme.dart';
import 'package:arena/data/models/arena_match.dart';
import 'package:arena/data/models/match_status.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
    if (!Platform.isAndroid) return;
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
      final opp = _opponentId;
      if (opp == null) return;
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

  @override
  Widget build(BuildContext context) {
    if (!Platform.isAndroid || !_isPlayer) {
      return const SizedBox.shrink();
    }

    if (_startError != null) {
      return _LifecycleBanner(
        icon: Icons.warning_amber_rounded,
        color: ArenaColors.warning,
        text: 'Recording indisponible — $_startError',
      );
    }

    final asyncState = ref.watch(_coordinatorStateProvider);
    final coordState = asyncState.value ?? const CoordinatorIdle();

    return switch (coordState) {
      CoordinatorRecording() => const _LifecycleBanner(
          icon: Icons.fiber_manual_record,
          color: ArenaColors.danger,
          text: 'Enregistrement anti-triche en cours',
        ),
      CoordinatorPaused() => const _LifecycleBanner(
          icon: Icons.pause_circle_outline,
          color: ArenaColors.warning,
          text: 'Match en pause — revenez sous 2 min ou forfait auto',
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
  });

  final IconData icon;
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
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
  }
}

/// Hands the coordinator's current state to widgets that need to
/// re-render when it changes. Defined here (rather than in the
/// coordinator file) so we don't pollute the core service with a
/// UI-shaped provider.
final _coordinatorStateProvider = StreamProvider<CoordinatorState>((ref) {
  final coord = ref.watch(matchRecordingCoordinatorProvider);
  return coord.stateStream;
});
