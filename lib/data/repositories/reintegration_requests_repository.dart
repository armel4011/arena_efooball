import 'package:arena/data/models/reintegration_request.dart';
import 'package:arena/data/repositories/profile_repository.dart';
import 'package:arena/features_shared/auth_common/shared_auth_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Phase 12.6 — Lecture/écriture des `reintegration_requests`.
///
/// - User banni à vie : `submit` (INSERT, RLS auto-vérifie permanent_ban
///   et bloque les autres) + `latestForUser` pour afficher l'état.
/// - Super-admin : `listPending` pour traiter les demandes,
///   `approve` / `reject` qui flippent le status — un trigger Postgres
///   débanne le user concerné et envoie la notif (`apply_reintegration_decision`).
class ReintegrationRequestsRepository {
  const ReintegrationRequestsRepository(this._client);

  static const _table = 'reintegration_requests';

  final SupabaseClient _client;

  /// Insère une nouvelle requête. Lève si l'utilisateur a déjà une
  /// requête `pending` (contrainte unique partielle DB).
  Future<ReintegrationRequest> submit({
    required String userId,
    required String message,
  }) async {
    final row = await _client
        .from(_table)
        .insert({'user_id': userId, 'message': message.trim()})
        .select()
        .single();
    return ReintegrationRequest.fromJson(row);
  }

  /// Dernière requête (peu importe le statut) de l'utilisateur courant.
  /// Utile pour afficher "en cours d'analyse" / "refusée" sur l'écran de
  /// blocage avant d'autoriser une nouvelle soumission.
  Future<ReintegrationRequest?> latestForUser(String userId) async {
    final rows = await _client
        .from(_table)
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .limit(1);
    final list = rows as List<dynamic>;
    if (list.isEmpty) return null;
    return ReintegrationRequest.fromJson(list.first as Map<String, dynamic>);
  }

  /// Liste les requêtes (admin only via RLS). `pendingOnly = true` pour
  /// l'écran de traitement, sinon retourne tout l'historique.
  Future<List<ReintegrationRequest>> list({
    bool pendingOnly = true,
    int limit = 100,
  }) async {
    var query = _client.from(_table).select();
    if (pendingOnly) {
      query = query.eq('status', 'pending');
    }
    final rows =
        await query.order('created_at', ascending: false).limit(limit);
    return [
      for (final row in rows as List<dynamic>)
        ReintegrationRequest.fromJson(row as Map<String, dynamic>),
    ];
  }

  /// Approbation : trigger DB débannit le user + envoie la notif.
  Future<void> approve({
    required String requestId,
    required String adminId,
    String? reason,
  }) async {
    await _client.from(_table).update({
      'status': 'approved',
      'resolved_at': DateTime.now().toUtc().toIso8601String(),
      'resolved_by': adminId,
      if (reason != null && reason.trim().isNotEmpty)
        'resolution_reason': reason.trim(),
    }).eq('id', requestId);
  }

  Future<void> reject({
    required String requestId,
    required String adminId,
    required String reason,
  }) async {
    await _client.from(_table).update({
      'status': 'rejected',
      'resolved_at': DateTime.now().toUtc().toIso8601String(),
      'resolved_by': adminId,
      'resolution_reason': reason.trim(),
    }).eq('id', requestId);
  }
}

final reintegrationRequestsRepositoryProvider =
    Provider<ReintegrationRequestsRepository>((ref) {
  return ReintegrationRequestsRepository(ref.watch(supabaseClientProvider));
});

/// Dernière requête de l'utilisateur connecté (null si jamais soumise).
final myReintegrationRequestProvider =
    FutureProvider.autoDispose<ReintegrationRequest?>((ref) async {
  final userId = ref.watch(currentSessionProvider)?.user.id;
  if (userId == null) return null;
  return ref
      .watch(reintegrationRequestsRepositoryProvider)
      .latestForUser(userId);
});

/// Liste pending pour l'écran super-admin (auto-refresh quand on tranche).
final pendingReintegrationRequestsProvider =
    FutureProvider.autoDispose<List<ReintegrationRequest>>((ref) {
  return ref
      .watch(reintegrationRequestsRepositoryProvider)
      .list(pendingOnly: true);
});
