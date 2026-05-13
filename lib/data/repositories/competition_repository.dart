import 'package:arena/data/models/competition.dart';
import 'package:arena/data/models/competition_enums.dart';
import 'package:arena/data/repositories/profile_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// CRUD + Realtime over the `competitions` table.
///
/// Read-only from the User app — competitions are created server-side by
/// admins (PHASE 11). The User app only needs `list / getById / watch`.
class CompetitionRepository {
  const CompetitionRepository(this._client);

  static const _table = 'competitions';

  final SupabaseClient _client;

  /// Single fetch — typically not used directly by UI (prefer [watch]),
  /// but handy for tests and for one-shot lookups.
  Future<List<Competition>> list({GameType? game}) async {
    final query = _client.from(_table).select();
    final filtered = game == null ? query : query.eq('game', game.value);
    final rows = await filtered.order('start_date', ascending: true);
    return [
      for (final row in rows as List<dynamic>)
        Competition.fromJson(row as Map<String, dynamic>),
    ];
  }

  Future<Competition?> getById(String id) async {
    final row =
        await _client.from(_table).select().eq('id', id).maybeSingle();
    if (row == null) return null;
    return Competition.fromJson(row);
  }

  /// Realtime stream of competitions. The Supabase `.stream()` API does
  /// not support arbitrary `where` chaining — we filter by [game]
  /// client-side instead, which keeps the stream simple and avoids
  /// reconnections when the filter changes.
  Stream<List<Competition>> watch({GameType? game}) {
    return _client
        .from(_table)
        .stream(primaryKey: ['id'])
        .order('start_date')
        .map((rows) {
          final list = [for (final row in rows) Competition.fromJson(row)];
          if (game == null) return list;
          return list.where((c) => c.game == game).toList(growable: false);
        });
  }

  /// Realtime stream of a single competition. Emits `null` if the row
  /// doesn't exist (yet).
  Stream<Competition?> watchById(String id) {
    return _client
        .from(_table)
        .stream(primaryKey: ['id'])
        .eq('id', id)
        .map((rows) => rows.isEmpty ? null : Competition.fromJson(rows.first));
  }

  /// PHASE 11bis — inscription directe sur compétition GRATUITE.
  /// L'INSERT passe par la policy `registrations_free_self_insert` qui
  /// vérifie côté DB que `competitions.registration_fee = 0`.
  Future<void> registerSelfFree(String competitionId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw StateError('No authenticated user — cannot register.');
    }
    await _client.from('competition_registrations').insert({
      'competition_id': competitionId,
      'player_id': userId,
      'status': 'confirmed',
    });
  }

  /// Stream realtime des ids de compétitions où le joueur courant est
  /// inscrit en `status='confirmed'`. Utilisé par la liste pour décider
  /// si on route vers le détail ou vers la page d'inscription.
  Stream<Set<String>> watchMyRegisteredCompetitionIds() {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      return const Stream.empty();
    }
    return _client
        .from('competition_registrations')
        .stream(primaryKey: ['competition_id', 'player_id'])
        .eq('player_id', userId)
        .map((rows) => {
              for (final r in rows)
                if (r['status'] == 'confirmed')
                  r['competition_id'] as String,
            });
  }
}

final competitionRepositoryProvider = Provider<CompetitionRepository>((ref) {
  return CompetitionRepository(ref.watch(supabaseClientProvider));
});

/// Realtime list of competitions, optionally filtered by game.
///
/// Use `competitionsListProvider(null)` for the unfiltered stream.
final competitionsListProvider =
    StreamProvider.family<List<Competition>, GameType?>((ref, game) {
  return ref.watch(competitionRepositoryProvider).watch(game: game);
});

/// Realtime stream of one competition by id.
final competitionByIdProvider =
    StreamProvider.family<Competition?, String>((ref, id) {
  return ref.watch(competitionRepositoryProvider).watchById(id);
});

/// Realtime set des ids de comps où le joueur courant est inscrit
/// (status='confirmed'). Utilisé pour le gate du détail + le routage
/// liste → détail vs inscription.
final myRegisteredCompetitionIdsProvider =
    StreamProvider<Set<String>>((ref) {
  return ref
      .watch(competitionRepositoryProvider)
      .watchMyRegisteredCompetitionIds();
});
