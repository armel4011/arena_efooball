import 'package:arena/data/repositories/profile_repository.dart';
import 'package:arena/features_shared/auth_common/shared_auth_providers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Snapshot d'un versement de gains (F-1, P2P manuel).
///
/// Mappé sur la table `payouts`. Flux : `pending_admin_validation` (généré par
/// le super-admin) → le gagnant réclame (saisit `payee_phone`/`payee_method`,
/// `claimed_at`) → le super-admin verse réellement et marque `completed`.
@immutable
class PayoutRecord {
  const PayoutRecord({
    required this.id,
    required this.userId,
    required this.competitionId,
    required this.amountLocal,
    required this.currency,
    required this.status,
    required this.createdAt,
    this.rank,
    this.payeePhone,
    this.payeeMethod,
    this.claimedAt,
    this.validatedAt,
    this.competitionName,
  });

  factory PayoutRecord.fromJson(Map<String, dynamic> row) {
    return PayoutRecord(
      id: row['id'] as String,
      userId: row['user_id'] as String,
      competitionId: row['competition_id'] as String,
      amountLocal: (row['amount_local'] as num).toDouble(),
      currency: row['currency'] as String? ?? 'XAF',
      status: row['status'] as String,
      rank: row['rank'] as int?,
      payeePhone: row['payee_phone'] as String?,
      payeeMethod: row['payee_method'] as String?,
      claimedAt: row['claimed_at'] == null
          ? null
          : DateTime.parse(row['claimed_at'] as String),
      validatedAt: row['validated_at'] == null
          ? null
          : DateTime.parse(row['validated_at'] as String),
      createdAt: DateTime.parse(row['created_at'] as String),
      // Nom de compétition embarqué (`*, competitions(name)`) pour la file admin.
      competitionName: (row['competitions'] as Map<String, dynamic>?)?['name']
          as String?,
    );
  }

  final String id;
  final String userId;
  final String competitionId;
  final double amountLocal;
  final String currency;

  /// `pending_admin_validation` · `completed` (+ statuts hérités du flux auto).
  final String status;
  final int? rank;
  final String? payeePhone;

  /// `MTN_MOMO` ou `ORANGE_MONEY`.
  final String? payeeMethod;
  final DateTime? claimedAt;
  final DateTime? validatedAt;
  final DateTime createdAt;

  /// Nom de la compétition (présent seulement sur la file admin embarquée).
  final String? competitionName;

  /// Le gagnant a fourni son numéro de retrait (en attente de versement).
  bool get isClaimed => payeePhone != null && payeePhone!.isNotEmpty;
  bool get isPaid => status == 'completed';
  bool get isPending => status == 'pending_admin_validation';
}

class PayoutRepository {
  PayoutRepository(this._client);

  static const _table = 'payouts';

  final SupabaseClient _client;

  // ─── Joueur ────────────────────────────────────────────────────────────

  /// Historique des gains du joueur courant (écran « Mes gains »).
  Future<List<PayoutRecord>> listMine({int limit = 50}) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return const [];
    final rows = await _client
        .from(_table)
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .limit(limit);
    return [for (final row in rows) PayoutRecord.fromJson(row)];
  }

  /// Le gagnant réclame un gain : saisit son numéro/méthode Mobile Money de
  /// retrait via la RPC `claim_payout` (SECURITY DEFINER, vérifie la propriété).
  Future<void> claim({
    required String payoutId,
    required String phone,
    required String method,
  }) async {
    await _client.rpc<void>(
      'claim_payout',
      params: {
        'p_payout_id': payoutId,
        'p_phone': phone,
        'p_method': method,
      },
    );
  }

  // ─── Super-admin ───────────────────────────────────────────────────────

  /// Génère les lignes de versement d'une compétition terminée via la RPC
  /// `generate_payouts` (gate is_super_admin). Retourne le nombre de gagnants.
  Future<int> generate(String competitionId) async {
    final res = await _client.rpc<dynamic>(
      'generate_payouts',
      params: {'p_competition_id': competitionId},
    );
    return (res as num?)?.toInt() ?? 0;
  }

  /// File globale des versements à traiter (super-admin) : tous les payouts
  /// encore `pending_admin_validation`, réclamés d'abord (numéro fourni →
  /// prêts à payer), puis ceux en attente de réclamation.
  Future<List<PayoutRecord>> listPendingGlobal({int limit = 200}) async {
    final rows = await _client
        .from(_table)
        .select('*, competitions(name)')
        .eq('status', 'pending_admin_validation')
        .order('claimed_at', ascending: false, nullsFirst: false)
        .order('created_at')
        .limit(limit);
    return [for (final row in rows) PayoutRecord.fromJson(row)];
  }

  /// Liste les versements d'une compétition (file admin), du plus récent.
  Future<List<PayoutRecord>> listByCompetition(String competitionId) async {
    final rows = await _client
        .from(_table)
        .select()
        .eq('competition_id', competitionId)
        .order('rank')
        .order('created_at', ascending: false);
    return [for (final row in rows) PayoutRecord.fromJson(row)];
  }

  /// Marque un versement comme payé (après virement Mobile Money réel) via la
  /// RPC `mark_payout_paid` (gate is_super_admin, exige un numéro réclamé).
  Future<void> markPaid(String payoutId) async {
    await _client.rpc<void>(
      'mark_payout_paid',
      params: {'p_payout_id': payoutId},
    );
  }
}

final payoutRepositoryProvider = Provider<PayoutRepository>((ref) {
  return PayoutRepository(ref.watch(supabaseClientProvider));
});

/// Gains du joueur courant (écran « Mes gains »).
final myPayoutsProvider = FutureProvider.autoDispose<List<PayoutRecord>>((ref) {
  final session = ref.watch(currentSessionProvider);
  if (session == null) return Future.value(const <PayoutRecord>[]);
  return ref.watch(payoutRepositoryProvider).listMine();
});

/// Versements d'une compétition (file admin), paramétré par competitionId.
final payoutsByCompetitionProvider = FutureProvider.autoDispose
    .family<List<PayoutRecord>, String>((ref, competitionId) {
  return ref.watch(payoutRepositoryProvider).listByCompetition(competitionId);
});

/// File globale des versements à traiter (écran admin `/super/payouts`).
final pendingPayoutsProvider =
    FutureProvider.autoDispose<List<PayoutRecord>>((ref) {
  return ref.watch(payoutRepositoryProvider).listPendingGlobal();
});
