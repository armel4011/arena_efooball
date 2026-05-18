import 'dart:io';

import 'package:arena/core/theme/arena_theme.dart';
import 'package:arena/data/repositories/admin/super_admin_dashboard_repository.dart';
import 'package:arena/features_shared/widgets/arena_app_bar.dart';
import 'package:arena/features_shared/widgets/arena_button.dart';
import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// PHASE 11 · SA4 — super-admin revenue & accounting.
///
/// Lot B : branché sur la DB via `superAdminRevenueBreakdownProvider` et
/// `superAdminRevenuePerCompetitionProvider`. Le selector de période
/// alimente `selectedRevenuePeriodProvider` (StateProvider) qui
/// invalide automatiquement le breakdown. Export CSV ship en 11.7.
class SuperAdminRevenue extends ConsumerWidget {
  const SuperAdminRevenue({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final periodChoice = ref.watch(_selectedPeriodChipProvider);
    final breakdownAsync = ref.watch(superAdminRevenueBreakdownProvider);
    final perCompAsync = ref.watch(superAdminRevenuePerCompetitionProvider);

    return Scaffold(
      appBar: ArenaAppBar(
        title: 'Revenus & compta',
        actions: [
          TextButton(
            onPressed: () => _exportCsv(context, ref),
            child: Text(
              'CSV ↓',
              style: ArenaText.body.copyWith(
                color: ArenaColors.statusOk,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: ArenaColors.signalBlue,
          onRefresh: () async {
            ref
              ..invalidate(superAdminRevenueBreakdownProvider)
              ..invalidate(superAdminRevenuePerCompetitionProvider);
            await ref.read(superAdminRevenueBreakdownProvider.future);
          },
          child: ListView(
            padding: const EdgeInsets.all(ArenaSpacing.lg),
            children: [
              _PeriodChipsRow(
                current: periodChoice,
                onTap: (label) {
                  ref.read(_selectedPeriodChipProvider.notifier).state = label;
                  ref.read(selectedRevenuePeriodProvider.notifier).state =
                      _resolvePeriod(label);
                },
              ),
              const SizedBox(height: ArenaSpacing.md),
              _RevenueHero(async: breakdownAsync),
              const SizedBox(height: ArenaSpacing.lg),
              Text('DÉCOMPOSITION', style: ArenaText.inputLabel),
              const SizedBox(height: ArenaSpacing.sm),
              _BreakdownCard(async: breakdownAsync),
              const SizedBox(height: ArenaSpacing.sm),
              breakdownAsync.maybeWhen(
                data: (b) => Center(
                  child: Text(
                    'Marge ${b.marginPct.toStringAsFixed(1)}%',
                    style: ArenaText.bodyMuted
                        .copyWith(color: ArenaColors.statusOk),
                  ),
                ),
                orElse: () => const SizedBox.shrink(),
              ),
              const SizedBox(height: ArenaSpacing.lg),
              Text('PAR COMPÉTITION', style: ArenaText.inputLabel),
              const SizedBox(height: ArenaSpacing.sm),
              _CompetitionsTable(async: perCompAsync),
              const SizedBox(height: ArenaSpacing.lg),
              ArenaButton(
                label: '📥 EXPORT CSV (comptable)',
                fullWidth: true,
                size: ArenaButtonSize.large,
                onPressed: () => _exportCsv(context, ref),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Lot B.3 — Génère un CSV avec la décomposition + la table par
  /// compétition, écrit en cache temp + déclenche le sheet de partage
  /// natif (`share_plus`).
  Future<void> _exportCsv(BuildContext context, WidgetRef ref) async {
    final scaffold = ScaffoldMessenger.of(context);
    try {
      final breakdown = await ref.read(superAdminRevenueBreakdownProvider.future);
      final perComp =
          await ref.read(superAdminRevenuePerCompetitionProvider.future);
      final period = ref.read(selectedRevenuePeriodProvider);

      final periodLabel = '${DateFormat('yyyy-MM-dd').format(period.start)}'
          '_${DateFormat('yyyy-MM-dd').format(period.end)}';

      final rows = <List<dynamic>>[
        ['Période', periodLabel],
        [],
        ['DÉCOMPOSITION'],
        ['Frais inscriptions collectés (XAF)', breakdown.collectedXaf.round()],
        ['Payouts versés (XAF)', -breakdown.payoutsXaf.round()],
        ['Frais processeur (XAF)', -breakdown.processorFeesXaf.round()],
        ['Marge nette (XAF)', breakdown.marginXaf.round()],
        ['Marge %', breakdown.marginPct.toStringAsFixed(1)],
        [],
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

      final csv = const ListToCsvConverter().convert(rows);
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/arena-revenue-$periodLabel.csv');
      await file.writeAsString(csv);

      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'text/csv')],
        subject: 'ARENA revenue $periodLabel',
        text: 'Export comptable ARENA — période $periodLabel.',
      );
    } catch (e) {
      scaffold.showSnackBar(
        SnackBar(content: Text('Export CSV échoué : $e')),
      );
    }
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
}

final _selectedPeriodChipProvider = StateProvider<String>(
  (_) => 'Mois en cours',
);

class _PeriodChipsRow extends StatelessWidget {
  const _PeriodChipsRow({required this.current, required this.onTap});

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
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final l in _labels)
            Padding(
              padding: const EdgeInsets.only(right: ArenaSpacing.xs),
              child: InkWell(
                onTap: () => onTap(l),
                borderRadius: BorderRadius.circular(ArenaRadius.round),
                child: AnimatedContainer(
                  duration: ArenaDurations.short,
                  padding: const EdgeInsets.symmetric(
                    horizontal: ArenaSpacing.md,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: l == current
                        ? ArenaColors.signalBlue.withValues(alpha: 0.15)
                        : ArenaColors.carbon,
                    borderRadius:
                        BorderRadius.circular(ArenaRadius.round),
                    border: Border.all(
                      color: l == current
                          ? ArenaColors.signalBlue
                          : ArenaColors.border,
                    ),
                  ),
                  child: Text(
                    l,
                    style: ArenaText.body.copyWith(
                      color: l == current
                          ? ArenaColors.signalBlue
                          : ArenaColors.silver,
                      fontWeight: l == current
                          ? FontWeight.w600
                          : FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _RevenueHero extends StatelessWidget {
  const _RevenueHero({required this.async});
  final AsyncValue<RevenueBreakdown> async;

  @override
  Widget build(BuildContext context) {
    return async.when(
      data: (b) => Container(
        padding: const EdgeInsets.all(ArenaSpacing.lg),
        decoration: arenaSuccessCardDecoration(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Revenus période', style: ArenaText.bodyMuted),
            const SizedBox(height: 4),
            Text(
              '${_money(b.collectedXaf)} XAF',
              style: ArenaText.bigNumber
                  .copyWith(color: ArenaColors.statusOk, fontSize: 30),
            ),
            const SizedBox(height: 2),
            Text(
              'Marge nette : ${_money(b.marginXaf)} XAF',
              style: ArenaText.bodyMuted,
            ),
          ],
        ),
      ),
      loading: () => Container(
        padding: const EdgeInsets.all(ArenaSpacing.lg),
        decoration: arenaSuccessCardDecoration(),
        child: const Center(
          child: CircularProgressIndicator(color: ArenaColors.statusOk),
        ),
      ),
      error: (e, _) => Container(
        padding: const EdgeInsets.all(ArenaSpacing.lg),
        decoration: arenaDangerCardDecoration(),
        child: Text(
          'Erreur breakdown : $e',
          style: ArenaText.body.copyWith(color: ArenaColors.neonRed),
        ),
      ),
    );
  }
}

class _BreakdownCard extends StatelessWidget {
  const _BreakdownCard({required this.async});
  final AsyncValue<RevenueBreakdown> async;

  @override
  Widget build(BuildContext context) {
    return async.when(
      data: (b) {
        final rows = <(String, String, _RowKind)>[
          (
            'Frais inscriptions collectés',
            _money(b.collectedXaf),
            _RowKind.neutral
          ),
          (
            '— Payouts versés',
            '-${_money(b.payoutsXaf)}',
            _RowKind.negative
          ),
          (
            '— Frais processeur (V1 : 0)',
            '-${_money(b.processorFeesXaf)}',
            _RowKind.negative
          ),
          ('= MARGE NETTE', '${_money(b.marginXaf)} XAF', _RowKind.positive),
        ];
        return Container(
          decoration: BoxDecoration(
            color: ArenaColors.carbon,
            borderRadius: BorderRadius.circular(ArenaRadius.lg),
            border: Border.all(color: ArenaColors.border),
          ),
          child: Column(
            children: [
              for (var i = 0; i < rows.length; i++) ...[
                _BreakdownRow(
                  label: rows[i].$1,
                  value: rows[i].$2,
                  kind: rows[i].$3,
                ),
                if (i < rows.length - 1)
                  const Divider(
                    height: 1,
                    thickness: 1,
                    color: ArenaColors.border,
                  ),
              ],
            ],
          ),
        );
      },
      loading: () => Container(
        padding: const EdgeInsets.all(ArenaSpacing.lg),
        decoration: BoxDecoration(
          color: ArenaColors.carbon,
          borderRadius: BorderRadius.circular(ArenaRadius.lg),
          border: Border.all(color: ArenaColors.border),
        ),
        child: const Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Text(
        'Erreur : $e',
        style: ArenaText.body.copyWith(color: ArenaColors.neonRed),
      ),
    );
  }
}

enum _RowKind { neutral, negative, positive }

class _BreakdownRow extends StatelessWidget {
  const _BreakdownRow({
    required this.label,
    required this.value,
    required this.kind,
  });

  final String label;
  final String value;
  final _RowKind kind;

  @override
  Widget build(BuildContext context) {
    final color = switch (kind) {
      _RowKind.neutral => ArenaColors.bone,
      _RowKind.negative => ArenaColors.neonRed,
      _RowKind.positive => ArenaColors.statusOk,
    };
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: ArenaSpacing.md,
        vertical: ArenaSpacing.sm,
      ),
      color: kind == _RowKind.positive
          ? ArenaColors.statusOk.withValues(alpha: 0.05)
          : null,
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: ArenaText.body.copyWith(
                fontWeight:
                    kind == _RowKind.positive ? FontWeight.w700 : null,
              ),
            ),
          ),
          Text(
            value,
            style: ArenaText.mono.copyWith(
              color: color,
              fontWeight:
                  kind == _RowKind.positive ? FontWeight.w700 : null,
              fontSize: kind == _RowKind.positive ? 14 : null,
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
      data: (rows) {
        if (rows.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(ArenaSpacing.md),
            decoration: BoxDecoration(
              color: ArenaColors.carbon,
              borderRadius: BorderRadius.circular(ArenaRadius.lg),
              border: Border.all(color: ArenaColors.border),
            ),
            child: Text(
              'Aucune compétition active à afficher.',
              style: ArenaText.bodyMuted,
            ),
          );
        }
        return Container(
          padding: const EdgeInsets.all(ArenaSpacing.sm),
          decoration: BoxDecoration(
            color: ArenaColors.carbon,
            borderRadius: BorderRadius.circular(ArenaRadius.lg),
            border: Border.all(color: ArenaColors.border),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Text('Compét.', style: ArenaText.inputLabel),
                  ),
                  Expanded(
                    child: Text(
                      'Inscrits',
                      textAlign: TextAlign.right,
                      style: ArenaText.inputLabel,
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      'Revenu',
                      textAlign: TextAlign.right,
                      style: ArenaText.inputLabel,
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      'Commission',
                      textAlign: TextAlign.right,
                      style: ArenaText.inputLabel,
                    ),
                  ),
                ],
              ),
              const Divider(color: ArenaColors.border, height: 14),
              for (final r in rows)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Text(
                          r.name,
                          style: ArenaText.body
                              .copyWith(fontWeight: FontWeight.w600),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          '${r.registeredCount}',
                          textAlign: TextAlign.right,
                          style: ArenaText.body,
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          _money(r.revenueXaf),
                          textAlign: TextAlign.right,
                          style: ArenaText.mono,
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          _money(r.commissionXaf),
                          textAlign: TextAlign.right,
                          style: ArenaText.mono
                              .copyWith(color: ArenaColors.statusOk),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.all(ArenaSpacing.lg),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Text(
        'Erreur : $e',
        style: ArenaText.body.copyWith(color: ArenaColors.neonRed),
      ),
    );
  }
}

String _money(double xaf) {
  final fmt = NumberFormat('#,###', 'fr_FR');
  return fmt.format(xaf.round());
}
