import 'dart:math';

import 'package:arena/data/models/competition.dart';
import 'package:arena/data/models/competition_enums.dart';
import 'package:arena/data/models/user_role.dart';
import 'package:arena/data/repositories/profile_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Flat DTO for one registered player in the admin competition detail.
@immutable
class AdminCompetitionRegistrant {
  const AdminCompetitionRegistrant({
    required this.playerId,
    required this.username,
    required this.countryCode,
    required this.avatarColor,
    required this.role,
    required this.status,
    required this.registeredAt,
    this.finalRank,
  });

  final String playerId;
  final String username;
  final String countryCode;
  final String avatarColor;
  final UserRole role;

  /// One of `pending`, `confirmed`, `refunded`, `withdrawn`.
  final String status;
  final DateTime registeredAt;

  /// Rang d'arrivée final saisi par l'admin — null tant que le
  /// classement n'a pas été publié.
  final int? finalRank;
}

/// Admin-side CRUD for `competitions`.
///
/// The user-facing repo is read-only — admin writes happen through
/// here so the `is_admin()` RLS guard scopes the queries naturally.
class AdminCompetitionsRepository {
  const AdminCompetitionsRepository(this._client);

  static const _table = 'competitions';

  final SupabaseClient _client;

  /// Realtime list of every competition, optionally filtered by
  /// [status] (any of `draft`, `registration_open`, `ongoing`,
  /// `completed`, `cancelled`) and by [game]. Filtering happens
  /// client-side because Supabase `.stream()` only supports one
  /// `.eq()` per pipeline and we sometimes need both.
  Stream<List<Competition>> watch({
    CompetitionStatus? status,
    GameType? game,
  }) {
    return _client
        .from(_table)
        .stream(primaryKey: ['id'])
        .order('start_date')
        .map((rows) {
          final list = [for (final row in rows) Competition.fromJson(row)];
          return list.where((c) {
            if (status != null && c.status != status) return false;
            if (game != null && c.game != game) return false;
            return true;
          }).toList(growable: false);
        });
  }

  /// Inserts a new competition row.
  Future<Competition> create(Map<String, dynamic> payload) async {
    final row =
        await _client.from(_table).insert(payload).select().single();
    return Competition.fromJson(row);
  }

  Future<Competition> update(
    String id,
    Map<String, dynamic> patch,
  ) async {
    final row = await _client
        .from(_table)
        .update(patch)
        .eq('id', id)
        .select()
        .single();
    return Competition.fromJson(row);
  }

  /// Returns the registered players for [competitionId] joined with
  /// their profile (username, country, avatar color, role) ordered by
  /// registration time. Powers the "Inscrits" tab of the admin
  /// competition detail page.
  Future<List<AdminCompetitionRegistrant>> listRegistrations(
    String competitionId,
  ) async {
    final rows = await _client
        .from('competition_registrations')
        .select(
          'player_id, registered_at, status, final_rank, '
          'profiles!player_id(username, country_code, avatar_color, role)',
        )
        .eq('competition_id', competitionId)
        .order('registered_at');
    return [
      for (final row in rows as List<dynamic>)
        _mapRegistrant(row as Map<String, dynamic>),
    ];
  }

  AdminCompetitionRegistrant _mapRegistrant(Map<String, dynamic> row) {
    final profile = row['profiles'] as Map<String, dynamic>? ?? const {};
    return AdminCompetitionRegistrant(
      playerId: row['player_id'] as String,
      username: profile['username'] as String? ?? '—',
      countryCode: profile['country_code'] as String? ?? '',
      avatarColor: profile['avatar_color'] as String? ?? '#4C7AFF',
      role: UserRole.fromValue(profile['role'] as String?),
      status: row['status'] as String? ?? 'confirmed',
      registeredAt: DateTime.parse(row['registered_at'] as String),
      finalRank: row['final_rank'] as int?,
    );
  }

  /// Saisit — ou efface, si [rank] est `null` — le rang d'arrivée final
  /// d'un participant. Passe par la policy `registrations_update_admin`.
  Future<void> setFinalRank(
    String competitionId,
    String playerId,
    int? rank,
  ) async {
    await _client
        .from('competition_registrations')
        .update({'final_rank': rank})
        .eq('competition_id', competitionId)
        .eq('player_id', playerId);
  }

