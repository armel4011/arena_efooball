import 'package:arena/core/router/user_router.dart';
import 'package:arena/core/theme/arena_theme.dart';
import 'package:arena/data/models/match_stream.dart';
import 'package:arena/data/repositories/match_stream_repository.dart';
import 'package:arena/features_shared/widgets/arena_badge.dart';
import 'package:arena/features_user/home/widgets/home_error_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Section "Lives en cours" : affiche le stream public le plus récent,
/// avec un compteur "+N autres" si plusieurs sont actifs.
/// Source : `activePublicStreamsProvider`.
class LiveStreamsSection extends ConsumerWidget {
  const LiveStreamsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(activePublicStreamsProvider);
    return async.when(
      loading: () => const _LiveLoadingCard(),
      error: (e, _) => HomeErrorRow(message: 'Erreur : $e'),
      data: (streams) {
        if (streams.isEmpty) {
          return Container(
            height: 80,
            decoration: BoxDecoration(
              color: ArenaColors.carbon,
              borderRadius: BorderRadius.circular(ArenaRadius.lg),
              border: Border.all(color: ArenaColors.border),
            ),
            alignment: Alignment.center,
            child: Text(
              'Aucun live en cours.',
              style: ArenaText.bodyMuted,
            ),
          );
        }
        final top = streams.first;
        return _LiveStreamCard(stream: top, allCount: streams.length);
      },
    );
  }
}

class _LiveLoadingCard extends StatelessWidget {
  const _LiveLoadingCard();
  @override
  Widget build(BuildContext context) => Container(
        height: 80,
        decoration: BoxDecoration(
          color: ArenaColors.carbon,
          borderRadius: BorderRadius.circular(ArenaRadius.lg),
          border: Border.all(color: ArenaColors.border),
        ),
        alignment: Alignment.center,
        child: const CircularProgressIndicator(strokeWidth: 2),
      );
}

class _LiveStreamCard extends StatelessWidget {
  const _LiveStreamCard({required this.stream, required this.allCount});

  final MatchStream stream;
  final int allCount;

  @override
  Widget build(BuildContext context) {
    final matchId = stream.matchId;
    return InkWell(
      onTap: () => context.push(UserRoutes.watchStreamPath(matchId)),
      borderRadius: BorderRadius.circular(ArenaRadius.lg),
      child: Container(
        height: 80,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(ArenaRadius.lg),
        ),
        child: Stack(
          children: [
            const Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: ArenaColors.bannerFifa,
                ),
              ),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      ArenaColors.void_.withValues(alpha: 0.55),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              top: 8,
              left: 8,
              child: Row(
                children: [
                  const ArenaBadge(
                    label: 'LIVE',
                    variant: ArenaBadgeVariant.live,
                  ),
                  if (allCount > 1) ...[
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: ArenaColors.void_.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(ArenaRadius.round),
                      ),
                      child: Text(
                        '+${allCount - 1} autres',
                        style:
                            ArenaText.badge.copyWith(color: ArenaColors.bone),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Positioned(
              bottom: 8,
              left: 8,
              right: 8,
              child: Text(
                'Match #${stream.matchId.substring(0, 8)} • Tape pour regarder',
                style: ArenaText.body.copyWith(
                  color: ArenaColors.bone,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
