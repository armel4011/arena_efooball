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

part 'messages_inbox_widgets.dart';

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
