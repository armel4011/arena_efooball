import 'package:arena/data/repositories/payment_repository.dart';
import 'package:arena/data/repositories/profile_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Vue enrichie d'un paiement pour la console super-admin : on joint
/// l'username du joueur et le nom de la compétition pour éviter à la UI
/// de faire 2 lookups séparés par ligne.
@immutable
class AdminPaymentRow {
  const AdminPaymentRow({
    required this.payment,
    required this.username,
    required this.competitionName,
  });

  final PaymentRecord payment;
  final String username;
  final String competitionName;
}

/// PHASE 11bis — super-admin reads + writes sur `payments`.
///
/// Permet de :
///   • streamer les paiements `awaiting_admin` (les plus anciens en haut)
///   • streamer l'historique (validés + rejetés)
///   • valider un paiement (status → succeeded → trigger DB insère la
///     registration en confirmed)
///   • refuser un paiement (status → rejected + raison)
///
/// Pas de timeout : un paiement reste en `awaiting_admin` jusqu'à
/// validation ou refus manuel par le super-admin.
class AdminPaymentsRepository {
  const AdminPaymentsRepository(this._client);

  static const _table = 'payments';

  final SupabaseClient _client;

  Stream<List<AdminPaymentRow>> watchPending() {
    return _client
        .from(_table)
        .stream(primaryKey: ['id'])
        .order('created_at')
        .map((rows) {
          final pending = rows
              .where((r) => r['status'] == 'awaiting_admin')
              .toList(growable: false);
          // Realtime stream renvoie déjà les jointures — on les fait ici.
          return [
            for (final r in pending)
              AdminPaymentRow(
                payment: PaymentRecord.fromJson(r),
                username: '—',
                competitionName: '—',
              ),
          ];
        })
        .asyncMap(_enrich);
  }

  Stream<List<AdminPaymentRow>> watchHistory() {
    return _client
        .from(_table)
        .stream(primaryKey: ['id'])
        .order('updated_at', ascending: false)
        .map((rows) {
          final closed = rows.where((r) {
            final s = r['status'] as String?;
            return s == 'succeeded' || s == 'rejected';
          }).toList(growable: false);
          return [
            for (final r in closed)
              AdminPaymentRow(
                payment: PaymentRecord.fromJson(r),
                username: '—',
                competitionName: '—',
              ),
          ];
        })
        .asyncMap(_enrich);
  }

  /// Joint profiles.username + competitions.name. La realtime stream
  /// de Supabase ne supporte pas les selects avec joins — on le fait
  /// donc en deuxième pass côté Dart.
  Future<List<AdminPaymentRow>> _enrich(List<AdminPaymentRow> rows) async {
    if (rows.isEmpty) return rows;
    final userIds = {for (final r in rows) r.payment.userId}.toList();
    final compIds = {for (final r in rows) r.payment.competitionId}.toList();
    final users = await _client
        .from('profiles')
        .select('id, username')
        .inFilter('id', userIds);
    final comps = await _client
        .from('competitions')
        .select('id, name')
        .inFilter('id', compIds);
    final usernameById = {
      for (final u in users as List<dynamic>)
        u['id'] as String: u['username'] as String? ?? '—',
    };
    final compNameById = {
      for (final c in comps as List<dynamic>)
        c['id'] as String: c['name'] as String? ?? '—',
    };
    return [
      for (final r in rows)
        AdminPaymentRow(
          payment: r.payment,
          username: usernameById[r.payment.userId] ?? '—',
          competitionName: compNameById[r.payment.competitionId] ?? '—',
        ),
    ];
  }

  /// Valide un paiement. Le trigger DB `on_payment_validated`
  /// insère/upsert la registration en confirmed.
  Future<void> validate({
    required String paymentId,
    required String adminId,
  }) async {
    await _client.from(_table).update({
      'status': 'succeeded',
      'validated_by_admin_id': adminId,
      'validated_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', paymentId);
  }

  /// Refuse un paiement avec justification (affichée au joueur sur P5).
  Future<void> reject({
    required String paymentId,
    required String adminId,
    required String reason,
  }) async {
    await _client.from(_table).update({
      'status': 'rejected',
      'validated_by_admin_id': adminId,
      'validated_at': DateTime.now().toUtc().toIso8601String(),
      'rejection_reason': reason,
    }).eq('id', paymentId);
  }

}

final adminPaymentsRepositoryProvider =
    Provider<AdminPaymentsRepository>((ref) {
  return AdminPaymentsRepository(ref.watch(supabaseClientProvider));
});

final adminPendingPaymentsProvider =
    StreamProvider<List<AdminPaymentRow>>((ref) {
  return ref.watch(adminPaymentsRepositoryProvider).watchPending();
});

final adminPaymentsHistoryProvider =
    StreamProvider<List<AdminPaymentRow>>((ref) {
  return ref.watch(adminPaymentsRepositoryProvider).watchHistory();
});
