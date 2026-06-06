import 'package:arena/data/repositories/admin/super_admin_dashboard_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../_supabase_mocks.dart';

void main() {
  late MockSupabaseClient client;
  late SuperAdminDashboardRepository repo;

  setUp(() {
    client = MockSupabaseClient();
    repo = SuperAdminDashboardRepository(client);
  });

  // Branche un RPC SANS params (get_super_admin_kpis / get_country_breakdown).
  void stubRpcNoParams(String fn, Object? result) {
    when(() => client.rpc<dynamic>(fn))
        .thenAnswer((_) => FakeQueryChain<dynamic>(Future<dynamic>.value(result)));
  }

  // Branche un RPC AVEC params.
  void stubRpcParams(String fn, Object? result) {
    when(() => client.rpc<dynamic>(fn, params: any(named: 'params')))
        .thenAnswer((_) => FakeQueryChain<dynamic>(Future<dynamic>.value(result)));
  }

  group('fetchKpis (RPC get_super_admin_kpis)', () {
    test('parse tous les champs KPI', () async {
      stubRpcNoParams('get_super_admin_kpis', {
        'total_users': 1200,
        'active_30d': 800,
        'active_24h': 150,
        'dau_mau_ratio': 0.1875,
        'total_competitions': 42,
        'ongoing_competitions': 5,
        'total_commission_xaf': 250000.0,
        'total_revenue_xaf': 1000000.0,
        'total_payouts_xaf': 750000.0,
        'margin_30d_xaf': 90000.0,
      });

      final kpis = await repo.fetchKpis();

      expect(kpis.totalUsers, 1200);
      expect(kpis.active30d, 800);
      expect(kpis.active24h, 150);
      expect(kpis.dauMauRatio, 0.1875);
      expect(kpis.totalCompetitions, 42);
      expect(kpis.ongoingCompetitions, 5);
      expect(kpis.totalCommissionXaf, 250000.0);
      expect(kpis.totalRevenueXaf, 1000000.0);
      expect(kpis.totalPayoutsXaf, 750000.0);
      expect(kpis.margin30dXaf, 90000.0);

      verify(() => client.rpc<dynamic>('get_super_admin_kpis')).called(1);
    });

    test('champs manquants → fallbacks 0', () async {
      stubRpcNoParams('get_super_admin_kpis', <String, dynamic>{});
      final kpis = await repo.fetchKpis();
      expect(kpis.totalUsers, 0);
      expect(kpis.dauMauRatio, 0);
      expect(kpis.margin30dXaf, 0);
    });
  });

  group('fetchTopPlayers (RPC get_top_players_by_wins)', () {
    test('passe p_limit et parse les lignes', () async {
      stubRpcParams('get_top_players_by_wins', [
        {
          'id': 'u1',
          'username': 'kratos',
          'country_code': 'CI',
          'avatar_color': '#FF0000',
          'wins': 12,
          'total_earnings_xaf': 50000.0,
        },
      ]);

      final list = await repo.fetchTopPlayers(limit: 5);

      expect(list, hasLength(1));
      expect(list.first.id, 'u1');
      expect(list.first.username, 'kratos');
      expect(list.first.countryCode, 'CI');
      expect(list.first.avatarColor, '#FF0000');
      expect(list.first.wins, 12);
      expect(list.first.totalEarningsXaf, 50000.0);

      final params = verify(
        () => client.rpc<dynamic>(
          'get_top_players_by_wins',
          params: captureAny(named: 'params'),
        ),
      ).captured.single as Map<String, dynamic>;
      expect(params['p_limit'], 5);
    });

    test('limit par défaut = 10', () async {
      stubRpcParams('get_top_players_by_wins', <dynamic>[]);
      await repo.fetchTopPlayers();
      final params = verify(
        () => client.rpc<dynamic>(
          'get_top_players_by_wins',
          params: captureAny(named: 'params'),
        ),
      ).captured.single as Map<String, dynamic>;
      expect(params['p_limit'], 10);
    });

    test('liste vide → []', () async {
      stubRpcParams('get_top_players_by_wins', <dynamic>[]);
      expect(await repo.fetchTopPlayers(), isEmpty);
    });

    test('country_code / avatar_color manquants → fallbacks', () async {
      stubRpcParams('get_top_players_by_wins', [
        {'id': 'u2', 'username': 'zeus'},
      ]);
      final list = await repo.fetchTopPlayers();
      expect(list.first.countryCode, '');
      expect(list.first.avatarColor, '#4C7AFF');
      expect(list.first.wins, 0);
    });
  });

  group('fetchCountryBreakdown (RPC get_country_breakdown)', () {
    test('parse les parts pays (sans params)', () async {
      stubRpcNoParams('get_country_breakdown', [
        {'country_code': 'CI', 'user_count': 300, 'ratio': 0.25},
        {'country_code': 'CM', 'user_count': 200, 'ratio': 0.1667},
      ]);

      final list = await repo.fetchCountryBreakdown();

      expect(list, hasLength(2));
      expect(list.first.countryCode, 'CI');
      expect(list.first.userCount, 300);
      expect(list.first.ratio, 0.25);

      verify(() => client.rpc<dynamic>('get_country_breakdown')).called(1);
    });

    test('liste vide → []', () async {
      stubRpcNoParams('get_country_breakdown', <dynamic>[]);
      expect(await repo.fetchCountryBreakdown(), isEmpty);
    });
  });

  group('fetchRevenueBreakdown (RPC get_revenue_breakdown)', () {
    test('passe start/end ISO UTC et parse', () async {
      stubRpcParams('get_revenue_breakdown', {
        'collected_xaf': 1000000.0,
        'payouts_xaf': 700000.0,
        'processor_fees_xaf': 20000.0,
        'margin_xaf': 280000.0,
        'margin_pct': 28.0,
      });

      final start = DateTime.utc(2026, 6, 1);
      final end = DateTime.utc(2026, 7, 1);
      final res = await repo.fetchRevenueBreakdown(start: start, end: end);

      expect(res.collectedXaf, 1000000.0);
      expect(res.payoutsXaf, 700000.0);
      expect(res.processorFeesXaf, 20000.0);
      expect(res.marginXaf, 280000.0);
      expect(res.marginPct, 28.0);

      final params = verify(
        () => client.rpc<dynamic>(
          'get_revenue_breakdown',
          params: captureAny(named: 'params'),
        ),
      ).captured.single as Map<String, dynamic>;
      expect(params['p_start'], start.toUtc().toIso8601String());
      expect(params['p_end'], end.toUtc().toIso8601String());
    });

    test('champs manquants → fallbacks 0', () async {
      stubRpcParams('get_revenue_breakdown', <String, dynamic>{});
      final res = await repo.fetchRevenueBreakdown(
        start: DateTime.utc(2026, 1, 1),
        end: DateTime.utc(2026, 2, 1),
      );
      expect(res.collectedXaf, 0);
      expect(res.marginPct, 0);
    });
  });

  group('fetchRevenuePerCompetition (RPC get_revenue_per_competition)', () {
    test('passe p_limit et parse les lignes', () async {
      stubRpcParams('get_revenue_per_competition', [
        {
          'competition_id': 'c1',
          'name': 'Coupe Arena',
          'game': 'Dames',
          'registered_count': 64,
          'revenue_xaf': 320000.0,
          'commission_xaf': 32000.0,
        },
      ]);

      final list = await repo.fetchRevenuePerCompetition(limit: 50);

      expect(list, hasLength(1));
      expect(list.first.competitionId, 'c1');
      expect(list.first.name, 'Coupe Arena');
      expect(list.first.game, 'Dames');
      expect(list.first.registeredCount, 64);
      expect(list.first.revenueXaf, 320000.0);
      expect(list.first.commissionXaf, 32000.0);

      final params = verify(
        () => client.rpc<dynamic>(
          'get_revenue_per_competition',
          params: captureAny(named: 'params'),
        ),
      ).captured.single as Map<String, dynamic>;
      expect(params['p_limit'], 50);
    });

    test('limit par défaut = 20 + game manquant → ""', () async {
      stubRpcParams('get_revenue_per_competition', [
        {'competition_id': 'c2', 'name': 'Open'},
      ]);
      final list = await repo.fetchRevenuePerCompetition();
      expect(list.first.game, '');
      expect(list.first.registeredCount, 0);

      final params = verify(
        () => client.rpc<dynamic>(
          'get_revenue_per_competition',
          params: captureAny(named: 'params'),
        ),
      ).captured.single as Map<String, dynamic>;
      expect(params['p_limit'], 20);
    });
  });

  group('fetchMonthlySignups (RPC get_monthly_signups)', () {
    test('passe p_months et parse month_start/count', () async {
      stubRpcParams('get_monthly_signups', [
        {'month_start': '2026-05-01T00:00:00.000Z', 'count': 120},
      ]);

      final list = await repo.fetchMonthlySignups(months: 6);

      expect(list, hasLength(1));
      expect(list.first.month, DateTime.parse('2026-05-01T00:00:00.000Z'));
      expect(list.first.count, 120);

      final params = verify(
        () => client.rpc<dynamic>(
          'get_monthly_signups',
          params: captureAny(named: 'params'),
        ),
      ).captured.single as Map<String, dynamic>;
      expect(params['p_months'], 6);
    });

    test('months par défaut = 12 + count manquant → 0', () async {
      stubRpcParams('get_monthly_signups', [
        {'month_start': '2026-05-01T00:00:00.000Z'},
      ]);
      final list = await repo.fetchMonthlySignups();
      expect(list.first.count, 0);

      final params = verify(
        () => client.rpc<dynamic>(
          'get_monthly_signups',
          params: captureAny(named: 'params'),
        ),
      ).captured.single as Map<String, dynamic>;
      expect(params['p_months'], 12);
    });
  });

  group('fetchMonthlyRevenue (RPC get_monthly_revenue)', () {
    test('passe p_months et parse revenue/margin', () async {
      stubRpcParams('get_monthly_revenue', [
        {
          'month_start': '2026-05-01T00:00:00.000Z',
          'revenue_xaf': 500000.0,
          'margin_xaf': 120000.0,
        },
      ]);

      final list = await repo.fetchMonthlyRevenue(months: 3);

      expect(list, hasLength(1));
      expect(list.first.month, DateTime.parse('2026-05-01T00:00:00.000Z'));
      expect(list.first.revenueXaf, 500000.0);
      expect(list.first.marginXaf, 120000.0);

      final params = verify(
        () => client.rpc<dynamic>(
          'get_monthly_revenue',
          params: captureAny(named: 'params'),
        ),
      ).captured.single as Map<String, dynamic>;
      expect(params['p_months'], 3);
    });

    test('liste vide → []', () async {
      stubRpcParams('get_monthly_revenue', <dynamic>[]);
      expect(await repo.fetchMonthlyRevenue(), isEmpty);
    });
  });
}
