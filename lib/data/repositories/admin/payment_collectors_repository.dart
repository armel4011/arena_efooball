import 'package:arena/data/repositories/profile_repository.dart'
    show supabaseClientProvider;
import 'package:arena/features_shared/auth_common/shared_auth_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Un compte collecteur de paiement (agent qui valide les paiements de SON
/// pays sous quota). Lu depuis `payment_collectors` (+ pseudo joint).
class PaymentCollector {
  const PaymentCollector({
    required this.id,
    required this.profileId,
    required this.countryCode,
    required this.quotaLocal,
    required this.outstandingLocal,
    required this.isBlocked,
    required this.isActive,
    this.username,
  });

  factory PaymentCollector.fromJson(Map<String, dynamic> json) {
    final profile = json['profile'] as Map<String, dynamic>?;
    return PaymentCollector(
      id: json['id'] as String,
      profileId: json['profile_id'] as String,
      countryCode: json['country_code'] as String,
      quotaLocal: (json['quota_local'] as num).toDouble(),
      outstandingLocal: (json['outstanding_local'] as num).toDouble(),
      isBlocked: json['is_blocked'] as bool? ?? false,
      isActive: json['is_active'] as bool? ?? true,
      username: profile?['username'] as String?,
    );
  }

  final String id;
  final String profileId;
  final String countryCode;
  final double quotaLocal;
  final double outstandingLocal;
  final bool isBlocked;
  final bool isActive;
  final String? username;

  /// Reste disponible avant blocage (ne descend pas sous 0).
  double get remaining =>
      (quotaLocal - outstandingLocal).clamp(0, quotaLocal).toDouble();

  /// Part de quota consommée (0..1) — pour une jauge.
  double get usageRatio =>
      quotaLocal <= 0 ? 0 : (outstandingLocal / quotaLocal).clamp(0, 1);
}

/// Un versement déclaré par un collecteur, validé/refusé par le super-admin.
class CollectorRemittance {
  const CollectorRemittance({
    required this.id,
    required this.collectorId,
    required this.amountLocal,
    required this.status,
    required this.declaredAt,
    this.note,
    this.countryCode,
    this.username,
  });

  factory CollectorRemittance.fromJson(Map<String, dynamic> json) {
    final collector = json['collector'] as Map<String, dynamic>?;
    final profile = collector?['profile'] as Map<String, dynamic>?;
    return CollectorRemittance(
      id: json['id'] as String,
      collectorId: json['collector_id'] as String,
      amountLocal: (json['amount_local'] as num).toDouble(),
      status: json['status'] as String,
      declaredAt: DateTime.parse(json['declared_at'] as String),
      note: json['note'] as String?,
      countryCode: collector?['country_code'] as String?,
      username: profile?['username'] as String?,
    );
  }

  final String id;
  final String collectorId;
  final double amountLocal;
  final String status; // declared | validated | rejected
  final DateTime declaredAt;
  final String? note;
  final String? countryCode;
  final String? username;
}

/// Un profil éligible au rôle collecteur (pour l'affectation pays + quota).
class CollectorProfile {
  const CollectorProfile({
    required this.id,
    required this.username,
    required this.allowedCountries,
  });

  factory CollectorProfile.fromJson(Map<String, dynamic> json) {
    final raw = json['admin_allowed_countries'] as List<dynamic>?;
    return CollectorProfile(
      id: json['id'] as String,
      username: json['username'] as String? ?? '—',
      allowedCountries:
          raw == null ? const <String>[] : raw.map((e) => e as String).toList(),
    );
  }

  final String id;
  final String username;
  final List<String> allowedCountries;
}

/// Un paiement en attente de validation par le collecteur (sa file).
class CollectorPayment {
  const CollectorPayment({
    required this.id,
    required this.amountLocal,
    required this.currency,
    required this.createdAt,
    this.payerPhone,
    this.operatorLabel,
    this.countryCode,
    this.competitionName,
    this.proofPath,
  });

