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
  /// anciens en tête. Consommé en polling (cf. provider) : le filtre
  /// `status` est appliqué côté serveur — contrairement au `.stream()`
  /// Realtime qui aurait ramené toute la table.
  Future<List<AdminPaymentRow>> listPending() async {
    final rows = await _client
        .from(_table)
        .select()
        .eq('status', 'awaiting_admin')
        .order('created_at');
    return _enrich([
      for (final r in rows)
        AdminPaymentRow(
          payment: PaymentRecord.fromJson(r),
          username: '—',
          competitionName: '—',
        ),
    ]);
  }

  /// One-shot fetch de l'historique (paiements clos : validés ou
  /// rejetés), plus récents en tête. Filtre `status` côté serveur.
  Future<List<AdminPaymentRow>> listHistory() async {
    final rows = await _client
        .from(_table)
        .select()
        .inFilter('status', ['succeeded', 'rejected'])
        .order('updated_at', ascending: false);
    return _enrich([
      for (final r in rows)
        AdminPaymentRow(
          payment: PaymentRecord.fromJson(r),
          username: '—',
          competitionName: '—',
        ),
    ]);
  }

  /// Joint profiles.username + competitions.name. La realtime stream
  /// de Supabase ne supporte pas les selects avec joins — on le fait
  /// donc en deuxième pass côté Dart.
  Future<List<AdminPaymentRow>> _enrich(List<AdminPaymentRow> rows) async {
    if (rows.isEmpty) return rows;
    final userIds = {for (final r in rows) r.payment.userId}.toList();
    final compIds = {for (final r in rows) r.payment.competitionId}.toList();
    final users = (await _client
            .from('profiles')
            .select('id, username')
            .inFilter('id', userIds) as List<dynamic>)
        .cast<Map<String, dynamic>>();
    final comps = (await _client
            .from('competitions')
            .select('id, name')
            .inFilter('id', compIds) as List<dynamic>)
        .cast<Map<String, dynamic>>();
    final usernameById = {
      for (final u in users)
        u['id'] as String: u['username'] as String? ?? '—',
    };
    final compNameById = {
      for (final c in comps)
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
