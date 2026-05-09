import 'package:arena/core/theme/arena_theme.dart';
import 'package:arena/features_shared/widgets/arena_app_bar.dart';
import 'package:arena/features_shared/widgets/arena_avatar.dart';
import 'package:arena/features_shared/widgets/empty_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// PHASE 6 + PHASE 12.5 — global messages inbox.
///
/// Two tabs (DIRECT / COMPÉTITIONS) per `arena_v2.html` #15. Direct messages
/// arrive in PHASE 12.5 with Agora RTM presence; until then this screen
/// renders an empty state explaining the upcoming flow. Match chats are
/// reachable from the match-room (`/chat/match/:id`), not from here.
///
/// Maps to screen #15 of `arena_v2.html`.
class MessagesInboxPage extends StatelessWidget {
  const MessagesInboxPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: const ArenaAppBar(
          title: 'Messages',
          showBack: false,
        ),
        body: SafeArea(
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

  @override
  Widget build(BuildContext context) {
    // Phase 6 ships match-attached chat only. The placeholder mirrors a
    // v2 inbox row so the layout is in place for PHASE 12.5 wiring.
    return const EmptyState(
      icon: Icons.chat_bubble_outline,
      title: 'Pas encore de discussion',
      description: 'Les messages directs entre joueurs arriveront avec '
          'PHASE 12.5 (Agora RTM). En attendant, le chat 1-on-1 est '
          'accessible depuis chaque match-room.',
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

/// Helper avatar mapping for inbox cards (used once the
/// PHASE 12.5 backend lands). Kept here so the row component stays
/// in sync with the v2 colour palette.
ArenaAvatarColor inboxAvatarFor(String seed) {
  if (seed.isEmpty) return ArenaAvatarColor.blue;
  final c = seed.codeUnitAt(0) % ArenaAvatarColor.values.length;
  return ArenaAvatarColor.values[c];
}
