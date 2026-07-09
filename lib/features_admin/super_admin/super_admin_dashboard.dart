import 'package:arena/core/theme/arena_theme.dart';
import 'package:arena/data/repositories/admin/super_admin_dashboard_repository.dart';
import 'package:arena/features_shared/admin/admin_formatters.dart';
import 'package:arena/features_shared/widgets/arena_app_bar.dart';
import 'package:arena/features_shared/widgets/arena_avatar.dart';
import 'package:arena/features_shared/widgets/arena_screen_background.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

/// PHASE 11 · SA1 — super-admin global dashboard.
///
/// Lot B : branché sur les vraies données via 3 providers
/// (`superAdminKpisProvider`, `superAdminTopPlayersProvider`,
/// `superAdminCountryBreakdownProvider`). Les line / bar charts
/// d'évolution restent des placeholders en attendant `fl_chart`.
class SuperAdminDashboard extends ConsumerWidget {
  const SuperAdminDashboard({super.key});

  static const _gold = ArenaColors.tierGold;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final kpisAsync = ref.watch(superAdminKpisProvider);
    final topPlayersAsync = ref.watch(superAdminTopPlayersProvider);
    final countriesAsync = ref.watch(superAdminCountryBreakdownProvider);
    final signupsAsync = ref.watch(superAdminMonthlySignupsProvider);
    final monthlyRevenueAsync = ref.watch(superAdminMonthlyRevenueProvider);
    final monthLabel =
        DateFormat('LLLL yyyy', 'fr_FR').format(DateTime.now()).toUpperCase();

