import 'package:arena/core/router/admin_desktop_router.dart';
import 'package:arena/core/theme/arena_fluent_theme.dart';
import 'package:arena/core/theme/arena_theme.dart';
import 'package:arena/data/repositories/admin/admin_audit_log_repository.dart';
import 'package:arena/data/repositories/admin/admin_kpis_repository.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

/// Dashboard admin desktop — KPIs en grille, actions rapides et fil
/// d'activité récent, sur une mise en page multi-colonnes.
///
/// Réutilise [adminKpisProvider] et [adminAuditLogProvider] (les mêmes
/// providers que le dashboard mobile).
class DesktopDashboardPage extends ConsumerWidget {
  const DesktopDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final kpisAsync = ref.watch(adminKpisProvider);
    final auditAsync = ref.watch(
      adminAuditLogProvider(const AdminAuditLogFilter(periodDays: 7)),
    );

    return ScaffoldPage(
      header: PageHeader(
        title: const Text('TABLEAU DE BORD'),
        commandBar: CommandBar(
          mainAxisAlignment: MainAxisAlignment.end,
          primaryItems: [
            CommandBarButton(
              icon: const Icon(FluentIcons.refresh),
              label: const Text('Actualiser'),
              onPressed: () {
                ref
                  ..invalidate(adminKpisProvider)
                  ..invalidate(adminAuditLogProvider);
              },
            ),
            CommandBarButton(
              icon: const Icon(FluentIcons.add),
              label: const Text('Nouvelle compétition'),
              onPressed: () =>
                  context.go(AdminDesktopRoutes.competitionsCreate),
            ),
          ],
        ),
      ),
      content: ListView(
        padding: const EdgeInsets.symmetric(
          horizontal: ArenaDesktop.pagePadding,
        ),
        children: [
          // ─── KPIs ────────────────────────────────────────────────
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
                final cardWidth = (constraints.maxWidth -
                        3 * ArenaDesktop.cardGap) /
                    4;
                return Wrap(
                  spacing: ArenaDesktop.cardGap,
                  runSpacing: ArenaDesktop.cardGap,
                  children: [
                    _KpiCard(
                      width: cardWidth,
                      icon: FluentIcons.trophy2,
                      label: 'Compétitions actives',
                      value: '${kpis.activeCompetitions}',
                      accent: ArenaColors.neonRed,
                      onTap: () =>
                          context.go(AdminDesktopRoutes.competitions),
                    ),
                    _KpiCard(
                      width: cardWidth,
                      icon: FluentIcons.game,
                      label: 'Matchs en cours',
                      value: '${kpis.liveMatches}',
                      accent: ArenaColors.gameEfoot,
                      onTap: () => context.go(AdminDesktopRoutes.matches),
                    ),
                    _KpiCard(
                      width: cardWidth,
                      icon: FluentIcons.warning,
                      label: 'Litiges ouverts',
                      value: '${kpis.openDisputes}',
                      accent: ArenaColors.statusWarn,
                      onTap: () => context.go(AdminDesktopRoutes.matches),
                    ),
                    _KpiCard(
                      width: cardWidth,
                      icon: FluentIcons.money,
                      label: 'Paiements en attente',
                      value: '${kpis.pendingPayouts}',
                      sublabel: NumberFormat.compact(locale: 'fr')
                          .format(kpis.pendingPayoutsAmountLocal),
                      accent: ArenaColors.statusOk,
                      onTap: () => context.go(AdminDesktopRoutes.payouts),
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 32),

          // ─── Activité récente ────────────────────────────────────
          Text(
            'ACTIVITÉ RÉCENTE (7 JOURS)',
            style: GoogleFonts.bebasNeue(
              color: ArenaColors.silver,
              fontSize: 16,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          auditAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(48),
              child: Center(child: ProgressRing()),
            ),
            error: (e, _) => InfoBar(
              title: const Text("Impossible de charger l'activité"),
              content: Text('$e'),
              severity: InfoBarSeverity.error,
            ),
            data: (entries) {
              if (entries.isEmpty) {
                return const Card(
                  backgroundColor: ArenaColors.carbon,
                  padding: EdgeInsets.all(32),
                  child: Center(
                    child: Text('Aucune action admin sur les 7 derniers '
                        'jours.'),
                  ),
                );
              }
              return Card(
                backgroundColor: ArenaColors.carbon,
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    for (final entry in entries.take(10))
                      _AuditRow(
                        action: entry.action,
                        targetType: entry.targetType,
                        createdAt: entry.createdAt,
                      ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// Widgets privés
// ─────────────────────────────────────────────────────────────────────

class _KpiCard extends StatelessWidget {
  const _KpiCard({
    required this.width,
    required this.icon,
    required this.label,
    required this.value,
    required this.accent,
    required this.onTap,
    this.sublabel,
  });

  final double width;
  final IconData icon;
  final String label;
  final String value;
  final String? sublabel;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width.clamp(200, 400),
      child: HoverButton(
        onPressed: onTap,
        builder: (context, states) {
          final hovered = states.isHovered;
          return Card(
            backgroundColor:
                hovered ? ArenaColors.carbon2 : ArenaColors.carbon,
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
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      value,
                      style: GoogleFonts.bebasNeue(
                        color: ArenaColors.bone,
                        fontSize: 40,
                        height: 1,
                      ),
                    ),
                    if (sublabel != null) ...[
                      const SizedBox(width: 8),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          sublabel!,
                          style: GoogleFonts.spaceGrotesk(
                            color: accent,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _AuditRow extends StatelessWidget {
  const _AuditRow({
    required this.action,
    this.targetType,
    this.createdAt,
  });

  final String action;
  final String? targetType;
  final DateTime? createdAt;

  @override
  Widget build(BuildContext context) {
    final typography = FluentTheme.of(context).typography;
    final timestamp = createdAt;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: ArenaColors.border),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            FluentIcons.history,
            size: 14,
            color: ArenaColors.silver,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              targetType == null ? action : '$action · $targetType',
              style: typography.body,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (timestamp != null)
            Text(
              DateFormat('dd MMM HH:mm', 'fr').format(timestamp.toLocal()),
              style: typography.caption,
            ),
        ],
      ),
    );
  }
}
