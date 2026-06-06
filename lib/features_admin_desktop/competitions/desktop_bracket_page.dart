import 'package:arena/core/theme/arena_fluent_theme.dart';
import 'package:arena/core/theme/arena_theme.dart';
import 'package:arena/core/utils/arena_error_message.dart';
import 'package:arena/data/models/arena_match.dart';
import 'package:arena/data/models/competition.dart';
import 'package:arena/data/models/competition_enums.dart';
import 'package:arena/data/models/match_status.dart';
import 'package:arena/data/repositories/admin/admin_audit_log_repository.dart';
import 'package:arena/data/repositories/admin/admin_bracket_repository.dart';
import 'package:arena/data/repositories/admin/admin_matches_repository.dart';
import 'package:arena/data/repositories/competition_repository.dart';
import 'package:arena/data/repositories/match_repository.dart';
import 'package:arena/data/repositories/profile_repository.dart';
import 'package:arena/features_admin_desktop/competitions/desktop_competition_visuals.dart';
import 'package:arena/features_shared/auth_common/shared_auth_providers.dart';
// ArenaBracketTree est un widget Flutter pur (importe flutter/material)
// mais se compose dans un arbre Fluent sans problème : on l'enrobe ici.
import 'package:arena/features_shared/widgets/arena_bracket_tree.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

/// Gestion desktop du bracket d'une compétition.
///
/// Sans matchs → bouton « Générer le bracket » (single-elim / round-robin
/// / poules+KO). Avec matchs : single-elim → [ArenaBracketTree] (pur
/// Flutter, compatible Fluent) ; autres formats → liste groupée par
/// round. Tap sur un match → dialog Fluent (valider score / annuler).
///
/// Réutilise [competitionByIdProvider], [competitionMatchesProvider],
/// [adminBracketRepositoryProvider], [adminMatchesRepositoryProvider].
class DesktopBracketPage extends ConsumerWidget {
  const DesktopBracketPage({required this.competitionId, super.key});

  final String competitionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final compAsync = ref.watch(competitionByIdProvider(competitionId));
    final matchesAsync =
        ref.watch(competitionMatchesProvider(competitionId));

