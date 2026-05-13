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
  });

  final String playerId;
  final String username;
  final String countryCode;
  final String avatarColor;
  final UserRole role;

  /// One of `pending`, `confirmed`, `refunded`, `withdrawn`.
  final String status;
  final DateTime registeredAt;
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
          'player_id, registered_at, status, '
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

  /// Suppression définitive (super-admin only). Les paiements liés
  /// sont supprimés d'abord pour respecter la contrainte FK
  /// `payments.competition_id on delete restrict`. Les registrations
  /// et matches cascadent automatiquement côté DB.
  Future<void> delete(String competitionId) async {
    await _client
        .from('payments')
        .delete()
        .eq('competition_id', competitionId);
    await _client.from(_table).delete().eq('id', competitionId);
  }
}

final adminCompetitionsRepositoryProvider =
    Provider<AdminCompetitionsRepository>((ref) {
  return AdminCompetitionsRepository(ref.watch(supabaseClientProvider));
});

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

final adminCompetitionsProvider = StreamProvider.family<
    List<Competition>, AdminCompetitionsFilter>((ref, filter) {
  return ref
      .watch(adminCompetitionsRepositoryProvider)
      .watch(status: filter.status, game: filter.game);
});

final adminCompetitionRegistrantsProvider = FutureProvider.family<
    List<AdminCompetitionRegistrant>, String>((ref, competitionId) {
  return ref
      .watch(adminCompetitionsRepositoryProvider)
      .listRegistrations(competitionId);
});
