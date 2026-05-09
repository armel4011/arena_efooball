import 'package:arena/core/router/user_router.dart';
import 'package:arena/core/theme/arena_theme.dart';
import 'package:arena/data/models/competition.dart';
import 'package:arena/data/models/competition_enums.dart';
import 'package:arena/data/repositories/competition_repository.dart';
import 'package:arena/features_shared/widgets/arena_banner.dart';
import 'package:arena/features_shared/widgets/empty_state.dart';
import 'package:arena/features_shared/widgets/error_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

/// PHASE 4 — list of competitions, filterable by game + status.
///
/// Maps to screen #10 of `arena_v2.html`. Two chip rows on top (jeu /
/// statut), then full-bleed [ArenaBanner] cards per competition with a
/// trailing OPEN badge + capacity counter.
class CompetitionsListPage extends ConsumerStatefulWidget {
  const CompetitionsListPage({super.key});

  @override
  ConsumerState<CompetitionsListPage> createState() =>
      _CompetitionsListPageState();
}

class _CompetitionsListPageState extends ConsumerState<CompetitionsListPage> {
  GameType? _game;
  _StatusBucket _bucket = _StatusBucket.upcoming;

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(competitionsListProvider(_game));

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            ArenaSpacing.lg,
            ArenaSpacing.md,
            ArenaSpacing.lg,
            0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('JEU', style: ArenaText.inputLabel),
              const SizedBox(height: ArenaSpacing.sm),
              _GameChips(
                selected: _game,
                onChanged: (g) => setState(() => _game = g),
              ),
              const SizedBox(height: ArenaSpacing.sm),
              Text('STATUS', style: ArenaText.inputLabel),
              const SizedBox(height: ArenaSpacing.sm),
              _StatusChips(
                selected: _bucket,
                onChanged: (b) => setState(() => _bucket = b),
              ),
            ],
          ),
        ),
        const SizedBox(height: ArenaSpacing.sm),
        const Divider(height: 1, thickness: 1, color: ArenaColors.border),
        Expanded(
          child: async.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => ErrorState(
              description: e.toString(),
              onRetry: () => ref.invalidate(competitionsListProvider(_game)),
            ),
            data: (items) {
              final filtered =
                  items.where((c) => _bucket.matches(c.status)).toList();
              if (filtered.isEmpty) {
                return EmptyState(
                  icon: Icons.sports_esports_outlined,
                  title: _game == null
                      ? 'Aucune compétition'
                      : 'Aucune compétition sur ${_game!.label}',
                  description: 'De nouveaux tournois sont publiés chaque'
                      ' semaine. Reviens bientôt !',
                );
              }
              return RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(competitionsListProvider(_game));
                  await ref
                      .read(competitionsListProvider(_game).future);
                },
                child: ListView.separated(
                  padding: const EdgeInsets.all(ArenaSpacing.lg),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: ArenaSpacing.md),
                  itemBuilder: (context, i) {
                    final c = filtered[i];
                    return _CompetitionBanner(
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

enum _StatusBucket {
  upcoming('À venir'),
  ongoing('En cours'),
  completed('Terminés');

  const _StatusBucket(this.label);
  final String label;

  bool matches(CompetitionStatus status) => switch (this) {
        _StatusBucket.upcoming => status == CompetitionStatus.draft ||
            status == CompetitionStatus.registrationOpen ||
            status == CompetitionStatus.registrationClosed,
        _StatusBucket.ongoing => status == CompetitionStatus.ongoing,
        _StatusBucket.completed => status == CompetitionStatus.completed ||
            status == CompetitionStatus.cancelled,
      };
}

class _GameChips extends StatelessWidget {
  const _GameChips({required this.selected, required this.onChanged});

  final GameType? selected;
  final ValueChanged<GameType?> onChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _Chip(
            label: 'Tous',
            active: selected == null,
            onTap: () => onChanged(null),
          ),
          for (final g in GameType.values) ...[
            const SizedBox(width: ArenaSpacing.xs),
            _Chip(
              label: g.label,
              active: selected == g,
              onTap: () => onChanged(g),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatusChips extends StatelessWidget {
  const _StatusChips({required this.selected, required this.onChanged});

  final _StatusBucket selected;
  final ValueChanged<_StatusBucket> onChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (var i = 0; i < _StatusBucket.values.length; i++) ...[
            _Chip(
              label: _StatusBucket.values[i].label,
              active: _StatusBucket.values[i] == selected,
              onTap: () => onChanged(_StatusBucket.values[i]),
            ),
            if (i < _StatusBucket.values.length - 1)
              const SizedBox(width: ArenaSpacing.xs),
          ],
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(ArenaRadius.round),
      child: AnimatedContainer(
        duration: ArenaDurations.short,
        padding: const EdgeInsets.symmetric(
          horizontal: ArenaSpacing.md,
          vertical: 6,
        ),
        decoration: BoxDecoration(
          color: active
              ? ArenaColors.signalBlue.withValues(alpha: 0.15)
              : ArenaColors.carbon,
          borderRadius: BorderRadius.circular(ArenaRadius.round),
          border: Border.all(
            color: active ? ArenaColors.signalBlue : ArenaColors.border,
          ),
        ),
        child: Text(
          label,
          style: ArenaText.body.copyWith(
            color: active ? ArenaColors.signalBlue : ArenaColors.silver,
            fontWeight: active ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _CompetitionBanner extends StatelessWidget {
  const _CompetitionBanner({
    required this.competition,
    required this.onTap,
  });

  final Competition competition;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(ArenaRadius.lg),
      child: ArenaBanner(
        game: _gameFor(competition.game),
        title: competition.name,
        subtitle: _subtitleFor(competition),
        trailing: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: ArenaSpacing.sm,
            vertical: 4,
          ),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(ArenaRadius.round),
          ),
          child: Text(
            '${competition.currentPlayers}/${competition.maxPlayers}',
            style: ArenaText.mono.copyWith(
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
        ),
      ),
    );
  }

  static ArenaBannerGame _gameFor(GameType g) => switch (g) {
        GameType.efootball => ArenaBannerGame.efoot,
        GameType.fifaMobile => ArenaBannerGame.fifa,
        GameType.eaSportsFc => ArenaBannerGame.fc,
      };

  static String _subtitleFor(Competition c) {
    final dateLabel = _formatDateRange(c.startDate, c.endDate);
    final fee = c.registrationFee == 0
        ? 'Gratuit'
        : '${_money(c.registrationFee)} ${c.registrationCurrency}';
    if (c.prizePoolLocal > 0) {
      final pool = '${_money(c.prizePoolLocal)} '
          '${c.prizePoolCurrency ?? c.registrationCurrency}';
      return '$dateLabel · Récompense $pool';
    }
    return '$dateLabel · $fee';
  }

  static String _formatDateRange(DateTime start, DateTime? end) {
    final s = DateFormat('d MMM', 'fr').format(start.toLocal());
    if (end == null) return s;
    final e = DateFormat('d MMM', 'fr').format(end.toLocal());
    return '$s → $e';
  }

  static String _money(double v) => NumberFormat.decimalPattern('fr').format(v);
}
