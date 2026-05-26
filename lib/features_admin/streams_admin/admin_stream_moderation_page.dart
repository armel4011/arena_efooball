import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:arena/core/services/agora_multi_streaming_service.dart';
import 'package:arena/core/theme/arena_theme.dart';
import 'package:arena/data/models/match_stream.dart';
import 'package:arena/data/repositories/admin/admin_audit_log_repository.dart';
import 'package:arena/data/repositories/match_stream_repository.dart';
import 'package:arena/features_admin/streams_admin/admin_multi_stream_controller.dart';
import 'package:arena/features_shared/auth_common/shared_auth_providers.dart';
import 'package:arena/features_shared/widgets/arena_app_bar.dart';
import 'package:arena/features_shared/widgets/arena_badge.dart';
import 'package:arena/features_shared/widgets/arena_screen_background.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// PHASE 11 · A12 — multi-stream moderation grid avec vraies vidéos
/// live (multiplex via [AgoraMultiStreamingService] + `joinChannelEx`).
///
/// Reads live public streams via [activePublicStreamsProvider]. Pour
/// chaque match actif, [adminMultiStreamStatesProvider] join un canal
/// audience en parallèle et émet l'uid distant dès qu'il arrive — la
/// tuile affiche alors `AgoraVideoView`. L'audio est mute par défaut
/// (4 streams = bouillie) ; tap sur une tuile = focus audio (mute tous
/// les autres). Retap = mute global.
///
/// Le kill switch flip `streams.is_public = false`, audit log inchangé.
class AdminStreamModerationPage extends ConsumerWidget {
  const AdminStreamModerationPage({super.key});

  static const _capacity = 6;
  static const _gradients = <LinearGradient>[
    ArenaColors.streamSlot1Gradient,
    ArenaColors.streamSlot2Gradient,
    ArenaColors.streamSlot3Gradient,
    ArenaColors.streamSlot4Gradient,
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final streams = ref.watch(activePublicStreamsProvider);
    final tiles =
        ref.watch(adminMultiStreamStatesProvider).value ?? const {};

    return Scaffold(
      appBar: const ArenaAppBar(title: '🔴 STREAMS'),
      body: ArenaScreenBackground(
        accent: ArenaColors.neonRed,
        child: SafeArea(
          child: streams.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Padding(
              padding: const EdgeInsets.all(ArenaSpacing.lg),
              child: Text(
                'Erreur de chargement : $e',
                style: ArenaText.bodyMuted,
              ),
            ),
            data: (list) => ListView(
              padding: const EdgeInsets.all(ArenaSpacing.lg),
              children: [
                _SummaryCard(streams: list),
                const SizedBox(height: ArenaSpacing.md),
                if (list.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(ArenaSpacing.lg),
                    child: Text(
                      'Aucun stream public actif.',
                      style: ArenaText.bodyMuted,
                      textAlign: TextAlign.center,
                    ),
                  )
                else
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    childAspectRatio: 0.95,
                    crossAxisSpacing: ArenaSpacing.xs,
                    mainAxisSpacing: ArenaSpacing.xs,
                    children: [
                      for (var i = 0; i < list.length; i++)
                        _StreamTile(
                          stream: list[i],
                          gradient: _gradients[i % _gradients.length],
                          tileState: tiles[list[i].matchId],
                        ),
                      if (list.length < _capacity)
                        _EmptySlot(
                          used: list.length,
                          total: _capacity,
                        ),
                    ],
                  ),
                const SizedBox(height: ArenaSpacing.lg),
                Container(
                  padding: const EdgeInsets.all(ArenaSpacing.md),
                  decoration: arenaWarningCardDecoration(),
                  child: Text(
                    '⚠ Couper un stream est journalisé dans admin_audit_log '
                    'avec ton ID admin. Tap une tuile = focus audio.',
                    style: ArenaText.body,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.streams});
  final List<MatchStream> streams;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(ArenaSpacing.md),
      decoration: arenaGlowCardDecoration(),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${streams.length} stream${streams.length > 1 ? 's' : ''} actif${streams.length > 1 ? 's' : ''}',
                  style: ArenaText.h3,
                ),
                const SizedBox(height: 2),
                Text(
                  'Sur ${AdminStreamModerationPage._capacity} max simultanés',
                  style: ArenaText.bodyMuted,
                ),
              ],
            ),
          ),
          if (streams.isNotEmpty)
            const ArenaBadge(label: 'LIVE', variant: ArenaBadgeVariant.live),
        ],
      ),
    );
  }
}

