import 'package:arena/core/router/user_router.dart';
import 'package:arena/core/theme/arena_theme.dart';
import 'package:arena/core/utils/arena_error_message.dart';
import 'package:arena/data/models/arena_match.dart';
import 'package:arena/data/models/competition.dart';
import 'package:arena/data/models/match_status.dart';
import 'package:arena/data/models/profile.dart';
import 'package:arena/data/models/tutorial_video.dart';
import 'package:arena/data/repositories/admin_chat_repository.dart';
import 'package:arena/data/repositories/chat_repository.dart';
import 'package:arena/data/repositories/competition_repository.dart';
import 'package:arena/data/repositories/match_repository.dart';
import 'package:arena/data/repositories/profile_repository.dart';
import 'package:arena/features_shared/auth_common/shared_auth_providers.dart';
import 'package:arena/features_shared/widgets/arena_app_bar.dart';
import 'package:arena/features_shared/widgets/arena_avatar.dart';
import 'package:arena/features_shared/widgets/arena_screen_background.dart';
import 'package:arena/features_shared/widgets/empty_state.dart';
import 'package:arena/features_user/home/widgets/tutorial_video_section.dart';
import 'package:arena/l10n/generated/app_localizations.dart';
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
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: ArenaAppBar(
        title: l10n.inboxAppBarTitle,
        actions: const [InboxComposeAction()],
      ),
      body: const ArenaScreenBackground(child: MessagesInboxBody()),
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
            const TutorialBannerSection(page: TutorialPage.messages),
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
    final l10n = AppLocalizations.of(context);
    return IconButton(
      tooltip: l10n.inboxComposeTooltip,
      icon: const Icon(Icons.edit_outlined, color: ArenaColors.gameEfoot),
      onPressed: () => context.push(UserRoutes.friendsSearch),
    );
  }
}

