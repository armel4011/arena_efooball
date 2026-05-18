import 'package:arena/data/repositories/profile_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Lot B — branche le dashboard et la page revenue super-admin sur la
/// vraie base de données via 5 RPC SQL (`get_super_admin_kpis`,
/// `get_top_players_by_wins`, `get_country_breakdown`,
/// `get_revenue_breakdown`, `get_revenue_per_competition`). Toutes
/// vérifient le rôle super_admin en interne.
class SuperAdminDashboardRepository {
  const SuperAdminDashboardRepository(this._client);

  final SupabaseClient _client;

  /// KPIs globaux pour SA1 (MAU/DAU, revenu cumulé, marge 30j, etc.).
  Future<SuperAdminKpis> fetchKpis() async {
    final res = await _client.rpc<dynamic>('get_super_admin_kpis');
    return SuperAdminKpis.fromJson(res as Map<String, dynamic>);
  }

  /// Top N joueurs (par victoires + earnings).
  Future<List<TopPlayerEntry>> fetchTopPlayers({int limit = 10}) async {
    final res = await _client
        .rpc<dynamic>('get_top_players_by_wins', params: {'p_limit': limit});
    return [
      for (final row in res as List<dynamic>)
        TopPlayerEntry.fromJson(row as Map<String, dynamic>),
    ];
  }

  /// Répartition des joueurs par pays (top 10).
  Future<List<CountryShare>> fetchCountryBreakdown() async {
    final res = await _client.rpc<dynamic>('get_country_breakdown');
    return [
      for (final row in res as List<dynamic>)
        CountryShare.fromJson(row as Map<String, dynamic>),
    ];
  }

  /// Décomposition revenu sur une période (page SA4).
  Future<RevenueBreakdown> fetchRevenueBreakdown({
    required DateTime start,
    required DateTime end,
  }) async {
    final res = await _client.rpc<dynamic>(
      'get_revenue_breakdown',
      params: {
        'p_start': start.toUtc().toIso8601String(),
        'p_end': end.toUtc().toIso8601String(),
      },
    );
    return RevenueBreakdown.fromJson(res as Map<String, dynamic>);
  }

  /// Revenu par compétition (table SA4).
  Future<List<CompetitionRevenue>> fetchRevenuePerCompetition({
    int limit = 20,
  }) async {
    final res = await _client
        .rpc<dynamic>('get_revenue_per_competition', params: {'p_limit': limit});
    return [
      for (final row in res as List<dynamic>)
        CompetitionRevenue.fromJson(row as Map<String, dynamic>),
    ];
  }

  /// Lot B.2 — Évolution mensuelle des inscriptions (12 derniers mois).
  Future<List<MonthlyCount>> fetchMonthlySignups({int months = 12}) async {
    final res = await _client
        .rpc<dynamic>('get_monthly_signups', params: {'p_months': months});
    return [
      for (final row in res as List<dynamic>)
        MonthlyCount.fromJson(row as Map<String, dynamic>),
    ];
  }

  /// Lot B.2 — Évolution mensuelle du revenu + marge.
  Future<List<MonthlyRevenue>> fetchMonthlyRevenue({int months = 12}) async {
    final res = await _client
        .rpc<dynamic>('get_monthly_revenue', params: {'p_months': months});
    return [
      for (final row in res as List<dynamic>)
        MonthlyRevenue.fromJson(row as Map<String, dynamic>),
    ];
  }
}

class MonthlyCount {
  const MonthlyCount({required this.month, required this.count});
  factory MonthlyCount.fromJson(Map<String, dynamic> json) => MonthlyCount(
        month: DateTime.parse(json['month_start'] as String),
        count: (json['count'] as num?)?.toInt() ?? 0,
      );
  final DateTime month;
  final int count;
}

class MonthlyRevenue {
  const MonthlyRevenue({
    required this.month,
    required this.revenueXaf,
    required this.marginXaf,
  });
  factory MonthlyRevenue.fromJson(Map<String, dynamic> json) => MonthlyRevenue(
        month: DateTime.parse(json['month_start'] as String),
        revenueXaf: (json['revenue_xaf'] as num?)?.toDouble() ?? 0,
        marginXaf: (json['margin_xaf'] as num?)?.toDouble() ?? 0,
      );
  final DateTime month;
  final double revenueXaf;
  final double marginXaf;
}

