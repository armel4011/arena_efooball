import 'package:arena/core/theme/arena_fluent_theme.dart';
import 'package:arena/core/theme/arena_theme.dart';
import 'package:arena/data/models/arena_match.dart';
import 'package:arena/data/models/match_status.dart';
import 'package:arena/data/repositories/admin/admin_matches_repository.dart';
import 'package:arena/features_admin_desktop/competitions/desktop_competition_visuals.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

/// Liste desktop des matchs — tableau dense avec filtre de statut dans la
/// CommandBar. Réutilise [adminMatchesProvider] (stream realtime global).
///
/// Le paramètre [competitionId] permet d'afficher uniquement les matchs
/// d'une compétition (réutilisé comme onglet « Matchs » du détail). En
/// mode page complète (`competitionId == null`), affiche tous les matchs
/// de la plateforme dans une [ScaffoldPage] avec en-tête.
class DesktopMatchesListPage extends ConsumerStatefulWidget {
  const DesktopMatchesListPage({this.competitionId, super.key});

  /// Si non nul, filtre sur cette compétition et masque l'en-tête de page.
  final String? competitionId;

  @override
  ConsumerState<DesktopMatchesListPage> createState() =>
      _DesktopMatchesListPageState();
}

class _DesktopMatchesListPageState
    extends ConsumerState<DesktopMatchesListPage> {
  MatchStatus? _statusFilter;

  bool get _embedded => widget.competitionId != null;

  @override
  Widget build(BuildContext context) {
    final listAsync = ref.watch(
      adminMatchesProvider(
        AdminMatchesFilter(
          status: _statusFilter,
          competitionId: widget.competitionId,
        ),
      ),
    );

    final body = listAsync.when(
      loading: () => const Center(child: ProgressRing()),
      error: (e, _) => Padding(
        padding: const EdgeInsets.all(ArenaDesktop.pagePadding),
        child: InfoBar(
          title: const Text('Impossible de charger les matchs'),
          content: Text('$e'),
          severity: InfoBarSeverity.error,
        ),
      ),
      data: (matches) {
        if (matches.isEmpty) {
          return const Center(child: Text('Aucun match pour ce filtre.'));
        }
        return _MatchesTable(matches: matches, embedded: _embedded);
      },
    );

    if (_embedded) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 8, 0, 12),
            child: Row(children: [_statusCombo()]),
          ),
          Expanded(child: body),
        ],
      );
    }

    return ScaffoldPage(
      header: PageHeader(
        title: const Text('MATCHS'),
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
            CommandBarButton(
              icon: const Icon(FluentIcons.refresh),
              label: const Text('Actualiser'),
              onPressed: () => ref.invalidate(adminMatchesProvider),
            ),
          ],
        ),
      ),
      content: body,
    );
  }

  Widget _statusCombo() {
    return SizedBox(
      width: 180,
      child: ComboBox<MatchStatus?>(
        value: _statusFilter,
        placeholder: const Text('Tous les statuts'),
        items: [
          const ComboBoxItem<MatchStatus?>(child: Text('Tous les statuts')),
          for (final s in _filterableStatuses)
            ComboBoxItem<MatchStatus?>(
              value: s,
              child: Text(matchStatusVisual(s).label),
            ),
        ],
        onChanged: (v) => setState(() => _statusFilter = v),
      ),
    );
  }

  static const _filterableStatuses = <MatchStatus>[
    MatchStatus.pending,
    MatchStatus.inProgress,
    MatchStatus.disputed,
    MatchStatus.completed,
  ];
}

// ─────────────────────────────────────────────────────────────────────
// Tableau
// ─────────────────────────────────────────────────────────────────────

class _MatchesTable extends StatelessWidget {
  const _MatchesTable({required this.matches, required this.embedded});

  final List<ArenaMatch> matches;
  final bool embedded;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.symmetric(
        horizontal: embedded ? 0 : ArenaDesktop.pagePadding,
      ),
      children: [
        const _HeaderRow(),
        Card(
          backgroundColor: ArenaColors.carbon,
          padding: EdgeInsets.zero,
          child: Column(
            children: [for (final m in matches) _MatchRow(match: m)],
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
          Expanded(flex: 2, child: Text('RÉFÉRENCE', style: style())),
          Expanded(child: Text('ROUND', style: style())),
          Expanded(flex: 3, child: Text('JOUEURS', style: style())),
          Expanded(child: Text('SCORE', style: style())),
          Expanded(flex: 2, child: Text('STATUT', style: style())),
          Expanded(flex: 2, child: Text('HORODATAGE', style: style())),
        ],
      ),
    );
  }
}

class _MatchRow extends StatelessWidget {
  const _MatchRow({required this.match});

  final ArenaMatch match;

  @override
  Widget build(BuildContext context) {
    final visual = matchStatusVisual(match.status);
    final bodyStyle = GoogleFonts.spaceGrotesk(
      color: ArenaColors.bone,
      fontSize: 13,
    );
    final mutedStyle = GoogleFonts.spaceGrotesk(
      color: ArenaColors.silver,
      fontSize: 13,
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: ArenaColors.border)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              'M-${match.id.substring(0, 6).toUpperCase()}',
              style: GoogleFonts.jetBrainsMono(
                color: ArenaColors.silver,
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            child: Text('${match.round ?? '—'}', style: mutedStyle),
          ),
          Expanded(
            flex: 3,
            child: Text(
              '${_short(match.player1Id)} vs ${_short(match.player2Id)}',
              style: bodyStyle,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            child: Text(
              _scoreText(match),
              style: GoogleFonts.jetBrainsMono(
                color: ArenaColors.bone,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
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
            flex: 2,
            child: Text(_timeText(match), style: mutedStyle),
          ),
        ],
      ),
    );
  }

  static String _short(String? id) {
    if (id == null || id.length < 6) return 'TBD';
    return id.substring(0, 6);
  }

  static String _scoreText(ArenaMatch m) {
    final s1 = m.score1;
    final s2 = m.score2;
    if (s1 == null && s2 == null) return '—';
    return '${s1 ?? 0} - ${s2 ?? 0}';
  }

  static String _timeText(ArenaMatch m) {
    final t = m.finishedAt ?? m.startedAt ?? m.scheduledAt;
    if (t == null) return '—';
    return DateFormat('dd/MM HH:mm', 'fr').format(t.toLocal());
  }
}
