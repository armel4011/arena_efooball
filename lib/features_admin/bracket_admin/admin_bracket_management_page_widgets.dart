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
          height: _treeHeightFor(matches.length),
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

  static double _treeHeightFor(int matchCount) {
    if (matchCount >= 15) return 460;
    if (matchCount >= 7) return 320;
    if (matchCount >= 3) return 220;
    return 160;
  }
}

/// Bottom-sheet d'actions admin pour un match (déclenchée par tap sur
/// une card de l'arbre). Affiche le statut, les deux joueurs/scores, et
/// 2 CTA (Valider score / Annuler) tant que le match n'est pas
/// `completed`. La logique business est portée par `_AdminMatchActions`
/// (Consumer) qui réutilise repo / audit log providers existants.
class _AdminMatchActionsSheet extends StatelessWidget {
  const _AdminMatchActionsSheet({required this.match});

  final ArenaMatch match;

  static Future<void> show(BuildContext context, ArenaMatch match) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: ArenaColors.carbon,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(ArenaRadius.lg)),
      ),
      builder: (_) => _AdminMatchActionsSheet(match: match),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isCompleted = match.status == MatchStatus.completed;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(ArenaSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                ArenaBadge(
                  label: _statusLabel(match.status),
                  variant: _statusBadgeVariant(match.status),
                ),
                const Spacer(),
                Text(
                  'M-${match.id.substring(0, 6)}',
                  style: ArenaText.monoSmall,
                ),
              ],
            ),
            const SizedBox(height: ArenaSpacing.md),
            _PlayerRow(
              playerId: match.player1Id,
              score: match.score1,
              color: ArenaAvatarColor.blue,
            ),
            const SizedBox(height: 6),
            _PlayerRow(
              playerId: match.player2Id,
              score: match.score2,
              color: ArenaAvatarColor.green,
            ),
            if (!isCompleted) ...[
              const SizedBox(height: ArenaSpacing.lg),
              _AdminMatchActions(match: match),
            ] else ...[
              const SizedBox(height: ArenaSpacing.md),
              Text(
                'Match validé — actions clôturées.',
                style: ArenaText.small.copyWith(color: ArenaColors.silver),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Boutons d'action admin (Valider score / Annuler) pour le match
/// courant. Extrait en `ConsumerWidget` pour accéder aux repositories
/// sans porter le ref dans tous les ancêtres.
class _AdminMatchActions extends ConsumerWidget {
  const _AdminMatchActions({required this.match});

  final ArenaMatch match;

  /// Le HOME player détient la session de broadcast. Fallback player1 si le
  /// champ dédié n'est pas renseigné (matchs anciens / cascade bracket).
  String? get _homePlayerId => match.homePlayerId ?? match.player1Id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final homeId = _homePlayerId;
    final isStreamed = match.isStreamed;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: ArenaButton(
                label: '✅ VALIDER SCORE',
                fullWidth: true,
                onPressed: () => _openVerdictDialog(context, ref),
              ),
            ),
            const SizedBox(width: ArenaSpacing.sm),
            Expanded(
              child: ArenaButton(
                label: '🚫 ANNULER',
                fullWidth: true,
                variant: ArenaButtonVariant.danger,
                onPressed: () async {
                  await _cancel(context, ref);
                  if (context.mounted) Navigator.of(context).pop();
                },
              ),
            ),
          ],
        ),
        // Toggle diffusion live : seulement si un joueur HOME est connu
        // (sinon aucune session streams à publier).
        if (homeId != null) ...[
          const SizedBox(height: ArenaSpacing.sm),
          ArenaButton(
            label: isStreamed
                ? '⏹ COUPER LA DIFFUSION'
                : '📡 ACTIVER LA DIFFUSION LIVE',
            fullWidth: true,
            variant: isStreamed
                ? ArenaButtonVariant.danger
                : ArenaButtonVariant.secondary,
            onPressed: () async {
              await _toggleStreaming(context, ref, homeId, enable: !isStreamed);
              if (context.mounted) Navigator.of(context).pop();
            },
          ),
        ],
        // Édition de l'horaire du match (scheduled_at). Pilote le verrou
        // d'accès « T-5 min » côté app user + les rappels T-60/30/10/5.
        const SizedBox(height: ArenaSpacing.sm),
        ArenaButton(
          label: match.scheduledAt == null
              ? "🕒 DÉFINIR L'HORAIRE"
              : "🕒 MODIFIER L'HORAIRE",
          fullWidth: true,
          variant: ArenaButtonVariant.secondary,
          onPressed: () => _reschedule(context, ref),
        ),
      ],
    );
  }

  Future<void> _reschedule(BuildContext context, WidgetRef ref) async {
    final adminId = ref.read(currentSessionProvider)?.user.id;
    if (adminId == null) return;
    final initial = match.scheduledAt?.toLocal() ?? DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date == null || !context.mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (time == null || !context.mounted) return;
    final scheduledAt =
        DateTime(date.year, date.month, date.day, time.hour, time.minute);
    try {
      await ref.read(adminMatchesRepositoryProvider).reschedule(
            matchId: match.id,
            scheduledAt: scheduledAt,
          );
      await ref.read(adminAuditLogRepositoryProvider).record(
        adminId: adminId,
        action: 'match_rescheduled',
        targetType: 'match',
        targetId: match.id,
        afterState: {
          'scheduled_at': scheduledAt.toUtc().toIso8601String(),
          'from': 'bracket_sheet',
        },
      );
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Horaire du match mis à jour.')),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Échec : ${arenaErrorMessage(e)}')),
      );
    }
  }

  Future<void> _toggleStreaming(
    BuildContext context,
    WidgetRef ref,
    String homePlayerId, {
    required bool enable,
  }) async {
    final adminId = ref.read(currentSessionProvider)?.user.id;
    if (adminId == null) return;
    try {
      await ref.read(adminMatchesRepositoryProvider).setManualStreaming(
            matchId: match.id,
            homePlayerId: homePlayerId,
            enabled: enable,
            adminId: adminId,
          );
      await ref.read(adminAuditLogRepositoryProvider).record(
        adminId: adminId,
        action: enable ? 'stream_enabled' : 'stream_disabled',
        targetType: 'match',
        targetId: match.id,
        afterState: {'home_player_id': homePlayerId, 'from': 'bracket_sheet'},
      );
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            enable ? 'Diffusion live activée.' : 'Diffusion coupée.',
          ),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Échec : ${arenaErrorMessage(e)}')),
      );
    }
  }

  Future<void> _openVerdictDialog(BuildContext context, WidgetRef ref) async {
    final p1Ctrl = TextEditingController(text: '${match.score1 ?? 0}');
    final p2Ctrl = TextEditingController(text: '${match.score2 ?? 0}');
    final result = await showDialog<(int, int)?>(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: ArenaColors.carbon,
        title: Text('Valider le score', style: ArenaText.h3),
        content: Row(
          children: [
            Expanded(
              child: ArenaTextField(
                controller: p1Ctrl,
                hint: 'J1',
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: ArenaSpacing.sm),
              child: Text('-'),
            ),
            Expanded(
              child: ArenaTextField(
                controller: p2Ctrl,
                hint: 'J2',
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(c).pop(),
            child: const Text('ANNULER'),
          ),
          TextButton(
            onPressed: () {
              final s1 = int.tryParse(p1Ctrl.text);
              final s2 = int.tryParse(p2Ctrl.text);
              if (s1 == null || s2 == null) return;
              Navigator.of(c).pop((s1, s2));
            },
            child: const Text('VALIDER'),
          ),
        ],
      ),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      p1Ctrl.dispose();
      p2Ctrl.dispose();
    });
    if (result == null) return;
    final (s1, s2) = result;
    final adminId = ref.read(currentSessionProvider)?.user.id;
    if (adminId == null) return;
    final winnerId = s1 > s2
        ? match.player1Id
        : s2 > s1
            ? match.player2Id
            : null;
    try {
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
        afterState: {
          'score1': s1,
          'score2': s2,
          'winner_id': winnerId,
        },
      );
      if (context.mounted) Navigator.of(context).pop();
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Échec : ${arenaErrorMessage(e)}')),
      );
    }
  }

  Future<void> _cancel(BuildContext context, WidgetRef ref) async {
    final adminId = ref.read(currentSessionProvider)?.user.id;
    if (adminId == null) return;
    try {
      await ref.read(adminMatchesRepositoryProvider).cancel(match.id);
      await ref.read(adminAuditLogRepositoryProvider).record(
            adminId: adminId,
            action: 'match_cancelled',
            targetType: 'match',
            targetId: match.id,
          );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Échec : ${arenaErrorMessage(e)}')),
      );
    }
  }
}