class SuperAdminKpis {
  const SuperAdminKpis({
    required this.totalUsers,
    required this.active30d,
    required this.active24h,
    required this.dauMauRatio,
    required this.totalCompetitions,
    required this.ongoingCompetitions,
    required this.totalCommissionXaf,
    required this.totalRevenueXaf,
    required this.totalPayoutsXaf,
    required this.margin30dXaf,
  });

  factory SuperAdminKpis.fromJson(Map<String, dynamic> json) => SuperAdminKpis(
        totalUsers: (json['total_users'] as num?)?.toInt() ?? 0,
        active30d: (json['active_30d'] as num?)?.toInt() ?? 0,
        active24h: (json['active_24h'] as num?)?.toInt() ?? 0,
        dauMauRatio: (json['dau_mau_ratio'] as num?)?.toDouble() ?? 0,
        totalCompetitions: (json['total_competitions'] as num?)?.toInt() ?? 0,
        ongoingCompetitions:
            (json['ongoing_competitions'] as num?)?.toInt() ?? 0,
        totalCommissionXaf:
            (json['total_commission_xaf'] as num?)?.toDouble() ?? 0,
        totalRevenueXaf: (json['total_revenue_xaf'] as num?)?.toDouble() ?? 0,
        totalPayoutsXaf: (json['total_payouts_xaf'] as num?)?.toDouble() ?? 0,
        margin30dXaf: (json['margin_30d_xaf'] as num?)?.toDouble() ?? 0,
      );

  final int totalUsers;
  final int active30d;
  final int active24h;
  final double dauMauRatio;
  final int totalCompetitions;
  final int ongoingCompetitions;
  final double totalCommissionXaf;
  final double totalRevenueXaf;
  final double totalPayoutsXaf;
  final double margin30dXaf;
}

class TopPlayerEntry {
  const TopPlayerEntry({
    required this.id,
    required this.username,
    required this.countryCode,
    required this.avatarColor,
    required this.wins,
    required this.totalEarningsXaf,
  });

  factory TopPlayerEntry.fromJson(Map<String, dynamic> json) => TopPlayerEntry(
        id: json['id'] as String,
        username: json['username'] as String,
        countryCode: (json['country_code'] as String?) ?? '',
        avatarColor: (json['avatar_color'] as String?) ?? '#4C7AFF',
        wins: (json['wins'] as num?)?.toInt() ?? 0,
        totalEarningsXaf:
            (json['total_earnings_xaf'] as num?)?.toDouble() ?? 0,
      );

  final String id;
  final String username;
  final String countryCode;
  final String avatarColor;
  final int wins;
  final double totalEarningsXaf;
}

class CountryShare {
  const CountryShare({
    required this.countryCode,
    required this.userCount,
    required this.ratio,
  });

  factory CountryShare.fromJson(Map<String, dynamic> json) => CountryShare(
        countryCode: (json['country_code'] as String?) ?? '',
        userCount: (json['user_count'] as num?)?.toInt() ?? 0,
        ratio: (json['ratio'] as num?)?.toDouble() ?? 0,
      );

  final String countryCode;
  final int userCount;
  final double ratio;
}

class RevenueBreakdown {
  const RevenueBreakdown({
    required this.collectedXaf,
    required this.payoutsXaf,
    required this.processorFeesXaf,
    required this.marginXaf,
    required this.marginPct,
  });

  factory RevenueBreakdown.fromJson(Map<String, dynamic> json) =>
      RevenueBreakdown(
        collectedXaf: (json['collected_xaf'] as num?)?.toDouble() ?? 0,
        payoutsXaf: (json['payouts_xaf'] as num?)?.toDouble() ?? 0,
        processorFeesXaf: (json['processor_fees_xaf'] as num?)?.toDouble() ?? 0,
        marginXaf: (json['margin_xaf'] as num?)?.toDouble() ?? 0,
        marginPct: (json['margin_pct'] as num?)?.toDouble() ?? 0,
      );

