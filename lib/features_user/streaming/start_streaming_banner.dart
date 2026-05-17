import 'package:arena/core/services/agora_streaming_service.dart';
import 'package:arena/core/theme/arena_theme.dart';
import 'package:arena/data/repositories/match_stream_repository.dart';
import 'package:arena/features_shared/widgets/arena_button.dart';
import 'package:arena/features_user/auth/auth_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Inline banner displayed inside `MatchRoomPage` when the admin has
/// flipped the HOME's recording row to `is_public = true`.
///
/// Behavior:
///   * if no public stream row exists for the match → renders nothing,
///   * if the public row's owner is the current user → renders the
///     "Démarrer la diffusion live" CTA,
///   * otherwise (the OPPONENT is the broadcaster) → renders a passive
///     "Match diffusé en direct" indicator without a CTA.
class StartStreamingBanner extends ConsumerWidget {
  const StartStreamingBanner({required this.matchId, super.key});

  final String matchId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final streamsAsync = ref.watch(matchStreamsByMatchProvider(matchId));
    final myId = ref.watch(currentSessionProvider)?.user.id;

    return streamsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (streams) {
        final publicStream = streams.where((s) => s.isPublic && s.isActive);
        if (publicStream.isEmpty) return const SizedBox.shrink();

        final stream = publicStream.first;
        final isMine = myId != null && stream.playerId == myId;

        return Container(
          margin: const EdgeInsets.symmetric(
            horizontal: ArenaSpacing.md,
            vertical: ArenaSpacing.sm,
          ),
          padding: const EdgeInsets.all(ArenaSpacing.md),
          decoration: BoxDecoration(
            color: ArenaColors.danger.withValues(alpha: 0.1),
            borderRadius: ArenaRadius.card,
            border: Border.all(color: ArenaColors.danger),
            boxShadow: [
              BoxShadow(
                color: ArenaColors.danger.withValues(alpha: 0.45),
                blurRadius: 26,
                spreadRadius: -2,
              ),
            ],
          ),
          child: Row(
            children: [
              const Icon(Icons.live_tv, color: ArenaColors.danger),
              const SizedBox(width: ArenaSpacing.sm),
              Expanded(
                child: Text(
                  isMine
                      ? 'Ce match est sélectionné pour la diffusion live'
                      : 'Match diffusé en direct',
                  style: const TextStyle(
                    color: ArenaColors.text,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (isMine) ...[
                const SizedBox(width: ArenaSpacing.sm),
                ArenaButton(
                  label: 'Démarrer',
                  onPressed: () async {
                    final svc = ref.read(agoraStreamingServiceProvider);
                    try {
                      await svc.joinAsBroadcaster(matchId: matchId);
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Diffusion démarrée.')),
                      );
                    } catch (e) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Erreur: $e')),
                      );
                    }
                  },
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
