part of 'desktop_bracket_page.dart';

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
          backgroundColor: hovered ? ArenaColors.carbon2 : ArenaColors.carbon,
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
            const SizedBox(height: 16),
            _RescheduleSection(match: match),
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

/// Section « Horaire » du dialog de match — desktop.
///
/// Le desktop n'avait AUCUN moyen de changer un horaire : `reschedule` n'existait
/// que côté mobile, alors que l'admin desktop gère le même bracket (parité
/// mobile/desktop, audit 2026-07-13).
///
/// Deux portées, volontairement distinctes :
///   * « Replanifier ce match » — décale ce seul match ;
///   * « Décaler tout le round N » — décale tous les matchs NON DÉMARRÉS du
///     round (leur unité de planification) ET **notifie les inscrits**.
class _RescheduleSection extends ConsumerStatefulWidget {
  const _RescheduleSection({required this.match});

  final ArenaMatch match;

  @override
  ConsumerState<_RescheduleSection> createState() => _RescheduleSectionState();
}

class _RescheduleSectionState extends ConsumerState<_RescheduleSection> {
  late DateTime _slot = widget.match.scheduledAt?.toLocal() ??
      DateTime.now().add(const Duration(hours: 1));
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final round = widget.match.round;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InfoLabel(
          label: 'Horaire',
          child: Row(
            children: [
              Expanded(
                child: DatePicker(
                  selected: _slot,
                  onChanged: (d) => setState(
                    () => _slot = DateTime(
                      d.year,
                      d.month,
                      d.day,
                      _slot.hour,
                      _slot.minute,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TimePicker(
                  selected: _slot,
                  onChanged: (t) => setState(
                    () => _slot = DateTime(
                      _slot.year,
                      _slot.month,
                      _slot.day,
                      t.hour,
                      t.minute,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        if (_busy)
          const Center(child: ProgressRing())
        else
          Row(
            children: [
              Expanded(
                child: Button(
                  onPressed: _rescheduleMatch,
                  child: const Text('Replanifier ce match'),
                ),
              ),
              if (round != null) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: Button(
                    onPressed: _rescheduleRound,
                    child: Text('Décaler le round $round'),
                  ),
                ),
              ],
            ],
          ),
      ],
    );
  }

  Future<void> _rescheduleMatch() async {
    final adminId = ref.read(currentSessionProvider)?.user.id;
    if (adminId == null) return;
    setState(() => _busy = true);
    try {
      await ref.read(adminMatchesRepositoryProvider).reschedule(
            matchId: widget.match.id,
            scheduledAt: _slot,
          );
      await ref.read(adminAuditLogRepositoryProvider).record(
        adminId: adminId,
        action: 'match_rescheduled',
        targetType: 'match',
        targetId: widget.match.id,
        afterState: {
          'scheduled_at': _slot.toUtc().toIso8601String(),
          'from': 'desktop_bracket',
        },
      );
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      await _showError(e);
    }
  }

  Future<void> _rescheduleRound() async {
    final adminId = ref.read(currentSessionProvider)?.user.id;
    final round = widget.match.round;
    if (adminId == null || round == null) return;
    setState(() => _busy = true);
    try {
      final notified =
          await ref.read(adminMatchesRepositoryProvider).rescheduleRound(
                competitionId: widget.match.competitionId,
                round: round,
                scheduledAt: _slot,
              );
      await ref.read(adminAuditLogRepositoryProvider).record(
        adminId: adminId,
        action: 'round_rescheduled',
        targetType: 'competition',
        targetId: widget.match.competitionId,
        afterState: {
          'round': round,
          'scheduled_at': _slot.toUtc().toIso8601String(),
          'notified': notified,
        },
      );
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      await _showError(e);
    }
  }

  Future<void> _showError(Object e) async {
    if (!mounted) return;
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
