import 'package:arena/core/theme/arena_theme.dart';
import 'package:arena/features_shared/widgets/arena_app_bar.dart';
import 'package:arena/features_shared/widgets/arena_avatar.dart';
import 'package:arena/features_shared/widgets/empty_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// PHASE 6 + PHASE 12.5 — global messages inbox.
///
/// Two tabs (DIRECT / COMPÉTITIONS) per `arena_v2.html` #15. Direct
/// messages arrive in PHASE 12.5 with Agora RTM presence; until then
/// the DIRECT tab renders a deterministic v2 sample feed so the layout
/// stays in sync with the design kit. Match chats remain reachable via
/// the match-room (`/chat/match/:id`).
///
/// Used both as the Chat tab inside [MainLayout] (no AppBar — host
/// supplies it) and as a stand-alone route at `/messages` (Scaffold
/// wrapper). The shared body lives in [MessagesInboxBody].
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
/// Scaffold (the user app's [MainLayout] already supplies the AppBar
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

/// Compose-button shown in the inbox AppBar / parent layout. Opens the
/// "new conversation" UI once Agora RTM lands (PHASE 12.5).
class InboxComposeAction extends StatelessWidget {
  const InboxComposeAction({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Nouvelle conversation',
      icon: const Icon(Icons.edit_outlined, color: ArenaColors.gameEfoot),
      onPressed: () => _showPlaceholder(
        context,
        'La composition de nouveaux messages directs arrive en PHASE 12.5.',
      ),
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

class _DirectTab extends StatelessWidget {
  const _DirectTab();

  static const _sample = <_InboxThread>[
    _InboxThread(
      username: 'DianaA',
      lastMessage: 'GG, beau match !',
      timestamp: '14:25',
      avatarColor: ArenaAvatarColor.green,
      unread: 2,
      online: true,
    ),
    _InboxThread(
      username: 'SamuelK',
      lastMessage: 'On joue le quart à quelle heure ?',
      timestamp: '12:18',
      avatarColor: ArenaAvatarColor.cyan,
      online: true,
    ),
    _InboxThread(
      username: 'AhmedB',
      lastMessage: 'Tu joues pour la EA FC Night ?',
      timestamp: 'Hier',
      avatarColor: ArenaAvatarColor.orange,
    ),
    _InboxThread(
      username: 'LindaO',
      lastMessage: "Beau match l'autre fois !",
      timestamp: '2j',
      avatarColor: ArenaAvatarColor.purple,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(
        ArenaSpacing.lg,
        0,
        ArenaSpacing.lg,
        ArenaSpacing.lg,
      ),
      itemCount: _sample.length,
      separatorBuilder: (_, __) => const SizedBox(height: ArenaSpacing.sm),
      itemBuilder: (context, i) => _InboxRow(
        thread: _sample[i],
        highlighted: i == 0,
      ),
    );
  }
}

class _CompetitionsTab extends StatelessWidget {
  const _CompetitionsTab();

  @override
  Widget build(BuildContext context) {
    return const EmptyState(
      icon: Icons.emoji_events_outlined,
      title: 'Aucune compétition active',
      description: 'Les fils de discussion liés à tes compétitions '
          'apparaîtront ici dès que tu rejoindras un tournoi.',
    );
  }
}

class _InboxThread {
  const _InboxThread({
    required this.username,
    required this.lastMessage,
    required this.timestamp,
    required this.avatarColor,
    this.unread = 0,
    this.online = false,
  });

  final String username;
  final String lastMessage;
  final String timestamp;
  final ArenaAvatarColor avatarColor;
  final int unread;
  final bool online;
}

class _InboxRow extends StatelessWidget {
  const _InboxRow({required this.thread, required this.highlighted});

  final _InboxThread thread;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showPlaceholder(
          context,
          'Les messages directs avec ${thread.username} arrivent en PHASE 12.5.',
        ),
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
              _AvatarWithPresence(
                initials: thread.username.isEmpty
                    ? '?'
                    : thread.username[0].toUpperCase(),
                color: thread.avatarColor,
                online: thread.online,
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
                            thread.username,
                            style: ArenaText.small.copyWith(
                              color: ArenaColors.bone,
                              fontWeight: FontWeight.w700,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          thread.timestamp,
                          style: ArenaText.small.copyWith(
                            color: ArenaColors.silver,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      thread.lastMessage,
                      style: ArenaText.small.copyWith(
                        color: thread.unread > 0
                            ? ArenaColors.bone
                            : ArenaColors.silver,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (thread.unread > 0) ...[
                const SizedBox(width: ArenaSpacing.sm),
                _UnreadBadge(count: thread.unread),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _AvatarWithPresence extends StatelessWidget {
  const _AvatarWithPresence({
    required this.initials,
    required this.color,
    required this.online,
  });

  final String initials;
  final ArenaAvatarColor color;
  final bool online;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ArenaAvatar(initials: initials, color: color),
        if (online)
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: ArenaColors.statusOk,
                shape: BoxShape.circle,
                border: Border.all(color: ArenaColors.carbon, width: 2),
              ),
            ),
          ),
      ],
    );
  }
}

class _UnreadBadge extends StatelessWidget {
  const _UnreadBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 18,
      height: 18,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: ArenaColors.neonRed,
        shape: BoxShape.circle,
      ),
      child: Text(
        count > 9 ? '9+' : '$count',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 9,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

void _showPlaceholder(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      duration: const Duration(seconds: 2),
    ),
  );
}

/// Helper avatar mapping for inbox cards (used once the
/// PHASE 12.5 backend lands). Kept here so the row component stays
/// in sync with the v2 colour palette.
ArenaAvatarColor inboxAvatarFor(String seed) {
  if (seed.isEmpty) return ArenaAvatarColor.blue;
  final c = seed.codeUnitAt(0) % ArenaAvatarColor.values.length;
  return ArenaAvatarColor.values[c];
}
