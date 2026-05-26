import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:arena/core/router/admin_router.dart';
import 'package:arena/core/services/agora_multi_streaming_service.dart';
import 'package:arena/core/theme/arena_theme.dart';
import 'package:arena/data/repositories/admin/admin_audit_log_repository.dart';
import 'package:arena/data/repositories/match_stream_repository.dart';
import 'package:arena/features_admin/streams_admin/admin_multi_stream_controller.dart';
import 'package:arena/features_shared/auth_common/shared_auth_providers.dart';
import 'package:arena/features_shared/widgets/arena_badge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Page admin de visionnage plein-écran d'un stream live.
///
/// Réutilise la `RtcConnection` déjà jointe par
/// [AgoraMultiStreamingService] (le service reste vivant tant que la
/// page de modération est dans la stack underneath). Si le matchId
/// n'est pas encore dans `service.states` (ex : ouverture via deep
/// link sans passer par la grille), on déclenche `joinAudience` au
/// mount.
///
/// Actions disponibles depuis l'app bar :
/// - 🔊 / 🔇 toggle audio
/// - 🛑 COUPER (kill switch : flip `is_public = false` + audit log)
class AdminWatchStreamPage extends ConsumerStatefulWidget {
  const AdminWatchStreamPage({required this.matchId, super.key});

  final String matchId;

  @override
  ConsumerState<AdminWatchStreamPage> createState() =>
      _AdminWatchStreamPageState();
}

