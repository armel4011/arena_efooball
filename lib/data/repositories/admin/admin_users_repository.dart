import 'package:arena/data/models/profile.dart';
import 'package:arena/data/repositories/profile_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Super-admin user management (PHASE 11).
///
/// Reads come through here for the `super_admin_users` page; the ban /
/// unban / KYC override writes flip flags on `profiles` directly under
/// the `profiles_admin_all` RLS.
class AdminUsersRepository {
  const AdminUsersRepository(this._client);

  static const _table = 'profiles';

  final SupabaseClient _client;

  Future<List<Profile>> list({
    String? countryCode,
    String? filter, // 'active' | 'banned' | 'kyc_pending'
    String? searchQuery,
    int limit = 50,
  }) async {
    var query = _client.from(_table).select();

    if (countryCode != null) {
      query = query.eq('country_code', countryCode);
    }
    switch (filter) {
      case 'active':
        query = query.eq('is_active', true);
      case 'banned':
        query = query.eq('is_active', false);
      case 'kyc_pending':
        query = query.eq('kyc_status', 'pending');
    }
    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      final needle = '%${searchQuery.trim()}%';
      query = query.or('username.ilike.$needle,email.ilike.$needle');
    }

    final rows =
        await query.order('created_at', ascending: false).limit(limit);
    return [
      for (final row in rows as List<dynamic>)
        Profile.fromJson(row as Map<String, dynamic>),
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

class AdminUsersFilter {
  const AdminUsersFilter({this.countryCode, this.filter, this.searchQuery});
  final String? countryCode;
  final String? filter;
  final String? searchQuery;

  @override
  bool operator ==(Object other) =>
      other is AdminUsersFilter &&
      other.countryCode == countryCode &&
      other.filter == filter &&
      other.searchQuery == searchQuery;

  @override
  int get hashCode => Object.hash(countryCode, filter, searchQuery);
}

final adminUsersProvider =
    FutureProvider.family<List<Profile>, AdminUsersFilter>((ref, filter) {
  return ref.watch(adminUsersRepositoryProvider).list(
        countryCode: filter.countryCode,
        filter: filter.filter,
        searchQuery: filter.searchQuery,
      );
});
