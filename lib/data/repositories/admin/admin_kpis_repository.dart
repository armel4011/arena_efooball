import 'package:arena/data/repositories/profile_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Snapshot of the headline numbers shown on the admin dashboard.
///
/// Computed client-side via small Supabase `select('id')` queries —
/// the `admin_kpis` materialized view referenced in the master prompt
/// never landed and the row counts at V1.0 scale (≤ a few thousand)
/// don't justify writing one. Refresh on pull-to-refresh.
class AdminKpis {
  AdminKpis({
    required this.activeCompetitions,
    required this.liveMatches,
    required this.openDisputes,
    required this.pendingPayouts,
    required this.pendingPayoutsAmountLocal,
  });

  final int activeCompetitions;
  final int liveMatches;
  final int openDisputes;
  final int pendingPayouts;
  final double pendingPayoutsAmountLocal;
}

class AdminKpisRepository {
  const AdminKpisRepository(this._client);

  final SupabaseClient _client;

  Future<AdminKpis> fetch() async {
    final results = await Future.wait([
      _client
          .from('competitions')
          .select('id')
          .inFilter('status', const ['registration_open', 'ongoing']),
      _client.from('matches').select('id').eq('status', 'in_progress'),
      _client
          .from('disputes')
          .select('id')
          .inFilter('status', const ['open', 'escalated']),
      _client.from('payouts').select('amount_local').eq('status', 'pending'),
    ]);

    final payouts = results[3];
    final totalPending = payouts.fold<double>(0, (acc, row) {
      final raw = (row)['amount_local'];
      if (raw is num) return acc + raw.toDouble();
      return acc;
    });

    return AdminKpis(
      activeCompetitions: results[0].length,
      liveMatches: results[1].length,
      openDisputes: results[2].length,
      pendingPayouts: payouts.length,
      pendingPayoutsAmountLocal: totalPending,
    );
  }
}

final adminKpisRepositoryProvider = Provider<AdminKpisRepository>((ref) {
  return AdminKpisRepository(ref.watch(supabaseClientProvider));
});

final adminKpisProvider = FutureProvider<AdminKpis>((ref) {
  return ref.watch(adminKpisRepositoryProvider).fetch();
});
