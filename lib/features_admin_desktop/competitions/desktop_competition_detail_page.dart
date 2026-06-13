import 'package:arena/core/router/admin_desktop_router.dart';
import 'package:arena/core/theme/arena_fluent_theme.dart';
import 'package:arena/core/theme/arena_theme.dart';
import 'package:arena/core/utils/arena_error_message.dart';
import 'package:arena/data/models/competition.dart';
import 'package:arena/data/models/competition_enums.dart';
import 'package:arena/data/models/user_role.dart';
import 'package:arena/data/repositories/admin/admin_competitions_repository.dart';
import 'package:arena/data/repositories/competition_repository.dart';
import 'package:arena/features_admin_desktop/competitions/desktop_competition_visuals.dart';
import 'package:arena/features_admin_desktop/matches/desktop_matches_list_page.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

/// Détail desktop d'une compétition — TabView Fluent à 5 onglets : Infos,
/// Inscrits, Matchs, Classement, Actions.
///
/// Réutilise [competitionByIdProvider] (stream realtime public),
/// [adminCompetitionRegistrantsProvider] et
/// [adminCompetitionsRepositoryProvider].
class DesktopCompetitionDetailPage extends ConsumerStatefulWidget {
  const DesktopCompetitionDetailPage({
    required this.competitionId,
    super.key,
  });

  final String competitionId;

  @override
  ConsumerState<DesktopCompetitionDetailPage> createState() =>
      _DesktopCompetitionDetailPageState();
}

