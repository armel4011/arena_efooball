import 'package:arena/core/router/user_router.dart';
import 'package:arena/core/theme/arena_colors.dart';
import 'package:arena/core/theme/arena_theme.dart';
import 'package:arena/core/theme/arena_typography.dart';
import 'package:arena/data/models/competition_enums.dart';
import 'package:arena/data/repositories/competition_repository.dart';
import 'package:arena/features_shared/widgets/empty_state.dart';
import 'package:arena/features_shared/widgets/error_state.dart';
import 'package:arena/features_user/competitions/widgets/competition_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// PHASE 4 — list of competitions, filterable by game.
///
/// Streams from `competitions` via `competitionsListProvider(game?)`.
/// Tapping a card flashes a deferred-detail snackbar (the detail page
/// arrives in sub-step 4.C).
class CompetitionsListPage extends ConsumerStatefulWidget {
  const CompetitionsListPage({super.key});

  @override
  ConsumerState<CompetitionsListPage> createState() =>
      _CompetitionsListPageState();
}

class _CompetitionsListPageState extends ConsumerState<CompetitionsListPage> {
  GameType? _selected;

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(competitionsListProvider(_selected));

    return Column(
      children: [
        _GameFilterBar(
          selected: _selected,
          onChanged: (g) => setState(() => _selected = g),
        ),
        const Divider(height: 1, thickness: 1, color: ArenaColors.border),
        Expanded(
          child: async.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => ErrorState(
              description: e.toString(),
              onRetry: () =>
                  ref.invalidate(competitionsListProvider(_selected)),
            ),
            data: (items) {
              if (items.isEmpty) {
                return EmptyState(
                  icon: Icons.sports_esports_outlined,
                  title: _selected == null
                      ? 'Aucune compétition'
                      : 'Aucune compétition sur ${_selected!.label}',
                  description: 'De nouveaux tournois sont publiés chaque'
                      ' semaine. Reviens bientôt !',
                );
              }
              return RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(competitionsListProvider(_selected));
                  await ref
                      .read(competitionsListProvider(_selected).future);
                },
                child: ListView.separated(
                  padding: const EdgeInsets.all(ArenaSpacing.lg),
                  itemCount: items.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: ArenaSpacing.md),
                  itemBuilder: (context, i) {
                    final c = items[i];
                    return CompetitionCard(
                      competition: c,
                      onTap: () =>
                          context.push(UserRoutes.competitionPath(c.id)),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _GameFilterBar extends StatelessWidget {
  const _GameFilterBar({required this.selected, required this.onChanged});

  final GameType? selected;
  final ValueChanged<GameType?> onChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(
        horizontal: ArenaSpacing.lg,
        vertical: ArenaSpacing.sm,
      ),
      child: Row(
        children: [
          _FilterChip(
            label: 'Tous',
            selected: selected == null,
            onTap: () => onChanged(null),
          ),
          for (final g in GameType.values) ...[
            const SizedBox(width: ArenaSpacing.sm),
            _FilterChip(
              label: g.label,
              selected: selected == g,
              onTap: () => onChanged(g),
            ),
          ],
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final chip = ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      labelStyle: ArenaTypography.labelLarge.copyWith(
        color: selected ? Colors.white : ArenaColors.text,
        fontSize: 12,
      ),
      selectedColor: primary,
      backgroundColor: ArenaColors.surface,
      side: BorderSide(
        color: selected ? primary : ArenaColors.border,
      ),
    );

    if (!selected) return chip;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: ArenaRadius.pill,
        boxShadow: [
          BoxShadow(
            color: primary.withValues(alpha: 0.55),
            blurRadius: 18,
            spreadRadius: -2,
          ),
        ],
      ),
      child: chip,
    );
  }
}
