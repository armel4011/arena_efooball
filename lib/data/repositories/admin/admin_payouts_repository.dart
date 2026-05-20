import 'package:arena/core/utils/poll_stream.dart';
import 'package:arena/data/models/payout.dart';
import 'package:arena/data/repositories/profile_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Admin-side reads + writes over `payouts` (PHASE 11).
///
/// The provider dispatch (CinetPay / NowPayments) lives in the
/// `validate_payout` Edge Function (PHASE 11bis / 12.5). Until that
/// EF lands, the admin still does the manual review — we flip the
/// status to `validated`, stamp who/when/why, and let PHASE 11bis
/// pick up the row to actually push the money. The
/// `payouts_admin_update` RLS in migration
/// `20260512100001_phase11_admin_write_rls.sql` is what lets this
/// happen.
class AdminPayoutsRepository {
  const AdminPayoutsRepository(this._client);

  static const _table = 'payouts';

  final SupabaseClient _client;

  /// One-shot fetch de tous les payouts, plus récents en tête,
  /// optionnellement filtrés par [status]. Consommé en polling.
  Future<List<Payout>> listAll({String? status}) async {
    final rows = await _client
        .from(_table)
        .select()
        .order('created_at', ascending: false);
    final list = [for (final row in rows) Payout.fromJson(row)];
    if (status == null) return list;
    return list.where((p) => p.status == status).toList(growable: false);
  }

  /// Admin validates a payout. Flips status to `validated`, stamps
  /// who validated when, and stores the justification.
  Future<void> validate({
    required String payoutId,
    required String adminId,
    required String justification,
  }) async {
    await _client.from(_table).update({
      'status': 'validated',
      'validated_by_admin_id': adminId,
      'validated_at': DateTime.now().toUtc().toIso8601String(),
      'validation_justification': justification,
    }).eq('id', payoutId);
  }

  /// Refuses a payout — money stays in the platform commission, the
  /// player gets notified (PHASE 12.5 dispatch). The DB enum calls
  /// this state `cancelled`.
  Future<void> refuse({
    required String payoutId,
    required String adminId,
    required String justification,
  }) async {
    await _client.from(_table).update({
      'status': 'cancelled',
      'validated_by_admin_id': adminId,
      'validated_at': DateTime.now().toUtc().toIso8601String(),
      'validation_justification': justification,
    }).eq('id', payoutId);
  }
}

final adminPayoutsRepositoryProvider =
    Provider<AdminPayoutsRepository>((ref) {
  return AdminPayoutsRepository(ref.watch(supabaseClientProvider));
});

/// Polling 300 s (Realtime dégradé) — un payout se traite en minutes
/// à heures, les updates instantanés n'apportent rien.
final adminPendingPayoutsProvider =
    StreamProvider.autoDispose<List<Payout>>((ref) {
  final repo = ref.watch(adminPayoutsRepositoryProvider);
  return pollStream(
    const Duration(seconds: 300),
    () => repo.listAll(status: 'pending_admin_validation'),
  );
});

final adminAllPayoutsProvider =
    StreamProvider.autoDispose<List<Payout>>((ref) {
  final repo = ref.watch(adminPayoutsRepositoryProvider);
  return pollStream(const Duration(seconds: 300), repo.listAll);
});