  /// Calcule et écrit le classement final automatiquement à partir des
  /// résultats de matchs. Critères, du plus discriminant au moins :
  ///   1. niveau atteint dans la compétition (round le plus élevé joué)
  ///   2. nombre de buts marqués sur l'ensemble de ses matchs
  ///   3. ordre alphabétique du pseudo (départage par défaut)
  ///
  /// Écrase les rangs déjà saisis. Une seule écriture groupée via upsert
  /// sur la PK `(competition_id, player_id)` — seul `final_rank` change.
  Future<void> autoRankFromResults(String competitionId) async {
    final registrants = await listRegistrations(competitionId);
    if (registrants.isEmpty) return;

    final matchRows = await _client
        .from('matches')
        .select('round, player1_id, player2_id, score1, score2')
        .eq('competition_id', competitionId);

    // Agrège, par joueur, le niveau atteint et les buts marqués.
    final levelReached = <String, int>{};
    final goalsScored = <String, int>{};
    for (final row in matchRows as List<dynamic>) {
      final m = row as Map<String, dynamic>;
      final round = (m['round'] as int?) ?? 0;
      final p1 = m['player1_id'] as String?;
      final p2 = m['player2_id'] as String?;
      final s1 = (m['score1'] as int?) ?? 0;
      final s2 = (m['score2'] as int?) ?? 0;
      if (p1 != null) {
        levelReached[p1] = max(levelReached[p1] ?? 0, round);
        goalsScored[p1] = (goalsScored[p1] ?? 0) + s1;
      }
      if (p2 != null) {
        levelReached[p2] = max(levelReached[p2] ?? 0, round);
        goalsScored[p2] = (goalsScored[p2] ?? 0) + s2;
      }
    }

    final ordered = [...registrants]..sort((a, b) {
        final la = levelReached[a.playerId] ?? 0;
        final lb = levelReached[b.playerId] ?? 0;
        if (la != lb) return lb.compareTo(la);
        final ga = goalsScored[a.playerId] ?? 0;
        final gb = goalsScored[b.playerId] ?? 0;
        if (ga != gb) return gb.compareTo(ga);
        return a.username.toLowerCase().compareTo(b.username.toLowerCase());
      });

    await _client.from('competition_registrations').upsert(
      [
        for (var i = 0; i < ordered.length; i++)
          {
            'competition_id': competitionId,
            'player_id': ordered[i].playerId,
            'final_rank': i + 1,
          },
      ],
      onConflict: 'competition_id,player_id',
    );
  }

  /// Flips a competition into `cancelled`. The Edge Function that
  /// refunds the registrations (PHASE 11bis) doesn't exist yet — the
  /// admin still gets a clean UI affordance, and the rows
  /// stay around for the eventual refund sweep.
  Future<void> cancel(String id) async {
    await _client
        .from(_table)
        .update({'status': 'cancelled'})
        .eq('id', id);
  }

  /// Suppression définitive (super-admin only). Appelle la RPC SQL
  /// `delete_competition_cascade` (SECURITY DEFINER) qui supprime
  /// atomiquement payouts → platform_revenue → payments → competition.
  /// Les registrations / matches / brackets cascadent via leurs FK
  /// `on delete cascade` propres.
  Future<void> delete(String competitionId) async {
    await _client.rpc<void>(
      'delete_competition_cascade',
      params: {'p_competition_id': competitionId},
    );
  }
}

final adminCompetitionsRepositoryProvider =
    Provider<AdminCompetitionsRepository>((ref) {
  return AdminCompetitionsRepository(ref.watch(supabaseClientProvider));
});

@immutable
class AdminCompetitionsFilter {
  const AdminCompetitionsFilter({this.status, this.game});
  final CompetitionStatus? status;
  final GameType? game;

  @override
  bool operator ==(Object other) =>
      other is AdminCompetitionsFilter &&
      other.status == status &&
      other.game == game;

  @override
  int get hashCode => Object.hash(status, game);
}

final adminCompetitionsProvider = StreamProvider.family.autoDispose<
    List<Competition>, AdminCompetitionsFilter>((ref, filter) {
  return ref
      .watch(adminCompetitionsRepositoryProvider)
      .watch(status: filter.status, game: filter.game);
});

final adminCompetitionRegistrantsProvider = FutureProvider.family.autoDispose<
    List<AdminCompetitionRegistrant>, String>((ref, competitionId) {
  return ref
      .watch(adminCompetitionsRepositoryProvider)
      .listRegistrations(competitionId);
});