class _StreamTile extends ConsumerWidget {
  const _StreamTile({
    required this.stream,
    required this.gradient,
    required this.tileState,
  });

  final MatchStream stream;
  final LinearGradient gradient;
  final MultiTileState? tileState;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ts = tileState;
    final audioFocused = ts is MultiTileJoined && ts.audioFocused;

    return Container(
      decoration: BoxDecoration(
        color: ArenaColors.carbon,
        borderRadius: BorderRadius.circular(ArenaRadius.lg),
        border: Border.all(
          color: audioFocused
              ? ArenaColors.signalBlue
              : ArenaColors.border,
          width: audioFocused ? 2 : 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GestureDetector(
            onTap: () => ref
                .read(agoraMultiStreamingServiceProvider)
                .focusAudio(stream.matchId),
            child: SizedBox(
              height: 110,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _TileMedia(state: ts, gradient: gradient),
                  const Positioned(
                    top: 4,
                    left: 4,
                    child: ArenaBadge(
                      label: 'LIVE',
                      variant: ArenaBadgeVariant.live,
                    ),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: ArenaColors.blackPure.withValues(alpha: 0.6),
                        shape: BoxShape.circle,
                      ),
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: Icon(
                          audioFocused ? Icons.volume_up : Icons.volume_off,
                          size: 14,
                          color: audioFocused
                              ? ArenaColors.signalBlue
                              : ArenaColors.silver,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 4,
                    left: 4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: ArenaColors.blackPure.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(2),
                      ),
                      child: Text(
                        'M-${stream.matchId.substring(0, 6)}',
                        style: ArenaText.body.copyWith(
                          color: ArenaColors.bone,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Streamer ${stream.playerId.substring(0, 6)}',
                  style: ArenaText.body.copyWith(fontSize: 9),
                ),
                const SizedBox(height: 4),
                _MiniButton(
                  label: '🔇 COUPER',
                  danger: true,
                  onTap: () => _cut(context, ref),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _cut(BuildContext context, WidgetRef ref) async {
    final adminId = ref.read(currentSessionProvider)?.user.id;
    if (adminId == null) return;
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
      await ref.read(matchStreamRepositoryProvider).setStreamingPublic(
            streamId: stream.id,
            isPublic: false,
          );
      await ref.read(adminAuditLogRepositoryProvider).record(
        adminId: adminId,
        action: 'stream_cut',
        targetType: 'stream',
        targetId: stream.id,
        afterState: {'match_id': stream.matchId},
      );
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Stream coupé.')),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Échec : $e')),
      );
    }
  }
}

class _TileMedia extends ConsumerWidget {
  const _TileMedia({required this.state, required this.gradient});

  final MultiTileState? state;
  final LinearGradient gradient;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = state;
    if (s is MultiTileJoined && s.remoteUid != null) {
      final engine = ref.watch(agoraMultiStreamingServiceProvider).engine;
      if (engine != null) {
        return AgoraVideoView(
          controller: VideoViewController.remote(
            rtcEngine: engine,
            canvas: VideoCanvas(uid: s.remoteUid),
            connection: s.connection,
          ),
        );
      }
    }
    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(decoration: BoxDecoration(gradient: gradient)),
        Center(
          child: switch (s) {
            MultiTileFailed() => Icon(
                Icons.error_outline,
                size: 20,
                color: ArenaColors.bone.withValues(alpha: 0.7),
              ),
            _ => const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
          },
        ),
      ],
    );
  }
}

class _EmptySlot extends StatelessWidget {
  const _EmptySlot({required this.used, required this.total});

  final int used;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(ArenaSpacing.md),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(ArenaRadius.lg),
        border: Border.all(
          color: ArenaColors.silverDim,
          width: 1.5,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '+',
              style: ArenaText.bigNumber.copyWith(
                color: ArenaColors.silverDim,
                fontSize: 24,
              ),
            ),
            const SizedBox(height: 4),
            Text('Slot libre', style: ArenaText.bodyMuted),
            const SizedBox(height: 2),
            Text(
              '$used/$total utilisés',
              style: ArenaText.small,
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniButton extends StatelessWidget {
  const _MiniButton({
    required this.label,
    required this.onTap,
    this.danger = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(ArenaRadius.sm),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        decoration: BoxDecoration(
          color: danger ? ArenaColors.neonRed : ArenaColors.carbon2,
          borderRadius: BorderRadius.circular(ArenaRadius.sm),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: ArenaText.badge.copyWith(
            color: ArenaColors.bone,
            fontSize: 9,
          ),
        ),
      ),
    );
  }
}
