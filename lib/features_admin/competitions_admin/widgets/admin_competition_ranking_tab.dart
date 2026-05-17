import 'package:arena/core/theme/arena_theme.dart';
import 'package:arena/data/repositories/admin/admin_competitions_repository.dart';
import 'package:arena/features_admin/competitions_admin/widgets/admin_competition_registrants_tab.dart'
    show registrantAvatarColor;
import 'package:arena/features_shared/prize_ranks.dart';
import 'package:arena/features_shared/widgets/arena_avatar.dart';
import 'package:arena/features_shared/widgets/arena_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Onglet CLASSEMENT — l'admin saisit le rang d'arrivée final de chaque
/// participant. Les rangs alimentent l'écran joueur (podium + gains
/// croisés avec `prize_distribution`). Réutilise le provider des
/// inscrits ; le tri par rang se fait côté client.
class AdminCompetitionRankingTab extends ConsumerWidget {
  const AdminCompetitionRankingTab({required this.competitionId, super.key});
  final String competitionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(adminCompetitionRegistrantsProvider(competitionId));

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(adminCompetitionRegistrantsProvider(competitionId));
        await ref.read(
          adminCompetitionRegistrantsProvider(competitionId).future,
        );
      },
      child: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ListView(
          padding: const EdgeInsets.all(ArenaSpacing.lg),
          children: [Text('Erreur : $e', style: ArenaText.bodyMuted)],
        ),
        data: (list) {
          if (list.isEmpty) {
            return ListView(
              padding: const EdgeInsets.all(ArenaSpacing.lg),
              children: [
                Text(
                  'Aucun inscrit — le classement se remplira une fois '
                  'les inscriptions ouvertes.',
                  style: ArenaText.bodyMuted,
                ),
              ],
            );
          }
          final sorted = [...list]..sort((a, b) {
              final ra = a.finalRank ?? 1 << 30;
              final rb = b.finalRank ?? 1 << 30;
              if (ra != rb) return ra.compareTo(rb);
              return a.username
                  .toLowerCase()
                  .compareTo(b.username.toLowerCase());
            });
          final ranked = list.where((r) => r.finalRank != null).length;
          return ListView.separated(
            padding: const EdgeInsets.all(ArenaSpacing.lg),
            itemCount: sorted.length + 1,
            separatorBuilder: (_, __) =>
                const SizedBox(height: ArenaSpacing.xs),
            itemBuilder: (_, i) {
              if (i == 0) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: ArenaSpacing.sm),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ArenaButton(
                        label: '⚡ CLASSEMENT AUTOMATIQUE',
                        variant: ArenaButtonVariant.secondary,
                        fullWidth: true,
                        onPressed: () => _autoRank(context, ref),
                      ),
                      const SizedBox(height: ArenaSpacing.xs),
                      Text(
                        'Critères : niveau atteint dans la compétition, '
                        'puis buts marqués, puis ordre alphabétique. '
                        'Ajustable manuellement ensuite.',
                        style: ArenaText.small,
                      ),
                      const SizedBox(height: ArenaSpacing.sm),
                      Text(
                        '$ranked/${list.length} '
                        'classé${ranked > 1 ? "s" : ""}',
                        style: ArenaText.inputLabel,
                      ),
                    ],
                  ),
                );
              }
              return _RankingRow(
                competitionId: competitionId,
                registrant: sorted[i - 1],
                participantCount: list.length,
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _autoRank(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: ArenaColors.carbon,
        title: Text('Calculer le classement ?', style: ArenaText.h3),
        content: Text(
          'Les rangs seront recalculés à partir des résultats de matchs '
          '(niveau atteint, buts marqués, ordre alphabétique). Cela '
          'écrase les rangs déjà saisis manuellement.',
          style: ArenaText.bodyMuted,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(c).pop(false),
            child: const Text('ANNULER'),
          ),
          TextButton(
            onPressed: () => Navigator.of(c).pop(true),
            child: const Text('CALCULER'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref
          .read(adminCompetitionsRepositoryProvider)
          .autoRankFromResults(competitionId);
      ref.invalidate(adminCompetitionRegistrantsProvider(competitionId));
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Classement calculé automatiquement.')),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Échec : $e')),
      );
    }
  }
}

class _RankingRow extends ConsumerWidget {
  const _RankingRow({
    required this.competitionId,
    required this.registrant,
    required this.participantCount,
  });

  final String competitionId;
  final AdminCompetitionRegistrant registrant;
  final int participantCount;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rank = registrant.finalRank;
    final initials = registrant.username.isNotEmpty
        ? registrant.username.substring(0, 1).toUpperCase()
        : '?';
    return Container(
      padding: const EdgeInsets.all(ArenaSpacing.md),
      decoration: BoxDecoration(
        color: ArenaColors.carbon,
        borderRadius: BorderRadius.circular(ArenaRadius.lg),
        border: Border.all(color: ArenaColors.border),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: Text(
              rank == null ? '—' : prizeRankEmoji(rank - 1),
              style: ArenaText.body,
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: ArenaSpacing.xs),
          ArenaAvatar(
            initials: initials,
            color: registrantAvatarColor(registrant.username),
            size: ArenaAvatarSize.sm,
          ),
          const SizedBox(width: ArenaSpacing.sm),
          Expanded(
            child: Text(
              registrant.username,
              style: ArenaText.body,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: ArenaSpacing.sm),
          DropdownButton<int?>(
            value: rank,
            hint: Text('Rang', style: ArenaText.bodyMuted),
            dropdownColor: ArenaColors.carbon,
            underline: const SizedBox.shrink(),
            style: ArenaText.body,
            items: [
              DropdownMenuItem<int?>(
                child: Text('—', style: ArenaText.bodyMuted),
              ),
              for (var n = 1; n <= participantCount; n++)
                DropdownMenuItem<int?>(
                  value: n,
                  child: Text('Rang $n', style: ArenaText.body),
                ),
            ],
            onChanged: (value) => _setRank(context, ref, value),
          ),
        ],
      ),
    );
  }

  Future<void> _setRank(
    BuildContext context,
    WidgetRef ref,
    int? rank,
  ) async {
    try {
      await ref
          .read(adminCompetitionsRepositoryProvider)
          .setFinalRank(competitionId, registrant.playerId, rank);
      ref.invalidate(adminCompetitionRegistrantsProvider(competitionId));
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            rank == null
                ? 'Rang effacé pour ${registrant.username}.'
                : '${registrant.username} → rang $rank.',
          ),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Échec : $e')),
      );
    }
  }
}
