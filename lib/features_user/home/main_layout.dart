import 'package:arena/core/theme/arena_colors.dart';
import 'package:arena/core/theme/arena_theme.dart';
import 'package:arena/core/theme/arena_typography.dart';
import 'package:arena/features_user/auth/auth_providers.dart';
import 'package:arena/features_user/home/home_page.dart';
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
    _PhasePlaceholder(
      phase: 'PHASE 4',
      title: 'COMPÉTITIONS',
      subtitle: 'Liste, détail et brackets — à venir.',
      icon: Icons.sports_esports_outlined,
    ),
    _PhasePlaceholder(
      phase: 'PHASE 6',
      title: 'CHAT',
      subtitle: 'Salons hybrides Supabase Realtime + Agora RTM — à venir.',
      icon: Icons.chat_bubble_outline,
    ),
    _PhasePlaceholder(
      phase: 'PHASE 9',
      title: 'PROFIL',
      subtitle: 'Settings, suppression compte (RGPD), badges — à venir.',
      icon: Icons.person_outline,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _titleForIndex(_currentIndex),
          style: ArenaTypography.headlineMedium,
        ),
        actions: [
          if (_currentIndex == 3)
            IconButton(
              icon: const Icon(Icons.logout),
              tooltip: 'Se déconnecter',
              onPressed: () => ref.read(signOutProvider)(),
            ),
        ],
      ),
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
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
    );
  }

  String _titleForIndex(int i) => switch (i) {
        0 => 'ACCUEIL',
        1 => 'COMPÉTITIONS',
        2 => 'CHAT',
        3 => 'PROFIL',
        _ => 'ARENA',
      };
}

class _PhasePlaceholder extends StatelessWidget {
  const _PhasePlaceholder({
    required this.phase,
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String phase;
  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(ArenaSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: ArenaColors.surface,
                  border: Border.all(color: ArenaColors.border),
                ),
                child: Icon(icon, size: 48, color: ArenaColors.textMuted),
              ),
              const SizedBox(height: ArenaSpacing.lg),
              Text(
                phase,
                style: ArenaTypography.labelLarge.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: ArenaSpacing.xs),
              Text(title, style: ArenaTypography.displayMedium),
              const SizedBox(height: ArenaSpacing.sm),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: ArenaTypography.bodyMedium.copyWith(
                  color: ArenaColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
