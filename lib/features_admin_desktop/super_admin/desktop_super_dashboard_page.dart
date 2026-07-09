import 'package:arena/core/theme/arena_theme.dart';
import 'package:arena/data/repositories/admin/super_admin_dashboard_repository.dart';
import 'package:arena/features_shared/admin/admin_formatters.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

/// Super-admin · Vue d'ensemble (desktop) — KPIs globaux élargis en
/// grille (MAU / DAU, ratio, marge, top joueurs, répartition pays).
///
/// Réutilise [superAdminKpisProvider], [superAdminTopPlayersProvider] et
/// [superAdminCountryBreakdownProvider] (mêmes providers que le mobile).
class DesktopSuperDashboardPage extends ConsumerWidget {
  const DesktopSuperDashboardPage({super.key});

  static const _gold = ArenaColors.tierGold;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final kpisAsync = ref.watch(superAdminKpisProvider);
    final topPlayersAsync = ref.watch(superAdminTopPlayersProvider);
    final countriesAsync = ref.watch(superAdminCountryBreakdownProvider);
    final signupsAsync = ref.watch(superAdminMonthlySignupsProvider);
    final monthlyRevenueAsync = ref.watch(superAdminMonthlyRevenueProvider);
    final monthLabel =
        DateFormat('LLLL yyyy', 'fr').format(DateTime.now()).toUpperCase();

