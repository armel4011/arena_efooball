import 'package:arena/core/theme/arena_theme.dart';
import 'package:arena/data/models/match_stream.dart';
import 'package:arena/data/repositories/match_stream_repository.dart';
import 'package:arena/features_shared/widgets/arena_app_bar.dart';
import 'package:arena/features_shared/widgets/arena_badge.dart';
import 'package:arena/features_shared/widgets/arena_card.dart';
import 'package:arena/features_shared/widgets/arena_screen_background.dart';
import 'package:arena/features_shared/widgets/empty_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Lists every match an admin has flagged as a live Agora stream.
///
/// Streams appear automatically when the admin flips `is_public = true`
/// on the HOME's recording row, and disappear when they flip it back
/// or when the broadcaster ends the session. Backed by
/// [activePublicStreamsProvider] which uses Supabase realtime, so
/// the list updates live.
class LiveStreamsPage extends ConsumerWidget {
  const LiveStreamsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final streamsAsync = ref.watch(activePublicStreamsProvider);

    return Scaffold(
      backgroundColor: ArenaColors.void_,
      appBar: const ArenaAppBar(title: 'Lives en cours'),
      body: ArenaScreenBackground(
        child: streamsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(
            child: Text(
              'Erreur: $e',
              style: ArenaText.body.copyWith(color: ArenaColors.danger),
            ),
          ),
          data: (streams) {
            if (streams.isEmpty) {
              return const EmptyState(
                title: 'Aucun match en direct',
                description:
                    "Les diffusions live apparaissent ici dès qu'un admin "
                    'sélectionne un match pour la diffusion.',
                icon: Icons.live_tv_outlined,
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.all(ArenaSpacing.md),
              itemCount: streams.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(height: ArenaSpacing.sm),
              itemBuilder: (context, index) =>
                  _LiveStreamCard(stream: streams[index]),
            );
          },
        ),
      ),
    );
  }
}

class _LiveStreamCard extends StatelessWidget {
  const _LiveStreamCard({required this.stream});

  final MatchStream stream;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: ArenaRadius.card,
        boxShadow: [
          BoxShadow(
            color: ArenaColors.danger.withValues(alpha: 0.32),
            blurRadius: 28,
            spreadRadius: -4,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ArenaCard(
        onTap: () => context.go('/streams/watch/${stream.matchId}'),
        child: Row(
          children: [
            const ArenaBadge(label: 'LIVE', variant: ArenaBadgeVariant.live),
            const SizedBox(width: ArenaSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Match #${stream.matchId.substring(0, 8)}',
                    style: ArenaText.h3,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Diffusé par ${stream.playerId.substring(0, 8)}…',
                    style: ArenaText.bodyMuted,
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: ArenaColors.silver),
          ],
        ),
      ),
    );
  }
}
