import 'package:arena/core/theme/arena_theme.dart';
import 'package:arena/data/models/arena_match.dart';
import 'package:arena/data/models/match_status.dart';
import 'package:arena/data/repositories/match_stats_repository.dart';
import 'package:arena/features_shared/widgets/arena_app_bar.dart';
import 'package:arena/features_shared/widgets/arena_avatar.dart';
import 'package:arena/features_shared/widgets/arena_badge.dart';
import 'package:arena/features_shared/widgets/arena_screen_background.dart';
import 'package:arena/features_shared/widgets/empty_state.dart';
import 'package:arena/features_shared/widgets/error_state.dart';
import 'package:arena/features_user/auth/auth_providers.dart';
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
    final profile = ref.watch(currentProfileProvider).valueOrNull;
    if (profile == null) {
      return const Scaffold(
        appBar: ArenaAppBar(title: 'Historique'),
        body: ArenaScreenBackground(
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    final matchesAsync = ref.watch(playerMatchHistoryProvider(profile.id));

    return Scaffold(
      appBar: const ArenaAppBar(title: 'Historique'),
      body: ArenaScreenBackground(
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: ArenaSpacing.sm),
              _FilterChips(
                current: _filter,
                onChanged: (f) => setState(() => _filter = f),
              ),
              const SizedBox(height: ArenaSpacing.sm),
              Expanded(
                child: matchesAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (err, _) => ErrorState(
                    description: 'Impossible de charger ton historique. '
                        'Vérifie ta connexion.',
                    onRetry: () =>
                        ref.invalidate(playerMatchHistoryProvider(profile.id)),
                  ),
                  data: (matches) => _MatchList(
                    matches: _applyFilter(matches, profile.id, _filter),
                    selfId: profile.id,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
  const _FilterChips({required this.current, required this.onChanged});

  final _Filter current;
  final ValueChanged<_Filter> onChanged;

  static const _options = <(_Filter, String)>[
    (_Filter.all, 'Tous'),
    (_Filter.wins, 'Victoires'),
    (_Filter.losses, 'Défaites'),
    (_Filter.ongoing, 'En cours'),
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: ArenaSpacing.lg),
        children: [
          for (final (f, label) in _options) ...[
            _Chip(
              label: label,
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

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.active, required this.onTap});

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(ArenaRadius.round),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: active
              ? ArenaColors.signalBlue.withValues(alpha: 0.18)
              : ArenaColors.carbon,
          borderRadius: BorderRadius.circular(ArenaRadius.round),
          border: Border.all(
            color: active ? ArenaColors.signalBlue : ArenaColors.border,
          ),
        ),
        child: Text(
          label,
          style: ArenaText.button.copyWith(
            color: active ? ArenaColors.signalBlue : ArenaColors.silver,
          ),
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
    if (matches.isEmpty) {
      return const EmptyState(
        title: 'Aucun match',
        description: 'Tes matchs apparaîtront ici dès la première compétition.',
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

  ArenaBadgeVariant get _statusVariant {
    if (match.status != MatchStatus.completed) {
      return match.status == MatchStatus.disputed
          ? ArenaBadgeVariant.warn
          : ArenaBadgeVariant.info;
    }
    if (match.winnerId == null) return ArenaBadgeVariant.neutral;
    return match.winnerId == selfId
        ? ArenaBadgeVariant.success
        : ArenaBadgeVariant.danger;
  }

  String get _statusLabel {
    if (match.status == MatchStatus.disputed) return 'Litige';
    if (match.status == MatchStatus.scheduled) return 'À venir';
    if (match.status == MatchStatus.inProgress) return 'En cours';
    if (match.status == MatchStatus.ready) return 'Prêt';
    if (match.status != MatchStatus.completed) return 'En attente';
    if (match.winnerId == null) return 'Nul';
    return match.winnerId == selfId ? 'Victoire' : 'Défaite';
  }

  @override
  Widget build(BuildContext context) {
    final scores = _scores;
    return Container(
      padding: const EdgeInsets.all(ArenaSpacing.md),
      decoration: BoxDecoration(
        color: ArenaColors.carbon,
        borderRadius: BorderRadius.circular(ArenaRadius.lg),
        border: Border.all(color: ArenaColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ArenaBadge(label: _statusLabel, variant: _statusVariant),
              const Spacer(),
              Text(
                _formatDate(match.scheduledAt ?? match.createdAt),
                style: ArenaText.small,
              ),
            ],
          ),
          const SizedBox(height: ArenaSpacing.sm),
          Row(
            children: [
              ArenaAvatar(
                initials: _opponentLabel.substring(0, 2).toUpperCase(),
                size: ArenaAvatarSize.sm,
              ),
              const SizedBox(width: ArenaSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_opponentLabel, style: ArenaText.h3),
                    Text(
                      'Match #${match.id.substring(0, match.id.length.clamp(0, 8))}',
                      style: ArenaText.small,
                    ),
                  ],
                ),
              ),
              if (scores != null)
                Text(
                  '${scores.self} – ${scores.opp}',
                  style: ArenaText.bigNumber.copyWith(
                    color: switch (_statusVariant) {
                      ArenaBadgeVariant.success => ArenaColors.statusOk,
                      ArenaBadgeVariant.danger => ArenaColors.neonRed,
                      _ => ArenaColors.bone,
                    },
                  ),
                )
              else
                const Icon(
                  Icons.schedule,
                  size: 28,
                  color: ArenaColors.silverDim,
                ),
            ],
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