    return Scaffold(
      appBar: const ArenaAppBar(title: '👑 GOD MODE', showBack: false),
      body: ArenaScreenBackground(
        accent: ArenaColors.neonRed,
        child: SafeArea(
          child: RefreshIndicator(
            color: ArenaColors.signalBlue,
            onRefresh: () async {
              ref
                ..invalidate(superAdminKpisProvider)
                ..invalidate(superAdminTopPlayersProvider)
                ..invalidate(superAdminCountryBreakdownProvider)
                ..invalidate(superAdminMonthlySignupsProvider)
                ..invalidate(superAdminMonthlyRevenueProvider);
              await ref.read(superAdminKpisProvider.future);
            },
            child: ListView(
              padding: const EdgeInsets.all(ArenaSpacing.lg),
              children: [
                Text(
                  'KPIs GLOBAUX · $monthLabel',
                  style: ArenaText.inputLabel.copyWith(color: _gold),
                ),
                const SizedBox(height: ArenaSpacing.sm),
                _KpiRow(kpisAsync: kpisAsync),
                const SizedBox(height: ArenaSpacing.sm),
                _MarginCard(kpisAsync: kpisAsync),
                const SizedBox(height: ArenaSpacing.lg),
                Text('📈 Inscriptions / mois', style: ArenaText.h3),
                const SizedBox(height: ArenaSpacing.sm),
                _SignupsLineChart(async: signupsAsync),
                const SizedBox(height: ArenaSpacing.lg),
                Text('💰 Revenus / mois', style: ArenaText.h3),
                const SizedBox(height: ArenaSpacing.sm),
                _RevenueBarChart(async: monthlyRevenueAsync),
                const SizedBox(height: ArenaSpacing.lg),
                Text('🏆 Top 10 joueurs', style: ArenaText.h3),
                const SizedBox(height: ArenaSpacing.sm),
                _TopPlayers(async: topPlayersAsync),
                const SizedBox(height: ArenaSpacing.lg),
                Text('🌍 Répartition pays', style: ArenaText.h3),
                const SizedBox(height: ArenaSpacing.sm),
                _CountryBreakdown(async: countriesAsync),
                const SizedBox(height: ArenaSpacing.lg),
                Container(
                  padding: const EdgeInsets.all(ArenaSpacing.md),
                  decoration: arenaDangerCardDecoration(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('🚨 Alertes système', style: ArenaText.h3),
                      const SizedBox(height: 4),
                      Text(
                        'Sentry events surveillés via le dashboard externe '
                        '(`sentry.io/arena`). Aucune intégration in-app V1.',
                        style: ArenaText.bodyMuted,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _KpiRow extends StatelessWidget {
  const _KpiRow({required this.kpisAsync});
  final AsyncValue<SuperAdminKpis> kpisAsync;

  @override
  Widget build(BuildContext context) {
    return kpisAsync.when(
      data: (k) => Row(
        children: [
          Expanded(
            child: _Tile(
              value: _intLabel(k.active30d),
              label: 'MAU',
              border: SuperAdminDashboard._gold,
              valueColor: SuperAdminDashboard._gold,
            ),
          ),
          const SizedBox(width: ArenaSpacing.sm),
          Expanded(child: _Tile(value: _intLabel(k.active24h), label: 'DAU')),
          const SizedBox(width: ArenaSpacing.sm),
          Expanded(
            child: _Tile(
              value: '${k.dauMauRatio.toStringAsFixed(1)}%',
              label: 'DAU/MAU',
              valueColor: ArenaColors.statusOk,
            ),
          ),
        ],
      ),
      loading: () => const Row(
        children: [
          Expanded(child: _Tile(value: '…', label: 'MAU')),
          SizedBox(width: ArenaSpacing.sm),
          Expanded(child: _Tile(value: '…', label: 'DAU')),
          SizedBox(width: ArenaSpacing.sm),
          Expanded(child: _Tile(value: '…', label: 'DAU/MAU')),
        ],
      ),
      error: (e, _) => Text(
        'KPIs indisponibles : $e',
        style: ArenaText.body.copyWith(color: ArenaColors.neonRed),
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.value,
    required this.label,
    this.border,
    this.valueColor,
  });

  final String value;
  final String label;
  final Color? border;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: ArenaSpacing.md,
        horizontal: ArenaSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: ArenaColors.carbon,
        borderRadius: BorderRadius.circular(ArenaRadius.lg),
        border: Border.all(color: border ?? ArenaColors.border),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: ArenaText.bigNumber.copyWith(
              color: valueColor ?? ArenaColors.bone,
            ),
          ),
          const SizedBox(height: 2),
          Text(label, style: ArenaText.bodyMuted),
        ],
      ),
    );
  }
}

class _MarginCard extends StatelessWidget {
  const _MarginCard({required this.kpisAsync});
  final AsyncValue<SuperAdminKpis> kpisAsync;

  @override
  Widget build(BuildContext context) {
    final value = kpisAsync.maybeWhen(
      data: (k) => adminMoneyShort(k.margin30dXaf),
      orElse: () => '—',
    );
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: ArenaSpacing.md,
        horizontal: ArenaSpacing.lg,
      ),
      decoration: BoxDecoration(
        color: ArenaColors.statusOk.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(ArenaRadius.lg),
        border: Border.all(color: ArenaColors.statusOk),
      ),
      child: Column(
        children: [
          Text(
            '$value XAF',
            style: ArenaText.bigNumber.copyWith(
              color: ArenaColors.statusOk,
              fontSize: 24,
            ),
          ),
          const SizedBox(height: 2),
          Text('Marge ARENA · 30j', style: ArenaText.bodyMuted),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════
// Lot B.2 — Charts d'évolution mensuelle (fl_chart)
// ════════════════════════════════════════════════════════════════════
class _SignupsLineChart extends StatelessWidget {
  const _SignupsLineChart({required this.async});
  final AsyncValue<List<MonthlyCount>> async;

  @override
  Widget build(BuildContext context) {
    return async.when(
      loading: () => const _ChartFrame(
        child: Center(
          child: CircularProgressIndicator(color: ArenaColors.signalBlue),
        ),
      ),
      error: (e, _) => _ChartFrame(
        child: Text(
          'Erreur : $e',
          style: ArenaText.small.copyWith(color: ArenaColors.neonRed),
        ),
      ),
      data: (rows) {
        if (rows.isEmpty) {
          return _ChartFrame(
            child: Text(
              'Aucune inscription sur la période.',
              style: ArenaText.bodyMuted,
            ),
          );
        }
        final maxY = rows.fold<double>(
          1,
          (acc, r) => r.count.toDouble() > acc ? r.count.toDouble() : acc,
        );
        final spots = <FlSpot>[
          for (var i = 0; i < rows.length; i++)
            FlSpot(i.toDouble(), rows[i].count.toDouble()),
        ];
        return _ChartFrame(
          height: 140,
          child: LineChart(
            LineChartData(
              minY: 0,
              maxY: maxY * 1.15,
              gridData: const FlGridData(show: false),
              titlesData: FlTitlesData(
                leftTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: (rows.length / 4).clamp(1, 6).toDouble(),
                    reservedSize: 18,
                    getTitlesWidget: (v, _) {
                      final i = v.toInt();
                      if (i < 0 || i >= rows.length) {
                        return const SizedBox.shrink();
                      }
                      return Text(
                        DateFormat('MMM', 'fr_FR')
                            .format(rows[i].month)
                            .toUpperCase(),
                        style: ArenaText.small
                            .copyWith(color: ArenaColors.silver, fontSize: 9),
                      );
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  color: ArenaColors.signalBlue,
                  barWidth: 2,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        ArenaColors.signalBlue.withValues(alpha: 0.4),
                        ArenaColors.signalBlue.withValues(alpha: 0),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _RevenueBarChart extends StatelessWidget {
  const _RevenueBarChart({required this.async});
  final AsyncValue<List<MonthlyRevenue>> async;

  @override
  Widget build(BuildContext context) {
    return async.when(
      loading: () => const _ChartFrame(
        child: Center(
          child: CircularProgressIndicator(color: ArenaColors.statusOk),
        ),
      ),
      error: (e, _) => _ChartFrame(
        child: Text(
          'Erreur : $e',
          style: ArenaText.small.copyWith(color: ArenaColors.neonRed),
        ),
      ),
      data: (rows) {
        if (rows.isEmpty) {
          return _ChartFrame(
            child: Text(
              'Aucun revenu sur la période.',
              style: ArenaText.bodyMuted,
            ),
          );
        }
        final maxY = rows.fold<double>(
          1,
          (acc, r) => r.revenueXaf > acc ? r.revenueXaf : acc,
        );
        return _ChartFrame(
          height: 140,
          child: BarChart(
            BarChartData(
              minY: 0,
              maxY: maxY * 1.15,
              gridData: const FlGridData(show: false),
              titlesData: FlTitlesData(
                leftTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: (rows.length / 4).clamp(1, 6).toDouble(),
                    reservedSize: 18,
                    getTitlesWidget: (v, _) {
                      final i = v.toInt();
                      if (i < 0 || i >= rows.length) {
                        return const SizedBox.shrink();
                      }
                      return Text(
                        DateFormat('MMM', 'fr_FR')
                            .format(rows[i].month)
                            .toUpperCase(),
                        style: ArenaText.small
                            .copyWith(color: ArenaColors.silver, fontSize: 9),
                      );
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              barGroups: [
                for (var i = 0; i < rows.length; i++)
                  BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: rows[i].revenueXaf,
                        color: ArenaColors.statusOk,
                        width: 8,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(2),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ChartFrame extends StatelessWidget {
  const _ChartFrame({required this.child, this.height = 120});
  final Widget child;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      padding: const EdgeInsets.all(ArenaSpacing.sm),
      decoration: BoxDecoration(
        color: ArenaColors.carbon,
        borderRadius: BorderRadius.circular(ArenaRadius.lg),
        border: Border.all(color: ArenaColors.border),
      ),
      child: child,
    );
  }
}

class _TopPlayers extends StatelessWidget {
  const _TopPlayers({required this.async});
  final AsyncValue<List<TopPlayerEntry>> async;

  static const _avatarColors = <String, ArenaAvatarColor>{
    '#4C7AFF': ArenaAvatarColor.blue,
    '#FF2D55': ArenaAvatarColor.red,
    '#00C896': ArenaAvatarColor.green,
    '#F77F00': ArenaAvatarColor.orange,
    '#00B4D8': ArenaAvatarColor.cyan,
    '#9D4EDD': ArenaAvatarColor.purple,
    '#FF6B9D': ArenaAvatarColor.pink,
    '#FFD700': ArenaAvatarColor.yellow,
  };

  static ArenaAvatarColor _colorFromHex(String hex) =>
      _avatarColors[hex.toUpperCase()] ?? ArenaAvatarColor.blue;

  @override
  Widget build(BuildContext context) {
    return async.when(
      data: (players) {
        if (players.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(ArenaSpacing.md),
            decoration: BoxDecoration(
              color: ArenaColors.carbon,
              borderRadius: BorderRadius.circular(ArenaRadius.lg),
              border: Border.all(color: ArenaColors.border),
            ),
            child: Text(
              "Aucun joueur classé pour l'instant.",
              style: ArenaText.bodyMuted,
            ),
          );
        }
        return Container(
          decoration: BoxDecoration(
            color: ArenaColors.carbon,
            borderRadius: BorderRadius.circular(ArenaRadius.lg),
            border: Border.all(color: ArenaColors.border),
          ),
          child: Column(
            children: [
              for (var i = 0; i < players.length; i++) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: ArenaSpacing.md,
                    vertical: ArenaSpacing.sm,
                  ),
                  child: Row(
                    children: [
                      Text(
                        _medalFor(i),
                        style: const TextStyle(fontSize: 14),
                      ),
                      const SizedBox(width: 6),
                      ArenaAvatar(
                        initials: players[i].username[0],
                        color: _colorFromHex(players[i].avatarColor),
                        size: ArenaAvatarSize.sm,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(players[i].username, style: ArenaText.body),
                      ),
                      Text(
                        '${players[i].wins} V',
                        style: ArenaText.mono.copyWith(
                          color: i == 0
                              ? SuperAdminDashboard._gold
                              : ArenaColors.bone,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                if (i < players.length - 1)
                  const Divider(
                    height: 1,
                    color: ArenaColors.border,
                  ),
              ],
            ],
          ),
        );
      },
      loading: () => const _LoadingTile(label: 'Chargement top joueurs…'),
      error: (e, _) => _ErrorTile(message: 'Top joueurs : $e'),
    );
  }

  static String _medalFor(int index) {
    switch (index) {
      case 0:
        return '🥇';
      case 1:
        return '🥈';
      case 2:
        return '🥉';
      default:
        return '${index + 1}.';
    }
  }
}

class _CountryBreakdown extends StatelessWidget {
  const _CountryBreakdown({required this.async});
  final AsyncValue<List<CountryShare>> async;

  static String _flagFor(String code) {
    if (code.length != 2) return '🌍';
    const base = 0x1F1E6;
    return String.fromCharCodes([
      base + code.codeUnitAt(0) - 65,
      base + code.codeUnitAt(1) - 65,
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return async.when(
      data: (rows) {
        if (rows.isEmpty) {
          return const _ErrorTile(
            message: 'Aucune répartition pays disponible.',
            isError: false,
          );
        }
        final colors = <Color>[
          ArenaColors.gameEfoot,
          ArenaColors.gameDraughts,
          ArenaColors.gameFc,
          ArenaColors.silver,
          ArenaColors.signalBlue,
        ];
        return Container(
          padding: const EdgeInsets.all(ArenaSpacing.md),
          decoration: BoxDecoration(
            color: ArenaColors.carbon,
            borderRadius: BorderRadius.circular(ArenaRadius.lg),
            border: Border.all(color: ArenaColors.border),
          ),
          child: Column(
            children: [
              for (var i = 0; i < rows.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: ArenaSpacing.sm),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${_flagFor(rows[i].countryCode)} '
                              '${rows[i].countryCode}',
                              style: ArenaText.bodyMuted,
                            ),
                          ),
                          Text(
                            '${(rows[i].ratio * 100).round()}%',
                            style: ArenaText.mono,
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: LinearProgressIndicator(
                          value: rows[i].ratio.clamp(0, 1).toDouble(),
                          minHeight: 4,
                          backgroundColor: ArenaColors.carbon2,
                          valueColor: AlwaysStoppedAnimation(
                            colors[i % colors.length],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
      loading: () => const _LoadingTile(label: 'Chargement pays…'),
      error: (e, _) => _ErrorTile(message: 'Pays : $e'),
    );
  }
}

class _LoadingTile extends StatelessWidget {
  const _LoadingTile({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(ArenaSpacing.md),
      decoration: BoxDecoration(
        color: ArenaColors.carbon,
        borderRadius: BorderRadius.circular(ArenaRadius.lg),
        border: Border.all(color: ArenaColors.border),
      ),
      child: Row(
        children: [
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: ArenaColors.signalBlue,
            ),
          ),
          const SizedBox(width: ArenaSpacing.sm),
          Text(label, style: ArenaText.bodyMuted),
        ],
      ),
    );
  }
}

class _ErrorTile extends StatelessWidget {
  const _ErrorTile({required this.message, this.isError = true});
  final String message;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(ArenaSpacing.md),
      decoration: BoxDecoration(
        color: ArenaColors.carbon,
        borderRadius: BorderRadius.circular(ArenaRadius.lg),
        border: Border.all(
          color: isError ? ArenaColors.neonRed : ArenaColors.border,
        ),
      ),
      child: Text(
        message,
        style: ArenaText.body.copyWith(
          color: isError ? ArenaColors.neonRed : ArenaColors.silver,
        ),
      ),
    );
  }
}

/// Helpers de formatage.
String _intLabel(int n) {
  if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
  return '$n';
}
