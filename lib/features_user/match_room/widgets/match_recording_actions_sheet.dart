import 'package:arena/core/services/match_recording_coordinator.dart';
import 'package:arena/core/theme/arena_theme.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Modal bottom sheet with every recording action available from the
/// match room (PHASE 8 fallback when the floating overlay is killed by
/// the OEM or the user can't reach it). The same widget is reachable
/// from the floating button itself (tap → focusMain → autoShow this
/// sheet) so the two surfaces stay in sync.
class MatchRecordingActionsSheet extends ConsumerWidget {
  const MatchRecordingActionsSheet({super.key});

  static Future<void> show(BuildContext context) {
    // isScrollControlled: true so the sheet can grow past the default 50%
    // cap when the device has chunky bottom system bars (MIUI gesture nav
    // adds ~30 dp, which overflowed the 4-tile column on Android 15).
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: ArenaColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => const MatchRecordingActionsSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncState = ref.watch(coordinatorStateProvider);
    final state = asyncState.value ?? const CoordinatorIdle();
    final coord = ref.read(matchRecordingCoordinatorProvider);

    final isPaused = state is CoordinatorPaused;
    final isLive = state is CoordinatorRecording || state is CoordinatorPaused;

    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                ArenaSpacing.lg,
                ArenaSpacing.xs,
                ArenaSpacing.lg,
                ArenaSpacing.sm,
              ),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _stateDotColor(state),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: ArenaSpacing.sm),
                  Text(
                    _stateLabel(state),
                    style: ArenaText.inputLabel.copyWith(
                      color: ArenaColors.silver,
                    ),
                  ),
                ],
              ),
            ),
            if (isLive) ...[
              if (isPaused)
                _ActionTile(
                  icon: Icons.play_arrow,
                  color: ArenaColors.success,
                  label: 'Continuer',
                  onTap: () {
                    coord.resume();
                    Navigator.of(context).pop();
                  },
                )
              else
                _ActionTile(
                  icon: Icons.pause,
                  color: ArenaColors.warning,
                  label: 'Pause (max 2 min)',
                  onTap: () {
                    coord.pause();
                    Navigator.of(context).pop();
                  },
                ),
              _ActionTile(
                icon: Icons.save_alt,
                color: ArenaColors.success,
                label: 'Enregistrer et arrêter',
                onTap: () => _onStopAndExport(context, coord),
              ),
              _ActionTile(
                icon: Icons.stop_circle_outlined,
                color: ArenaColors.danger,
                label: 'Arrêter (forfait)',
                onTap: () async {
                  Navigator.of(context).pop();
                  await coord.declareForfeit();
                },
              ),
            ] else
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: ArenaSpacing.lg,
                  vertical: ArenaSpacing.md,
                ),
                child: Text(
                  'Aucun enregistrement en cours.',
                  style: ArenaText.bodyMuted,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _onStopAndExport(
    BuildContext context,
    MatchRecordingCoordinator coord,
  ) async {
    Navigator.of(context).pop();
    try {
      await coord.stopCleanly();
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('[recording] stopAndExport stopCleanly failed: $e\n$st');
      }
    }
  }

  Color _stateDotColor(CoordinatorState s) => switch (s) {
        CoordinatorRecording() => ArenaColors.danger,
        CoordinatorPaused() => ArenaColors.warning,
        CoordinatorForfeited() => ArenaColors.danger,
        CoordinatorStopped() => ArenaColors.silver,
        CoordinatorIdle() => ArenaColors.silver,
      };

  String _stateLabel(CoordinatorState s) => switch (s) {
        CoordinatorRecording() => 'Enregistrement en cours',
        CoordinatorPaused() => 'En pause — reprends sous 2 min',
        CoordinatorForfeited() => 'Forfait déclaré',
        CoordinatorStopped() => 'Enregistrement arrêté',
        CoordinatorIdle() => 'Aucun enregistrement',
      };
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.color,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(
        label,
        style: ArenaText.body.copyWith(color: ArenaColors.text),
      ),
      onTap: onTap,
    );
  }
}

/// Stream of the coordinator's current state. Exposed here so the
/// match-room banner and the actions sheet share the same source of
/// truth without redeclaring a private provider in each file.
final coordinatorStateProvider = StreamProvider<CoordinatorState>((ref) {
  final coord = ref.watch(matchRecordingCoordinatorProvider);
  return coord.stateStream;
});

/// Emits each time the overlay sends a focusMain — used by the match
/// room widget to auto-open the actions sheet right after ARENA comes
/// back to front from a tap on the floating button.
final coordinatorFocusRequestsProvider = StreamProvider<void>((ref) {
  final coord = ref.watch(matchRecordingCoordinatorProvider);
  return coord.focusRequests;
});

/// Emits when the overlay's mini "save & stop" button is tapped — the
/// match-room widget exports the just-finished MP4 via GalleryExporter
/// and shows a snackbar. Carries the local file path (or null on
/// stop failure).
final coordinatorSaveStopRequestsProvider = StreamProvider<String?>((ref) {
  final coord = ref.watch(matchRecordingCoordinatorProvider);
  return coord.saveStopRequests;
});

/// Emits le matchId quand l'overlay envoie `ask_go_live` (5ᵉ mini) :
/// le recording a déjà été stoppé par le coordinator, le listener
/// dans `MatchRecordingLifecycle` doit appeler `joinAsBroadcaster`.
final coordinatorGoLiveRequestsProvider = StreamProvider<String>((ref) {
  final coord = ref.watch(matchRecordingCoordinatorProvider);
  return coord.goLiveRequests;
});
