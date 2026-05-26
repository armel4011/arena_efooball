import 'package:arena/core/theme/arena_theme.dart';
import 'package:arena/data/models/arena_match.dart';
import 'package:arena/data/models/match_status.dart';
import 'package:arena/data/repositories/admin/admin_matches_repository.dart';
import 'package:arena/features_shared/widgets/arena_app_bar.dart';
import 'package:arena/features_shared/widgets/arena_avatar.dart';
import 'package:arena/features_shared/widgets/arena_badge.dart';
import 'package:arena/features_shared/widgets/arena_filter_menu.dart';
import 'package:arena/features_shared/widgets/arena_screen_background.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

/// PHASE 11 · A10 — global admin matches list with status filters.
///
/// Reads `matches` realtime via [adminMatchesProvider]. Lot C.1 : la
/// rangée de chips status inline a été remplacée par `ArenaFilterMenu`
/// (radio, défaut = Tous). Tap a card → not yet wired (admin still uses
/// the bracket page for verdicts in V1.0).
///
/// Maps to screen A10 of `arena_v2.html`.
class AdminMatchesListPage extends ConsumerStatefulWidget {
  const AdminMatchesListPage({super.key});

  @override
  ConsumerState<AdminMatchesListPage> createState() =>
      _AdminMatchesListPageState();
}

class _AdminMatchesListPageState extends ConsumerState<AdminMatchesListPage> {
  _MatchesFilter _filter = _MatchesFilter.all;

