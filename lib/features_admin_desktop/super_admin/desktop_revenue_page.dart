import 'dart:io';

import 'package:arena/core/theme/arena_theme.dart';
import 'package:arena/data/repositories/admin/super_admin_dashboard_repository.dart';
import 'package:arena/features_shared/excel_csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/material.dart' as m;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

/// Super-admin · Revenus (desktop) — décomposition de la marge, graphique
/// d'évolution mensuelle (fl_chart) + export CSV comptable via le SAF
/// picker (`file_picker.saveFile`).
///
/// Réutilise [superAdminRevenueBreakdownProvider],
/// [superAdminRevenuePerCompetitionProvider],
/// [superAdminMonthlyRevenueProvider], [selectedRevenuePeriodProvider]
/// (mêmes providers que le mobile).
class DesktopRevenuePage extends ConsumerWidget {
  const DesktopRevenuePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final periodChip = ref.watch(_selectedPeriodChipProvider);
    final breakdownAsync = ref.watch(superAdminRevenueBreakdownProvider);
    final perCompAsync = ref.watch(superAdminRevenuePerCompetitionProvider);
    final monthlyAsync = ref.watch(superAdminMonthlyRevenueProvider);

    return ScaffoldPage(
      header: PageHeader(
        title: const Text('REVENUS'),
        commandBar: CommandBar(
          mainAxisAlignment: MainAxisAlignment.end,
          primaryItems: [
            CommandBarButton(
              icon: const Icon(FluentIcons.download),
              label: const Text('Export CSV'),
              onPressed: () => _exportCsv(context, ref),
            ),
            CommandBarButton(
              icon: const Icon(FluentIcons.refresh),
              label: const Text('Actualiser'),
              onPressed: () => ref
                ..invalidate(superAdminRevenueBreakdownProvider)
                ..invalidate(superAdminRevenuePerCompetitionProvider)
                ..invalidate(superAdminMonthlyRevenueProvider),
            ),
          ],
        ),
      ),
      content: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        children: [
          _PeriodChips(
            current: periodChip,
            onTap: (label) {
              ref.read(_selectedPeriodChipProvider.notifier).state = label;
              ref.read(selectedRevenuePeriodProvider.notifier).state =
                  _resolvePeriod(label);
            },
          ),
          const SizedBox(height: 16),
          _RevenueHero(async: breakdownAsync),
          const SizedBox(height: 24),
          Text('ÉVOLUTION MENSUELLE', style: _sectionStyle),
          const SizedBox(height: 12),
          _RevenueChart(async: monthlyAsync),
          const SizedBox(height: 24),
          Text('DÉCOMPOSITION', style: _sectionStyle),
          const SizedBox(height: 12),
          _BreakdownCard(async: breakdownAsync),
          const SizedBox(height: 24),
          Text('PAR COMPÉTITION', style: _sectionStyle),
          const SizedBox(height: 12),
          _CompetitionsTable(async: perCompAsync),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  static RevenuePeriod _resolvePeriod(String label) {
    final now = DateTime.now();
    switch (label) {
      case 'Mois en cours':
        return RevenuePeriod.currentMonth();
      case 'Mois précédent':
        return RevenuePeriod.previousMonth();
      case 'Trimestre':
        final q = ((now.month - 1) ~/ 3) + 1;
        return RevenuePeriod.quarter(now.year, q);
      case 'Année':
      default:
        return RevenuePeriod.year(now.year);
    }
  }

  Future<void> _exportCsv(BuildContext context, WidgetRef ref) async {
    try {
      final breakdown =
          await ref.read(superAdminRevenueBreakdownProvider.future);
      final perComp =
          await ref.read(superAdminRevenuePerCompetitionProvider.future);
      final period = ref.read(selectedRevenuePeriodProvider);
      final periodLabel = '${DateFormat('yyyy-MM-dd').format(period.start)}'
          '_${DateFormat('yyyy-MM-dd').format(period.end)}';

      final rows = <List<dynamic>>[
        ['Période', periodLabel],
        <dynamic>[],
        ['DÉCOMPOSITION'],
        ['Frais inscriptions collectés (XAF)', breakdown.collectedXaf.round()],
        ['Payouts versés (XAF)', -breakdown.payoutsXaf.round()],
        ['Frais processeur (XAF)', -breakdown.processorFeesXaf.round()],
        ['Marge nette (XAF)', breakdown.marginXaf.round()],
        ['Marge %', breakdown.marginPct.toStringAsFixed(1)],
        <dynamic>[],
        ['PAR COMPÉTITION'],
        ['Compétition', 'Jeu', 'Inscrits', 'Revenu (XAF)', 'Commission (XAF)'],
        for (final c in perComp)
          [
            c.name,
            c.game,
            c.registeredCount,
            c.revenueXaf.round(),
            c.commissionXaf.round(),
          ],
      ];

      final bytes = buildExcelCsvBytes(rows);

      final savedPath = await FilePicker.platform.saveFile(
        dialogTitle: 'Enregistrer le CSV ARENA',
        fileName: 'arena-revenue-$periodLabel.csv',
        bytes: bytes,
        type: FileType.custom,
        allowedExtensions: const ['csv'],
      );
      // Sur desktop, FilePicker.saveFile IGNORE `bytes` : il ne renvoie que le
      // chemin choisi sans écrire le fichier → on l'écrit nous-mêmes (même
      // correctif que l'export WhatsApp desktop).
      if (savedPath != null) {
        await File(savedPath).writeAsBytes(bytes, flush: true);
      }

      if (!context.mounted) return;
      if (savedPath == null) {
        await _showResult(context, 'Export annulé.', isError: false);
        return;
      }
      await _showResult(context, 'CSV enregistré : $savedPath', isError: false);
    } catch (e) {
      if (!context.mounted) return;
      await _showResult(context, 'Export échoué : $e', isError: true);
    }
  }
}

final _selectedPeriodChipProvider = StateProvider<String>(
  (_) => 'Mois en cours',
);

class _PeriodChips extends StatelessWidget {
  const _PeriodChips({required this.current, required this.onTap});

  final String current;
  final ValueChanged<String> onTap;

  static const _labels = [
    'Mois en cours',
    'Mois précédent',
    'Trimestre',
    'Année',
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final l in _labels)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ToggleButton(
              checked: l == current,
              onChanged: (_) => onTap(l),
              child: Text(l),
            ),
          ),
      ],
    );
  }
}

