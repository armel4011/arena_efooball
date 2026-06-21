import 'package:arena/core/router/admin_desktop_router.dart';
import 'package:arena/core/theme/arena_fluent_theme.dart';
import 'package:arena/core/theme/arena_theme.dart';
import 'package:arena/data/models/competition.dart';
import 'package:arena/data/models/competition_enums.dart';
import 'package:arena/data/repositories/admin/admin_competitions_repository.dart';
import 'package:arena/features_admin_desktop/competitions/desktop_competition_visuals.dart';
import 'package:arena/features_shared/auth_common/shared_auth_providers.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

/// Liste desktop des compétitions — tableau dense avec filtres statut /
/// jeu dans la CommandBar et navigation au clic vers le détail.
///
/// Réutilise [adminCompetitionsProvider] (le même stream realtime que la
/// liste mobile). Le filtrage statut + jeu est appliqué côté repository.
class DesktopCompetitionsListPage extends ConsumerStatefulWidget {
  const DesktopCompetitionsListPage({super.key});

  @override
  ConsumerState<DesktopCompetitionsListPage> createState() =>
      _DesktopCompetitionsListPageState();
}

class _DesktopCompetitionsListPageState
    extends ConsumerState<DesktopCompetitionsListPage> {
  CompetitionStatus? _statusFilter;
  GameType? _gameFilter;

  @override
  Widget build(BuildContext context) {
    final filter = AdminCompetitionsFilter(
      status: _statusFilter,
      game: _gameFilter,
    );
    final listAsync = ref.watch(adminCompetitionsProvider(filter));

    return ScaffoldPage(
      header: PageHeader(
        title: const Text('COMPÉTITIONS'),
        commandBar: CommandBar(
          mainAxisAlignment: MainAxisAlignment.end,
          primaryItems: [
            CommandBarBuilderItem(
              builder: (context, mode, child) => _statusCombo(),
              wrappedItem: CommandBarButton(
                label: const Text('Statut'),
                onPressed: () {},
              ),
            ),
            CommandBarBuilderItem(
              builder: (context, mode, child) => _gameCombo(),
              wrappedItem: CommandBarButton(
                label: const Text('Jeu'),
                onPressed: () {},
              ),
            ),
            CommandBarButton(
              icon: const Icon(FluentIcons.refresh),
              label: const Text('Actualiser'),
              onPressed: () => ref.invalidate(adminCompetitionsProvider),
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
      content: listAsync.when(
        loading: () => const Center(child: ProgressRing()),
        error: (e, _) => Padding(
          padding: const EdgeInsets.all(ArenaDesktop.pagePadding),
          child: InfoBar(
            title: const Text('Impossible de charger les compétitions'),
            content: Text('$e'),
            severity: InfoBarSeverity.error,
          ),
        ),
        data: (comps) {
          if (comps.isEmpty) {
            return const Center(
              child: Text('Aucune compétition pour ce filtre.'),
            );
          }
          return _CompetitionsTable(competitions: comps);
        },
      ),
    );
  }

  Widget _statusCombo() {
    return SizedBox(
      width: 170,
      // Pas d'option « Tous les statuts » dans la liste : le placeholder
      // (aucune sélection) vaut « tous ». Les items sont les statuts concrets.
      child: ComboBox<CompetitionStatus?>(
        value: _statusFilter,
        placeholder: const Text('Tous les statuts'),
        items: [
          for (final s in CompetitionStatus.values)
            ComboBoxItem<CompetitionStatus?>(
              value: s,
              child: Text(competitionStatusVisual(s).label),
            ),
        ],
        onChanged: (v) => setState(() => _statusFilter = v),
      ),
    );
  }

  Widget _gameCombo() {
    return SizedBox(
      width: 170,
      child: ComboBox<GameType?>(
        value: _gameFilter,
        placeholder: const Text('Tous les jeux'),
        items: [
          const ComboBoxItem<GameType?>(child: Text('Tous les jeux')),
          for (final g in GameType.values)
            ComboBoxItem<GameType?>(value: g, child: Text(g.label)),
        ],
        onChanged: (v) => setState(() => _gameFilter = v),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// Tableau
// ─────────────────────────────────────────────────────────────────────

class _CompetitionsTable extends StatelessWidget {
  const _CompetitionsTable({required this.competitions});

  final List<Competition> competitions;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(
        horizontal: ArenaDesktop.pagePadding,
      ),
      children: [
        const _HeaderRow(),
        Card(
          backgroundColor: ArenaColors.carbon,
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              for (final c in competitions) _CompetitionRow(competition: c),
            ],
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

class _HeaderRow extends StatelessWidget {
  const _HeaderRow();

  @override
  Widget build(BuildContext context) {
    TextStyle style() => GoogleFonts.spaceGrotesk(
          color: ArenaColors.silver,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 1,
        );
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          Expanded(flex: 3, child: Text('NOM', style: style())),
          Expanded(flex: 2, child: Text('JEU', style: style())),
          Expanded(flex: 2, child: Text('FORMAT', style: style())),
          Expanded(flex: 2, child: Text('STATUT', style: style())),
          Expanded(child: Text('INSCRITS', style: style())),
          Expanded(flex: 2, child: Text('DÉBUT', style: style())),
          SizedBox(width: 40, child: Text('', style: style())),
        ],
      ),
    );
  }
}

class _CompetitionRow extends ConsumerStatefulWidget {
  const _CompetitionRow({required this.competition});

  final Competition competition;

  @override
  ConsumerState<_CompetitionRow> createState() => _CompetitionRowState();
}

class _CompetitionRowState extends ConsumerState<_CompetitionRow> {
  final _flyoutController = FlyoutController();

  Competition get competition => widget.competition;

  @override
  void dispose() {
    _flyoutController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final visual = competitionStatusVisual(competition.status);
    final startFmt = DateFormat('dd/MM/yyyy HH:mm', 'fr');
    final bodyStyle = GoogleFonts.spaceGrotesk(
      color: ArenaColors.bone,
      fontSize: 13,
    );
    final mutedStyle = GoogleFonts.spaceGrotesk(
      color: ArenaColors.silver,
      fontSize: 13,
    );

    return HoverButton(
      onPressed: () => context.go(
        AdminDesktopRoutes.competitionDetailPath(competition.id),
      ),
      builder: (context, states) {
        final hovered = states.isHovered;
        return Container(
          color: hovered ? ArenaColors.carbon2 : ArenaColors.carbon,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: ArenaColors.border)),
          ),
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: Row(
                  children: [
                    if (competition.isPinned) ...[
                      const Icon(
                        FluentIcons.pinned,
                        size: 12,
                        color: ArenaColors.neonRed,
                      ),
                      const SizedBox(width: 6),
                    ],
                    Flexible(
                      child: Text(
                        competition.name,
                        style: bodyStyle.copyWith(fontWeight: FontWeight.w600),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  competition.game.label,
                  style: mutedStyle,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  competitionFormatLabel(competition.format),
                  style: mutedStyle,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Expanded(
                flex: 2,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: DesktopStatusBadge(visual: visual),
                ),
              ),
              Expanded(
                child: Text(
                  '${competition.currentPlayers}/${competition.maxPlayers}',
                  style: bodyStyle,
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  startFmt.format(competition.startDate.toLocal()),
                  style: mutedStyle,
                ),
              ),
              SizedBox(
                width: 40,
                child: FlyoutTarget(
                  controller: _flyoutController,
                  child: IconButton(
                    icon: const Icon(FluentIcons.more, size: 14),
                    onPressed: _openActions,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _openActions() {
    final c = competition;
    final canOpenRegistration = c.status == CompetitionStatus.draft ||
        c.status == CompetitionStatus.registrationOpen;
    _flyoutController.showFlyout<void>(
      autoModeConfiguration: FlyoutAutoConfiguration(
        preferredMode: FlyoutPlacementMode.bottomLeft,
      ),
      barrierDismissible: true,
      builder: (context) => MenuFlyout(
        items: [
          MenuFlyoutItem(
            leading: const Icon(FluentIcons.view),
            text: const Text('Voir le détail'),
            onPressed: () {
              Flyout.of(context).close();
              this.context.go(
                    AdminDesktopRoutes.competitionDetailPath(c.id),
                  );
            },
          ),
          MenuFlyoutItem(
            leading: const Icon(FluentIcons.pinned),
            text: Text(c.isPinned ? 'Désépingler' : 'Épingler à la une'),
            onPressed: () {
              Flyout.of(context).close();
              _togglePinned();
            },
          ),
          MenuFlyoutItem(
            leading: const Icon(FluentIcons.org),
            text: const Text('Gérer le bracket'),
            onPressed: () {
              Flyout.of(context).close();
              this.context.go(AdminDesktopRoutes.bracketPath(c.id));
            },
          ),
          MenuFlyoutItem(
            leading: const Icon(FluentIcons.edit),
            text: const Text('Modifier'),
            onPressed: () {
              Flyout.of(context).close();
              this.context.go(
                    AdminDesktopRoutes.competitionsCreate,
                    extra: c,
                  );
            },
          ),
          if (canOpenRegistration)
            MenuFlyoutItem(
              leading: const Icon(FluentIcons.play),
              text: const Text('Ouvrir les inscriptions'),
              onPressed: () {
                Flyout.of(context).close();
                _setStatus(CompetitionStatus.registrationOpen);
              },
            ),
          if (c.status == CompetitionStatus.registrationOpen)
            MenuFlyoutItem(
              leading: const Icon(FluentIcons.pause),
              text: const Text('Fermer les inscriptions'),
              onPressed: () {
                Flyout.of(context).close();
                _setStatus(CompetitionStatus.registrationClosed);
              },
            ),
          const MenuFlyoutSeparator(),
          MenuFlyoutItem(
            leading: const Icon(FluentIcons.cancel, color: ArenaColors.neonRed),
            text: const Text(
              'Annuler',
              style: TextStyle(color: ArenaColors.neonRed),
            ),
            onPressed: () {
              Flyout.of(context).close();
              _cancel();
            },
          ),
          MenuFlyoutItem(
            leading: const Icon(FluentIcons.delete, color: ArenaColors.neonRed),
            text: const Text(
              'Supprimer',
              style: TextStyle(color: ArenaColors.neonRed),
            ),
            onPressed: () {
              Flyout.of(context).close();
              _delete();
            },
          ),
        ],
      ),
    );
  }

  Future<void> _togglePinned() async {
    final adminId = ref.read(currentSessionProvider)?.user.id;
    if (adminId == null) {
      await _showError('Session admin introuvable.');
      return;
    }
    final willPin = !competition.isPinned;
    try {
      await ref.read(adminCompetitionsRepositoryProvider).setPinned(
            competitionId: competition.id,
            pinned: willPin,
            adminId: adminId,
          );
      if (!mounted) return;
      await displayInfoBar(
        context,
        builder: (ctx, close) => InfoBar(
          title: Text(willPin ? 'Épinglée' : 'Désépinglée'),
          content: Text(
            willPin
                ? '« ${competition.name} » est désormais à la une.'
                : '« ${competition.name} » a été retirée de la une.',
          ),
          severity: InfoBarSeverity.success,
          onClose: close,
        ),
      );
    } catch (e) {
      await _showError(e);
    }
  }

  Future<void> _setStatus(CompetitionStatus status) async {
    try {
      await ref.read(adminCompetitionsRepositoryProvider).update(
        competition.id,
        {'status': status.value},
      );
    } catch (e) {
      await _showError(e);
    }
  }

  Future<void> _cancel() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => ContentDialog(
        title: const Text('Annuler la compétition ?'),
        content: Text(
          "L'opération est irréversible côté joueurs. Les remboursements "
          'seront déclenchés ultérieurement.\n\n« ${competition.name} »',
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
      await _showError(e);
    }
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => ContentDialog(
        title: const Text('Supprimer définitivement ?'),
        content: Text(
          'Cette compétition et tous ses paiements liés seront effacés de la '
          'base. Inscriptions, matches et brackets cascadent automatiquement. '
          'Cette action est IRRÉVERSIBLE.\n\n« ${competition.name} »',
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
    } catch (e) {
      await _showError(e);
    }
  }

  Future<void> _showError(Object error) async {
    if (!mounted) return;
    await displayInfoBar(
      context,
      builder: (ctx, close) => InfoBar(
        title: const Text('Échec'),
        content: Text('$error'),
        severity: InfoBarSeverity.error,
        onClose: close,
      ),
    );
  }
}