  @override
  Widget build(BuildContext context) {
    final list = ref.watch(
      adminMatchesProvider(
        AdminMatchesFilter(status: _filter.status),
      ),
    );

    return Scaffold(
      appBar: ArenaAppBar(
        title: 'MATCHS',
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: ArenaColors.silver),
            onPressed: () {},
          ),
        ],
      ),
      body: ArenaScreenBackground(
        accent: ArenaColors.neonRed,
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(ArenaSpacing.lg),
            children: [
              Row(
                children: [
                  ArenaFilterMenu(
                    activeCount: _filter == _MatchesFilter.all ? 0 : 1,
                    sections: _buildSections(),
                    initialSelection: {
                      'status': _filter == _MatchesFilter.all
                          ? const []
                          : [_filter.name],
                    },
                    onApply: _applySelection,
                  ),
                  const Spacer(),
                  if (_filter != _MatchesFilter.all)
                    TextButton(
                      onPressed: () =>
                          setState(() => _filter = _MatchesFilter.all),
                      child: Text(
                        'Réinitialiser',
                        style: ArenaText.small.copyWith(
                          color: ArenaColors.signalBlue,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: ArenaSpacing.md),
              list.when(
                loading: () => const Padding(
                  padding: EdgeInsets.all(ArenaSpacing.lg),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (e, _) => Padding(
                  padding: const EdgeInsets.all(ArenaSpacing.md),
                  child: Text(
                    'Erreur de chargement : $e',
                    style: ArenaText.bodyMuted,
                  ),
                ),
                data: (matches) => matches.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.all(ArenaSpacing.lg),
                        child: Text(
                          'Aucun match pour ce filtre.',
                          style: ArenaText.bodyMuted,
                          textAlign: TextAlign.center,
                        ),
                      )
                    : Column(
                        children: [
                          for (final m in matches) ...[
                            _MatchCard(match: m),
                            const SizedBox(height: ArenaSpacing.sm),
                          ],
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<ArenaFilterSection> _buildSections() {
    return [
      ArenaFilterSection(
        id: 'status',
        title: 'Statut',
        mode: ArenaFilterMode.radio,
        options: [
          // On omet `all` : empty selection = "tous".
          for (final f in _MatchesFilter.values.where(
            (e) => e != _MatchesFilter.all,
          ))
            ArenaFilterOption(id: f.name, label: f.label),
        ],
      ),
    ];
  }

  void _applySelection(Map<String, List<String>> selection) {
    final id = selection['status']?.firstOrNull;
    setState(() {
      _filter = id == null
          ? _MatchesFilter.all
          : _MatchesFilter.values.firstWhere((f) => f.name == id);
    });
  }
}

enum _MatchesFilter {
  all('Tous', null),
  pending('Pending', MatchStatus.pending),
  inProgress('En cours', MatchStatus.inProgress),
  disputed('Disputed', MatchStatus.disputed),
  completed('Validés', MatchStatus.completed);

  const _MatchesFilter(this.label, this.status);
  final String label;
  final MatchStatus? status;
}

class _MatchCard extends StatelessWidget {
  const _MatchCard({required this.match});
  final ArenaMatch match;

  @override
  Widget build(BuildContext context) {
    final visual = _visualFor(match.status);
    return Container(
      padding: const EdgeInsets.all(ArenaSpacing.md),
      decoration: BoxDecoration(
        color: ArenaColors.carbon,
        border: Border(
          top: const BorderSide(color: ArenaColors.border),
          right: const BorderSide(color: ArenaColors.border),
          bottom: const BorderSide(color: ArenaColors.border),
          left: BorderSide(color: visual.color, width: 3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ArenaBadge(label: visual.label, variant: visual.variant),
              const Spacer(),
              Text(
                'M-${match.id.substring(0, 6).toUpperCase()}',
                style: ArenaText.monoSmall,
              ),
            ],
          ),
          const SizedBox(height: ArenaSpacing.sm),
          _Players(match: match),
          const SizedBox(height: ArenaSpacing.xs),
          Text(
            _footText(match),
            style: ArenaText.bodyMuted.copyWith(color: visual.footColor),
          ),
        ],
      ),
    ).animate().fadeIn(duration: ArenaDurations.medium);
  }
}

class _Players extends StatelessWidget {
  const _Players({required this.match});
  final ArenaMatch match;

  @override
  Widget build(BuildContext context) {
    final homeShort = _shortId(match.player1Id);
    final awayShort = _shortId(match.player2Id);

    return Row(
      children: [
        ArenaAvatar(
          initials: homeShort.isEmpty ? '?' : homeShort[0],
          color: ArenaAvatarColor.blue,
          size: ArenaAvatarSize.sm,
        ),
        const SizedBox(width: ArenaSpacing.xs),
        Text(homeShort.isEmpty ? 'TBD' : homeShort, style: ArenaText.body),
        const Spacer(),
        Text(
          _scoreText(match),
          style: ArenaText.mono.copyWith(fontWeight: FontWeight.w700),
        ),
        const Spacer(),
        Text(awayShort.isEmpty ? 'TBD' : awayShort, style: ArenaText.body),
        const SizedBox(width: ArenaSpacing.xs),
        ArenaAvatar(
          initials: awayShort.isEmpty ? '?' : awayShort[0],
          color: ArenaAvatarColor.green,
          size: ArenaAvatarSize.sm,
        ),
      ],
    );
  }

  static String _shortId(String? id) {
    if (id == null || id.length < 6) return '';
    return id.substring(0, 6);
  }
}

String _scoreText(ArenaMatch m) {
  final s1 = m.score1;
  final s2 = m.score2;
  if (s1 == null && s2 == null) return '— —';
  if (m.status == MatchStatus.disputed) return '${s1 ?? '?'} / ${s2 ?? '?'}';
  return '${s1 ?? 0} - ${s2 ?? 0}';
}

String _footText(ArenaMatch m) {
  switch (m.status) {
    case MatchStatus.disputed:
      return '⚠ Désaccord sur score';
    case MatchStatus.inProgress:
    case MatchStatus.scorePending:
      final started = m.startedAt;
      if (started == null) return 'En cours';
      final elapsed = DateTime.now().difference(started).inMinutes;
      return "En cours · $elapsed'";
    case MatchStatus.completed:
      final finished = m.finishedAt;
      if (finished == null) return 'Terminé';
      final diff = DateTime.now().difference(finished);
      if (diff.inHours < 24) return 'Il y a ${diff.inHours}h';
      return DateFormat('dd/MM').format(finished);
    case MatchStatus.scheduled:
    case MatchStatus.pending:
    case MatchStatus.ready:
      final scheduled = m.scheduledAt;
      if (scheduled == null) return 'En attente';
      return 'Démarre ${DateFormat('dd/MM HH:mm').format(scheduled)}';
    case MatchStatus.cancelled:
      return 'Annulé';
    case MatchStatus.forfeited:
      return 'Forfait';
    case MatchStatus.awaitingValidation:
      return 'En attente de validation';
  }
}

class _StatusVisual {
  const _StatusVisual({
    required this.label,
    required this.variant,
    required this.color,
    this.footColor,
  });
  final String label;
  final ArenaBadgeVariant variant;
  final Color color;
  final Color? footColor;
}

_StatusVisual _visualFor(MatchStatus status) {
  switch (status) {
    case MatchStatus.inProgress:
    case MatchStatus.scorePending:
      return const _StatusVisual(
        label: 'EN COURS',
        variant: ArenaBadgeVariant.live,
        color: ArenaColors.neonRed,
      );
    case MatchStatus.disputed:
      return const _StatusVisual(
        label: 'DISPUTED',
        variant: ArenaBadgeVariant.warn,
        color: ArenaColors.statusWarn,
        footColor: ArenaColors.statusWarn,
      );
    case MatchStatus.completed:
      return const _StatusVisual(
        label: 'VALIDÉ',
        variant: ArenaBadgeVariant.success,
        color: ArenaColors.statusOk,
      );
    case MatchStatus.cancelled:
    case MatchStatus.forfeited:
      return const _StatusVisual(
        label: 'ANNULÉ',
        variant: ArenaBadgeVariant.neutral,
        color: ArenaColors.silver,
      );
    case MatchStatus.awaitingValidation:
      return const _StatusVisual(
        label: 'VALIDATION',
        variant: ArenaBadgeVariant.warn,
        color: ArenaColors.statusWarn,
      );
    case MatchStatus.pending:
    case MatchStatus.scheduled:
    case MatchStatus.ready:
      return const _StatusVisual(
        label: 'PENDING',
        variant: ArenaBadgeVariant.info,
        color: ArenaColors.border,
      );
  }
}
