import 'package:arena/data/models/admin_audit_log.dart';
import 'package:arena/data/repositories/profile_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Reads + appends `admin_audit_log` (PHASE 11).
///
/// Every consequential admin write should call `record(...)` so the
/// trail stays exhaustive. RLS guarantees `admin_id = auth.uid()` on
/// insert — one admin can't backdate an action under someone else's
/// name.
class AdminAuditLogRepository {
  const AdminAuditLogRepository(this._client);

  static const _table = 'admin_audit_log';

  final SupabaseClient _client;

  /// Filtered list of audit entries. [category] groups action types:
  /// `payout`, `dispute`, `ban`, `stream`; null returns everything.
  ///
  /// [periodDays] caps the time range — `7`, `30`, or `null` for
  /// "tout".
  Future<List<AdminAuditLog>> list({
    String? category,
    int? periodDays,
    String? searchQuery,
    int limit = 50,
  }) async {
    var query = _client.from(_table).select();

    if (periodDays != null) {
      final since = DateTime.now()
          .toUtc()
          .subtract(Duration(days: periodDays))
          .toIso8601String();
      query = query.gte('created_at', since);
    }

    if (category != null) {
      final actions = _actionsForCategory(category);
      if (actions.isNotEmpty) {
        query = query.inFilter('action', actions);
      }
    }

    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      final needle = '%${searchQuery.trim()}%';
      query = query.or(
        'action.ilike.$needle,target_id::text.ilike.$needle',
      );
    }

    final rows =
        await query.order('created_at', ascending: false).limit(limit);
    return [
      for (final row in rows as List<dynamic>)
        AdminAuditLog.fromJson(row as Map<String, dynamic>),
    ];
  }

  /// Inserts a new audit entry. The caller (admin repository method)
  /// passes the action name + the before/after snapshots so the trail
  /// captures what actually changed.
  Future<void> record({
    required String adminId,
    required String action,
    String? targetType,
    String? targetId,
    Map<String, dynamic>? beforeState,
    Map<String, dynamic>? afterState,
  }) async {
    await _client.from(_table).insert({
      'admin_id': adminId,
      'action': action,
      if (targetType != null) 'target_type': targetType,
      if (targetId != null) 'target_id': targetId,
      if (beforeState != null) 'before_state': beforeState,
      if (afterState != null) 'after_state': afterState,
    });
  }

  static List<String> _actionsForCategory(String category) {
    switch (category) {
      case 'payout':
        return const ['payout_validated', 'payout_refused', 'payout_retried'];
      case 'dispute':
        return const ['dispute_resolved', 'dispute_cancelled'];
      case 'ban':
        return const ['user_banned', 'user_unbanned', 'user_kyc_overridden'];
      case 'stream':
        return const ['stream_enabled', 'stream_disabled', 'stream_cut'];
      default:
        return const [];
    }
  }
}

final adminAuditLogRepositoryProvider =
    Provider<AdminAuditLogRepository>((ref) {
  return AdminAuditLogRepository(ref.watch(supabaseClientProvider));
});

@immutable
class AdminAuditLogFilter {
  const AdminAuditLogFilter({
    this.category,
    this.periodDays = 7,
    this.searchQuery,
  });

  final String? category;
  final int? periodDays;
  final String? searchQuery;

  @override
  bool operator ==(Object other) =>
      other is AdminAuditLogFilter &&
      other.category == category &&
      other.periodDays == periodDays &&
      other.searchQuery == searchQuery;

  @override
  int get hashCode => Object.hash(category, periodDays, searchQuery);
}

final adminAuditLogProvider = FutureProvider.family<
    List<AdminAuditLog>, AdminAuditLogFilter>((ref, filter) {
  return ref.watch(adminAuditLogRepositoryProvider).list(
        category: filter.category,
        periodDays: filter.periodDays,
        searchQuery: filter.searchQuery,
      );
});
