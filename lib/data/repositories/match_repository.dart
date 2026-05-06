import 'package:arena/data/models/arena_match.dart';
import 'package:arena/data/repositories/profile_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Read API over the `matches` table.
class MatchRepository {
  const MatchRepository(this._client);

  static const _table = 'matches';

  final SupabaseClient _client;

  /// All matches of a competition, sorted by round then match_number.
  ///
  /// Not exposed as a Realtime stream in V1.0 — the bracket changes
  /// infrequently and a manual `invalidate()` on pull-to-refresh keeps
  /// things simple. Switch to `.stream()` later if needed.
  Future<List<ArenaMatch>> listForCompetition(String competitionId) async {
    final rows = await _client
        .from(_table)
        .select()
        .eq('competition_id', competitionId)
        .order('round', ascending: true)
        .order('match_number', ascending: true);
    return [
      for (final row in rows as List<dynamic>)
        ArenaMatch.fromJson(row as Map<String, dynamic>),
    ];
  }
}

final matchRepositoryProvider = Provider<MatchRepository>((ref) {
  return MatchRepository(ref.watch(supabaseClientProvider));
});

/// All matches of a competition, keyed by competition id.
final competitionMatchesProvider =
    FutureProvider.family<List<ArenaMatch>, String>((ref, competitionId) {
  return ref.watch(matchRepositoryProvider).listForCompetition(competitionId);
});
