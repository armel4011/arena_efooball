import 'package:arena/core/theme/arena_theme.dart';
import 'package:arena/data/models/arena_match.dart';
import 'package:arena/data/models/match_status.dart';
import 'package:arena/data/repositories/match_stats_repository.dart';
import 'package:arena/features_shared/widgets/arena_app_bar.dart';
import 'package:arena/features_shared/widgets/arena_avatar.dart';
import 'package:arena/features_shared/widgets/arena_screen_background.dart';
import 'package:arena/features_shared/widgets/empty_state.dart';
import 'package:arena/features_shared/widgets/error_state.dart';
import 'package:arena/features_user/auth/auth_providers.dart';
import 'package:arena/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// `ArenaMatch` field reminder (see lib/data/models/arena_match.dart):
// player1Id, player2Id, score1, score2, winnerId, status, scheduledAt,
// startedAt, finishedAt. There's no `home/away` distinction at the row
// level — `homePlayerId` only marks who shares the room code.

/// Player match history with status filter chips.
///
/// Maps to screen #14 of `arena_v2.html`. Reached from `PlayerProfilePage`
/// "Voir tout l'historique". Shows the authenticated user's matches
/// across all competitions, filterable by outcome.
class MatchHistoryPage extends ConsumerStatefulWidget {
  const MatchHistoryPage({super.key});

  @override
  ConsumerState<MatchHistoryPage> createState() => _MatchHistoryPageState();
}

enum _Filter { all, wins, losses, ongoing }

