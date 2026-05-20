import 'package:arena/core/utils/poll_stream.dart';
import 'package:arena/data/models/dispute.dart';
import 'package:arena/data/repositories/profile_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Admin-side reads + writes over `disputes` (PHASE 11).
///
/// Players open disputes via the user-facing flow (RLS
/// `disputes_party_insert`). Admins read everything via
/// `disputes_admin_all` and resolve from here — the resolution path
/// commits the verdict on the underlying match too, so the bracket
/// progresses.
class AdminDisputesRepository {
  const AdminDisputesRepository(this._client);

  static const _table = 'disputes';

  final SupabaseClient _client;

  /// One-shot fetch de tous les litiges, plus récents en tête.
  ///
  /// Le filtre `status` est client-side (on veut `open` + `escalated`
  /// ensemble). Consommé en polling plutôt qu'en Realtime : un litige
  /// s'ouvre rarement, pas la peine d'un WebSocket dédié par admin.
  Future<List<Dispute>> listAll({bool openOnly = true}) async {
    final rows = await _client
        .from(_table)
        .select()
        .order('created_at', ascending: false);
    final list = [for (final row in rows) Dispute.fromJson(row)];
    if (!openOnly) return list;
    return list.where((d) => d.isOpen).toList(growable: false);
  }

  Stream<Dispute?> watchById(String id) {
    return _client
        .from(_table)
        .stream(primaryKey: ['id'])
        .eq('id', id)
        .map((rows) => rows.isEmpty ? null : Dispute.fromJson(rows.first));
  }

  Future<Dispute?> getByMatchId(String matchId) async {
    final row = await _client
        .from(_table)
        .select()
        .eq('match_id', matchId)
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();
    if (row == null) return null;
    return Dispute.fromJson(row);
  }

  /// Resolves a dispute. The admin's written reasoning is required —
  /// surfaced in the audit log + future "see why" link from the
  /// player-facing notif.
  Future<void> resolve({
    required String disputeId,
    required String adminId,
    required String resolution,
    String status = 'resolved',
  }) async {
    await _client.from(_table).update({
      'status': status,
      'resolved_at': DateTime.now().toUtc().toIso8601String(),
      'resolved_by': adminId,
      'resolution': resolution,
    }).eq('id', disputeId);
  }
}

final adminDisputesRepositoryProvider =
    Provider<AdminDisputesRepository>((ref) {
  return AdminDisputesRepository(ref.watch(supabaseClientProvider));
});

/// Polling 120 s (Realtime dégradé) — un litige s'ouvre ~1×/jour, pas
/// besoin d'un canal WebSocket dédié par admin connecté.
final adminOpenDisputesProvider =
    StreamProvider.autoDispose<List<Dispute>>((ref) {
  final repo = ref.watch(adminDisputesRepositoryProvider);
  return pollStream(const Duration(seconds: 120), repo.listAll);
});

final adminDisputeByMatchProvider =
    FutureProvider.family.autoDispose<Dispute?, String>((ref, matchId) {
  return ref.watch(adminDisputesRepositoryProvider).getByMatchId(matchId);
});
