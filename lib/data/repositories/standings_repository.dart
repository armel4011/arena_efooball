import 'package:arena/core/services/persistent_cache.dart';
import 'package:arena/data/models/standings.dart';
import 'package:arena/data/repositories/profile_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Read API over `groups` + `group_memberships`.
///
/// Group-stage standings are fetched on-demand (no Realtime in V1.0 —
/// invalidate the provider on pull-to-refresh).
class StandingsRepository {
  const StandingsRepository(this._client);

  final SupabaseClient _client;

  /// Returns one [StandingsBucket] per group of the competition,
  /// each with its memberships ordered by `position` (then by `points`
  /// descending as a fallback when position isn't set yet).
  Future<List<StandingsBucket>> forCompetition(String competitionId) async {
    final groupsRaw = await _client
        .from('groups')
        .select()
        .eq('competition_id', competitionId)
        .order('group_number', ascending: true);

    final groups = [
      for (final row in groupsRaw as List<dynamic>)
        CompetitionGroup.fromJson(row as Map<String, dynamic>),
    ];
    if (groups.isEmpty) return const [];

    final ids = [for (final g in groups) g.id];
    final membershipsRaw = await _client
        .from('group_memberships')
        .select()
        .inFilter('group_id', ids);

    // Bucket by group id and sort each.
    final byGroup = <String, List<GroupStandingRow>>{};
    for (final row in membershipsRaw as List<dynamic>) {
      final r = GroupStandingRow.fromJson(row as Map<String, dynamic>);
      (byGroup[r.groupId] ??= []).add(r);
    }
    for (final list in byGroup.values) {
      list.sort((a, b) {
        // `position` may not be set yet — fall back to points / goal-diff.
        final pa = a.position ?? 999;
        final pb = b.position ?? 999;
        if (pa != pb) return pa.compareTo(pb);
        if (a.points != b.points) return b.points.compareTo(a.points);
        return b.goalDiff.compareTo(a.goalDiff);
      });
    }

    return [
      for (final g in groups)
        StandingsBucket(group: g, rows: byGroup[g.id] ?? const []),
    ];
  }
}

final standingsRepositoryProvider = Provider<StandingsRepository>((ref) {
  return StandingsRepository(ref.watch(supabaseClientProvider));
});

final competitionStandingsProvider =
    FutureProvider.family.autoDispose<List<StandingsBucket>, String>(
        (ref, competitionId) async {
  final cache = await ref.watch(persistentCacheProvider.future);
  // Offline-safe : les poules restent figees sur le dernier classement
  // connu au lieu d'une ErrorState reseau. `StandingsBucket` est une
  // classe simple (pas de JSON) → on serialise ses parts (group + rows),
  // toutes deux freezed.
  return cache.fetchListOrCache<StandingsBucket>(
    namespace: 'standings.$competitionId',
    fetch: () =>
        ref.watch(standingsRepositoryProvider).forCompetition(competitionId),
    fromJson: (json) => StandingsBucket(
      group: CompetitionGroup.fromJson(json['group'] as Map<String, dynamic>),
      rows: [
        for (final r in json['rows'] as List<dynamic>)
          GroupStandingRow.fromJson(r as Map<String, dynamic>),
      ],
    ),
    toJson: (b) => {
      'group': b.group.toJson(),
      'rows': [for (final r in b.rows) r.toJson()],
    },
  );
});