class _MatchHistoryPageState extends ConsumerState<MatchHistoryPage> {
  _Filter _filter = _Filter.all;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final profile = ref.watch(currentProfileProvider).valueOrNull;
    if (profile == null) {
      return Scaffold(
        appBar: ArenaAppBar(title: l10n.matchHistoryAppBarLoadingTitle),
        body: const ArenaScreenBackground(
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    final matchesAsync = ref.watch(playerMatchHistoryProvider(profile.id));

    return Scaffold(
      appBar: ArenaAppBar(title: l10n.matchHistoryAppBarTitle),
      body: ArenaScreenBackground(
        child: SafeArea(
          child: matchesAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => ErrorState(
              description: l10n.matchHistoryError,
              onRetry: () =>
                  ref.invalidate(playerMatchHistoryProvider(profile.id)),
            ),
            data: (matches) {
              final counts = _countByFilter(matches, profile.id);
              return Column(
                children: [
                  const SizedBox(height: ArenaSpacing.sm),
                  _FilterChips(
                    current: _filter,
                    counts: counts,
                    onChanged: (f) => setState(() => _filter = f),
                  ),
                  const SizedBox(height: ArenaSpacing.sm),
                  Expanded(
                    child: _MatchList(
                      matches: _applyFilter(matches, profile.id, _filter),
                      selfId: profile.id,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  /// Compte les matches dans chaque bucket — affiché en suffixe `· N`
  /// dans les chips de filtre. Reproduit `ALL · 54 / W · 42 / L · 12`
  /// de la maquette.
  Map<_Filter, int> _countByFilter(List<ArenaMatch> all, String selfId) {
    return {
      _Filter.all: all.length,
      _Filter.wins: all.where((m) => m.winnerId == selfId).length,
      _Filter.losses: all
          .where(
            (m) =>
                m.status == MatchStatus.completed &&
                m.winnerId != null &&
                m.winnerId != selfId,
          )
          .length,
      _Filter.ongoing: all
          .where(
            (m) =>
                m.status == MatchStatus.scheduled ||
                m.status == MatchStatus.ready ||
                m.status == MatchStatus.inProgress ||
                m.status == MatchStatus.scorePending ||
                m.status == MatchStatus.awaitingValidation ||
                m.status == MatchStatus.disputed,
          )
          .length,
    };
  }

  List<ArenaMatch> _applyFilter(
    List<ArenaMatch> all,
    String selfId,
    _Filter filter,
  ) {
    return switch (filter) {
      _Filter.all => all,
      _Filter.wins => all.where((m) => m.winnerId == selfId).toList(),
      _Filter.losses => all
          .where(
            (m) =>
                m.status == MatchStatus.completed &&
                m.winnerId != null &&
                m.winnerId != selfId,
          )
          .toList(),
      _Filter.ongoing => all
          .where(
            (m) =>
                m.status == MatchStatus.scheduled ||
                m.status == MatchStatus.ready ||
                m.status == MatchStatus.inProgress ||
                m.status == MatchStatus.scorePending ||
                m.status == MatchStatus.awaitingValidation ||
                m.status == MatchStatus.disputed,
          )
          .toList(),
    };
  }
}

class _FilterChips extends StatelessWidget {
  const _FilterChips({
    required this.current,
    required this.counts,
    required this.onChanged,
  });

  final _Filter current;
  final Map<_Filter, int> counts;
  final ValueChanged<_Filter> onChanged;

  static const _options = <(_Filter, Color)>[
    (_Filter.all, ArenaColors.signalBlue),
    (_Filter.wins, ArenaColors.statusOk),
    (_Filter.losses, ArenaColors.neonRed),
    (_Filter.ongoing, ArenaColors.statusWarn),
  ];

  String _labelFor(_Filter f, AppLocalizations l10n) => switch (f) {
        _Filter.all => l10n.matchHistoryFilterAll,
        _Filter.wins => l10n.matchHistoryFilterWins,
        _Filter.losses => l10n.matchHistoryFilterLosses,
        _Filter.ongoing => l10n.matchHistoryFilterOngoing,
      };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SizedBox(
      height: 36,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: ArenaSpacing.lg),
        children: [
          for (final (f, accent) in _options) ...[
            _Chip(
              label: _labelFor(f, l10n),
              count: counts[f] ?? 0,
              accent: accent,
              active: f == current,
              onTap: () => onChanged(f),
            ),
            const SizedBox(width: ArenaSpacing.sm),
          ],
        ],
      ),
    );
  }
}

/// Chip de filtre avec count `· N` (style maquette `ALL · 54`). Quand
/// actif : fond `accent @ 18 %` + border accent, sinon carbon neutre.
class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.count,
    required this.accent,
    required this.active,
    required this.onTap,
  });

  final String label;
  final int count;
  final Color accent;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(ArenaRadius.round),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: active ? accent.withValues(alpha: 0.18) : ArenaColors.carbon,
          borderRadius: BorderRadius.circular(ArenaRadius.round),
          border: Border.all(
            color: active ? accent : ArenaColors.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: ArenaText.button.copyWith(
                color: active ? accent : ArenaColors.silver,
                fontSize: 12,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              '· $count',
              style: ArenaText.mono.copyWith(
                color: active ? accent : ArenaColors.silver,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MatchList extends StatelessWidget {
  const _MatchList({required this.matches, required this.selfId});

  final List<ArenaMatch> matches;
  final String selfId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (matches.isEmpty) {
      return EmptyState(
        title: l10n.matchHistoryEmptyTitle,
        description: l10n.matchHistoryEmptyDescription,
        icon: Icons.history,
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.symmetric(
        horizontal: ArenaSpacing.lg,
        vertical: ArenaSpacing.sm,
      ),
      itemCount: matches.length,
      separatorBuilder: (_, __) => const SizedBox(height: ArenaSpacing.sm),
      itemBuilder: (_, i) => _MatchCard(match: matches[i], selfId: selfId)
          .animate(delay: (i * 40).ms)
          .fadeIn(duration: ArenaDurations.short),
    );
  }
}

/// Card de match dans l'historique — reproduit `.m-card-success` /
/// `.m-card-danger` de la maquette : fond `accent @ 6 %`, border
/// `accent @ 35 %`, avatar adversaire + nom + jeu/date à gauche, score
/// final en `bigNumber` à droite (couleur accent). Quand le match n'est
/// pas terminé, l'icône horloge remplace le score.
class _MatchCard extends StatelessWidget {
  const _MatchCard({required this.match, required this.selfId});

  final ArenaMatch match;
  final String selfId;

  bool get _selfIsP1 => match.player1Id == selfId;

  String get _opponentLabel {
    final id = _selfIsP1 ? match.player2Id : match.player1Id;
    if (id == null) return 'Adversaire';
    return 'Joueur ${id.substring(0, id.length.clamp(0, 6))}…';
  }

  ({int self, int opp})? get _scores {
    final s1 = match.score1;
    final s2 = match.score2;
    if (s1 == null || s2 == null) return null;
    return _selfIsP1 ? (self: s1, opp: s2) : (self: s2, opp: s1);
  }

  /// Couleur d'accent de la card — vert pour victoire, rouge pour
  /// défaite, signalBlue pour les matches en cours, silver pour nul ou
  /// indéterminé. Sert à la fois pour le fond, la border et le score.
  Color get _accent {
    if (match.status != MatchStatus.completed) {
      if (match.status == MatchStatus.disputed) return ArenaColors.statusWarn;
      return ArenaColors.signalBlue;
    }
    if (match.winnerId == null) return ArenaColors.silver;
    return match.winnerId == selfId
        ? ArenaColors.statusOk
        : ArenaColors.neonRed;
  }

  @override
  Widget build(BuildContext context) {
    final scores = _scores;
    final accent = _accent;
    return Container(
      padding: const EdgeInsets.all(ArenaSpacing.md),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(ArenaRadius.lg),
        border: Border.all(color: accent.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          ArenaAvatar(
            initials: _opponentLabel.length >= 2
                ? _opponentLabel.substring(0, 2).toUpperCase()
                : 'A',
            size: ArenaAvatarSize.sm,
          ),
          const SizedBox(width: ArenaSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'vs $_opponentLabel',
                  style: ArenaText.body.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  _formatDate(match.scheduledAt ?? match.createdAt),
                  style: ArenaText.small.copyWith(color: ArenaColors.silver),
                ),
              ],
            ),
          ),
          const SizedBox(width: ArenaSpacing.sm),
          if (scores != null)
            Text(
              '${scores.self}-${scores.opp}',
              style: ArenaText.mono.copyWith(
                color: accent,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            )
          else
            Icon(
              Icons.schedule,
              size: 24,
              color: accent.withValues(alpha: 0.8),
            ),
        ],
      ),
    );
  }
}

String _formatDate(DateTime? d) {
  if (d == null) return '';
  final mm = d.month.toString().padLeft(2, '0');
  final dd = d.day.toString().padLeft(2, '0');
  return '$dd/$mm/${d.year}';
}
