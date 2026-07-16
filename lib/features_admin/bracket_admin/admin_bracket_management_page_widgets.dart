part of 'admin_bracket_management_page.dart';

// ─────────────────────────────────────────────────────────────────────
// Vues, tuiles et helpers d'affichage
// ─────────────────────────────────────────────────────────────────────

class _BracketView extends StatelessWidget {
  const _BracketView({required this.competition, required this.matches});

  final Competition competition;
  final List<ArenaMatch> matches;

  @override
  Widget build(BuildContext context) {
    // Single elim → arbre arborescent #20 ; autres formats (round-robin,
    // groupes+KO) restent en liste verticale legacy car ce ne sont pas
    // des arbres KO et l'arbre n'aurait pas de sens visuel.
    final showTree = competition.format == TournamentFormat.singleElimination;

    if (showTree) {
      return _BracketTreeView(competition: competition, matches: matches);
    }

    // ── Vue legacy : liste verticale groupée par round. ────────────
    final byRound = <int, List<ArenaMatch>>{};
    for (final m in matches) {
      byRound.putIfAbsent(m.round ?? 1, () => []).add(m);
    }
    final rounds = byRound.keys.toList()..sort();

    return ListView(
      padding: const EdgeInsets.all(ArenaSpacing.lg),
      children: [
        Text(
          '${competition.name} · ${matches.length} match${matches.length > 1 ? 's' : ''}',
          style: ArenaText.bodyMuted,
        ),
        const SizedBox(height: ArenaSpacing.md),
        for (final round in rounds) ...[
          Text(
            'ROUND $round',
            style: ArenaText.inputLabel,
          ),
          const SizedBox(height: ArenaSpacing.sm),
          for (final m in byRound[round]!) ...[
            _MatchRow(match: m),
            const SizedBox(height: ArenaSpacing.sm),
          ],
          const SizedBox(height: ArenaSpacing.md),
        ],
        Container(
          padding: const EdgeInsets.all(ArenaSpacing.md),
          decoration: arenaWarningCardDecoration(),
          child: Text(
            '⚠ Toutes les actions sont auditées (admin_audit_log).',
            style: ArenaText.body,
          ),
        ),
      ],
    );
  }
}

/// Vue arbre arborescent pour single-elim (maquette #20 admin) : header
/// caption avec compteur + `ArenaBracketTree` (pinch-to-zoom). Tap sur
/// une card ouvre un bottom-sheet d'actions admin (valider score /
/// annuler) qui reproduit la logique de `_MatchRow` legacy mais sans
/// les boutons inline (incompatibles avec la densité de l'arbre).
///
/// `ConsumerWidget` pour pouvoir watcher `profilesByIdsProvider` et
/// afficher le vrai username dans les cards (fallback `P-XXXX`).
class _BracketTreeView extends ConsumerWidget {
  const _BracketTreeView({required this.competition, required this.matches});

  final Competition competition;
  final List<ArenaMatch> matches;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final players = <String>{
      for (final m in matches) ...[
        if (m.player1Id != null) m.player1Id!,
        if (m.player2Id != null) m.player2Id!,
      ],
    };
    final joinedIds = (players.toList()..sort()).join(',');
    final profilesAsync = ref.watch(profilesByIdsProvider(joinedIds));
    final usernames = profilesAsync.maybeWhen(
      data: (m) => {
        for (final e in m.entries)
          if (e.value.username.isNotEmpty) e.key: e.value.username,
      },
      orElse: () => const <String, String>{},
    );

    return ListView(
      padding: const EdgeInsets.symmetric(
        horizontal: ArenaSpacing.md,
        vertical: ArenaSpacing.md,
      ),
      children: [
        Text(
          '${competition.name} · ${matches.length} match${matches.length > 1 ? 's' : ''}',
          textAlign: TextAlign.center,
          style: ArenaText.bodyMuted,
        ),
        const SizedBox(height: 4),
        Text(
          'ÉLIMINATION DIRECTE · ${players.length} JOUEURS',
          textAlign: TextAlign.center,
          style: ArenaText.monoSmall.copyWith(
            color: ArenaColors.silver,
            letterSpacing: 1.5,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: ArenaSpacing.sm),
        SizedBox(
          height: ArenaBracketTree.viewportHeightFor(matches.length),
          child: ArenaBracketTree(
            matches: matches,
            usernamesByPlayerId: usernames,
            onTapMatch: (m) => _AdminMatchActionsSheet.show(context, m),
          ),
        ),
        const SizedBox(height: ArenaSpacing.sm),
        Text(
          '↔ pince pour zoomer · touche un match pour les actions admin',
          textAlign: TextAlign.center,
          style: ArenaText.small.copyWith(color: ArenaColors.silver),
        ),
        const SizedBox(height: ArenaSpacing.md),
        Container(
          padding: const EdgeInsets.all(ArenaSpacing.md),
          decoration: arenaWarningCardDecoration(),
          child: Text(
            '⚠ Toutes les actions sont auditées (admin_audit_log).',
            style: ArenaText.body,
          ),
        ),
      ],
    );
  }

}

// _formatLabel → competitionFormatLabel (features_shared/admin/competition_labels.dart)

String _statusLabel(MatchStatus s) {
  switch (s) {
    case MatchStatus.inProgress:
    case MatchStatus.scorePending:
      return 'EN COURS';
    case MatchStatus.completed:
      return 'VALIDÉ';
    case MatchStatus.disputed:
      return 'DISPUTED';
    case MatchStatus.cancelled:
      return 'ANNULÉ';
    case MatchStatus.forfeited:
      return 'FORFAIT';
    case MatchStatus.pending:
    case MatchStatus.scheduled:
    case MatchStatus.ready:
    case MatchStatus.awaitingValidation:
      return 'EN ATTENTE';
  }
}

ArenaBadgeVariant _statusBadgeVariant(MatchStatus s) {
  switch (s) {
    case MatchStatus.inProgress:
    case MatchStatus.scorePending:
      return ArenaBadgeVariant.live;
    case MatchStatus.completed:
      return ArenaBadgeVariant.success;
    case MatchStatus.disputed:
      return ArenaBadgeVariant.warn;
    case MatchStatus.cancelled:
    case MatchStatus.forfeited:
      return ArenaBadgeVariant.neutral;
    case MatchStatus.pending:
    case MatchStatus.scheduled:
    case MatchStatus.ready:
    case MatchStatus.awaitingValidation:
      return ArenaBadgeVariant.info;
  }
}
