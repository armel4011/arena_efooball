import 'package:arena/core/utils/poll_stream.dart';
import 'package:arena/data/repositories/profile_repository.dart';
import 'package:arena/features_shared/auth_common/shared_auth_providers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Snapshot d'un paiement P2P manuel (PHASE 11bis).
///
/// Mappé directement sur la table `payments`. On garde un modèle flat,
/// pas freezed, parce que les paiements n'ont pas vocation à être passés
/// au build_runner pour V1 (le modèle reste interne à la feature).
@immutable
class PaymentRecord {
  const PaymentRecord({
    required this.id,
    required this.userId,
    required this.competitionId,
    required this.amountLocal,
    required this.currency,
    required this.status,
    required this.payerMethod,
    required this.payerPhone,
    required this.createdAt,
    this.validatedAt,
    this.validatedByAdminId,
    this.rejectionReason,
  });

  factory PaymentRecord.fromJson(Map<String, dynamic> row) {
    return PaymentRecord(
      id: row['id'] as String,
      userId: row['user_id'] as String,
      competitionId: row['competition_id'] as String,
      amountLocal: (row['amount_local'] as num).toDouble(),
      currency: row['currency'] as String? ?? 'XAF',
      status: row['status'] as String,
      payerMethod: row['payer_method'] as String?,
      payerPhone: row['payer_phone'] as String?,
      createdAt: DateTime.parse(row['created_at'] as String),
      validatedAt: row['validated_at'] == null
          ? null
          : DateTime.parse(row['validated_at'] as String),
      validatedByAdminId: row['validated_by_admin_id'] as String?,
      rejectionReason: row['rejection_reason'] as String?,
    );
  }

  final String id;
  final String userId;
  final String competitionId;
  final double amountLocal;
  final String currency;

  /// `pending` · `awaiting_admin` · `succeeded` · `rejected`.
  final String status;

  /// `MTN_MOMO` ou `ORANGE_MONEY`.
  final String? payerMethod;

  /// Numéro Mobile Money utilisé par le joueur pour payer.
  final String? payerPhone;
  final DateTime createdAt;
  final DateTime? validatedAt;
  final String? validatedByAdminId;
  final String? rejectionReason;
}

class PaymentRepository {
  PaymentRepository(this._client);

  static const _table = 'payments';

  final SupabaseClient _client;

  /// INSERT manuel d'un paiement P2P après que le joueur ait cliqué
  /// "J'AI PAYÉ" sur P2. Retourne l'id du row pour permettre à P3 de
  /// streamer son statut. Le row reste en `awaiting_admin` jusqu'à
  /// validation/refus manuel par le super-admin (pas de timeout).
  Future<String> submitManualPayment({
    required String competitionId,
    required double amountLocal,
    required String currency,
    required String payerMethodCode,
    required String payerPhone,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw StateError('No authenticated user — cannot submit payment.');
    }
    final inserted = await _client
        .from(_table)
        .insert({
          'user_id': userId,
          'competition_id': competitionId,
          'amount_local': amountLocal,
          'currency': currency,
          'provider': 'mobile_money_manual',
          'provider_method': payerMethodCode,
          'payer_method': payerMethodCode,
          'payer_phone': payerPhone,
          'status': 'awaiting_admin',
        })
        .select('id')
        .single();
    return inserted['id'] as String;
  }

  /// Stream realtime du row payment — utilisé par P3 pour passer à P4 ou
  /// P5 dès que le super-admin valide / rejette / le row expire.
  Stream<PaymentRecord?> watchById(String paymentId) {
    return _client
        .from(_table)
        .stream(primaryKey: ['id'])
        .eq('id', paymentId)
        .map((rows) => rows.isEmpty ? null : PaymentRecord.fromJson(rows.first));
  }

  /// Cancel la transaction côté joueur — utilisé sur P3 si l'utilisateur
  /// abandonne avant l'expiration. RLS : seul l'auteur peut le faire.
  Future<void> cancel(String paymentId) async {
    await _client
        .from(_table)
        .update({'status': 'failed'})
        .eq('id', paymentId);
  }

  /// Retourne `true` si le joueur a au moins un paiement non réglé.
  /// Utilisé par le flux de suppression de compte pour bloquer la
  /// suppression tant qu'un paiement est en cours.
  ///
  /// Couvre les trois statuts « en vol » : `awaiting_admin` (P2P manuel V1,
  /// en attente de validation super-admin — c'est le cas réel aujourd'hui),
  /// plus `pending`/`processing` (passerelles CinetPay/NowPayments V2). Le
  /// filtre sur `'pending'` seul laissait passer la suppression d'un compte
  /// avec un paiement `awaiting_admin` non validé (fix audit P0).
  Future<bool> hasPendingPayments(String userId) async {
    final rows = await _client
        .from(_table)
        .select('id')
        .eq('user_id', userId)
        .inFilter('status', const ['pending', 'processing', 'awaiting_admin'])
        .limit(1);
    return (rows as List).isNotEmpty;
  }

  /// Stream de l'historique paiements du joueur courant (P6).
  Stream<List<PaymentRecord>> watchMine() {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      return const Stream.empty();
    }
    return _client
        .from(_table)
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('created_at')
        .map((rows) => [
              for (final row in rows.reversed) PaymentRecord.fromJson(row),
            ],);
  }

  /// One-shot historique paiements du joueur courant. Utilisé par le
  /// poll downgrade (`myPaymentsProvider`).
  Future<List<PaymentRecord>> listMine({int limit = 50}) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return const [];
    final rows = await _client
        .from(_table)
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .limit(limit);
    return [
      for (final row in rows) PaymentRecord.fromJson(row),
    ];
  }
}

final paymentRepositoryProvider = Provider<PaymentRepository>((ref) {
  return PaymentRepository(ref.watch(supabaseClientProvider));
});

/// `.autoDispose` — le payment processing page est court (P3/P4) ; rien
/// ne re-consomme un payment id passé.
final paymentByIdProvider =
    StreamProvider.family.autoDispose<PaymentRecord?, String>((ref, id) {
  return ref.watch(paymentRepositoryProvider).watchById(id);
});

/// Historique paiements du joueur courant (écran P6).
///
/// Downgrade Realtime → poll (audit 2026-05-19) : un validate paiement
/// admin met ~minutes, l'utilisateur reload la page volontairement.
/// Poll 60s couvre largement la perception et libère le Realtime
/// channel pour les usages critiques.
final myPaymentsProvider = StreamProvider<List<PaymentRecord>>((ref) {
  final session = ref.watch(currentSessionProvider);
  if (session == null) {
    return Stream.value(const <PaymentRecord>[]);
  }
  final repo = ref.watch(paymentRepositoryProvider);
  return pollStream(const Duration(seconds: 60), repo.listMine);
});

/// Map competition_id → PaymentRecord pour les paiements actuellement
/// en `awaiting_admin` du joueur courant. Utilisé par la liste comp
/// pour décider si on doit ré-ouvrir P3 sur un paiement existant au
/// lieu de relancer le flow d'inscription.
final myPendingPaymentByCompetitionProvider =
    Provider<Map<String, PaymentRecord>>((ref) {
  final payments = ref.watch(myPaymentsProvider).valueOrNull ?? const [];
  return {
    for (final p in payments)
      if (p.status == 'awaiting_admin') p.competitionId: p,
  };
});
