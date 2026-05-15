import 'package:arena/data/models/profile.dart';
import 'package:arena/data/repositories/profile_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Super-admin user management (PHASE 11 + 12.5).
///
/// Reads passent par la RPC `admin_filter_users` (PHASE 12.5) qui
/// supporte 5 critères avancés en plus des filtres classiques :
/// won / paid / rewarded / disputed / guilty. Les écritures (ban / unban
/// / KYC override) flippent encore les flags `profiles` directement
/// sous la policy `profiles_admin_all`.
class AdminUsersRepository {
  const AdminUsersRepository(this._client);

  static const _table = 'profiles';

  final SupabaseClient _client;

  Future<List<Profile>> list({AdminUsersFilter? filter, int limit = 100}) async {
    final f = filter ?? const AdminUsersFilter();
    final rows = await _client.rpc<List<dynamic>>(
      'admin_filter_users',
      params: {
        'p_country_code': f.countryCode,
        'p_status': f.filter,
        'p_search':
            (f.searchQuery == null || f.searchQuery!.trim().isEmpty)
                ? null
                : f.searchQuery!.trim(),
        'p_won': f.wonCompetition ? true : null,
        'p_paid': f.paidEntry ? true : null,
        'p_rewarded': f.receivedReward ? true : null,
        'p_disputed': f.hadDispute ? true : null,
        'p_guilty': f.guiltyInDispute ? true : null,
        'p_limit': limit,
      },
    );
    return [
      for (final row in rows) Profile.fromJson(row as Map<String, dynamic>),
    ];
  }

  Future<void> ban(String userId) async {
    await _client
        .from(_table)
        .update({'is_active': false})
        .eq('id', userId);
  }

  Future<void> unban(String userId) async {
    await _client
        .from(_table)
        .update({'is_active': true})
        .eq('id', userId);
  }

  Future<void> overrideKyc({
    required String userId,
    required String status, // 'verified' | 'rejected'
  }) async {
    await _client.from(_table).update({
      'kyc_status': status,
      if (status == 'verified')
        'kyc_verified_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', userId);
  }
}

final adminUsersRepositoryProvider = Provider<AdminUsersRepository>((ref) {
  return AdminUsersRepository(ref.watch(supabaseClientProvider));
});

/// Filtres combinables pour `admin_filter_users`. Tous nullable/false
/// par défaut → sans filtre la requête retourne les N derniers profils
/// créés (tri DESC par created_at).
@immutable
class AdminUsersFilter {
  const AdminUsersFilter({
    this.countryCode,
    this.filter,
    this.searchQuery,
    this.wonCompetition = false,
    this.paidEntry = false,
    this.receivedReward = false,
    this.hadDispute = false,
    this.guiltyInDispute = false,
  });

  /// ISO 3166-1 alpha-2 — ex. 'CM', 'CI'.
  final String? countryCode;

  /// 'active' | 'banned' | 'kyc_pending'.
  final String? filter;

  /// Match contre username OU email (ilike, case-insensitive).
  final String? searchQuery;

  /// A remporté au moins une compétition (`final_rank = 1`).
  final bool wonCompetition;

  /// A payé au moins une inscription (status succeeded/validated).
  final bool paidEntry;

  /// A reçu au moins un payout complété.
  final bool receivedReward;

  /// A été impliqué dans au moins un litige (player1 ou player2 du match).
  final bool hadDispute;

  /// A été désigné coupable dans au moins un litige résolu.
  final bool guiltyInDispute;

  AdminUsersFilter copyWith({
    String? countryCode,
    String? filter,
    String? searchQuery,
    bool? wonCompetition,
    bool? paidEntry,
    bool? receivedReward,
    bool? hadDispute,
    bool? guiltyInDispute,
    bool resetCountryCode = false,
    bool resetFilter = false,
    bool resetSearch = false,
  }) {
    return AdminUsersFilter(
      countryCode:
          resetCountryCode ? null : (countryCode ?? this.countryCode),
      filter: resetFilter ? null : (filter ?? this.filter),
      searchQuery: resetSearch ? null : (searchQuery ?? this.searchQuery),
      wonCompetition: wonCompetition ?? this.wonCompetition,
      paidEntry: paidEntry ?? this.paidEntry,
      receivedReward: receivedReward ?? this.receivedReward,
      hadDispute: hadDispute ?? this.hadDispute,
      guiltyInDispute: guiltyInDispute ?? this.guiltyInDispute,
    );
  }

  /// `true` quand au moins un des 5 critères avancés est actif. Utile
  /// pour l'UI (badge "filtres avancés actifs" + bouton reset).
  bool get hasAdvancedFilter =>
      wonCompetition ||
      paidEntry ||
      receivedReward ||
      hadDispute ||
      guiltyInDispute;

  @override
  bool operator ==(Object other) =>
      other is AdminUsersFilter &&
      other.countryCode == countryCode &&
      other.filter == filter &&
      other.searchQuery == searchQuery &&
      other.wonCompetition == wonCompetition &&
      other.paidEntry == paidEntry &&
      other.receivedReward == receivedReward &&
      other.hadDispute == hadDispute &&
      other.guiltyInDispute == guiltyInDispute;

  @override
  int get hashCode => Object.hash(
        countryCode,
        filter,
        searchQuery,
        wonCompetition,
        paidEntry,
        receivedReward,
        hadDispute,
        guiltyInDispute,
      );
}

final adminUsersProvider =
    FutureProvider.family<List<Profile>, AdminUsersFilter>((ref, filter) {
  return ref.watch(adminUsersRepositoryProvider).list(filter: filter);
});
