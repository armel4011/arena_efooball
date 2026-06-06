import 'package:arena/core/router/user_router.dart';
import 'package:arena/core/theme/arena_theme.dart';
import 'package:arena/data/models/match_stream.dart';
import 'package:arena/data/repositories/match_stream_repository.dart';
import 'package:arena/features_shared/widgets/arena_badge.dart';
import 'package:arena/features_user/home/widgets/home_error_row.dart';
import 'package:arena/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Section "LIVE NOW" : affiche le stream public le plus récent dans une
/// card hero (gradient game-themed) + compteur `+N autres` si plusieurs.
/// Le lien "View all" vers `/streams` est placé directement dans la
/// caption de section côté `home_page.dart`. Source :
/// `activePublicStreamsProvider`.
class LiveStreamsSection extends ConsumerWidget {
  const LiveStreamsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final async = ref.watch(activePublicStreamsProvider);
    return async.when(
      loading: () => const _LiveLoadingCard(),
      error: (e, _) =>
          HomeErrorRow(message: '${l10n.liveStreamsErrorPrefix}$e'),
      data: (streams) {
        if (streams.isEmpty) return const _LiveEmptyCard();
        return _LiveStreamCard(
          stream: streams.first,
          allCount: streams.length,
        );
      },
    );
  }
}

/// Card hero pour le stream le plus récent — reproduit `.m-card` de la
/// maquette : gradient game-themed cyclique (eFoot / Dames / FC / signal)
/// déterministe via `hash(matchId)`, badge LIVE pulsant top-left,
/// compteur `+N autres` éventuel, et titre + caption bottom over scrim.
class _LiveStreamCard extends StatelessWidget {
  const _LiveStreamCard({required this.stream, required this.allCount});

  final MatchStream stream;
  final int allCount;

  static const _palettes = <LinearGradient>[
    ArenaColors.bannerDraughts, // rouge dames mock
    ArenaColors.bannerFc, // orange FC
    LinearGradient(
      colors: [Color(0xFF6A11CB), Color(0xFF2575FC)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ), // violet FC Mobile
    ArenaColors.bannerEfoot, // bleu signal fallback
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final matchId = stream.matchId;
    final gradient = _palettes[matchId.hashCode.abs() % _palettes.length];

    return InkWell(
      onTap: () => context.push(UserRoutes.watchStreamPath(matchId)),
      borderRadius: BorderRadius.circular(ArenaRadius.lg),
      child: Container(
        height: 110,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(ArenaRadius.lg),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child:
                  DecoratedBox(decoration: BoxDecoration(gradient: gradient)),
            ),
            // Scrim sombre bottom→top pour lisibilité du titre.
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      ArenaColors.void_.withValues(alpha: 0.65),
                    ],
                  ),
                ),
              ),
            ),
            // Badges top-left : LIVE pulsant + éventuel "+N autres".
            Positioned(
              top: 10,
              left: 10,
              child: Row(
                children: [
                  ArenaBadge(
                    label: l10n.liveStreamsBadgeLive,
                    variant: ArenaBadgeVariant.live,
                  ),
                  if (allCount > 1) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: ArenaColors.void_.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(ArenaRadius.round),
                      ),
                      child: Text(
                        l10n.liveStreamsOthersCount(allCount - 1),
                        style: ArenaText.badge.copyWith(
                          color: ArenaColors.bone,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            // Titre + sous-titre bottom-left over scrim.
            Positioned(
              bottom: 12,
              left: 12,
              right: 12,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'MATCH N°${matchId.substring(0, matchId.length > 8 ? 8 : matchId.length).toUpperCase()}',
                    style: ArenaText.h3.copyWith(
                      color: ArenaColors.bone,
                      fontSize: 15,
                      letterSpacing: 1,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    l10n.liveStreamsTapToWatch,
                    style: ArenaText.small.copyWith(
                      color: ArenaColors.bone.withValues(alpha: 0.85),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// État loading : card grise 110px (même hauteur que la hero) avec
/// progress indicator centré, pour éviter un saut de layout au resolve.
class _LiveLoadingCard extends StatelessWidget {
  const _LiveLoadingCard();
  @override
  Widget build(BuildContext context) => Container(
        height: 110,
        decoration: BoxDecoration(
          color: ArenaColors.carbon,
          borderRadius: BorderRadius.circular(ArenaRadius.lg),
          border: Border.all(color: ArenaColors.border),
        ),
        alignment: Alignment.center,
        child: const SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
}

/// État empty : "Aucun live en cours" centré, icône TV éteinte —
/// préserve la hauteur hero pour éviter un reflow.
class _LiveEmptyCard extends StatelessWidget {
  const _LiveEmptyCard();
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      height: 110,
      decoration: BoxDecoration(
        color: ArenaColors.carbon,
        borderRadius: BorderRadius.circular(ArenaRadius.lg),
        border: Border.all(color: ArenaColors.border),
      ),
      alignment: Alignment.center,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.tv_off_outlined,
            color: ArenaColors.silver,
            size: 20,
          ),
          const SizedBox(width: ArenaSpacing.sm),
          Text(
            l10n.liveStreamsEmptyState,
            style: ArenaText.bodyMuted,
          ),
        ],
      ),
    );
  }
}
