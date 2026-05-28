import 'package:arena/core/services/network_status_service.dart';
import 'package:arena/core/services/realtime_resume_service.dart';
import 'package:arena/core/services/sync_queue_service.dart';
import 'package:arena/core/theme/arena_theme.dart';
import 'package:arena/features_shared/widgets/arena_app_bar.dart';
import 'package:arena/features_shared/widgets/offline_banner.dart';
import 'package:arena/features_user/chat/messages_inbox_page.dart';
import 'package:arena/features_user/competitions/competitions_list_page.dart';
import 'package:arena/features_user/home/home_page.dart';
import 'package:arena/features_user/profile/player_profile_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  DateTime? _lastBackPressedAt;

  static const _pages = <Widget>[
    HomePage(),
    CompetitionsListPage(),
    MessagesInboxBody(),
    PlayerProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    // Anchore les services session — `realtimeResumeServiceProvider`
    // invalide les StreamProvider Supabase au foreground resume ;
    // `networkStatusServiceProvider` ecoute connectivity_plus pour le
    // banner offline ; `syncQueueServiceProvider` attache l'auto-flush
    // au retour online. Les 3 sont keep-alive (singleton session).
    ref
      ..watch(realtimeResumeServiceProvider)
      ..watch(networkStatusServiceProvider)
      ..watch(syncQueueServiceProvider);
    return PopScope(
      // On gere le back system manuellement :
      //  - sur un tab non-home  -> revient sur Home
      //  - sur Home             -> double-tap dans <2s pour quitter
      canPop: false,
      onPopInvokedWithResult: _handleSystemBack,
      child: Scaffold(
        appBar: ArenaAppBar(
          title: _titleForIndex(_currentIndex),
          actions: [
            if (_currentIndex == 2) const InboxComposeAction(),
          ],
        ),
        // Banner offline tout en haut du body — n'occupe d'espace que
        // quand le reseau est down (AnimatedSize collapse a height 0).
        body: Column(
          children: [
            const OfflineBanner(),
            Expanded(
              child: IndexedStack(index: _currentIndex, children: _pages),
            ),
          ],
        ),
        bottomNavigationBar: _GlowingNavBar(
          currentIndex: _currentIndex,
          onChanged: (i) => setState(() => _currentIndex = i),
        ),
      ),
    );
  }

  void _handleSystemBack(bool didPop, Object? _) {
    if (didPop) return;
    if (_currentIndex != 0) {
      setState(() => _currentIndex = 0);
      return;
    }
    final now = DateTime.now();
    final last = _lastBackPressedAt;
    if (last == null || now.difference(last).inSeconds >= 2) {
      _lastBackPressedAt = now;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Appuie encore pour quitter ARENA'),
            duration: Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      return;
    }
    SystemNavigator.pop();
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