class _DesktopCompetitionDetailPageState
    extends ConsumerState<DesktopCompetitionDetailPage> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final compAsync =
        ref.watch(competitionByIdProvider(widget.competitionId));

    return ScaffoldPage(
      header: PageHeader(
        title: const Text('COMPÉTITION'),
        commandBar: CommandBar(
          mainAxisAlignment: MainAxisAlignment.end,
          primaryItems: [
            CommandBarButton(
              icon: const Icon(FluentIcons.back),
              label: const Text('Retour'),
              onPressed: () => context.go(AdminDesktopRoutes.competitions),
            ),
          ],
        ),
      ),
      content: compAsync.when(
        loading: () => const Center(child: ProgressRing()),
        error: (e, _) => Padding(
          padding: const EdgeInsets.all(ArenaDesktop.pagePadding),
          child: InfoBar(
            title: const Text('Erreur'),
            content: Text('$e'),
            severity: InfoBarSeverity.error,
          ),
        ),
        data: (comp) {
          if (comp == null) {
            return const Center(child: Text('Compétition introuvable.'));
          }
          return _buildTabs(comp);
        },
      ),
    );
  }

  Widget _buildTabs(Competition comp) {
    final tabs = [
      _tabItem('Infos', FluentIcons.info, _InfosTab(competition: comp)),
      _tabItem(
        'Inscrits',
        FluentIcons.people,
        _RegistrantsTab(competitionId: comp.id),
      ),
      _tabItem(
        'Matchs',
        FluentIcons.game,
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: ArenaDesktop.pagePadding,
          ),
          child: DesktopMatchesListPage(competitionId: comp.id),
        ),
      ),
      _tabItem(
        'Classement',
        FluentIcons.sort,
        _RankingTab(competitionId: comp.id),
      ),
      _tabItem('Actions', FluentIcons.build, _ActionsTab(competition: comp)),
    ];

    return Padding(
      padding: const EdgeInsets.only(
        left: ArenaDesktop.pagePadding,
        right: ArenaDesktop.pagePadding,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _CompetitionHeaderBar(competition: comp),
          if (comp.lastBracketError != null) ...[
            const SizedBox(height: 12),
            InfoBar(
              title: const Text('Échec auto-bracket'),
              content: Text(
                comp.lastBracketErrorAt == null
                    ? comp.lastBracketError!
                    : '${comp.lastBracketError!}\n'
                        '${DateFormat('d MMM y · HH:mm', 'fr').format(comp.lastBracketErrorAt!.toLocal())}',
              ),
              severity: InfoBarSeverity.warning,
            ),
          ],
          const SizedBox(height: 12),
          Expanded(
            child: TabView(
              currentIndex: _tab,
              onChanged: (i) => setState(() => _tab = i),
              closeButtonVisibility: CloseButtonVisibilityMode.never,
              tabWidthBehavior: TabWidthBehavior.sizeToContent,
              tabs: tabs,
            ),
          ),
        ],
      ),
    );
  }

  Tab _tabItem(String text, IconData icon, Widget body) {
    return Tab(
      text: Text(text),
      icon: Icon(icon),
      body: body,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// Header
// ─────────────────────────────────────────────────────────────────────

class _CompetitionHeaderBar extends StatelessWidget {
  const _CompetitionHeaderBar({required this.competition});

  final Competition competition;

  @override
  Widget build(BuildContext context) {
    final visual = competitionStatusVisual(competition.status);
    return Card(
      backgroundColor: ArenaColors.carbon,
      child: Row(
        children: [
          Container(width: 4, height: 44, color: visual.color),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  competition.name,
                  style: GoogleFonts.bebasNeue(
                    color: ArenaColors.bone,
                    fontSize: 24,
                    letterSpacing: 1,
                  ),
                ),
                Text(
                  '${competition.game.label} · '
                  '${competitionFormatLabel(competition.format)}',
                  style: GoogleFonts.spaceGrotesk(
                    color: ArenaColors.silver,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          DesktopStatusBadge(visual: visual),
          const SizedBox(width: 16),
          Text(
            '#${competition.id.substring(0, 6).toUpperCase()}',
            style: GoogleFonts.jetBrainsMono(
              color: ArenaColors.silver,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// Onglet Infos
// ─────────────────────────────────────────────────────────────────────

class _InfosTab extends StatelessWidget {
  const _InfosTab({required this.competition});

  final Competition competition;

  @override
  Widget build(BuildContext context) {
    final c = competition;
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 16),
      children: [
        Card(
          backgroundColor: ArenaColors.carbon,
          child: Column(
            children: [
              _InfoRow(label: 'Jeu', value: c.game.label),
              _InfoRow(
                label: 'Format',
                value: competitionFormatLabel(c.format),
              ),
              _InfoRow(
                label: 'Joueurs',
                value: '${c.currentPlayers}/${c.maxPlayers}',
              ),
              _InfoRow(
                label: 'Début',
                value: DateFormat('dd/MM/yyyy HH:mm', 'fr')
                    .format(c.startDate.toLocal()),
              ),
              if (c.registrationFee > 0)
                _InfoRow(
                  label: 'Inscription',
                  value: '${c.registrationFee} ${c.registrationCurrency}',
                ),
              _InfoRow(
                label: 'Commission',
                value: '${c.commissionPct.round()}%',
              ),
              _InfoRow(
                label: 'Bracket auto',
                value: c.autoGenerateBracket ? 'Activé' : 'Désactivé',
              ),
              _InfoRow(
                label: 'Intervalle rounds',
                value: _intervalLabel(c.matchIntervalMinutes),
              ),
              _InfoRow(
                label: 'Inscriptions restantes',
                value: c.spotsLeft == 0
                    ? 'Quota atteint'
                    : '${c.spotsLeft} place(s)',
              ),
            ],
          ),
        ),
        if (c.description != null && c.description!.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(
            'DESCRIPTION',
            style: GoogleFonts.spaceGrotesk(
              color: ArenaColors.silver,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            c.description!,
            style: GoogleFonts.spaceGrotesk(
              color: ArenaColors.bone,
              fontSize: 13,
              height: 1.5,
            ),
          ),
        ],
      ],
    );
  }

  static String _intervalLabel(int minutes) {
    if (minutes < 60) return '$minutes min';
    if (minutes < 1440) return '${minutes ~/ 60} h';
    final d = minutes ~/ 1440;
    return d == 1 ? '1 jour' : '$d jours';
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: ArenaColors.border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.spaceGrotesk(
                color: ArenaColors.silver,
                fontSize: 13,
              ),
            ),
          ),
          Text(
            value,
            style: GoogleFonts.spaceGrotesk(
              color: ArenaColors.bone,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// Onglet Inscrits
// ─────────────────────────────────────────────────────────────────────

class _RegistrantsTab extends ConsumerWidget {
  const _RegistrantsTab({required this.competitionId});

  final String competitionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async =
        ref.watch(adminCompetitionRegistrantsProvider(competitionId));
    return async.when(
      loading: () => const Center(child: ProgressRing()),
      error: (e, _) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: InfoBar(
          title: const Text('Erreur'),
          content: Text('$e'),
          severity: InfoBarSeverity.error,
        ),
      ),
      data: (list) {
        if (list.isEmpty) {
          return const Center(child: Text('Aucun inscrit pour le moment.'));
        }
        final confirmed =
            list.where((r) => r.status == 'confirmed').length;
        return ListView(
          padding: const EdgeInsets.symmetric(vertical: 16),
          children: [
            Text(
              '${list.length} inscrit(s) · $confirmed confirmé(s)',
              style: GoogleFonts.spaceGrotesk(
                color: ArenaColors.silver,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Card(
              backgroundColor: ArenaColors.carbon,
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  for (final r in list)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: const BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: ArenaColors.border),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: Row(
                              children: [
                                Text(
                                  r.username,
                                  style: GoogleFonts.spaceGrotesk(
                                    color: ArenaColors.bone,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                if (r.role == UserRole.admin ||
                                    r.role == UserRole.superAdmin) ...[
                                  const SizedBox(width: 8),
                                  DesktopStatusBadge(
                                    visual: DesktopStatusVisual(
                                      label: r.role == UserRole.superAdmin
                                          ? 'SUPER'
                                          : 'ADMIN',
                                      color: ArenaColors.signalBlue,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              r.countryCode,
                              style: GoogleFonts.spaceGrotesk(
                                color: ArenaColors.silver,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              DateFormat('dd/MM/yyyy HH:mm', 'fr')
                                  .format(r.registeredAt.toLocal()),
                              style: GoogleFonts.spaceGrotesk(
                                color: ArenaColors.silver,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          DesktopStatusBadge(
                            visual: _registrantStatusVisual(r.status),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
        );
      },
    );
  }

  static DesktopStatusVisual _registrantStatusVisual(String s) {
    switch (s) {
      case 'confirmed':
        return const DesktopStatusVisual(
          label: 'PAYÉ',
          color: ArenaColors.statusOk,
        );
      case 'pending':
        return const DesktopStatusVisual(
          label: 'EN ATTENTE',
          color: ArenaColors.statusWarn,
        );
      case 'refunded':
        return const DesktopStatusVisual(
          label: 'REMBOURSÉ',
          color: ArenaColors.neonRed,
        );
      case 'withdrawn':
        return const DesktopStatusVisual(
          label: 'RETRAIT',
          color: ArenaColors.neonRed,
        );
      default:
        return DesktopStatusVisual(
          label: s.toUpperCase(),
          color: ArenaColors.silver,
        );
    }
  }
}

// ─────────────────────────────────────────────────────────────────────
// Onglet Classement
// ─────────────────────────────────────────────────────────────────────

class _RankingTab extends ConsumerWidget {
  const _RankingTab({required this.competitionId});

  final String competitionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async =
        ref.watch(adminCompetitionRegistrantsProvider(competitionId));
    return async.when(
      loading: () => const Center(child: ProgressRing()),
      error: (e, _) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: InfoBar(
          title: const Text('Erreur'),
          content: Text('$e'),
          severity: InfoBarSeverity.error,
        ),
      ),
      data: (list) {
        if (list.isEmpty) {
          return const Center(
            child: Text('Aucun inscrit — le classement est vide.'),
          );
        }
        final sorted = [...list]..sort((a, b) {
            final ra = a.finalRank ?? 1 << 30;
            final rb = b.finalRank ?? 1 << 30;
            if (ra != rb) return ra.compareTo(rb);
            return a.username
                .toLowerCase()
                .compareTo(b.username.toLowerCase());
          });
        final ranked = list.where((r) => r.finalRank != null).length;
        return ListView(
          padding: const EdgeInsets.symmetric(vertical: 16),
          children: [
            Row(
              children: [
                FilledButton(
                  onPressed: () => _autoRank(context, ref),
                  child: const Text('Classement automatique'),
                ),
                const SizedBox(width: 16),
                Text(
                  '$ranked/${list.length} classé(s)',
                  style: GoogleFonts.spaceGrotesk(
                    color: ArenaColors.silver,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Card(
              backgroundColor: ArenaColors.carbon,
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  for (final r in sorted)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: const BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: ArenaColors.border),
                        ),
                      ),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 48,
                            child: Text(
                              r.finalRank == null ? '—' : '#${r.finalRank}',
                              style: GoogleFonts.jetBrainsMono(
                                color: ArenaColors.bone,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              r.username,
                              style: GoogleFonts.spaceGrotesk(
                                color: ArenaColors.bone,
                                fontSize: 13,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          SizedBox(
                            width: 140,
                            child: ComboBox<int?>(
                              value: r.finalRank,
                              isExpanded: true,
                              placeholder: const Text('Rang'),
                              items: [
                                const ComboBoxItem<int?>(child: Text('—')),
                                for (var n = 1; n <= list.length; n++)
                                  ComboBoxItem<int?>(
                                    value: n,
                                    child: Text('Rang $n'),
                                  ),
                              ],
                              onChanged: (rank) => _setRank(
                                context,
                                ref,
                                r.playerId,
                                rank,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
        );
      },
    );
  }

  Future<void> _autoRank(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => ContentDialog(
        title: const Text('Calculer le classement ?'),
        content: const Text(
          'Les rangs seront recalculés à partir des résultats de matchs. '
          'Cela écrase les rangs déjà saisis manuellement.',
        ),
        actions: [
          Button(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Calculer'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref
          .read(adminCompetitionsRepositoryProvider)
          .autoRankFromResults(competitionId);
      ref.invalidate(adminCompetitionRegistrantsProvider(competitionId));
    } catch (e) {
      if (!context.mounted) return;
      await _showError(context, e);
    }
  }

  Future<void> _setRank(
    BuildContext context,
    WidgetRef ref,
    String playerId,
    int? rank,
  ) async {
    try {
      await ref
          .read(adminCompetitionsRepositoryProvider)
          .setFinalRank(competitionId, playerId, rank);
      ref.invalidate(adminCompetitionRegistrantsProvider(competitionId));
    } catch (e) {
      if (!context.mounted) return;
      await _showError(context, e);
    }
  }
}

// ─────────────────────────────────────────────────────────────────────
// Onglet Actions
// ─────────────────────────────────────────────────────────────────────

class _ActionsTab extends ConsumerWidget {
  const _ActionsTab({required this.competition});

  final Competition competition;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = competition;
    final canOpenRegistration = c.status == CompetitionStatus.draft ||
        c.status == CompetitionStatus.registrationOpen;
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 16),
      children: [
        _ActionButton(
          icon: FluentIcons.edit,
          label: 'Modifier la compétition',
          onPressed: () => context.go(
            AdminDesktopRoutes.competitionsCreate,
            extra: c,
          ),
        ),
        _ActionButton(
          icon: FluentIcons.org,
          label: 'Gérer le bracket',
          onPressed: () =>
              context.go(AdminDesktopRoutes.bracketPath(c.id)),
        ),
        if (canOpenRegistration)
          _ActionButton(
            icon: FluentIcons.play,
            label: 'Ouvrir les inscriptions',
            onPressed: () => _setStatus(
              context,
              ref,
              CompetitionStatus.registrationOpen,
            ),
          ),
        if (c.status == CompetitionStatus.registrationOpen)
          _ActionButton(
            icon: FluentIcons.pause,
            label: 'Fermer les inscriptions',
            onPressed: () => _setStatus(
              context,
              ref,
              CompetitionStatus.registrationClosed,
            ),
          ),
        if (c.status == CompetitionStatus.completed)
          _ActionButton(
            icon: FluentIcons.refresh,
            label: 'Régénérer la compétition',
            onPressed: () => _regenerate(context, ref),
          ),
        _ActionButton(
          icon: FluentIcons.cancel,
          label: 'Annuler la compétition',
          danger: true,
          onPressed: () => _cancel(context, ref),
        ),
        _ActionButton(
          icon: FluentIcons.delete,
          label: 'Supprimer la compétition',
          danger: true,
          onPressed: () => _delete(context, ref),
        ),
      ],
    );
  }

  Future<void> _setStatus(
    BuildContext context,
    WidgetRef ref,
    CompetitionStatus status,
  ) async {
    try {
      await ref.read(adminCompetitionsRepositoryProvider).update(
        competition.id,
        {'status': status.value},
      );
    } catch (e) {
      if (!context.mounted) return;
      await _showError(context, e);
    }
  }

  Future<void> _regenerate(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => ContentDialog(
        title: const Text('Régénérer la compétition ?'),
        content: Text(
          'Une nouvelle compétition est créée avec la même configuration. '
          'Les inscriptions repartent à zéro (date à J+7). '
          '« ${competition.name} » reste inchangée.',
        ),
        actions: [
          Button(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Non'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Régénérer'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      final fresh = await ref
          .read(adminCompetitionsRepositoryProvider)
          .regenerate(competition.id);
      if (!context.mounted) return;
      context.go(AdminDesktopRoutes.competitionDetailPath(fresh.id));
    } catch (e) {
      if (!context.mounted) return;
      await _showError(context, e);
    }
  }

  Future<void> _cancel(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => ContentDialog(
        title: const Text('Annuler la compétition ?'),
        content: const Text(
          "L'opération est irréversible côté joueurs. Les remboursements "
          'seront déclenchés ultérieurement.',
        ),
        actions: [
          Button(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Non'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Oui, annuler'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref
          .read(adminCompetitionsRepositoryProvider)
          .cancel(competition.id);
    } catch (e) {
      if (!context.mounted) return;
      await _showError(context, e);
    }
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => ContentDialog(
        title: const Text('Supprimer définitivement ?'),
        content: const Text(
          'Cette compétition et tous ses paiements liés seront effacés de la '
          'base. Inscriptions, matches et brackets cascadent automatiquement. '
          'Cette action est IRRÉVERSIBLE.',
        ),
        actions: [
          Button(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Non'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Oui, supprimer'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref
          .read(adminCompetitionsRepositoryProvider)
          .delete(competition.id);
      if (!context.mounted) return;
      context.go(AdminDesktopRoutes.competitions);
    } catch (e) {
      if (!context.mounted) return;
      await _showError(context, e);
    }
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.danger = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final color = danger ? ArenaColors.neonRed : ArenaColors.bone;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: SizedBox(
        width: 320,
        child: Button(
          onPressed: onPressed,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                Icon(icon, size: 16, color: color),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: GoogleFonts.spaceGrotesk(
                    color: color,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
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

// ─────────────────────────────────────────────────────────────────────
// Helper d'erreur partagé
// ─────────────────────────────────────────────────────────────────────

Future<void> _showError(BuildContext context, Object error) {
  return displayInfoBar(
    context,
    builder: (ctx, close) => InfoBar(
      title: const Text('Échec'),
      content: Text(arenaErrorMessage(error)),
      severity: InfoBarSeverity.error,
      onClose: close,
    ),
  );
}
