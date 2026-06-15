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
import 'package:arena/features_shared/auth_common/shared_auth_providers.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

part 'desktop_competition_detail_widgets.dart';
part 'desktop_competition_detail_tabs.dart';

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