    return ScaffoldPage(
      header: const PageHeader(title: Text('GESTION DU BRACKET')),
      content: compAsync.when(
        loading: () => const Center(child: ProgressRing()),
        error: (e, _) => _errorBar('$e'),
        data: (comp) {
          if (comp == null) {
            return const Center(child: Text('Compétition introuvable.'));
          }
          return matchesAsync.when(
            loading: () => const Center(child: ProgressRing()),
            error: (e, _) => _errorBar('$e'),
            data: (matches) => matches.isEmpty
                ? _EmptyBracketState(competition: comp)
                : _BracketView(competition: comp, matches: matches),
          );
        },
      ),
    );
  }

  Widget _errorBar(String message) => Padding(
        padding: const EdgeInsets.all(ArenaDesktop.pagePadding),
        child: InfoBar(
          title: const Text('Erreur'),
          content: Text(message),
          severity: InfoBarSeverity.error,
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────
// État vide — génération
// ─────────────────────────────────────────────────────────────────────

class _EmptyBracketState extends ConsumerStatefulWidget {
  const _EmptyBracketState({required this.competition});

  final Competition competition;

  @override
  ConsumerState<_EmptyBracketState> createState() =>
      _EmptyBracketStateState();
}

class _EmptyBracketStateState extends ConsumerState<_EmptyBracketState> {
  bool _generating = false;
  String? _error;

  @override
  Widget build(BuildContext context) {
    final comp = widget.competition;
    return Padding(
      padding: const EdgeInsets.all(ArenaDesktop.pagePadding),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                FluentIcons.org,
                size: 48,
                color: ArenaColors.silver,
              ),
              const SizedBox(height: 16),
              Text(
                'Aucun bracket pour cette compétition.',
                style: GoogleFonts.spaceGrotesk(
                  color: ArenaColors.bone,
                  fontSize: 15,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Format : ${competitionFormatLabel(comp.format)} · '
                'Inscrits ${comp.currentPlayers}/${comp.maxPlayers}',
                style: GoogleFonts.spaceGrotesk(
                  color: ArenaColors.silver,
                  fontSize: 13,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              if (_error != null) ...[
                InfoBar(
                  title: const Text('Échec'),
                  content: Text(_error!),
                  severity: InfoBarSeverity.error,
                  onClose: () => setState(() => _error = null),
                ),
                const SizedBox(height: 16),
              ],
              if (_generating)
                const ProgressRing()
              else
                FilledButton(
                  onPressed: _confirmGenerate,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    child: Text('Générer le bracket'),
                  ),
                ),
              const SizedBox(height: 16),
              const InfoBar(
                title: Text('Action irréversible'),
                content: Text(
                  'Les matchs seront créés et chaque joueur inscrit reçoit '
                  'son premier adversaire.',
                ),
                severity: InfoBarSeverity.warning,
                isLong: true,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmGenerate() async {
    final adminId = ref.read(currentSessionProvider)?.user.id;
    if (adminId == null) return;
    final comp = widget.competition;
    final repo = ref.read(adminBracketRepositoryProvider);

    List<String> players;
    try {
      players = await repo.listConfirmedRegistrations(comp.id);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = arenaErrorMessage(e));
      return;
    }
    if (!mounted) return;
    if (players.length < 2) {
      setState(
        () => _error = '${players.length} joueur(s) inscrit(s) — minimum 2.',
      );
      return;
    }

    _GroupsConfig? groupsConfig = _GroupsConfig.empty;
    if (comp.format == TournamentFormat.groupsThenKnockout) {
      groupsConfig = await _askGroupsConfig();
      if (!mounted || groupsConfig == null) return;
    }

    final ok = await _confirmDialog(players.length);
    if (ok != true || !mounted) return;
    setState(() {
      _generating = true;
      _error = null;
    });

    try {
      switch (comp.format) {
        case TournamentFormat.singleElimination:
          await repo.generateSingleElim(
            competitionId: comp.id,
            playerIds: players,
            thirdPlace: comp.thirdPlaceMatch,
          );
        case TournamentFormat.roundRobin:
          await repo.generateRoundRobinTournament(
            competitionId: comp.id,
            playerIds: players,
          );
        case TournamentFormat.groupsThenKnockout:
          await repo.generateGroupsKnockoutTournament(
            competitionId: comp.id,
            playerIds: players,
            groupCount: groupsConfig.groupCount,
            qualifiersPerGroup: groupsConfig.qualifiers,
            thirdPlace: comp.thirdPlaceMatch,
          );
      }
      await ref.read(adminAuditLogRepositoryProvider).record(
        adminId: adminId,
        action: 'bracket_generated',
        targetType: 'competition',
        targetId: comp.id,
        afterState: {
          'format': comp.format.value,
          'players': players.length,
        },
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = arenaErrorMessage(e));
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  Future<bool?> _confirmDialog(int playerCount) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => ContentDialog(
        title: const Text('Générer le bracket ?'),
        content: Text(
          'Crée le bracket avec $playerCount joueurs. Action irréversible.',
        ),
        actions: [
          Button(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Générer'),
          ),
        ],
      ),
    );
  }

  Future<_GroupsConfig?> _askGroupsConfig() async {
    final groupsCtrl = TextEditingController(text: '4');
    final qualCtrl = TextEditingController(text: '2');
    final out = await showDialog<_GroupsConfig>(
      context: context,
      builder: (ctx) => ContentDialog(
        title: const Text('Configuration des poules'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            InfoLabel(
              label: 'Nombre de poules',
              child: TextBox(
                controller: groupsCtrl,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
            ),
            const SizedBox(height: 12),
            InfoLabel(
              label: 'Qualifiés par poule',
              child: TextBox(
                controller: qualCtrl,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
            ),
          ],
        ),
        actions: [
          Button(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () {
              final g = int.tryParse(groupsCtrl.text) ?? 0;
              final q = int.tryParse(qualCtrl.text) ?? 0;
              if (g < 2 || q < 1) return;
              Navigator.of(ctx).pop(_GroupsConfig(g, q));
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
    groupsCtrl.dispose();
    qualCtrl.dispose();
    return out;
  }
}

class _GroupsConfig {
  const _GroupsConfig(this.groupCount, this.qualifiers);

  final int groupCount;
  final int qualifiers;

  static const empty = _GroupsConfig(0, 0);
}

// ─────────────────────────────────────────────────────────────────────
// Vue du bracket
// ─────────────────────────────────────────────────────────────────────

class _BracketView extends ConsumerWidget {
  const _BracketView({required this.competition, required this.matches});

  final Competition competition;
  final List<ArenaMatch> matches;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final showTree =
        competition.format == TournamentFormat.singleElimination;

    final players = <String>{
      for (final m in matches) ...[
        if (m.player1Id != null) m.player1Id!,
        if (m.player2Id != null) m.player2Id!,
      ],
    };
    final joinedIds = (players.toList()..sort()).join(',');
    final usernames = ref.watch(profilesByIdsProvider(joinedIds)).maybeWhen(
          data: (m) => {
            for (final e in m.entries)
              if (e.value.username.isNotEmpty) e.key: e.value.username,
          },
          orElse: () => const <String, String>{},
        );

    return ListView(
      padding: const EdgeInsets.all(ArenaDesktop.pagePadding),
      children: [
        Text(
          '${competition.name} · ${matches.length} '
          'match${matches.length > 1 ? 's' : ''}',
          style: GoogleFonts.spaceGrotesk(
            color: ArenaColors.silver,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 16),
        if (showTree)
          SizedBox(
            height: 560,
            child: ArenaBracketTree(
              matches: matches,
              usernamesByPlayerId: usernames,
              onTapMatch: (m) =>
                  _showMatchActions(context, ref, m, usernames),
            ),
          )
        else
          _RoundsList(
            matches: matches,
            usernames: usernames,
            onTapMatch: (m) =>
                _showMatchActions(context, ref, m, usernames),
          ),
        const SizedBox(height: 16),
        const InfoBar(
          title: Text('Audit'),
          content: Text(
            'Toutes les actions sont enregistrées (admin_audit_log).',
          ),
          severity: InfoBarSeverity.info,
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Future<void> _showMatchActions(
    BuildContext context,
    WidgetRef ref,
    ArenaMatch match,
    Map<String, String> usernames,
  ) async {
    if (match.status == MatchStatus.completed) {
      await showDialog<void>(
        context: context,
        builder: (ctx) => ContentDialog(
          title: Text('Match M-${match.id.substring(0, 6)}'),
          content: const Text('Match validé — actions clôturées.'),
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Fermer'),
            ),
          ],
        ),
      );
      return;
    }
    await _MatchVerdictDialog.show(context, ref, match, usernames);
  }
}

class _RoundsList extends StatelessWidget {
  const _RoundsList({
    required this.matches,
    required this.usernames,
    required this.onTapMatch,
  });

  final List<ArenaMatch> matches;
  final Map<String, String> usernames;
  final ValueChanged<ArenaMatch> onTapMatch;

  @override
  Widget build(BuildContext context) {
    final byRound = <int, List<ArenaMatch>>{};
    for (final m in matches) {
      byRound.putIfAbsent(m.round ?? 1, () => []).add(m);
    }
    final rounds = byRound.keys.toList()..sort();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final round in rounds) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 8, top: 8),
            child: Text(
              'ROUND $round',
              style: GoogleFonts.spaceGrotesk(
                color: ArenaColors.silver,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
              ),
            ),
          ),
          for (final m in byRound[round]!) ...[
            _MatchCard(
              match: m,
              usernames: usernames,
              onTap: () => onTapMatch(m),
            ),
            const SizedBox(height: 8),
          ],
        ],
      ],
    );
  }
}

class _MatchCard extends StatelessWidget {
  const _MatchCard({
    required this.match,
    required this.usernames,
    required this.onTap,
  });

  final ArenaMatch match;
  final Map<String, String> usernames;
  final VoidCallback onTap;

  String _name(String? id) {
    if (id == null) return 'TBD';
    return usernames[id] ?? id.substring(0, 6);
  }

  @override
  Widget build(BuildContext context) {
    final visual = matchStatusVisual(match.status);
    return HoverButton(
      onPressed: onTap,
      builder: (context, states) {
        final hovered = states.isHovered;
        return Card(
          backgroundColor:
              hovered ? ArenaColors.carbon2 : ArenaColors.carbon,
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              DesktopStatusBadge(visual: visual),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  '${_name(match.player1Id)} vs ${_name(match.player2Id)}',
                  style: GoogleFonts.spaceGrotesk(
                    color: ArenaColors.bone,
                    fontSize: 13,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '${match.score1 ?? '—'} - ${match.score2 ?? '—'}',
                style: GoogleFonts.jetBrainsMono(
                  color: ArenaColors.bone,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// Dialog d'actions admin sur un match
// ─────────────────────────────────────────────────────────────────────

class _MatchVerdictDialog {
  static Future<void> show(
    BuildContext context,
    WidgetRef ref,
    ArenaMatch match,
    Map<String, String> usernames,
  ) async {
    final p1Ctrl = TextEditingController(text: '${match.score1 ?? 0}');
    final p2Ctrl = TextEditingController(text: '${match.score2 ?? 0}');
    String name(String? id) {
      if (id == null) return 'TBD';
      return usernames[id] ?? id.substring(0, 6);
    }

    final action = await showDialog<_VerdictAction>(
      context: context,
      builder: (ctx) => ContentDialog(
        title: Text('Match M-${match.id.substring(0, 6)}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: InfoLabel(
                    label: name(match.player1Id),
                    child: TextBox(
                      controller: p1Ctrl,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Text('-'),
                ),
                Expanded(
                  child: InfoLabel(
                    label: name(match.player2Id),
                    child: TextBox(
                      controller: p2Ctrl,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          Button(
            onPressed: () =>
                Navigator.of(ctx).pop(const _VerdictAction.cancelMatch()),
            child: const Text('Annuler le match'),
          ),
          Button(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Fermer'),
          ),
          FilledButton(
            onPressed: () {
              final s1 = int.tryParse(p1Ctrl.text);
              final s2 = int.tryParse(p2Ctrl.text);
              if (s1 == null || s2 == null) return;
              Navigator.of(ctx).pop(_VerdictAction.validate(s1, s2));
            },
            child: const Text('Valider le score'),
          ),
        ],
      ),
    );
    p1Ctrl.dispose();
    p2Ctrl.dispose();

    if (action == null) return;
    final adminId = ref.read(currentSessionProvider)?.user.id;
    if (adminId == null) return;

    try {
      if (action.isCancel) {
        await ref.read(adminMatchesRepositoryProvider).cancel(match.id);
        await ref.read(adminAuditLogRepositoryProvider).record(
              adminId: adminId,
              action: 'match_cancelled',
              targetType: 'match',
              targetId: match.id,
            );
      } else {
        final s1 = action.score1!;
        final s2 = action.score2!;
        final winnerId = s1 > s2
            ? match.player1Id
            : s2 > s1
                ? match.player2Id
                : null;
        await ref.read(adminMatchesRepositoryProvider).setVerdict(
              matchId: match.id,
              scoreP1: s1,
              scoreP2: s2,
              winnerId: winnerId,
            );
        await ref.read(adminAuditLogRepositoryProvider).record(
          adminId: adminId,
          action: 'match_verdict',
          targetType: 'match',
          targetId: match.id,
          afterState: {'score1': s1, 'score2': s2, 'winner_id': winnerId},
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      await displayInfoBar(
        context,
        builder: (ctx, close) => InfoBar(
          title: const Text('Échec'),
          content: Text(arenaErrorMessage(e)),
          severity: InfoBarSeverity.error,
          onClose: close,
        ),
      );
    }
  }
}

class _VerdictAction {
  const _VerdictAction.validate(this.score1, this.score2) : isCancel = false;
  const _VerdictAction.cancelMatch()
      : isCancel = true,
        score1 = null,
        score2 = null;

  final bool isCancel;
  final int? score1;
  final int? score2;
}