class _AdminWatchStreamPageState extends ConsumerState<AdminWatchStreamPage> {
  @override
  void initState() {
    super.initState();
    // Force la subscription au sync provider — au cas où la fullscreen
    // serait ouverte sans la grille de modération underneath.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(adminMultiStreamStatesProvider);
      final svc = ref.read(agoraMultiStreamingServiceProvider);
      if (!svc.states.containsKey(widget.matchId)) {
        svc.joinAudience(widget.matchId);
      }
      // Audio actif par défaut en fullscreen (sinon ça n'a aucun sens).
      svc.focusAudio(widget.matchId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final tilesAsync = ref.watch(adminMultiStreamStatesProvider);
    final tiles = tilesAsync.value ?? const <String, MultiTileState>{};
    final tile = tiles[widget.matchId];
    final engine = ref.watch(agoraMultiStreamingServiceProvider).engine;
    final isAudioFocused = tile is MultiTileJoined && tile.audioFocused;

    return Scaffold(
      backgroundColor: ArenaColors.blackPure,
      body: SafeArea(
        child: Stack(
          children: [
            // Vidéo plein-écran (ou état d'attente / erreur).
            Positioned.fill(
              child: _buildVideo(tile: tile, engine: engine),
            ),
            // Bandeau supérieur — back + badge LIVE + match ID.
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: _TopBar(
                matchId: widget.matchId,
                onBack: () => context.go(AdminRoutes.streams),
              ),
            ),
            // Bandeau inférieur — actions modération.
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _BottomActions(
                matchId: widget.matchId,
                isAudioFocused: isAudioFocused,
                onToggleAudio: () => ref
                    .read(agoraMultiStreamingServiceProvider)
                    .focusAudio(widget.matchId),
                onCut: () => _cut(context, ref),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideo({required MultiTileState? tile, required RtcEngineEx? engine}) {
    if (tile is MultiTileJoined && tile.remoteUid != null && engine != null) {
      return AgoraVideoView(
        controller: VideoViewController.remote(
          rtcEngine: engine,
          canvas: VideoCanvas(uid: tile.remoteUid),
          connection: tile.connection,
        ),
      );
    }
    return Center(
      child: switch (tile) {
        MultiTileFailed(reason: final r) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                size: 48,
                color: ArenaColors.danger,
              ),
              const SizedBox(height: ArenaSpacing.sm),
              Text(
                'Échec join : $r',
                style: ArenaText.bodyMuted,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        _ => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(strokeWidth: 2),
              const SizedBox(height: ArenaSpacing.md),
              Text(
                tile is MultiTileJoined
                    ? 'Attente du broadcaster…'
                    : 'Connexion au stream…',
                style: ArenaText.bodyMuted,
              ),
            ],
          ),
      },
    );
  }

  Future<void> _cut(BuildContext context, WidgetRef ref) async {
    final adminId = ref.read(currentSessionProvider)?.user.id;
    if (adminId == null) return;
    final repo = ref.read(matchStreamRepositoryProvider);
    // On charge l'id du stream à partir du matchId (le row streams).
    final allActive = await repo.listActivePublic();
    final stream = allActive.firstWhere(
      (s) => s.matchId == widget.matchId,
      orElse: () => throw StateError('stream introuvable pour ${widget.matchId}'),
    );
    if (!context.mounted) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: ArenaColors.carbon,
        title: Text('Couper ce stream ?', style: ArenaText.h3),
        content: Text(
          'Le stream sera retiré de la liste publique et les viewers '
          'seront déconnectés.',
          style: ArenaText.bodyMuted,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(c).pop(false),
            child: const Text('ANNULER'),
          ),
          TextButton(
            onPressed: () => Navigator.of(c).pop(true),
            style: TextButton.styleFrom(foregroundColor: ArenaColors.neonRed),
            child: const Text('COUPER'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await repo.setStreamingPublic(streamId: stream.id, isPublic: false);
      await ref.read(adminAuditLogRepositoryProvider).record(
        adminId: adminId,
        action: 'stream_cut',
        targetType: 'stream',
        targetId: stream.id,
        afterState: {'match_id': stream.matchId, 'from': 'fullscreen'},
      );
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Stream coupé.')),
      );
      context.go(AdminRoutes.streams);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Échec : $e')),
      );
    }
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.matchId, required this.onBack});

  final String matchId;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            ArenaColors.blackPure.withValues(alpha: 0.85),
            ArenaColors.blackPure.withValues(alpha: 0),
          ],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: ArenaSpacing.md,
          vertical: ArenaSpacing.sm,
        ),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back, color: ArenaColors.bone),
              onPressed: onBack,
            ),
            const SizedBox(width: ArenaSpacing.sm),
            const ArenaBadge(
              label: 'LIVE',
              variant: ArenaBadgeVariant.live,
            ),
            const SizedBox(width: ArenaSpacing.sm),
            Text(
              'M-${matchId.substring(0, 8)}',
              style: ArenaText.mono.copyWith(color: ArenaColors.bone),
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomActions extends StatelessWidget {
  const _BottomActions({
    required this.matchId,
    required this.isAudioFocused,
    required this.onToggleAudio,
    required this.onCut,
  });

  final String matchId;
  final bool isAudioFocused;
  final VoidCallback onToggleAudio;
  final VoidCallback onCut;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            ArenaColors.blackPure.withValues(alpha: 0.85),
            ArenaColors.blackPure.withValues(alpha: 0),
          ],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: ArenaSpacing.lg,
          vertical: ArenaSpacing.lg,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _ActionButton(
              icon: isAudioFocused ? Icons.volume_up : Icons.volume_off,
              label: isAudioFocused ? 'AUDIO ON' : 'AUDIO OFF',
              accent: isAudioFocused
                  ? ArenaColors.signalBlue
                  : ArenaColors.silver,
              onTap: onToggleAudio,
            ),
            _ActionButton(
              icon: Icons.stop_circle_outlined,
              label: 'COUPER',
              accent: ArenaColors.neonRed,
              onTap: onCut,
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.accent,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(ArenaRadius.lg),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: ArenaSpacing.md,
          vertical: ArenaSpacing.sm,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: accent, size: 28),
            const SizedBox(height: 4),
            Text(
              label,
              style: ArenaText.monoSmall.copyWith(color: accent),
            ),
          ],
        ),
      ),
    );
  }
}