  final double collectedXaf;
  final double payoutsXaf;
  final double processorFeesXaf;
  final double marginXaf;
  final double marginPct;
}

class CompetitionRevenue {
  const CompetitionRevenue({
    required this.competitionId,
    required this.name,
    required this.game,
    required this.registeredCount,
    required this.revenueXaf,
    required this.commissionXaf,
  });

  factory CompetitionRevenue.fromJson(Map<String, dynamic> json) =>
      CompetitionRevenue(
        competitionId: json['competition_id'] as String,
        name: json['name'] as String,
        game: (json['game'] as String?) ?? '',
        registeredCount: (json['registered_count'] as num?)?.toInt() ?? 0,
        revenueXaf: (json['revenue_xaf'] as num?)?.toDouble() ?? 0,
        commissionXaf: (json['commission_xaf'] as num?)?.toDouble() ?? 0,
      );

  final String competitionId;
  final String name;
  final String game;
  final int registeredCount;
  final double revenueXaf;
  final double commissionXaf;
}

/// Riverpod providers.
final superAdminDashboardRepositoryProvider =
    Provider<SuperAdminDashboardRepository>((ref) {
  return SuperAdminDashboardRepository(ref.watch(supabaseClientProvider));
});

final superAdminKpisProvider = FutureProvider<SuperAdminKpis>((ref) {
  return ref.watch(superAdminDashboardRepositoryProvider).fetchKpis();
});

final superAdminTopPlayersProvider =
    FutureProvider<List<TopPlayerEntry>>((ref) {
  return ref.watch(superAdminDashboardRepositoryProvider).fetchTopPlayers();
});

final superAdminCountryBreakdownProvider =
    FutureProvider<List<CountryShare>>((ref) {
  return ref
      .watch(superAdminDashboardRepositoryProvider)
      .fetchCountryBreakdown();
});

class RevenuePeriod {
  const RevenuePeriod(this.start, this.end);

  factory RevenuePeriod.currentMonth() {
    final now = DateTime.now();
    return RevenuePeriod(
      DateTime(now.year, now.month),
      DateTime(now.year, now.month + 1),
    );
  }

  factory RevenuePeriod.previousMonth() {
    final now = DateTime.now();
    return RevenuePeriod(
      DateTime(now.year, now.month - 1),
      DateTime(now.year, now.month),
    );
  }

  factory RevenuePeriod.quarter(int year, int quarter) {
    final startMonth = (quarter - 1) * 3 + 1;
    return RevenuePeriod(
      DateTime(year, startMonth),
      DateTime(year, startMonth + 3),
    );
  }

  factory RevenuePeriod.year(int year) => RevenuePeriod(
        DateTime(year),
        DateTime(year + 1),
      );

  final DateTime start;
  final DateTime end;
}

final selectedRevenuePeriodProvider = StateProvider<RevenuePeriod>(
  (_) => RevenuePeriod.currentMonth(),
);

final superAdminRevenueBreakdownProvider =
    FutureProvider<RevenueBreakdown>((ref) {
  final period = ref.watch(selectedRevenuePeriodProvider);
  return ref.watch(superAdminDashboardRepositoryProvider).fetchRevenueBreakdown(
        start: period.start,
        end: period.end,
      );
});

final superAdminRevenuePerCompetitionProvider =
    FutureProvider<List<CompetitionRevenue>>((ref) {
  return ref
      .watch(superAdminDashboardRepositoryProvider)
      .fetchRevenuePerCompetition();
});

final superAdminMonthlySignupsProvider =
    FutureProvider<List<MonthlyCount>>((ref) {
  return ref.watch(superAdminDashboardRepositoryProvider).fetchMonthlySignups();
});

final superAdminMonthlyRevenueProvider =
    FutureProvider<List<MonthlyRevenue>>((ref) {
  return ref.watch(superAdminDashboardRepositoryProvider).fetchMonthlyRevenue();
});
