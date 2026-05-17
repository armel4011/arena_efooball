import 'package:arena/core/router/user_router.dart';
import 'package:arena/core/theme/arena_theme.dart';
import 'package:arena/data/models/competition.dart';
import 'package:arena/data/models/competition_enums.dart';
import 'package:arena/data/repositories/competition_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Filtre courant (par jeu) appliqué à la liste des compétitions
/// actives sur la home. `null` = "Tous".
final homeGameFilterProvider = StateProvider<GameType?>((_) => null);

/// Section "Compétitions actives" : 3 chips de filtre par jeu +
/// jusqu'à 3 cards de compétitions en `registrationOpen`/`ongoing`.
class ActiveCompetitionsSection extends ConsumerWidget {
  const ActiveCompetitionsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(homeGameFilterProvider);
    final async = ref.watch(competitionsListProvider(filter));
    return Column(
      children: [
        const _GameFilterChips(),
        const SizedBox(height: ArenaSpacing.sm),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: ArenaSpacing.lg),
          child: async.when(
            loading: () => const SizedBox(
              height: 80,
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => Text(
              'Erreur : $e',
              style: const TextStyle(color: ArenaColors.danger),
            ),
            data: (all) {
              final active = all
                  .where(
                    (c) =>
                        c.status == CompetitionStatus.registrationOpen ||
                        c.status == CompetitionStatus.ongoing,
                  )
                  .take(3)
                  .toList(growable: false);
              if (active.isEmpty) {
                return Container(
                  decoration: BoxDecoration(
                    color: ArenaColors.carbon,
                    borderRadius: BorderRadius.circular(ArenaRadius.lg),
                    border: Border.all(color: ArenaColors.border),
                  ),
                  padding: const EdgeInsets.all(ArenaSpacing.md),
                  alignment: Alignment.center,
                  child: Text(
                    'Aucune compétition active pour ce filtre.',
                    style: ArenaText.bodyMuted,
                  ),
                );
              }
              return Column(
                children: [
                  for (final c in active) ...[
                    _CompetitionCard(competition: c),
                    const SizedBox(height: ArenaSpacing.sm),
                  ],
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

class _GameFilterChips extends ConsumerWidget {
  const _GameFilterChips();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(homeGameFilterProvider);
    final items = <(String, GameType?)>[
      ('Tous', null),
      ('eFoot', GameType.efootball),
      ('FIFA', GameType.fifaMobile),
      ('FC Mobile', GameType.eaSportsFc),
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: ArenaSpacing.lg),
      child: Row(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            _Chip(
              label: items[i].$1,
              selected: items[i].$2 == current,
              onTap: () => ref
                  .read(homeGameFilterProvider.notifier)
                  .state = items[i].$2,
            ),
            if (i < items.length - 1) const SizedBox(width: ArenaSpacing.xs),
          ],
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(ArenaRadius.round),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: ArenaSpacing.md,
          vertical: 6,
        ),
        decoration: BoxDecoration(
          color: selected
              ? ArenaColors.signalBlue.withValues(alpha: 0.15)
              : ArenaColors.carbon,
          borderRadius: BorderRadius.circular(ArenaRadius.round),
          border: Border.all(
            color:
                selected ? ArenaColors.signalBlue : ArenaColors.border,
          ),
        ),
        child: Text(
          label,
          style: ArenaText.body.copyWith(
            color: selected ? ArenaColors.signalBlue : ArenaColors.silver,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _CompetitionCard extends StatelessWidget {
  const _CompetitionCard({required this.competition});
  final Competition competition;

  @override
  Widget build(BuildContext context) {
    final c = competition;
    final emoji = switch (c.game) {
      GameType.efootball => '⚽',
      GameType.fifaMobile => '🎮',
      GameType.eaSportsFc => '🎯',
    };
    final daysToStart = c.startDate.difference(DateTime.now()).inDays;
    final startLabel = daysToStart > 0
        ? 'Démarre dans ${daysToStart}j'
        : daysToStart == 0
            ? "Démarre aujourd'hui"
            : 'En cours';
    final fee = c.registrationFee.round();
    final feeLabel =
        fee == 0 ? 'Gratuit' : '$fee ${c.registrationCurrency}';

    return InkWell(
      onTap: () => context.push(UserRoutes.competitionPath(c.id)),
      borderRadius: BorderRadius.circular(ArenaRadius.lg),
      child: Container(
        padding: const EdgeInsets.all(ArenaSpacing.md),
        decoration: BoxDecoration(
          color: ArenaColors.carbon,
          borderRadius: BorderRadius.circular(ArenaRadius.lg),
          border: Border.all(color: ArenaColors.border),
        ),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: ArenaSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    c.name,
                    style: ArenaText.body
                        .copyWith(fontWeight: FontWeight.w700),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${c.currentPlayers}/${c.maxPlayers} • $feeLabel • $startLabel',
                    style: ArenaText.bodyMuted,
                    overflow: TextOverflow.ellipsis,
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
