import 'package:arena/data/models/competition.dart';
import 'package:arena/data/models/competition_enums.dart';
import 'package:arena/data/repositories/profile_repository.dart';
import 'package:arena/features_user/auth/auth_providers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Une ligne du classement général final d'une compétition, telle que
/// vue côté joueur (lecture seule) : le participant joint à son profil
/// et son rang d'arrivée.
@immutable
class CompetitionRankingEntry {
  const CompetitionRankingEntry({
    required this.playerId,
    required this.username,
    required this.countryCode,
    required this.avatarColor,
    required this.finalRank,
  });

  final String playerId;
  final String username;
  final String countryCode;
  final String avatarColor;

  /// Rang d'arrivée — `null` tant que l'admin n'a pas publié le classement.
  final int? finalRank;
}

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

  /// Classement général final d'une compétition : les participants
  /// joints à leur profil, triés par `final_rank` croissant. Les
  /// non-classés (`final_rank` null) sont renvoyés en fin de liste.
  Future<List<CompetitionRankingEntry>> getRanking(
    String competitionId,
  ) async {
    final rows = await _client
        .from('competition_registrations')
        .select(
          'player_id, final_rank, '
          'profiles!player_id(username, country_code, avatar_color)',
        )
        .eq('competition_id', competitionId);
    final list = [
      for (final row in rows as List<dynamic>)
        _mapRankingEntry(row as Map<String, dynamic>),
    ]..sort((a, b) {
        // Les non-classés tombent en fin de liste.
        final ra = a.finalRank ?? 1 << 30;
        final rb = b.finalRank ?? 1 << 30;
        if (ra != rb) return ra.compareTo(rb);
        return a.username.toLowerCase().compareTo(b.username.toLowerCase());
      });
    return list;
  }

  CompetitionRankingEntry _mapRankingEntry(Map<String, dynamic> row) {
    final profile = row['profiles'] as Map<String, dynamic>? ?? const {};
    return CompetitionRankingEntry(
      playerId: row['player_id'] as String,
      username: profile['username'] as String? ?? '—',
      countryCode: profile['country_code'] as String? ?? '',
      avatarColor: profile['avatar_color'] as String? ?? '#4C7AFF',
      finalRank: row['final_rank'] as int?,
    );
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
            },);
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

/// Classement général final d'une compétition (lecture seule côté
/// joueur). `FutureProvider` — pas de Realtime en V1.0, on invalide au
/// pull-to-refresh, comme les standings de poule.
final competitionRankingProvider =
    FutureProvider.family<List<CompetitionRankingEntry>, String>(
        (ref, competitionId) {
  return ref.watch(competitionRepositoryProvider).getRanking(competitionId);
});

/// Realtime set des ids de comps où le joueur courant est inscrit
/// (status='confirmed'). Utilisé pour le gate du détail + le routage
/// liste → détail vs inscription.
///
/// Dépend explicitement de `currentSessionProvider` pour que la stream
/// soit reconstruite quand l'auth devient prête (sinon, lors d'un
/// cold-start avec session restaurée tardivement, la stream se crée
/// alors que `auth.currentUser` est encore null et reste vide).
final myRegisteredCompetitionIdsProvider =
    StreamProvider<Set<String>>((ref) {
  final session = ref.watch(currentSessionProvider);
  if (session == null) {
    return Stream.value(const <String>{});
  }
  return ref
      .watch(competitionRepositoryProvider)
      .watchMyRegisteredCompetitionIds();
});
