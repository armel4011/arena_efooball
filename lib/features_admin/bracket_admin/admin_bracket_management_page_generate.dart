part of 'admin_bracket_management_page.dart';

// ─────────────────────────────────────────────────────────────────────
// Génération du bracket (état vide + config poules)
// ─────────────────────────────────────────────────────────────────────

class _EmptyState extends ConsumerStatefulWidget {
  const _EmptyState({required this.competition});
  final Competition competition;

  @override
  ConsumerState<_EmptyState> createState() => _EmptyStateState();
}

class _EmptyStateState extends ConsumerState<_EmptyState> {
  bool _generating = false;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(ArenaSpacing.lg),
      children: [
        Container(
          padding: const EdgeInsets.all(ArenaSpacing.lg),
          decoration: arenaGlowCardDecoration(),
          child: Column(
            children: [
              Text(
                'Aucun bracket pour cette compétition.',
                style: ArenaText.body,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: ArenaSpacing.xs),
              Text(
                'Format : ${_formatLabel(widget.competition.format)} · '
                'Inscrits ${widget.competition.currentPlayers}/${widget.competition.maxPlayers}',
                style: ArenaText.bodyMuted,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        const SizedBox(height: ArenaSpacing.lg),
        if (_generating)
          const Center(child: CircularProgressIndicator())
        else
          ArenaButton(
            label: '🏆 GÉNÉRER LE BRACKET',
            fullWidth: true,
            onPressed: _confirmGenerate,
          ),
        const SizedBox(height: ArenaSpacing.md),
        Container(
          padding: const EdgeInsets.all(ArenaSpacing.md),
          decoration: arenaWarningCardDecoration(),
          child: Text(
            "L'opération est irréversible côté joueurs : les matchs "
            'seront créés et chaque joueur inscrit reçoit son premier '
            'adversaire.',
            style: ArenaText.body,
          ),
        ),
      ],
    );
  }

  Future<void> _confirmGenerate() async {
    final adminId = ref.read(currentSessionProvider)?.user.id;
    if (adminId == null) return;

    // Pull the player list first so we can show how many slots we'll seed.
    final repo = ref.read(adminBracketRepositoryProvider);
    final players =
        await repo.listConfirmedRegistrations(widget.competition.id);
    if (!mounted) return;
    if (players.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${players.length} joueurs inscrits — minimum 2.'),
        ),
      );
      return;
    }

    final extra = await _maybeAskGroupsConfig();
    if (!mounted) return;
    if (extra == null &&
        widget.competition.format == TournamentFormat.groupsThenKnockout) {
      return;
    }

    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: ArenaColors.carbon,
        title: Text('Générer le bracket ?', style: ArenaText.h3),
        content: Text(
          'Crée le bracket avec ${players.length} joueurs. '
          'Action irréversible.',
          style: ArenaText.bodyMuted,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(c).pop(false),
            child: const Text('ANNULER'),
          ),
          TextButton(
            onPressed: () => Navigator.of(c).pop(true),
            style: TextButton.styleFrom(foregroundColor: ArenaColors.statusOk),
            child: const Text('GÉNÉRER'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => _generating = true);

    try {
      switch (widget.competition.format) {
        case TournamentFormat.singleElimination:
          await repo.generateSingleElim(
            competitionId: widget.competition.id,
            playerIds: players,
            thirdPlace: widget.competition.thirdPlaceMatch,
          );
        case TournamentFormat.roundRobin:
          await repo.generateRoundRobinTournament(
            competitionId: widget.competition.id,
            playerIds: players,
          );
        case TournamentFormat.groupsThenKnockout:
          await repo.generateGroupsKnockoutTournament(
            competitionId: widget.competition.id,
            playerIds: players,
            groupCount: extra!.groupCount,
            qualifiersPerGroup: extra.qualifiers,
            thirdPlace: widget.competition.thirdPlaceMatch,
          );
      }
      await ref.read(adminAuditLogRepositoryProvider).record(
        adminId: adminId,
        action: 'bracket_generated',
        targetType: 'competition',
        targetId: widget.competition.id,
        afterState: {
          'format': widget.competition.format.value,
          'players': players.length,
        },
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Échec : ${arenaErrorMessage(e)}')),
      );
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  Future<_GroupsConfig?> _maybeAskGroupsConfig() async {
    if (widget.competition.format != TournamentFormat.groupsThenKnockout) {
      return _GroupsConfig.empty;
    }
    final groupsCtrl = TextEditingController(text: '4');
    final qualCtrl = TextEditingController(text: '2');
    final out = await showDialog<_GroupsConfig>(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: ArenaColors.carbon,
        title: Text('Config poules', style: ArenaText.h3),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ArenaTextField(
              controller: groupsCtrl,
              hint: 'Nombre de poules',
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
            const SizedBox(height: ArenaSpacing.sm),
            ArenaTextField(
              controller: qualCtrl,
              hint: 'Qualifiés par poule',
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
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
              final g = int.tryParse(groupsCtrl.text) ?? 0;
              final q = int.tryParse(qualCtrl.text) ?? 0;
              if (g < 2 || q < 1) return;
              Navigator.of(c).pop(_GroupsConfig(g, q));
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      groupsCtrl.dispose();
      qualCtrl.dispose();
    });
    return out;
  }
}

class _GroupsConfig {
  const _GroupsConfig(this.groupCount, this.qualifiers);
  final int groupCount;
  final int qualifiers;
  static const empty = _GroupsConfig(0, 0);
}
