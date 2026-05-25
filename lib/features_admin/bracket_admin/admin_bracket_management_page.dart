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
import 'package:arena/features_shared/auth_common/shared_auth_providers.dart';
import 'package:arena/features_shared/widgets/arena_app_bar.dart';
import 'package:arena/features_shared/widgets/arena_avatar.dart';
import 'package:arena/features_shared/widgets/arena_badge.dart';
import 'package:arena/features_shared/widgets/arena_button.dart';
import 'package:arena/features_shared/widgets/arena_screen_background.dart';
import 'package:arena/features_shared/widgets/arena_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// PHASE 11 · A11 — admin bracket management.
///
/// If no matches yet → "Generate bracket" CTA (single-elim / round-robin
/// / groups+KO). Once matches exist → grouped-by-round list with admin
/// actions per match (verdict, cancel, toggle streaming). The
/// underlying generators are pure Dart ([lib/core/utils/bracket_generators/]);
/// the persist step lives in [AdminBracketRepository].
///
/// Maps to screen A11 of `arena_v2.html`.
class AdminBracketManagementPage extends ConsumerWidget {
  const AdminBracketManagementPage({
    required this.competitionId,
    super.key,
  });

  final String competitionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final compAsync = ref.watch(competitionByIdProvider(competitionId));
    final matchesAsync = ref.watch(competitionMatchesProvider(competitionId));

    return Scaffold(
      appBar: const ArenaAppBar(title: 'Gestion bracket'),
      body: ArenaScreenBackground(
        accent: ArenaColors.neonRed,
        child: SafeArea(
          child: compAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Padding(
              padding: const EdgeInsets.all(ArenaSpacing.lg),
              child: Text('Erreur : $e', style: ArenaText.bodyMuted),
            ),
            data: (comp) {
              if (comp == null) return const SizedBox.shrink();
              return matchesAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) =>
                    Text('Erreur : $e', style: ArenaText.bodyMuted),
                data: (matches) => matches.isEmpty
                    ? _EmptyState(competition: comp)
                    : _BracketView(competition: comp, matches: matches),
              );
            },
          ),
        ),
      ),
    );
  }
}

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

class _BracketView extends StatelessWidget {
  const _BracketView({required this.competition, required this.matches});

  final Competition competition;
  final List<ArenaMatch> matches;

  @override
  Widget build(BuildContext context) {
    // Group by round.
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
