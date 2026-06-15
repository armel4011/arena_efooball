part of 'desktop_competition_detail_page.dart';

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
            const InfoBar(
              title: Text('Classement automatique'),
              content: Text(
                'Le classement final est calculé et publié automatiquement '
                'dès que tous les matchs sont terminés. Ce bouton le recalcule '
                'à la demande ; le menu déroulant permet un ajustement manuel.',
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                FilledButton(
                  onPressed: () => _autoRank(context, ref),
                  child: const Text('Recalculer'),
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
        title: const Text('Recalculer le classement ?'),
        content: const Text(
          'Les rangs seront recalculés côté serveur — le MÊME classement que '
          'celui publié automatiquement à la clôture de la compétition '
          '(champion, finaliste, classement de poule…). Cela écrase les rangs '
          'saisis manuellement.',
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
          icon: FluentIcons.pinned,
          label: c.isPinned
              ? 'Désépingler (retirer de la une)'
              : 'Épingler à la une',
          onPressed: () => _togglePinned(context, ref),
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

  Future<void> _togglePinned(BuildContext context, WidgetRef ref) async {
    final adminId = ref.read(currentSessionProvider)?.user.id;
    if (adminId == null) {
      await _showError(context, 'Session admin introuvable.');
      return;
    }
    final willPin = !competition.isPinned;
    try {
      await ref.read(adminCompetitionsRepositoryProvider).setPinned(
            competitionId: competition.id,
            pinned: willPin,
            adminId: adminId,
          );
      if (!context.mounted) return;
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
