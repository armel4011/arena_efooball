part of 'desktop_competition_detail_page.dart';

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
              _InfoRow(
                label: 'À la une',
                value: c.isPinned ? '📌 Épinglée' : 'Non épinglée',
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
