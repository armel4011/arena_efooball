import 'package:arena/core/theme/arena_theme.dart';
import 'package:arena/features_shared/widgets/arena_app_bar.dart';
import 'package:arena/features_user/chat/messages_inbox_page.dart';
import 'package:arena/features_user/competitions/competitions_list_page.dart';
import 'package:arena/features_user/home/home_page.dart';
import 'package:arena/features_user/profile/player_profile_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Root scaffold of the User app once authenticated.
///
/// Holds 4 tabs: Home, Compétitions, Chat, Profil. Tabs 2-4 are
/// placeholders awaiting their respective phases (4, 6, 9). Uses an
/// `IndexedStack` so each tab keeps its own scroll/state when the user
/// switches away and comes back.
class MainLayout extends ConsumerStatefulWidget {
  const MainLayout({super.key});

  @override
  ConsumerState<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends ConsumerState<MainLayout> {
  int _currentIndex = 0;

  static const _pages = <Widget>[
    HomePage(),
    CompetitionsListPage(),
    MessagesInboxBody(),
    PlayerProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ArenaAppBar(
        title: _titleForIndex(_currentIndex),
        actions: [
          if (_currentIndex == 2) const InboxComposeAction(),
        ],
      ),
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: _GlowingNavBar(
        currentIndex: _currentIndex,
        onChanged: (i) => setState(() => _currentIndex = i),
      ),
    );
  }

  String _titleForIndex(int i) => switch (i) {
        0 => 'ACCUEIL',
        1 => 'COMPÉTITIONS',
        2 => 'MESSAGES',
        3 => 'PROFIL',
        _ => 'ARENA',
      };
}

class _GlowingNavBar extends StatelessWidget {
  const _GlowingNavBar({
    required this.currentIndex,
    required this.onChanged,
  });

  final int currentIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return DecoratedBox(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: primary.withValues(alpha: 0.22),
            blurRadius: 36,
            spreadRadius: -4,
            offset: const Offset(0, -10),
          ),
        ],
      ),
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: Colors.white.withValues(alpha: 0.06),
            ),
          ),
        ),
        child: NavigationBarTheme(
          data: NavigationBarThemeData(
            backgroundColor: ArenaColors.surface.withValues(alpha: 0.92),
            surfaceTintColor: Colors.transparent,
            indicatorColor: primary.withValues(alpha: 0.28),
            indicatorShape: const StadiumBorder(),
            iconTheme: WidgetStateProperty.resolveWith(
              (states) => IconThemeData(
                color: states.contains(WidgetState.selected)
                    ? primary
                    : ArenaColors.textMuted,
                size: 24,
              ),
            ),
            labelTextStyle: WidgetStateProperty.resolveWith(
              (states) => ArenaTypography.labelMedium.copyWith(
                color: states.contains(WidgetState.selected)
                    ? primary
                    : ArenaColors.textMuted,
                fontSize: 11,
                fontWeight: states.contains(WidgetState.selected)
                    ? FontWeight.w600
                    : FontWeight.w500,
              ),
            ),
          ),
          child: NavigationBar(
            selectedIndex: currentIndex,
            onDestinationSelected: onChanged,
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home),
                label: 'Accueil',
              ),
              NavigationDestination(
                icon: Icon(Icons.sports_esports_outlined),
                selectedIcon: Icon(Icons.sports_esports),
                label: 'Compétitions',
              ),
              NavigationDestination(
                icon: Icon(Icons.chat_bubble_outline),
                selectedIcon: Icon(Icons.chat_bubble),
                label: 'Chat',
              ),
              NavigationDestination(
                icon: Icon(Icons.person_outline),
                selectedIcon: Icon(Icons.person),
                label: 'Profil',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
