import 'package:arena/core/router/user_router.dart';
import 'package:arena/core/theme/arena_theme.dart';
import 'package:arena/core/utils/arena_error_message.dart';
import 'package:arena/data/models/arena_match.dart';
import 'package:arena/data/models/competition.dart';
import 'package:arena/data/models/match_status.dart';
import 'package:arena/data/models/profile.dart';
import 'package:arena/data/repositories/chat_repository.dart';
import 'package:arena/data/repositories/competition_repository.dart';
import 'package:arena/data/repositories/match_repository.dart';
import 'package:arena/data/repositories/profile_repository.dart';
import 'package:arena/features_shared/auth_common/shared_auth_providers.dart';
import 'package:arena/features_shared/widgets/arena_app_bar.dart';
import 'package:arena/features_shared/widgets/arena_avatar.dart';
import 'package:arena/features_shared/widgets/empty_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Global messages inbox.
///
/// Two tabs :
///   * **DIRECT** — chats 1v1 attachés à un match (réel : `myAllMatchesProvider`).
///     L'utilisateur voit la liste de ses matchs récents avec l'opponent
///     hydraté ; tap → `/chat/match/:id`.
///   * **COMPÉTITIONS** — liste des compétitions où le joueur est inscrit
///     (intersection `myRegisteredCompetitionIdsProvider` + comp list).
///
/// Used both as the Chat tab inside `MainLayout` (no AppBar — host
/// supplies it) and as a stand-alone route at `/messages`.
///
/// Maps to screen #15 of `arena_v2.html`.
class MessagesInboxPage extends StatelessWidget {
  const MessagesInboxPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      appBar: ArenaAppBar(
        title: 'MESSAGES',
        actions: [InboxComposeAction()],
      ),
      body: MessagesInboxBody(),
    );
  }
}