  factory CollectorPayment.fromJson(Map<String, dynamic> json) {
    final comp = json['competition'] as Map<String, dynamic>?;
    return CollectorPayment(
      id: json['id'] as String,
      amountLocal: (json['amount_local'] as num).toDouble(),
      currency: json['currency'] as String? ?? '',
      createdAt: DateTime.parse(json['created_at'] as String),
      payerPhone: json['payer_phone'] as String?,
      operatorLabel: json['operator_label'] as String?,
      countryCode: json['country_code'] as String?,
      competitionName: comp?['name'] as String?,
      proofPath: json['proof_path'] as String?,
    );
  }

  final String id;
  final double amountLocal;
  final String currency;
  final DateTime createdAt;
  final String? payerPhone;
  final String? operatorLabel;
  final String? countryCode;
  final String? competitionName;
  final String? proofPath;
}

/// CRUD + RPC autour des collecteurs de paiement et de leurs versements.
///
/// Toutes les écritures passent par des RPC `SECURITY DEFINER` (gardes de rôle
/// + quota côté serveur). Le repo n'expose que des lectures RLS-cloisonnées et
/// les appels RPC.
class PaymentCollectorsRepository {
  const PaymentCollectorsRepository(this._client);

  final SupabaseClient _client;

  static const _selectCollector =
      '*, profile:profiles!payment_collectors_profile_id_fkey(username)';
  static const _selectRemittance =
      '*, collector:payment_collectors!collector_remittances_collector_id_fkey(country_code, profile:profiles!payment_collectors_profile_id_fkey(username))';

  // ─── Lectures ────────────────────────────────────────────────────────────

  /// Profils ayant le rôle `collector` — pour que le super-admin leur affecte
  /// un pays + un quota (création d'un compte collecteur). Lecture profiles
  /// autorisée à l'admin (RLS profiles).
  Future<List<CollectorProfile>> listCollectorProfiles() async {
    final rows = await _client
        .from('profiles')
        .select('id, username, admin_allowed_countries')
        .eq('role', 'collector')
        .order('username');
    return (rows as List)
        .map((r) => CollectorProfile.fromJson(r as Map<String, dynamic>))
        .toList();
  }

  /// Collecteurs visibles (super-admin : ceux de ses pays ; collecteur : les
  /// siens) — RLS `payment_collectors_select`.
  Future<List<PaymentCollector>> listCollectors() async {
    final rows = await _client
        .from('payment_collectors')
        .select(_selectCollector)
        .order('country_code')
        .order('created_at');
    return (rows as List)
        .map((r) => PaymentCollector.fromJson(r as Map<String, dynamic>))
        .toList();
  }

  /// Mes comptes collecteur (côté agent).
  Future<List<PaymentCollector>> listMyCollectors(String selfId) async {
    final rows = await _client
        .from('payment_collectors')
        .select(_selectCollector)
        .eq('profile_id', selfId)
        .order('country_code');
    return (rows as List)
        .map((r) => PaymentCollector.fromJson(r as Map<String, dynamic>))
        .toList();
  }

  /// File des paiements en attente pour MES comptes collecteur (RLS
  /// `payments_collector_select` ne laisse voir que les miens).
  Future<List<CollectorPayment>> listMyPendingPayments(
    List<String> collectorIds,
  ) async {
    if (collectorIds.isEmpty) return const [];
    final rows = await _client
        .from('payments')
        .select(
          'id, amount_local, currency, payer_phone, operator_label, '
          'country_code, proof_path, created_at, competition:competitions(name)',
        )
        .eq('status', 'awaiting_admin')
        .inFilter('collector_id', collectorIds)
        .order('created_at');
    return (rows as List)
        .map((r) => CollectorPayment.fromJson(r as Map<String, dynamic>))
        .toList();
  }

