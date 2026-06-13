import 'package:arena/core/router/admin_desktop_router.dart';
import 'package:arena/core/theme/arena_fluent_theme.dart';
import 'package:arena/core/theme/arena_theme.dart';
import 'package:arena/data/models/competition.dart';
import 'package:arena/data/models/competition_enums.dart';
import 'package:arena/data/repositories/admin/admin_competitions_repository.dart';
import 'package:arena/features_admin_desktop/competitions/desktop_competition_visuals.dart';
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

class _CompetitionRow extends StatelessWidget {
  const _CompetitionRow({required this.competition});

  final Competition competition;

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
                child: Text(
                  competition.name,
                  style: bodyStyle.copyWith(fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
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
              const SizedBox(
                width: 40,
                child: Icon(
                  FluentIcons.chevron_right,
                  size: 12,
                  color: ArenaColors.silver,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