class _RevenueHero extends StatelessWidget {
  const _RevenueHero({required this.async});

  final AsyncValue<RevenueBreakdown> async;

  @override
  Widget build(BuildContext context) {
    return async.when(
      loading: () => const Card(
        backgroundColor: ArenaColors.carbon,
        padding: EdgeInsets.all(24),
        child: Center(child: ProgressRing()),
      ),
      error: (e, _) => InfoBar(
        title: const Text('Décomposition indisponible'),
        content: Text('$e'),
        severity: InfoBarSeverity.error,
      ),
      data: (b) => Card(
        backgroundColor: ArenaColors.carbon,
        borderColor: ArenaColors.statusOk.withValues(alpha: 0.4),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Revenus sur la période',
              style: GoogleFonts.spaceGrotesk(
                color: ArenaColors.silver,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${_money(b.collectedXaf)} XAF',
              style: GoogleFonts.bebasNeue(
                color: ArenaColors.statusOk,
                fontSize: 32,
                height: 1,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Marge nette : ${_money(b.marginXaf)} XAF '
              '(${b.marginPct.toStringAsFixed(1)}%)',
              style: GoogleFonts.spaceGrotesk(
                color: ArenaColors.silver,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RevenueChart extends StatelessWidget {
  const _RevenueChart({required this.async});

  final AsyncValue<List<MonthlyRevenue>> async;

  @override
  Widget build(BuildContext context) {
    return async.when(
      loading: () => const _ChartFrame(child: Center(child: ProgressRing())),
      error: (e, _) => _ChartFrame(
        child: Center(
          child: Text(
            'Erreur : $e',
            style: GoogleFonts.spaceGrotesk(
              color: ArenaColors.neonRed,
              fontSize: 12,
            ),
          ),
        ),
      ),
      data: (rows) {
        if (rows.isEmpty) {
          return _ChartFrame(
            child: Center(
              child: Text(
                'Aucun revenu sur la période.',
                style: GoogleFonts.spaceGrotesk(
                  color: ArenaColors.silver,
                  fontSize: 13,
                ),
              ),
            ),
          );
        }
        final maxY = rows.fold<double>(
          1,
          (acc, r) => r.revenueXaf > acc ? r.revenueXaf : acc,
        );
        // fl_chart s'appuie sur le theming Material ; on l'isole dans un
        // Material local pour ne pas exposer Material au reste de l'écran.
        return _ChartFrame(
          child: m.Material(
            type: m.MaterialType.transparency,
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
                      reservedSize: 20,
                      getTitlesWidget: (v, _) {
                        final i = v.toInt();
                        if (i < 0 || i >= rows.length) {
                          return const SizedBox.shrink();
                        }
                        return Text(
                          DateFormat('MMM', 'fr')
                              .format(rows[i].month)
                              .toUpperCase(),
                          style: GoogleFonts.spaceGrotesk(
                            color: ArenaColors.silver,
                            fontSize: 9,
                          ),
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
                          width: 10,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(2),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ChartFrame extends StatelessWidget {
  const _ChartFrame({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      backgroundColor: ArenaColors.carbon,
      padding: const EdgeInsets.all(16),
      child: SizedBox(height: 180, child: child),
    );
  }
}

class _BreakdownCard extends StatelessWidget {
  const _BreakdownCard({required this.async});

  final AsyncValue<RevenueBreakdown> async;

  @override
  Widget build(BuildContext context) {
    return async.when(
      loading: () => const Card(
        backgroundColor: ArenaColors.carbon,
        padding: EdgeInsets.all(24),
        child: Center(child: ProgressRing()),
      ),
      error: (e, _) => InfoBar(
        title: const Text('Décomposition indisponible'),
        content: Text('$e'),
        severity: InfoBarSeverity.error,
      ),
      data: (b) {
        final rows = <(String, String, _RowKind)>[
          (
            'Frais inscriptions collectés',
            _money(b.collectedXaf),
            _RowKind.neutral
          ),
          ('— Payouts versés', '-${_money(b.payoutsXaf)}', _RowKind.negative),
          (
            '— Frais processeur',
            '-${_money(b.processorFeesXaf)}',
            _RowKind.negative
          ),
          ('= Marge nette', '${_money(b.marginXaf)} XAF', _RowKind.positive),
        ];
        return Card(
          backgroundColor: ArenaColors.carbon,
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              for (var i = 0; i < rows.length; i++)
                _BreakdownRow(
                  label: rows[i].$1,
                  value: rows[i].$2,
                  kind: rows[i].$3,
                  divider: i < rows.length - 1,
                ),
            ],
          ),
        );
      },
    );
  }
}

enum _RowKind { neutral, negative, positive }

class _BreakdownRow extends StatelessWidget {
  const _BreakdownRow({
    required this.label,
    required this.value,
    required this.kind,
    required this.divider,
  });

  final String label;
  final String value;
  final _RowKind kind;
  final bool divider;

  @override
  Widget build(BuildContext context) {
    final color = switch (kind) {
      _RowKind.neutral => ArenaColors.bone,
      _RowKind.negative => ArenaColors.neonRed,
      _RowKind.positive => ArenaColors.statusOk,
    };
    final bold = kind == _RowKind.positive;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: bold ? ArenaColors.statusOk.withValues(alpha: 0.05) : null,
        border: divider
            ? const Border(bottom: BorderSide(color: ArenaColors.border))
            : null,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.spaceGrotesk(
                color: ArenaColors.bone,
                fontSize: 13,
                fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
          ),
          Text(
            value,
            style: GoogleFonts.spaceGrotesk(
              color: color,
              fontSize: bold ? 14 : 13,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}

class _CompetitionsTable extends StatelessWidget {
  const _CompetitionsTable({required this.async});

  final AsyncValue<List<CompetitionRevenue>> async;

  @override
  Widget build(BuildContext context) {
    return async.when(
      loading: () => const Card(
        backgroundColor: ArenaColors.carbon,
        padding: EdgeInsets.all(24),
        child: Center(child: ProgressRing()),
      ),
      error: (e, _) => InfoBar(
        title: const Text('Revenu par compétition indisponible'),
        content: Text('$e'),
        severity: InfoBarSeverity.error,
      ),
      data: (rows) {
        if (rows.isEmpty) {
          return const Card(
            backgroundColor: ArenaColors.carbon,
            padding: EdgeInsets.all(24),
            child: Center(child: Text('Aucune compétition active.')),
          );
        }
        return Card(
          backgroundColor: ArenaColors.carbon,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _headerRow(),
              const Divider(style: DividerThemeData(thickness: 1)),
              for (final r in rows)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Text(
                          r.name,
                          style: GoogleFonts.spaceGrotesk(
                            color: ArenaColors.bone,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      _numCell('${r.registeredCount}', ArenaColors.bone),
                      _numCell(_money(r.revenueXaf), ArenaColors.bone, flex: 2),
                      _numCell(
                        _money(r.commissionXaf),
                        ArenaColors.statusOk,
                        flex: 2,
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

  Widget _headerRow() {
    TextStyle s() => GoogleFonts.spaceGrotesk(
          color: ArenaColors.silver,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 1,
        );
    return Row(
      children: [
        Expanded(flex: 3, child: Text('COMPÉTITION', style: s())),
        Expanded(child: Text('INSCRITS', textAlign: TextAlign.right, style: s())),
        Expanded(
          flex: 2,
          child: Text('REVENU', textAlign: TextAlign.right, style: s()),
        ),
        Expanded(
          flex: 2,
          child: Text('COMMISSION', textAlign: TextAlign.right, style: s()),
        ),
      ],
    );
  }

  Widget _numCell(String value, Color color, {int flex = 1}) {
    return Expanded(
      flex: flex,
      child: Text(
        value,
        textAlign: TextAlign.right,
        style: GoogleFonts.spaceGrotesk(color: color, fontSize: 13),
      ),
    );
  }
}

final TextStyle _sectionStyle = GoogleFonts.bebasNeue(
  color: ArenaColors.silver,
  fontSize: 16,
  letterSpacing: 1.5,
);

Future<void> _showResult(
  BuildContext context,
  String message, {
  required bool isError,
}) async {
  await displayInfoBar(
    context,
    builder: (ctx, close) => InfoBar(
      title: Text(isError ? 'Échec' : 'Succès'),
      content: Text(message),
      severity: isError ? InfoBarSeverity.error : InfoBarSeverity.success,
      onClose: close,
    ),
  );
}

String _money(double xaf) => NumberFormat('#,###', 'fr').format(xaf.round());