    return ScaffoldPage(
      header: PageHeader(
        title: const Text("VUE D'ENSEMBLE"),
        commandBar: CommandBar(
          mainAxisAlignment: MainAxisAlignment.end,
          primaryItems: [
            CommandBarButton(
              icon: const Icon(FluentIcons.refresh),
              label: const Text('Actualiser'),
              onPressed: () => ref
                ..invalidate(superAdminKpisProvider)
                ..invalidate(superAdminTopPlayersProvider)
                ..invalidate(superAdminCountryBreakdownProvider)
                ..invalidate(superAdminMonthlySignupsProvider)
                ..invalidate(superAdminMonthlyRevenueProvider),
            ),
          ],
        ),
      ),
      content: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        children: [
          Text(
            'KPIs GLOBAUX · $monthLabel',
            style: GoogleFonts.bebasNeue(
              color: _gold,
              fontSize: 16,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          kpisAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(48),
              child: Center(child: ProgressRing()),
            ),
            error: (e, _) => InfoBar(
              title: const Text('Impossible de charger les KPIs'),
              content: Text('$e'),
              severity: InfoBarSeverity.error,
            ),
            data: (kpis) => LayoutBuilder(
              builder: (context, constraints) {
                final cardWidth = (constraints.maxWidth - 3 * 16) / 4;
                return Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    _KpiCard(
                      width: cardWidth,
                      icon: FluentIcons.people,
                      label: 'Utilisateurs actifs (30j)',
                      value: _intLabel(kpis.active30d),
                      accent: _gold,
                    ),
                    _KpiCard(
                      width: cardWidth,
                      icon: FluentIcons.contact,
                      label: 'Actifs (24h)',
                      value: _intLabel(kpis.active24h),
                      accent: ArenaColors.signalBlue,
                    ),
                    _KpiCard(
                      width: cardWidth,
                      icon: FluentIcons.chart,
                      label: 'DAU / MAU',
                      value: '${kpis.dauMauRatio.toStringAsFixed(1)}%',
                      accent: ArenaColors.statusOk,
                    ),
                    _KpiCard(
                      width: cardWidth,
                      icon: FluentIcons.money,
                      label: 'Marge ARENA (30j)',
                      value: '${adminMoneyShort(kpis.margin30dXaf)} XAF',
                      accent: ArenaColors.statusOk,
                    ),
                    _KpiCard(
                      width: cardWidth,
                      icon: FluentIcons.people,
                      label: 'Utilisateurs totaux',
                      value: _intLabel(kpis.totalUsers),
                      accent: ArenaColors.silver,
                    ),
                    _KpiCard(
                      width: cardWidth,
                      icon: FluentIcons.trophy2,
                      label: 'Compétitions en cours',
                      value: '${kpis.ongoingCompetitions}',
                      accent: ArenaColors.neonRed,
                    ),
                    _KpiCard(
                      width: cardWidth,
                      icon: FluentIcons.money,
                      label: 'Revenu cumulé',
                      value: '${adminMoneyShort(kpis.totalRevenueXaf)} XAF',
                      accent: ArenaColors.signalBlue,
                    ),
                    _KpiCard(
                      width: cardWidth,
                      icon: FluentIcons.bank,
                      label: 'Payouts cumulés',
                      value: '${adminMoneyShort(kpis.totalPayoutsXaf)} XAF',
                      accent: ArenaColors.statusWarn,
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 32),
          Text('ÉVOLUTION MENSUELLE (12 MOIS)', style: _sectionStyle),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _ChartCard(
                  title: 'Inscriptions / mois',
                  child: _SignupsLineChart(async: signupsAsync),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _ChartCard(
                  title: 'Revenu / mois (XAF)',
                  child: _RevenueBarChart(async: monthlyRevenueAsync),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          Text(
            'TOP 10 JOUEURS',
            style: _sectionStyle,
          ),
          const SizedBox(height: 12),
          _TopPlayers(async: topPlayersAsync),
          const SizedBox(height: 32),
          Text(
            'RÉPARTITION PAR PAYS',
            style: _sectionStyle,
          ),
          const SizedBox(height: 12),
          _CountryBreakdown(async: countriesAsync),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({
    required this.width,
    required this.icon,
    required this.label,
    required this.value,
    required this.accent,
  });

  final double width;
  final IconData icon;
  final String label;
  final String value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width.clamp(200, 400),
      child: Card(
        backgroundColor: ArenaColors.carbon,
        borderRadius: BorderRadius.circular(10),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: accent),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    label,
                    style: GoogleFonts.spaceGrotesk(
                      color: ArenaColors.silver,
                      fontSize: 12,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: GoogleFonts.bebasNeue(
                color: ArenaColors.bone,
                fontSize: 36,
                height: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopPlayers extends StatelessWidget {
  const _TopPlayers({required this.async});

  final AsyncValue<List<TopPlayerEntry>> async;

  @override
  Widget build(BuildContext context) {
    return async.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: ProgressRing()),
      ),
      error: (e, _) => InfoBar(
        title: const Text('Top joueurs indisponible'),
        content: Text('$e'),
        severity: InfoBarSeverity.error,
      ),
      data: (players) {
        if (players.isEmpty) {
          return const Card(
            backgroundColor: ArenaColors.carbon,
            padding: EdgeInsets.all(24),
            child: Center(child: Text('Aucun joueur classé.')),
          );
        }
        return Card(
          backgroundColor: ArenaColors.carbon,
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              for (var i = 0; i < players.length; i++)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    border: i < players.length - 1
                        ? const Border(
                            bottom: BorderSide(color: ArenaColors.border),
                          )
                        : null,
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 32,
                        child: Text(
                          _rankLabel(i),
                          style: GoogleFonts.spaceGrotesk(
                            color: i == 0
                                ? ArenaColors.tierGold
                                : ArenaColors.silver,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          players[i].username,
                          style: GoogleFonts.spaceGrotesk(
                            color: ArenaColors.bone,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      Text(
                        '${players[i].wins} V',
                        style: GoogleFonts.spaceGrotesk(
                          color:
                              i == 0 ? ArenaColors.tierGold : ArenaColors.bone,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  static String _rankLabel(int index) => '${index + 1}.';
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
      loading: () => const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: ProgressRing()),
      ),
      error: (e, _) => InfoBar(
        title: const Text('Répartition pays indisponible'),
        content: Text('$e'),
        severity: InfoBarSeverity.error,
      ),
      data: (rows) {
        if (rows.isEmpty) {
          return const Card(
            backgroundColor: ArenaColors.carbon,
            padding: EdgeInsets.all(24),
            child: Center(child: Text('Aucune donnée de répartition.')),
          );
        }
        const colors = <Color>[
          ArenaColors.gameEfoot,
          ArenaColors.gameDraughts,
          ArenaColors.gameFc,
          ArenaColors.silver,
          ArenaColors.signalBlue,
        ];
        return Card(
          backgroundColor: ArenaColors.carbon,
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              for (var i = 0; i < rows.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${_flagFor(rows[i].countryCode)} '
                              '${rows[i].countryCode}',
                              style: GoogleFonts.spaceGrotesk(
                                color: ArenaColors.silver,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          Text(
                            '${(rows[i].ratio * 100).round()}%',
                            style: GoogleFonts.spaceGrotesk(
                              color: ArenaColors.bone,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      ProgressBar(
                        value: (rows[i].ratio.clamp(0, 1) * 100).toDouble(),
                        activeColor: colors[i % colors.length],
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

// ════════════════════════════════════════════════════════════════════
// Charts d'évolution mensuelle (fl_chart) — port du dashboard mobile.
// ════════════════════════════════════════════════════════════════════
class _ChartCard extends StatelessWidget {
  const _ChartCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      backgroundColor: ArenaColors.carbon,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.spaceGrotesk(
              color: ArenaColors.silver,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(height: 160, child: child),
        ],
      ),
    );
  }
}

TextStyle get _axisStyle =>
    GoogleFonts.spaceGrotesk(color: ArenaColors.silver, fontSize: 9);

Widget _chartCenter(Widget child) => Center(child: child);

FlTitlesData _monthAxis(int count, DateTime Function(int) monthAt) {
  return FlTitlesData(
    leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
    bottomTitles: AxisTitles(
      sideTitles: SideTitles(
        showTitles: true,
        interval: (count / 4).clamp(1, 6).toDouble(),
        reservedSize: 20,
        getTitlesWidget: (v, _) {
          final i = v.toInt();
          if (i < 0 || i >= count) return const SizedBox.shrink();
          return Text(
            DateFormat('MMM', 'fr').format(monthAt(i)).toUpperCase(),
            style: _axisStyle,
          );
        },
      ),
    ),
  );
}

class _SignupsLineChart extends StatelessWidget {
  const _SignupsLineChart({required this.async});

  final AsyncValue<List<MonthlyCount>> async;

  @override
  Widget build(BuildContext context) {
    return async.when(
      loading: () => _chartCenter(const ProgressRing()),
      error: (e, _) => _chartCenter(
        Text('Erreur : $e', style: _axisStyle),
      ),
      data: (rows) {
        if (rows.isEmpty) {
          return _chartCenter(
            Text('Aucune inscription sur la période.', style: _axisStyle),
          );
        }
        final maxY = rows.fold<double>(
          1,
          (acc, r) => r.count.toDouble() > acc ? r.count.toDouble() : acc,
        );
        return LineChart(
          LineChartData(
            minY: 0,
            maxY: maxY * 1.15,
            gridData: const FlGridData(show: false),
            borderData: FlBorderData(show: false),
            titlesData: _monthAxis(rows.length, (i) => rows[i].month),
            lineBarsData: [
              LineChartBarData(
                spots: [
                  for (var i = 0; i < rows.length; i++)
                    FlSpot(i.toDouble(), rows[i].count.toDouble()),
                ],
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
      loading: () => _chartCenter(const ProgressRing()),
      error: (e, _) => _chartCenter(
        Text('Erreur : $e', style: _axisStyle),
      ),
      data: (rows) {
        if (rows.isEmpty) {
          return _chartCenter(
            Text('Aucun revenu sur la période.', style: _axisStyle),
          );
        }
        final maxY = rows.fold<double>(
          1,
          (acc, r) => r.revenueXaf > acc ? r.revenueXaf : acc,
        );
        return BarChart(
          BarChartData(
            minY: 0,
            maxY: maxY * 1.15,
            gridData: const FlGridData(show: false),
            borderData: FlBorderData(show: false),
            titlesData: _monthAxis(rows.length, (i) => rows[i].month),
            barGroups: [
              for (var i = 0; i < rows.length; i++)
                BarChartGroupData(
                  x: i,
                  barRods: [
                    BarChartRodData(
                      toY: rows[i].revenueXaf,
                      color: ArenaColors.statusOk,
                      width: 10,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(2),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }
}

final TextStyle _sectionStyle = GoogleFonts.bebasNeue(
  color: ArenaColors.silver,
  fontSize: 16,
  letterSpacing: 1.5,
);

String _intLabel(int n) {
  if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
  return '$n';
}