  /// Versements en attente de validation (super-admin, cloisonné pays par RLS).
  Future<List<CollectorRemittance>> listPendingRemittances() async {
    final rows = await _client
        .from('collector_remittances')
        .select(_selectRemittance)
        .eq('status', 'declared')
        .order('declared_at');
    return (rows as List)
        .map((r) => CollectorRemittance.fromJson(r as Map<String, dynamic>))
        .toList();
  }

  // ─── RPC super-admin ─────────────────────────────────────────────────────

  Future<String> upsertCollector({
    required String profileId,
    required String country,
    required double quota,
  }) async {
    final id = await _client.rpc<dynamic>(
      'upsert_payment_collector',
      params: {
        'p_profile_id': profileId,
        'p_country': country,
        'p_quota': quota,
      },
    );
    return id as String;
  }

  Future<void> setCollectorActive({
    required String collectorId,
    required bool active,
  }) =>
      _client.rpc<dynamic>(
        'set_payment_collector_active',
        params: {'p_collector_id': collectorId, 'p_active': active},
      );

  Future<void> validateRemittance(String remittanceId) => _client.rpc<dynamic>(
        'validate_collector_remittance',
        params: {'p_remittance_id': remittanceId},
      );

  Future<void> rejectRemittance({
    required String remittanceId,
    required String reason,
  }) =>
      _client.rpc<dynamic>(
        'reject_collector_remittance',
        params: {'p_remittance_id': remittanceId, 'p_reason': reason},
      );

  // ─── RPC collecteur ──────────────────────────────────────────────────────

  Future<void> validatePayment(String paymentId) => _client.rpc<dynamic>(
        'collector_validate_payment',
        params: {'p_payment_id': paymentId},
      );

  Future<void> rejectPayment({
    required String paymentId,
    required String reason,
  }) =>
      _client.rpc<dynamic>(
        'collector_reject_payment',
        params: {'p_payment_id': paymentId, 'p_reason': reason},
      );

  Future<String> declareRemittance({
    required String collectorId,
    String? note,
  }) async {
    final id = await _client.rpc<dynamic>(
      'declare_collector_remittance',
      params: {'p_collector_id': collectorId, 'p_note': note},
    );
    return id as String;
  }
}

final paymentCollectorsRepositoryProvider =
    Provider<PaymentCollectorsRepository>((ref) {
  return PaymentCollectorsRepository(ref.watch(supabaseClientProvider));
});

/// Liste des collecteurs (super-admin). Polling léger : la table bouge peu.
final collectorsListProvider =
    FutureProvider.autoDispose<List<PaymentCollector>>((ref) {
  return ref.watch(paymentCollectorsRepositoryProvider).listCollectors();
});

/// Versements en attente (super-admin).
final pendingRemittancesProvider =
    FutureProvider.autoDispose<List<CollectorRemittance>>((ref) {
  return ref
      .watch(paymentCollectorsRepositoryProvider)
      .listPendingRemittances();
});

/// Profils au rôle collecteur (super-admin) — pour affecter pays + quota.
final collectorProfilesProvider =
    FutureProvider.autoDispose<List<CollectorProfile>>((ref) {
  return ref.watch(paymentCollectorsRepositoryProvider).listCollectorProfiles();
});

/// Mes comptes collecteur (côté agent).
final myCollectorsProvider =
    FutureProvider.autoDispose<List<PaymentCollector>>((ref) {
  final selfId = ref.watch(currentSessionProvider)?.user.id;
  if (selfId == null) return Future.value(const []);
  return ref
      .watch(paymentCollectorsRepositoryProvider)
      .listMyCollectors(selfId);
});

/// File des paiements à valider (côté agent) — dérivée de mes comptes.
final myPendingPaymentsProvider =
    FutureProvider.autoDispose<List<CollectorPayment>>((ref) async {
  final mine = await ref.watch(myCollectorsProvider.future);
  final ids = mine.map((c) => c.id).toList();
  return ref
      .watch(paymentCollectorsRepositoryProvider)
      .listMyPendingPayments(ids);
});
