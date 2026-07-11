import 'dart:io';

import 'package:arena/core/services/network_status_service.dart';
import 'package:arena/core/services/realtime_resume_service.dart';
import 'package:arena/core/services/sync_queue_service.dart';
import 'package:arena/core/theme/arena_theme.dart';
import 'package:arena/data/repositories/app_update_repository.dart';
import 'package:arena/features_shared/widgets/arena_app_bar.dart';
import 'package:arena/features_shared/widgets/miui_optimization_dialog.dart';
import 'package:arena/features_shared/widgets/offline_banner.dart';
import 'package:arena/features_user/chat/messages_inbox_page.dart';
import 'package:arena/features_user/competitions/competitions_list_page.dart';
import 'package:arena/features_user/home/home_page.dart';
import 'package:arena/features_user/home/update_available_dialog.dart';
import 'package:arena/features_user/profile/player_profile_page.dart';
import 'package:arena/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Demande de bascule d'onglet depuis ailleurs dans l'app (ex. le CTA
/// « Parcourir les tournois » de l'empty state de la home). `null` = pas de
/// demande en attente ; [MainLayout] la consomme puis la remet à `null`.
/// Index : 0 Accueil · 1 Compétitions · 2 Chat · 3 Profil.
final mainTabRequestProvider = StateProvider<int?>((_) => null);

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
  bool _updateChecked = false;

  static const _pages = <Widget>[
    HomePage(),
    CompetitionsListPage(),
    MessagesInboxBody(),
    PlayerProfilePage(),
  ];

  @override
  void initState() {
    super.initState();
    // Vérifie une MAJ in-app au démarrage (Android, distribution APK directe).
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybePromptUpdate());
  }

  /// Best-effort : propose une mise à jour si une version plus récente est
  /// publiée. Toute erreur (réseau, plateforme non Android) est silencieuse.
  Future<void> _maybePromptUpdate() async {
    if (_updateChecked || !Platform.isAndroid) return;
    _updateChecked = true;
    try {
      final status = await ref.read(updateStatusProvider.future);
      if (status != null && mounted) {
        await UpdateAvailableDialog.show(context, status);
      }
    } catch (_) {/* non bloquant */}
    // Après l'éventuelle MAJ : guide MIUI/Xiaomi une seule fois (déblocage de
    // l'upload background de preuve anti-triche). No-op hors Xiaomi / si déjà vu.
    if (mounted) {
      await maybePromptMiuiOptimization(context, ref);
    }
  }

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
      ..watch(syncQueueServiceProvider)
      // Bascule d'onglet demandée ailleurs (ex. CTA empty state home).
      ..listen<int?>(mainTabRequestProvider, (_, next) {
        if (next == null) return;
        setState(() => _currentIndex = next);
        ref.read(mainTabRequestProvider.notifier).state = null;
      });
    return PopScope(
      // On gere le back system manuellement :
      //  - sur un tab non-home  -> revient sur Home
      //  - sur Home             -> double-tap dans <2s pour quitter
      canPop: false,
      onPopInvokedWithResult: _handleSystemBack,
      child: Scaffold(
        appBar: ArenaAppBar(
          title: _titleForIndex(context, _currentIndex),
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
      final l10n = AppLocalizations.of(context);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(l10n.mainLayoutExitConfirm),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      return;
    }
    SystemNavigator.pop();
  }

  String _titleForIndex(BuildContext context, int i) {
    final l10n = AppLocalizations.of(context);
    return switch (i) {
      0 => l10n.mainLayoutTitleHome,
      1 => l10n.mainLayoutTitleCompetitions,
      2 => l10n.mainLayoutTitleMessages,
      3 => l10n.mainLayoutTitleProfile,
      _ => 'ARENA',
    };
  }
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
    final l10n = AppLocalizations.of(context);

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
            destinations: [
              NavigationDestination(
                icon: const Icon(Icons.home_outlined),
                selectedIcon: const Icon(Icons.home),
                label: l10n.mainLayoutNavHome,
              ),
              NavigationDestination(
                icon: const Icon(Icons.sports_esports_outlined),
                selectedIcon: const Icon(Icons.sports_esports),
                label: l10n.mainLayoutNavCompetitions,
              ),
              NavigationDestination(
                icon: const Icon(Icons.chat_bubble_outline),
                selectedIcon: const Icon(Icons.chat_bubble),
                label: l10n.mainLayoutNavChat,
              ),
              NavigationDestination(
                icon: const Icon(Icons.person_outline),
                selectedIcon: const Icon(Icons.person),
                label: l10n.mainLayoutNavProfile,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