class _MatchRow extends ConsumerWidget {
  const _MatchRow({required this.match});
  final ArenaMatch match;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLive = match.status == MatchStatus.inProgress;
    final isCompleted = match.status == MatchStatus.completed;
    final isDisputed = match.status == MatchStatus.disputed;

    return Container(
      padding: const EdgeInsets.all(ArenaSpacing.md),
      decoration: BoxDecoration(
        color: ArenaColors.carbon,
        borderRadius: BorderRadius.circular(ArenaRadius.lg),
        border: Border.all(
          color: isLive
              ? ArenaColors.neonRed
              : isDisputed
                  ? ArenaColors.statusWarn
                  : ArenaColors.border,
        ),
        boxShadow: isLive
            ? [
                BoxShadow(
                  color: ArenaColors.neonRed.withValues(alpha: 0.25),
                  blurRadius: 12,
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              ArenaBadge(
                label: _statusLabel(match.status),
                variant: _statusBadgeVariant(match.status),
              ),
              const Spacer(),
              Text(
                _refLabel(match),
                style: ArenaText.monoSmall,
              ),
            ],
          ),
          const SizedBox(height: ArenaSpacing.sm),
          _PlayerRow(
            playerId: match.player1Id,
            score: match.score1,
            color: ArenaAvatarColor.blue,
          ),
          const SizedBox(height: 4),
          _PlayerRow(
            playerId: match.player2Id,
            score: match.score2,
            color: ArenaAvatarColor.green,
          ),
          if (!isCompleted) ...[
            const SizedBox(height: ArenaSpacing.sm),
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: [
                _SmallActionButton(
                  label: '✅ VALIDER SCORE',
                  onTap: () => _openVerdictDialog(context, ref),
                ),
                _SmallActionButton(
                  label: '🚫 ANNULER',
                  danger: true,
                  onTap: () => _cancel(context, ref),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _openVerdictDialog(BuildContext context, WidgetRef ref) async {
    final p1Ctrl = TextEditingController(text: '${match.score1 ?? 0}');
    final p2Ctrl = TextEditingController(text: '${match.score2 ?? 0}');
    final result = await showDialog<(int, int)?>(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: ArenaColors.carbon,
        title: Text('Valider le score', style: ArenaText.h3),
        content: Row(
          children: [
            Expanded(
              child: ArenaTextField(
                controller: p1Ctrl,
                hint: 'J1',
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: ArenaSpacing.sm),
              child: Text('-'),
            ),
            Expanded(
              child: ArenaTextField(
                controller: p2Ctrl,
                hint: 'J2',
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(c).pop(),
            child: const Text('ANNULER'),
          ),
          TextButton(
            onPressed: () {
              final s1 = int.tryParse(p1Ctrl.text);
              final s2 = int.tryParse(p2Ctrl.text);
              if (s1 == null || s2 == null) return;
              Navigator.of(c).pop((s1, s2));
            },
            child: const Text('VALIDER'),
          ),
        ],
      ),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      p1Ctrl.dispose();
      p2Ctrl.dispose();
    });
    if (result == null) return;
    final (s1, s2) = result;
    final adminId = ref.read(currentSessionProvider)?.user.id;
    if (adminId == null) return;
    final winnerId = s1 > s2
        ? match.player1Id
        : s2 > s1
            ? match.player2Id
            : null;
    try {
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
        afterState: {
          'score1': s1,
          'score2': s2,
          'winner_id': winnerId,
        },
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Échec : ${arenaErrorMessage(e)}')),
      );
    }
  }

  Future<void> _cancel(BuildContext context, WidgetRef ref) async {
    final adminId = ref.read(currentSessionProvider)?.user.id;
    if (adminId == null) return;
    try {
      await ref.read(adminMatchesRepositoryProvider).cancel(match.id);
      await ref.read(adminAuditLogRepositoryProvider).record(
            adminId: adminId,
            action: 'match_cancelled',
            targetType: 'match',
            targetId: match.id,
          );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Échec : ${arenaErrorMessage(e)}')),
      );
    }
  }

  static String _refLabel(ArenaMatch m) {
    final id = 'M-${m.id.substring(0, 6)}';
    final time = m.startedAt;
    if (time == null) return id;
    final elapsed = DateTime.now().difference(time).inMinutes;
    return "$id · $elapsed'";
  }
}

class _PlayerRow extends StatelessWidget {
  const _PlayerRow({
    required this.playerId,
    required this.score,
    required this.color,
  });
  final String? playerId;
  final int? score;
  final ArenaAvatarColor color;

  @override
  Widget build(BuildContext context) {
    final label = playerId == null ? 'TBD' : playerId!.substring(0, 8);
    return Row(
      children: [
        ArenaAvatar(
          initials: label[0],
          color: color,
          size: ArenaAvatarSize.sm,
        ),
        const SizedBox(width: ArenaSpacing.sm),
        Expanded(child: Text(label, style: ArenaText.body)),
        Text(
          score?.toString() ?? '—',
          style: ArenaText.bigNumber.copyWith(fontSize: 18),
        ),
      ],
    );
  }
}

class _SmallActionButton extends StatelessWidget {
  const _SmallActionButton({
    required this.label,
    required this.onTap,
    this.danger = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(ArenaRadius.md),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: ArenaSpacing.sm,
          vertical: 6,
        ),
        decoration: BoxDecoration(
          color: danger ? ArenaColors.neonRed : ArenaColors.carbon,
          borderRadius: BorderRadius.circular(ArenaRadius.md),
          border: Border.all(
            color: danger ? Colors.transparent : ArenaColors.borderHi,
          ),
        ),
        child: Text(
          label,
          style: ArenaText.body.copyWith(
            color: danger ? Colors.white : ArenaColors.bone,
            fontSize: 9,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

String _formatLabel(TournamentFormat f) {
  switch (f) {
    case TournamentFormat.singleElimination:
      return 'Élimination directe';
    case TournamentFormat.groupsThenKnockout:
      return 'Poules + KO';
    case TournamentFormat.roundRobin:
      return 'Round robin';
  }
}

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
