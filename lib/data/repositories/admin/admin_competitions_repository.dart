
import 'package:arena/data/models/competition.dart';
import 'package:arena/data/models/competition_enums.dart';
import 'package:arena/data/models/user_role.dart';
import 'package:arena/data/repositories/admin/admin_audit_log_repository.dart';
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
  const AdminCompetitionsRepository(this._client, this._auditLog);

  static const _table = 'competitions';

  final SupabaseClient _client;
  final AdminAuditLogRepository _auditLog;

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

  /// Régénère une compétition `completed` : crée une NOUVELLE compétition
  /// (inscriptions ouvertes, date à J+7) qui copie toute la configuration
  /// de base. Inscriptions / matchs / brackets repartent de zéro.
  ///
  /// Passe par la RPC `regenerate_competition` (SECURITY DEFINER, gardée
  /// par `is_admin()`). Renvoie la compétition fraîchement créée.
  Future<Competition> regenerate(String competitionId) async {
    final rows = await _client.rpc<dynamic>(
      'regenerate_competition',
      params: {'p_competition_id': competitionId},
    );
    final list = rows as List<dynamic>;
    if (list.isEmpty) {
      throw StateError('regenerate_competition returned no row');
    }
    return Competition.fromJson(list.first as Map<String, dynamic>);
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

  /// (Re)calcule le classement final via la RPC serveur
  /// `admin_recompute_final_ranks` (SECURITY DEFINER, gardée `is_admin()`).
  ///
  /// Délègue à `compute_competition_final_ranks` — la MÊME logique que la
  /// clôture automatique : round-robin = position de poule ; single_elim =
  /// champion / finaliste / demies (match 3e place ou buts) / round
  /// d'élimination ; groups_then_knockout = qualifiés par KO puis éliminés par
  /// classement de poule. Remplace l'ancien calcul client (niveau + buts), qui
  /// divergeait du classement auto et l'écrasait. Écrase les rangs saisis.
  Future<void> autoRankFromResults(String competitionId) async {
    await _client.rpc<dynamic>(
      'admin_recompute_final_ranks',
      params: {'p_competition_id': competitionId},
    );
  }

  /// Épingle (ou désépingle) une compétition pour la mettre « à la une » :
  /// elle remonte alors en tête des listes côté user avec un badge. Écrit
  /// `is_pinned` + `pinned_at` (horodatage UTC quand on épingle, `null`
  /// sinon), PUIS trace l'action dans `admin_audit_log`
  /// (`competition_pinned` / `competition_unpinned`).
  Future<void> setPinned({
    required String competitionId,
    required bool pinned,
    required String adminId,
  }) async {
    await _client.from(_table).update({
      'is_pinned': pinned,
      'pinned_at': pinned ? DateTime.now().toUtc().toIso8601String() : null,
    }).eq('id', competitionId);

    await _auditLog.record(
      adminId: adminId,
      action: pinned ? 'competition_pinned' : 'competition_unpinned',
      targetType: 'competition',
      targetId: competitionId,
      afterState: {'is_pinned': pinned},
    );
  }

  /// Annule une compétition via la RPC `cancel_competition` (SECURITY
  /// DEFINER, gate `is_admin()`) : flip `status=cancelled` ET notifie chaque
  /// joueur ayant un paiement `succeeded`/`awaiting_admin` qu'un remboursement
  /// manuel (Mobile Money) va suivre (fix audit C-2). Retourne le nombre de
  /// joueurs notifiés. Le remboursement effectif reste un geste manuel du
  /// super-admin (file de remboursement traçable = chantier ultérieur).
  Future<int> cancel(String id) async {
    final res = await _client.rpc<dynamic>(
      'cancel_competition',
      params: {'p_competition_id': id},
    );
    return (res as num?)?.toInt() ?? 0;
  }

  /// Reprogramme une compétition (typiquement `to_reprogram`) à une nouvelle
  /// date via la RPC `reprogram_competition` (SECURITY DEFINER, gate
  /// `is_admin()`) : `status=registration_open` + `start_date=newStartDate` ET
  /// rouvre les inscriptions, PUIS notifie tous les inscrits confirmés de la
  /// nouvelle date. Retourne le nombre de joueurs notifiés.
  Future<int> reprogram(String id, DateTime newStartDate) async {
    final res = await _client.rpc<dynamic>(
      'reprogram_competition',
      params: {
        'p_competition_id': id,
        'p_new_start_date': newStartDate.toUtc().toIso8601String(),
      },
    );
    return (res as num?)?.toInt() ?? 0;
  }

  /// Démarre une compétition avec les joueurs disponibles via la RPC
  /// `start_competition_now` (SECURITY DEFINER, gate `is_admin()`) : notifie
  /// les inscrits confirmés (≥ 2 requis), puis génère le bracket
  /// (single_elimination → `ongoing`) ou ferme les inscriptions (autres
  /// formats, bracket manuel ensuite). Retourne le nombre de joueurs notifiés.
  Future<int> startNow(String id) async {
    final res = await _client.rpc<dynamic>(
      'start_competition_now',
      params: {'p_competition_id': id},
    );
    return (res as num?)?.toInt() ?? 0;
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
  return AdminCompetitionsRepository(
    ref.watch(supabaseClientProvider),
    ref.watch(adminAuditLogRepositoryProvider),
  );
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