class _InboxTabs extends StatelessWidget {
  const _InboxTabs();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
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
        tabs: [
          Tab(text: l10n.inboxTabDirect),
          Tab(text: l10n.inboxTabTournaments),
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
    final l10n = AppLocalizations.of(context);
    final me = ref.watch(currentSessionProvider)?.user.id;
    final matchesAsync = ref.watch(myAllMatchesProvider);
    final openedIdsAsync = ref.watch(myOpenedMatchChannelIdsProvider);
    final friendChannelsAsync = ref.watch(myFriendChannelsProvider);
    final unreadCounts =
        ref.watch(myUnreadCountsProvider).valueOrNull ?? const {};
    final matchChannelMap =
        ref.watch(myMatchChannelIdsMapProvider).valueOrNull ?? const {};

    return RefreshIndicator(
      onRefresh: () async {
        ref
          ..invalidate(myAllMatchesProvider)
          ..invalidate(myOpenedMatchChannelIdsProvider)
          ..invalidate(myFriendChannelsProvider)
          ..invalidate(myUnreadCountsProvider);
        await Future.wait([
          ref.read(myAllMatchesProvider.future),
          ref.read(myOpenedMatchChannelIdsProvider.future),
          ref.read(myFriendChannelsProvider.future),
          ref.read(myUnreadCountsProvider.future),
        ]);
      },
      child: matchesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _ErrorList(message: '${l10n.inboxErrorPrefix}$e'),
        data: (matches) {
          if (me == null) {
            return EmptyState(
              icon: Icons.chat_bubble_outline,
              title: l10n.inboxNoConversationsTitle,
              description: l10n.inboxNoConversationsDesc,
            );
          }
          // Filtre : ne garde que les matchs dont la chat a été initiée.
          return openedIdsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => _ErrorList(message: '${l10n.inboxErrorPrefix}$e'),
            data: (openedIds) {
              final conversations = [
                for (final m in matches)
                  if (openedIds.contains(m.id)) m,
              ];
              final friendChannels =
                  friendChannelsAsync.valueOrNull ?? const [];
              // La row ARENA reste TOUJOURS visible en tete : on ne fait
              // plus d'early return quand conversations & friends sont
              // vides ; un EmptyState compact prend la place en dessous.
              final opponentIds = <String>{
                for (final m in conversations)
                  if (m.player1Id == me && m.player2Id != null)
                    m.player2Id!
                  else if (m.player2Id == me && m.player1Id != null)
                    m.player1Id!,
                for (final fc in friendChannels) fc.peerId,
              };
              final key = (opponentIds.toList()..sort()).join(',');
              final peersAsync = key.isEmpty
                  ? const AsyncValue<Map<String, Profile>>.data(
                      <String, Profile>{},
                    )
                  : ref.watch(profilesByIdsProvider(key));
              final peers = peersAsync.maybeWhen(
                data: (m) => m,
                orElse: () => const <String, Profile>{},
              );
              // Construit la liste plate :
              //  1. row ARENA (toujours en tete, conversation officielle)
              //  2. friends si presents
              //  3. matches si presents
              final items = <_InboxItem>[
                const _InboxItem.arenaTeam(),
                if (friendChannels.isNotEmpty)
                  _InboxItem.sectionHeader(l10n.inboxSectionFriends),
                for (final fc in friendChannels)
                  _InboxItem.friend(
                    fc,
                    peers[fc.peerId],
                    unread: unreadCounts[fc.channelId] ?? 0,
                  ),
                if (conversations.isNotEmpty && friendChannels.isNotEmpty)
                  _InboxItem.sectionHeader(l10n.inboxSectionMatches),
                for (var i = 0; i < conversations.length; i++)
                  _InboxItem.match(
                    conversations[i],
                    peers[conversations[i].player1Id == me
                        ? conversations[i].player2Id
                        : conversations[i].player1Id],
                    highlighted: i == 0 && _isHot(conversations[i]),
                    unread:
                        unreadCounts[matchChannelMap[conversations[i].id]] ?? 0,
                  ),
                if (conversations.isEmpty && friendChannels.isEmpty)
                  const _InboxItem.emptyHint(),
              ];
              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(
                  ArenaSpacing.lg,
                  0,
                  ArenaSpacing.lg,
                  ArenaSpacing.lg,
                ),
                itemCount: items.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(height: ArenaSpacing.sm),
                itemBuilder: (ctx, i) {
                  final it = items[i];
                  if (it.kind == _InboxItemKind.arenaTeam) {
                    return const _ArenaTeamRow();
                  }
                  if (it.kind == _InboxItemKind.emptyHint) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: ArenaSpacing.xl,
                      ),
                      child: Text(
                        l10n.inboxEmptyHint,
                        style: ArenaText.small.copyWith(
                          color: ArenaColors.silver,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    );
                  }
                  if (it.kind == _InboxItemKind.header) {
                    return Padding(
                      padding: EdgeInsets.only(
                        top: i == 0 ? 0 : ArenaSpacing.sm,
                        bottom: 4,
                      ),
                      child: Text(
                        it.headerLabel!,
                        style: ArenaText.small.copyWith(
                          color: ArenaColors.silver,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                        ),
                      ),
                    );
                  }
                  if (it.kind == _InboxItemKind.friend) {
                    final fc = it.friend!;
                    return Dismissible(
                      key: ValueKey('inbox_friend_${fc.channelId}'),
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
                      // Tout dans confirmDismiss : confirm + delete +
                      // invalidate AVANT le return true, sinon
                      // "Dismissible widget still part of the tree".
                      confirmDismiss: (_) => _confirmAndDeleteFriendChannel(
                        ctx,
                        ref,
                        fc.channelId,
                      ),
                      child: _FriendThreadRow(
                        friendshipId: fc.friendshipId,
                        peer: it.peer,
                        unread: it.unread,
                      ),
                    );
                  }
                  // match
                  final m = it.match!;
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
                    confirmDismiss: (_) => _confirmAndDeleteMatchConversation(
                      ctx,
                      ref,
                      m.id,
                    ),
                    child: _MatchThreadRow(
                      match: m,
                      opponent: it.peer,
                      highlighted: it.highlighted,
                      unread: it.unread,
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

  /// Dialog de confirmation simple (réutilisable).
  Future<bool> _confirmDelete(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ArenaColors.carbon,
        title: Text(l10n.inboxDeleteDialogTitle),
        content: Text(l10n.inboxDeleteDialogContent),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.inboxDeleteCancel),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: ArenaColors.neonRed),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.inboxDeleteConfirm),
          ),
        ],
      ),
    );
    return ok ?? false;
  }

  /// `confirmDismiss` unifié pour match : confirme + delete + invalidate
  /// AVANT le return true, sinon Dismissible reste dans l'arbre après
  /// dismiss async → Flutter throw.
  Future<bool> _confirmAndDeleteMatchConversation(
    BuildContext context,
    WidgetRef ref,
    String matchId,
  ) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await _confirmDelete(context);
    if (!confirmed) return false;
    try {
      final repo = ref.read(chatRepositoryProvider);
      final channel = await repo.ensureMatchChannel(matchId);
      // "Supprimer pour moi" : hide + cleared_at = now(). Le peer
      // garde sa conv et l'historique. Si je rouvre plus tard, la
      // conv revient dans mon inbox via ensureMatchChannel qui
      // un-hide automatiquement (mais cleared_at masque l'historique).
      await repo.hideChannelForMe(channel.id);
      ref.invalidate(myOpenedMatchChannelIdsProvider);
      return true;
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('${l10n.inboxDeleteFailure}${arenaErrorMessage(e)}'),
        ),
      );
      return false;
    }
  }

  /// Idem pour friend channel.
  Future<bool> _confirmAndDeleteFriendChannel(
    BuildContext context,
    WidgetRef ref,
    String channelId,
  ) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await _confirmDelete(context);
    if (!confirmed) return false;
    try {
      await ref.read(chatRepositoryProvider).hideChannelForMe(channelId);
      ref.invalidate(myFriendChannelsProvider);
      return true;
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('${l10n.inboxDeleteFailure}${arenaErrorMessage(e)}'),
        ),
      );
      return false;
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
    this.unread = 0,
  });

  final ArenaMatch match;
  final Profile? opponent;
  final bool highlighted;
  final int unread;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final opponentName = opponent?.username ?? l10n.inboxOpponentWaiting;
    final initials = opponentName.isEmpty ? '?' : opponentName[0].toUpperCase();
    final color = _avatarFor(opponent?.avatarColor);
    final subtitle = _subtitleFor(match, l10n);
    final timeLabel = _timeLabelFor(match, l10n);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => context.push(UserRoutes.matchChatPath(match.id)),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: highlighted
                ? ArenaColors.signalBlue.withValues(alpha: 0.08)
                : ArenaColors.carbon2,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: highlighted ? ArenaColors.signalBlue : ArenaColors.border,
            ),
            boxShadow: highlighted
                ? const [
                    BoxShadow(
                      color: ArenaColors.signalBlueGlow,
                      blurRadius: 14,
                      spreadRadius: -4,
                    ),
                  ]
                : null,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar + dot statut en bas-droite : vert si le match est
              // "hot" (en cours ou imminent), sinon pas de dot. Reproduit
              // `m-dot m-dot-online` de la maquette #15.
              Stack(
                clipBehavior: Clip.none,
                children: [
                  ArenaAvatar(initials: initials, color: color),
                  if (highlighted)
                    Positioned(
                      right: -2,
                      bottom: -2,
                      child: Container(
                        width: 11,
                        height: 11,
                        decoration: BoxDecoration(
                          color: ArenaColors.statusOk,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: ArenaColors.carbon2,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
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
                        color:
                            highlighted ? ArenaColors.bone : ArenaColors.silver,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (unread > 0) ...[
                const SizedBox(width: 6),
                _UnreadBadge(count: unread),
              ],
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

  static String _subtitleFor(ArenaMatch m, AppLocalizations l10n) {
    return switch (m.status) {
      MatchStatus.pending => l10n.inboxMatchPending,
      MatchStatus.scheduled => l10n.inboxMatchScheduled,
      MatchStatus.ready => l10n.inboxMatchReady,
      MatchStatus.inProgress => l10n.inboxMatchInProgress,
      MatchStatus.scorePending => l10n.inboxMatchScorePending,
      MatchStatus.awaitingValidation => l10n.inboxMatchAwaitingValidation,
      MatchStatus.disputed => l10n.inboxMatchDisputed,
      MatchStatus.completed => l10n.inboxMatchCompleted,
      MatchStatus.cancelled => l10n.inboxMatchCancelled,
      MatchStatus.forfeited => l10n.inboxMatchForfeited,
    };
  }

  static String _timeLabelFor(ArenaMatch m, AppLocalizations l10n) {
    final t = m.finishedAt ?? m.scheduledAt ?? m.createdAt;
    if (t == null) return '—';
    final diff = DateTime.now().difference(t);
    if (diff.isNegative) {
      final upcoming = -diff.inHours;
      if (upcoming < 1) return l10n.inboxTimeSoon;
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
    final l10n = AppLocalizations.of(context);
    final registeredAsync = ref.watch(myRegisteredCompetitionIdsProvider);
    final compsAsync = ref.watch(competitionsListProvider(null));

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(competitionsListProvider(null));
        await Future<void>.delayed(const Duration(milliseconds: 200));
      },
      child: registeredAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _ErrorList(message: '${l10n.inboxErrorPrefix}$e'),
        data: (ids) {
          if (ids.isEmpty) {
            return EmptyState(
              icon: Icons.emoji_events_outlined,
              title: l10n.inboxNoActiveCompTitle,
              description: l10n.inboxNoActiveCompDesc,
            );
          }
          return compsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => _ErrorList(message: '${l10n.inboxErrorPrefix}$e'),
            data: (all) {
              final mine = [
                for (final c in all)
                  if (ids.contains(c.id)) c,
              ];
              if (mine.isEmpty) {
                return EmptyState(
                  icon: Icons.hourglass_empty,
                  title: l10n.inboxWaitingTitle,
                  description: l10n.inboxWaitingDesc,
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
    final l10n = AppLocalizations.of(context);
    final c = competition;
    final emoji = switch (c.game.value) {
      'efootball' => '⚽',
      'draughts' => '🔴',
      'ea_sports_fc' => '🎯',
      _ => '🏆',
    };
    final statusLabel = switch (c.status.value) {
      'registration_open' => l10n.inboxCompRegistrationOpen,
      'registration_closed' => l10n.inboxCompRegistrationClosed,
      'ongoing' => l10n.inboxCompOngoing,
      'completed' => l10n.inboxCompCompleted,
      'cancelled' => l10n.inboxCompCancelled,
      _ => l10n.inboxCompDraft,
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

// ─── Inbox unified item (AMIS + MATCHS) ──────────────────────────────────────

enum _InboxItemKind { arenaTeam, header, friend, match, emptyHint }

class _InboxItem {
  const _InboxItem._({
    required this.kind,
    this.headerLabel,
    this.friend,
    this.match,
    this.peer,
    this.highlighted = false,
    this.unread = 0,
  });

  const _InboxItem.arenaTeam() : this._(kind: _InboxItemKind.arenaTeam);

  const _InboxItem.emptyHint() : this._(kind: _InboxItemKind.emptyHint);

  const _InboxItem.sectionHeader(String label)
      : this._(kind: _InboxItemKind.header, headerLabel: label);

  const _InboxItem.friend(
    ({String channelId, String friendshipId, String peerId}) friend,
    Profile? peer, {
    required int unread,
  }) : this._(
          kind: _InboxItemKind.friend,
          friend: friend,
          peer: peer,
          unread: unread,
        );

  const _InboxItem.match(
    ArenaMatch match,
    Profile? peer, {
    required bool highlighted,
    required int unread,
  }) : this._(
          kind: _InboxItemKind.match,
          match: match,
          peer: peer,
          highlighted: highlighted,
          unread: unread,
        );

  final _InboxItemKind kind;
  final String? headerLabel;
  final ({String channelId, String friendshipId, String peerId})? friend;
  final ArenaMatch? match;
  final Profile? peer;
  final bool highlighted;
  final int unread;
}

/// Row inbox pour un friend chat (Item 3 wave C — 2026-05-19).
/// Tap → /chat/friend/:friendshipId. Layout cohérent avec _MatchThreadRow.
class _FriendThreadRow extends StatelessWidget {
  const _FriendThreadRow({
    required this.friendshipId,
    required this.peer,
    this.unread = 0,
  });

  final String friendshipId;
  final Profile? peer;
  final int unread;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final username = peer?.username ?? l10n.inboxFriendDefaultName;
    final initials = username.isEmpty ? '?' : username[0].toUpperCase();
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => context.push(UserRoutes.friendChatPath(friendshipId)),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: ArenaColors.carbon2,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: ArenaColors.border),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ArenaAvatar(
                initials: initials,
                color: inboxAvatarFor(username),
              ),
              const SizedBox(width: ArenaSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      username,
                      style: ArenaText.small.copyWith(
                        color: ArenaColors.bone,
                        fontWeight: FontWeight.w700,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      l10n.inboxChatWithFriend,
                      style: ArenaText.small.copyWith(
                        color: ArenaColors.silver,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (unread > 0)
                _UnreadBadge(count: unread)
              else
                const Icon(
                  Icons.chevron_right,
                  color: ArenaColors.silverDim,
                  size: 20,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Conversation "Équipe ARENA" : pinned en tête de l'inbox DIRECT.
/// Stream realtime via `adminChatRepository.watchInbox` — preview du
/// dernier message + badge unread. Tap -> /admin-messages.
class _ArenaTeamRow extends ConsumerWidget {
  const _ArenaTeamRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final me = ref.watch(currentSessionProvider)?.user.id;
    final repo = ref.read(adminChatRepositoryProvider);
    return StreamBuilder<List<AdminChatMessage>>(
      stream: me == null ? const Stream.empty() : repo.watchInbox(me),
      builder: (context, snap) {
        final msgs = snap.data ?? const <AdminChatMessage>[];
        final last = msgs.isNotEmpty ? msgs.first : null;
        final unread = msgs.where((m) => m.isUnread).length;
        final preview = _previewOf(last, l10n);
        final timeLabel = last == null ? '' : _relativeTime(last.sentAt, l10n);
        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => context.push(UserRoutes.adminMessages),
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: ArenaColors.neonRed.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: ArenaColors.neonRed),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: ArenaColors.neonRed.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: ArenaColors.neonRed),
                    ),
                    child: const Icon(
                      Icons.shield_outlined,
                      color: ArenaColors.neonRed,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: ArenaSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              l10n.inboxArenaTeam,
                              style: ArenaText.small.copyWith(
                                color: ArenaColors.bone,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: ArenaColors.neonRed,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                l10n.inboxArenaOfficialBadge,
                                style: ArenaText.small.copyWith(
                                  color: ArenaColors.bone,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 9,
                                  letterSpacing: 0.6,
                                ),
                              ),
                            ),
                            const Spacer(),
                            if (timeLabel.isNotEmpty)
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
                          preview,
                          style: ArenaText.small.copyWith(
                            color: ArenaColors.silver,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  if (unread > 0) ...[
                    const SizedBox(width: 6),
                    _UnreadBadge(count: unread),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  static String _previewOf(AdminChatMessage? m, AppLocalizations l10n) {
    if (m == null) return l10n.inboxArenaPreviewDefault;
    if (m.caption != null && m.caption!.isNotEmpty) return m.caption!;
    if (m.text != null && m.text!.isNotEmpty) return m.text!;
    if (m.hasImage) return l10n.inboxArenaPreviewImage;
    return '';
  }

  static String _relativeTime(DateTime t, AppLocalizations l10n) {
    final diff = DateTime.now().difference(t);
    if (diff.inMinutes < 1) return l10n.inboxTimeJustNow;
    if (diff.inMinutes < 60) return '${diff.inMinutes}min';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}j';
    return '${(diff.inDays / 7).floor()}sem';
  }
}

/// Badge "messages non-lus" style WhatsApp — bulle bleue avec compteur.
/// Affiche "99+" pour count >= 100.
class _UnreadBadge extends StatelessWidget {
  const _UnreadBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final label = count >= 100 ? '99+' : '$count';
    return Container(
      constraints: const BoxConstraints(minWidth: 22, minHeight: 22),
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: const BoxDecoration(
        color: ArenaColors.signalBlue,
        shape: BoxShape.rectangle,
        borderRadius: BorderRadius.all(Radius.circular(999)),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: ArenaText.small.copyWith(
          color: ArenaColors.bone,
          fontWeight: FontWeight.w700,
          fontSize: 11,
        ),
      ),
    );
  }
}
