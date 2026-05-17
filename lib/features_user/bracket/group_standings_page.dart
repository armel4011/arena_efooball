import 'package:arena/core/theme/arena_theme.dart';
import 'package:arena/data/models/standings.dart';
import 'package:arena/data/repositories/standings_repository.dart';
import 'package:arena/features_shared/widgets/empty_state.dart';
import 'package:arena/features_shared/widgets/error_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// PHASE 4.E — group-stage standings.
///
/// Renders one DataTable per group of the competition. Player display
/// names are stubbed (preview of the UUID) until the `profiles` join
/// lands in a later iteration.
class GroupStandingsPage extends ConsumerWidget {
  const GroupStandingsPage({required this.competitionId, super.key});

  final String competitionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(competitionStandingsProvider(competitionId));

    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => ErrorState(
        description: e.toString(),
        onRetry: () =>
            ref.invalidate(competitionStandingsProvider(competitionId)),
      ),
      data: (buckets) {
        if (buckets.isEmpty) {
          return const EmptyState(
            icon: Icons.table_chart_outlined,
            title: 'Pas encore de classement',
            description: "Le classement s'affichera dès que les premières"
                ' rencontres seront jouées.',
          );
        }
        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(competitionStandingsProvider(competitionId));
            await ref
                .read(competitionStandingsProvider(competitionId).future);
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(ArenaSpacing.lg),
            itemCount: buckets.length,
            itemBuilder: (_, i) => _GroupTable(bucket: buckets[i]),
          ),
        );
      },
    );
  }
}

class _GroupTable extends StatelessWidget {
  const _GroupTable({required this.bucket});

  final StandingsBucket bucket;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: ArenaSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            bucket.group.name.toUpperCase(),
            style: ArenaTypography.headlineMedium,
          ),
          const SizedBox(height: ArenaSpacing.sm),
          Container(
            decoration: BoxDecoration(
              color: ArenaColors.surface,
              borderRadius: ArenaRadius.card,
              border: Border.all(color: ArenaColors.border),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowHeight: 36,
                dataRowMinHeight: 36,
                dataRowMaxHeight: 40,
                columnSpacing: 12,
                horizontalMargin: 12,
                headingTextStyle: ArenaTypography.labelLarge.copyWith(
                  color: ArenaColors.textMuted,
                  fontSize: 11,
                ),
                dataTextStyle: ArenaTypography.bodyMedium,
                columns: const [
                  DataColumn(label: Text('#')),
                  DataColumn(label: Text('JOUEUR')),
                  DataColumn(label: Text('J'), numeric: true),
                  DataColumn(label: Text('V'), numeric: true),
                  DataColumn(label: Text('N'), numeric: true),
                  DataColumn(label: Text('D'), numeric: true),
                  DataColumn(label: Text('BP'), numeric: true),
                  DataColumn(label: Text('BC'), numeric: true),
                  DataColumn(label: Text('Diff'), numeric: true),
                  DataColumn(label: Text('Pts'), numeric: true),
                ],
                rows: [
                  for (final r in bucket.rows) _row(r, bucket.rows.length),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  DataRow _row(GroupStandingRow r, int total) {
    final pid = r.profileId;
    final label = 'Joueur ${pid.substring(0, 6)}…';
    final pos = r.position ?? bucket.rows.indexOf(r) + 1;
    final isLeader = pos == 1;
    return DataRow(
      cells: [
        DataCell(
          Text(
            '$pos',
            style: ArenaTypography.labelLarge.copyWith(
              color: isLeader
                  ? ArenaColors.warning
                  : ArenaColors.textMuted,
              fontSize: 12,
            ),
          ),
        ),
        DataCell(
          Row(
            children: [
              if (isLeader)
                const Padding(
                  padding: EdgeInsets.only(right: 6),
                  child: Icon(
                    Icons.emoji_events,
                    size: 14,
                    color: ArenaColors.warning,
                  ),
                ),
              Text(label),
            ],
          ),
        ),
        DataCell(Text('${r.played}')),
        DataCell(Text('${r.wins}')),
        DataCell(Text('${r.draws}')),
        DataCell(Text('${r.losses}')),
        DataCell(Text('${r.goalsFor}')),
        DataCell(Text('${r.goalsAgainst}')),
        DataCell(
          Text(
            r.goalDiff > 0 ? '+${r.goalDiff}' : '${r.goalDiff}',
            style: ArenaTypography.bodyMedium.copyWith(
              color: r.goalDiff > 0
                  ? ArenaColors.success
                  : (r.goalDiff < 0 ? ArenaColors.danger : null),
            ),
          ),
        ),
        DataCell(
          Text(
            '${r.points}',
            style: ArenaTypography.bodyMedium.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}
