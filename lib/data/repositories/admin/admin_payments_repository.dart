import 'package:arena/core/utils/poll_stream.dart';
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

  /// One-shot fetch des paiements en attente de validation, plus
  /// anciens en tête. **Joints serveur** pour username + competition
  /// name en une seule requête (vs 3 queries avant — payments +
  /// profiles + competitions).
  Future<List<AdminPaymentRow>> listPending() async {
    final rows = await _client
        .from(_table)
        .select(_selectWithJoins)
        .eq('status', 'awaiting_admin')
        .order('created_at');
    return [for (final r in rows) _parseJoinedRow(r)];
  }

  /// One-shot fetch de l'historique (paiements clos : validés ou
  /// rejetés), plus récents en tête. Idem : joints serveur.
  Future<List<AdminPaymentRow>> listHistory() async {
    final rows = await _client
        .from(_table)
        .select(_selectWithJoins)
        .inFilter('status', ['succeeded', 'rejected', 'refunded'])
        .order('updated_at', ascending: false);
    return [for (final r in rows) _parseJoinedRow(r)];
  }

  /// File des remboursements à effectuer : paiements `refund_pending`
  /// (compétition annulée), plus anciens en tête. Le `payer_phone` est le
  /// numéro sur lequel le staff doit rembourser via Mobile Money.
  Future<List<AdminPaymentRow>> listRefundPending() async {
    final rows = await _client
        .from(_table)
        .select(_selectWithJoins)
        .eq('status', 'refund_pending')
        .order('created_at');
    return [for (final r in rows) _parseJoinedRow(r)];
  }

  /// Select avec joints embarques sur `profiles` (username) et
  /// `competitions` (name). PostgREST embed les rows referencees
  /// sous une cle "profiles" / "competitions" dans la reponse JSON ;
  /// on les extrait dans `_parseJoinedRow`.
  static const _selectWithJoins =
      '*, profiles!user_id(username), competitions!competition_id(name)';

  AdminPaymentRow _parseJoinedRow(Map<String, dynamic> row) {
    final profile = row['profiles'] as Map<String, dynamic>?;
    final comp = row['competitions'] as Map<String, dynamic>?;
    // PaymentRecord.fromJson ne connait pas les nested ; on les retire
    // pour eviter un parsing inattendu.
    final paymentJson = Map<String, dynamic>.from(row)
      ..remove('profiles')
      ..remove('competitions');
    return AdminPaymentRow(
      payment: PaymentRecord.fromJson(paymentJson),
      username: profile?['username'] as String? ?? '—',
      competitionName: comp?['name'] as String? ?? '—',
    );
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

  /// Marque un paiement `refund_pending` comme `refunded` (après le virement
  /// Mobile Money réel) via la RPC `mark_payment_refunded` (super-admin +
  /// notifie le joueur).
  Future<void> markRefunded(String paymentId) async {
    await _client.rpc<void>(
      'mark_payment_refunded',
      params: {'p_payment_id': paymentId},
    );
  }
}

final adminPaymentsRepositoryProvider =
    Provider<AdminPaymentsRepository>((ref) {
  return AdminPaymentsRepository(ref.watch(supabaseClientProvider));
});

/// Polling 120 s (Realtime dégradé) — le super-admin valide les
/// paiements en minutes/heures, pas besoin d'updates instantanés.
final adminPendingPaymentsProvider =
    StreamProvider.autoDispose<List<AdminPaymentRow>>((ref) {
  final repo = ref.watch(adminPaymentsRepositoryProvider);
  return pollStream(const Duration(seconds: 120), repo.listPending);
});

final adminPaymentsHistoryProvider =
    StreamProvider.autoDispose<List<AdminPaymentRow>>((ref) {
  final repo = ref.watch(adminPaymentsRepositoryProvider);
  return pollStream(const Duration(seconds: 120), repo.listHistory);
});

/// File des remboursements à effectuer (paiements `refund_pending`).
final adminRefundPendingProvider =
    StreamProvider.autoDispose<List<AdminPaymentRow>>((ref) {
  final repo = ref.watch(adminPaymentsRepositoryProvider);
  return pollStream(const Duration(seconds: 120), repo.listRefundPending);
});