/// AppBar-less inbox body, suitable for embedding inside a parent
/// Scaffold (the user app's `MainLayout` already supplies the AppBar
/// + bottom nav).
class MessagesInboxBody extends StatelessWidget {
  const MessagesInboxBody({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: SafeArea(
        child: Column(
          children: [
            const _InboxTabs(),
            Expanded(
              child: TabBarView(
                children: [
                  const _DirectTab().animate().fadeIn(
                        duration: ArenaDurations.medium,
                      ),
                  const _CompetitionsTab().animate().fadeIn(
                        duration: ArenaDurations.medium,
                      ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Compose-button shown in the inbox AppBar. Ouvre la recherche d'amis
/// (point d'entrée pour démarrer une nouvelle interaction).
class InboxComposeAction extends StatelessWidget {
  const InboxComposeAction({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Rechercher un joueur',
      icon: const Icon(Icons.edit_outlined, color: ArenaColors.gameEfoot),
      onPressed: () => context.push(UserRoutes.friendsSearch),
    );
  }
}

class _InboxTabs extends StatelessWidget {
  const _InboxTabs();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        ArenaSpacing.lg,
        0,
        ArenaSpacing.lg,
        ArenaSpacing.md,
      ),
      child: TabBar(
        labelStyle: ArenaText.button,
        unselectedLabelStyle: ArenaText.button,
        labelColor: ArenaColors.bone,
        unselectedLabelColor: ArenaColors.silver,
        indicatorColor: ArenaColors.signalBlue,
        indicatorWeight: 2,
        tabs: const [
          Tab(text: 'DIRECT'),
          Tab(text: 'COMPÉTITIONS'),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// DIRECT — un thread par match dont la conversation a été initiée
// (un chat_channel existe en DB pour ce match)
// ──────────────────────────────────────────────────────────────────────────────
class _DirectTab extends ConsumerWidget {
  const _DirectTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final me = ref.watch(currentSessionProvider)?.user.id;
    final matchesAsync = ref.watch(myAllMatchesProvider);
    final openedIdsAsync = ref.watch(myOpenedMatchChannelIdsProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref
          ..invalidate(myAllMatchesProvider)
          ..invalidate(myOpenedMatchChannelIdsProvider);
        await Future.wait([
          ref.read(myAllMatchesProvider.future),
          ref.read(myOpenedMatchChannelIdsProvider.future),
        ]);
      },
      child: matchesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _ErrorList(message: 'Erreur : $e'),
        data: (matches) {
          if (matches.isEmpty || me == null) {
            return const EmptyState(
              icon: Icons.chat_bubble_outline,
              title: 'Aucune conversation',
              description:
                  'Tes conversations apparaîtront ici dès que tu '
                  'ouvriras la chat depuis la salle de match.',
            );
          }
          // Filtre : ne garde que les matchs dont la chat a été initiée.
          return openedIdsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => _ErrorList(message: 'Erreur : $e'),
            data: (openedIds) {
              final conversations = [
                for (final m in matches)
                  if (openedIds.contains(m.id)) m,
              ];
              if (conversations.isEmpty) {
                return const EmptyState(
                  icon: Icons.chat_bubble_outline,
                  title: 'Aucune conversation',
                  description:
                      'Ouvre la chat depuis une salle de match — elle '
                      'apparaîtra ici.',
                );
              }
              final opponentIds = <String>{
                for (final m in conversations)
                  if (m.player1Id == me && m.player2Id != null) m.player2Id!
                  else if (m.player2Id == me && m.player1Id != null)
                    m.player1Id!,
              };
              final key = (opponentIds.toList()..sort()).join(',');
              final peersAsync = ref.watch(profilesByIdsProvider(key));
              final peers = peersAsync.maybeWhen(
                data: (m) => m,
                orElse: () => const <String, Profile>{},
              );
              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(
                  ArenaSpacing.lg,
                  0,
                  ArenaSpacing.lg,
                  ArenaSpacing.lg,
                ),
                itemCount: conversations.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(height: ArenaSpacing.sm),
                itemBuilder: (ctx, i) {
                  final m = conversations[i];
                  final opponentId =
                      m.player1Id == me ? m.player2Id : m.player1Id;
                  final opponent =
                      opponentId == null ? null : peers[opponentId];
                  return Dismissible(
                    key: ValueKey('inbox_match_${m.id}'),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: ArenaSpacing.lg),
                      decoration: BoxDecoration(
                        color: ArenaColors.neonRed.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.delete_outline,
                        color: ArenaColors.neonRed,
                      ),
                    ),
                    confirmDismiss: (_) => _confirmDeleteConversation(ctx),
                    onDismissed: (_) =>
                        _onDeleteConversation(ctx, ref, m.id),
                    child: _MatchThreadRow(
                      match: m,
                      opponent: opponent,
                      highlighted: i == 0 && _isHot(m),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Future<bool> _confirmDeleteConversation(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ArenaColors.carbon,
        title: const Text('Supprimer cette conversation ?'),
        content: const Text(
          'La conversation sera retirée de ton inbox. Tu peux la retrouver '
          'en rouvrant le chat depuis la salle de match.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: ArenaColors.neonRed),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('SUPPRIMER'),
          ),
        ],
      ),
    );
    return ok ?? false;
  }

  Future<void> _onDeleteConversation(
    BuildContext context,
    WidgetRef ref,
    String matchId,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final repo = ref.read(chatRepositoryProvider);
      final channel = await repo.ensureMatchChannel(matchId);
      await repo.softDeleteChannel(channel.id);
      ref.invalidate(myOpenedMatchChannelIdsProvider);
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Échec : ${arenaErrorMessage(e)}')),
      );
    }
  }

  static bool _isHot(ArenaMatch m) {
    if (m.status == MatchStatus.inProgress ||
        m.status == MatchStatus.scorePending ||
        m.status == MatchStatus.awaitingValidation) {
      return true;
    }
    final s = m.scheduledAt;
    if (s == null) return false;
    final diff = s.difference(DateTime.now());
    return !diff.isNegative && diff.inHours < 4;
  }
}

class _MatchThreadRow extends StatelessWidget {
  const _MatchThreadRow({
    required this.match,
    required this.opponent,
    required this.highlighted,
  });

  final ArenaMatch match;
  final Profile? opponent;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final opponentName = opponent?.username ?? 'En attente';
    final initials =
        opponentName.isEmpty ? '?' : opponentName[0].toUpperCase();
    final color = _avatarFor(opponent?.avatarColor);
    final subtitle = _subtitleFor(match);
    final timeLabel = _timeLabelFor(match);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => context.push(UserRoutes.matchChatPath(match.id)),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: ArenaColors.carbon2,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: highlighted
                  ? ArenaColors.signalBlue
                  : ArenaColors.border,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ArenaAvatar(initials: initials, color: color),
              const SizedBox(width: ArenaSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            opponentName,
                            style: ArenaText.small.copyWith(
                              color: ArenaColors.bone,
                              fontWeight: FontWeight.w700,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          timeLabel,
                          style: ArenaText.small.copyWith(
                            color: ArenaColors.silver,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: ArenaText.small.copyWith(
                        color: highlighted
                            ? ArenaColors.bone
                            : ArenaColors.silver,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static ArenaAvatarColor _avatarFor(String? hex) {
    if (hex == null) return ArenaAvatarColor.blue;
    final cleaned = hex.replaceAll('#', '').toUpperCase();
    if (cleaned.startsWith('FF')) return ArenaAvatarColor.red;
    if (cleaned.startsWith('69')) return ArenaAvatarColor.green;
    if (cleaned.startsWith('3B') || cleaned.startsWith('15')) {
      return ArenaAvatarColor.cyan;
    }
    if (cleaned.startsWith('F7')) return ArenaAvatarColor.orange;
    if (cleaned.startsWith('97') || cleaned.startsWith('84')) {
      return ArenaAvatarColor.purple;
    }
    return ArenaAvatarColor.blue;
  }

  static String _subtitleFor(ArenaMatch m) {
    return switch (m.status) {
      MatchStatus.pending => "En attente d'adversaire",
      MatchStatus.scheduled => 'Match programmé',
      MatchStatus.ready => 'Code de salon partagé',
      MatchStatus.inProgress => 'En cours — appuie pour discuter',
      MatchStatus.scorePending => 'En attente du score',
      MatchStatus.awaitingValidation => 'Validation du score',
      MatchStatus.disputed => 'Score contesté — admin en cours',
      MatchStatus.completed => 'Match terminé',
      MatchStatus.cancelled => 'Match annulé',
      MatchStatus.forfeited => 'Forfait',
    };
  }

  static String _timeLabelFor(ArenaMatch m) {
    final t = m.finishedAt ?? m.scheduledAt ?? m.createdAt;
    if (t == null) return '—';
    final diff = DateTime.now().difference(t);
    if (diff.isNegative) {
      final upcoming = -diff.inHours;
      if (upcoming < 1) return 'Bientôt';
      if (upcoming < 24) return 'Dans ${upcoming}h';
      final days = -diff.inDays;
      return 'Dans ${days}j';
    }
    if (diff.inMinutes < 60) return '${diff.inMinutes}min';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}j';
    return '${(diff.inDays / 7).floor()}sem';
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// COMPÉTITIONS — list des comp où le user est inscrit
// ──────────────────────────────────────────────────────────────────────────────
class _CompetitionsTab extends ConsumerWidget {
  const _CompetitionsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final registeredAsync = ref.watch(myRegisteredCompetitionIdsProvider);
    final compsAsync = ref.watch(competitionsListProvider(null));

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(competitionsListProvider(null));
        await Future<void>.delayed(const Duration(milliseconds: 200));
      },
      child: registeredAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _ErrorList(message: 'Erreur : $e'),
        data: (ids) {
          if (ids.isEmpty) {
            return const EmptyState(
              icon: Icons.emoji_events_outlined,
              title: 'Aucune compétition active',
              description:
                  'Les fils de discussion liés à tes compétitions '
                  'apparaîtront ici dès que tu rejoindras un tournoi.',
            );
          }
          return compsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => _ErrorList(message: 'Erreur : $e'),
            data: (all) {
              final mine = [
                for (final c in all)
                  if (ids.contains(c.id)) c,
              ];
              if (mine.isEmpty) {
                return const EmptyState(
                  icon: Icons.hourglass_empty,
                  title: 'En attente',
                  description:
                      "Tu es inscrit mais les compétitions n'ont pas "
                      'encore été chargées.',
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(
                  ArenaSpacing.lg,
                  0,
                  ArenaSpacing.lg,
                  ArenaSpacing.lg,
                ),
                itemCount: mine.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(height: ArenaSpacing.sm),
                itemBuilder: (ctx, i) =>
                    _CompetitionThreadRow(competition: mine[i]),
              );
            },
          );
        },
      ),
    );
  }
}

class _CompetitionThreadRow extends StatelessWidget {
  const _CompetitionThreadRow({required this.competition});
  final Competition competition;

  @override
  Widget build(BuildContext context) {
    final c = competition;
    final emoji = switch (c.game.value) {
      'efootball' => '⚽',
      'fifa_mobile' => '🎮',
      'ea_sports_fc' => '🎯',
      _ => '🏆',
    };
    final statusLabel = switch (c.status.value) {
      'registration_open' => 'Inscriptions ouvertes',
      'registration_closed' => 'Inscriptions fermées',
      'ongoing' => 'En cours',
      'completed' => 'Terminée',
      'cancelled' => 'Annulée',
      _ => 'Brouillon',
    };
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => context.push(UserRoutes.competitionPath(c.id)),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: ArenaColors.carbon2,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: ArenaColors.border),
          ),
          child: Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 22)),
              const SizedBox(width: ArenaSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      c.name,
                      style: ArenaText.small.copyWith(
                        color: ArenaColors.bone,
                        fontWeight: FontWeight.w700,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${c.currentPlayers}/${c.maxPlayers} • $statusLabel',
                      style: ArenaText.small.copyWith(
                        color: ArenaColors.silver,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: ArenaColors.silver),
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorList extends StatelessWidget {
  const _ErrorList({required this.message});
  final String message;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(ArenaSpacing.lg),
      child: Text(
        message,
        style: ArenaText.body.copyWith(color: ArenaColors.danger),
      ),
    );
  }
}

/// Helper avatar mapping kept for backward compat with `chat_page.dart`
/// (imports `inboxAvatarFor` to pick a deterministic colour).
ArenaAvatarColor inboxAvatarFor(String seed) {
  if (seed.isEmpty) return ArenaAvatarColor.blue;
  final c = seed.codeUnitAt(0) % ArenaAvatarColor.values.length;
  return ArenaAvatarColor.values[c];
}
