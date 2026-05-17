import 'package:arena/core/theme/arena_theme.dart';
import 'package:arena/data/models/arena_match.dart';
import 'package:arena/data/repositories/match_repository.dart';
import 'package:arena/features_shared/widgets/arena_avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Onglet MATCHS — liste les matchs générés pour la compétition
/// (`competitionMatchesProvider`). Pas d'action admin sur ces rows pour
/// l'instant : la gestion fine se fait via /admin/bracket/{id}.
class AdminCompetitionMatchesTab extends ConsumerWidget {
  const AdminCompetitionMatchesTab({required this.competitionId, super.key});
  final String competitionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final matchesAsync =
        ref.watch(competitionMatchesProvider(competitionId));

    return matchesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) =>
          Padding(
        padding: const EdgeInsets.all(ArenaSpacing.lg),
        child: Text('Erreur : $e', style: ArenaText.bodyMuted),
      ),
      data: (matches) => matches.isEmpty
          ? Padding(
              padding: const EdgeInsets.all(ArenaSpacing.lg),
              child: Text(
                'Aucun match — génère le bracket.',
                style: ArenaText.bodyMuted,
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(ArenaSpacing.lg),
              itemCount: matches.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(height: ArenaSpacing.sm),
              itemBuilder: (_, i) => _MatchRow(match: matches[i]),
            ),
    );
  }
}

class _MatchRow extends StatelessWidget {
  const _MatchRow({required this.match});
  final ArenaMatch match;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(ArenaSpacing.md),
      decoration: BoxDecoration(
        color: ArenaColors.carbon,
        borderRadius: BorderRadius.circular(ArenaRadius.lg),
        border: Border.all(color: ArenaColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(
                'Round ${match.round ?? "—"} · M${match.matchNumber ?? "?"}',
                style: ArenaText.bodyMuted,
              ),
              const Spacer(),
              Text(
                'M-${match.id.substring(0, 6)}',
                style: ArenaText.monoSmall,
              ),
            ],
          ),
          const SizedBox(height: ArenaSpacing.sm),
          _PlayerRow(
            playerId: match.player1Id,
            score: match.score1,
            color: ArenaAvatarColor.blue,
          ),
          const SizedBox(height: 4),
          _PlayerRow(
            playerId: match.player2Id,
            score: match.score2,
            color: ArenaAvatarColor.green,
          ),
        ],
      ),
    );
  }
}

class _PlayerRow extends StatelessWidget {
  const _PlayerRow({
    required this.playerId,
    required this.score,
    required this.color,
  });
  final String? playerId;
  final int? score;
  final ArenaAvatarColor color;

  @override
  Widget build(BuildContext context) {
    final label =
        playerId == null ? 'TBD' : playerId!.substring(0, 8);
    return Row(
      children: [
        ArenaAvatar(
          initials: label[0],
          color: color,
          size: ArenaAvatarSize.sm,
        ),
        const SizedBox(width: ArenaSpacing.sm),
        Expanded(child: Text(label, style: ArenaText.body)),
        Text(
          score?.toString() ?? '—',
          style: ArenaText.bigNumber.copyWith(fontSize: 18),
        ),
      ],
    );
  }
}
