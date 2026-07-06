import 'package:arena/core/router/admin_desktop_router.dart';
import 'package:arena/core/theme/arena_theme.dart';
import 'package:arena/data/models/profile.dart';
import 'package:arena/features_admin_desktop/notifications/desktop_notification_bell.dart';
import 'package:arena/features_admin_desktop/notifications/desktop_notification_service.dart';
import 'package:arena/features_admin_desktop/shared/desktop_window_controls.dart';
import 'package:arena/features_shared/admin_sections.dart';
import 'package:arena/features_shared/auth_common/shared_auth_providers.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:window_manager/window_manager.dart';

/// Entrée du menu latéral desktop.
class _NavEntry {
  const _NavEntry({
    required this.route,
    required this.icon,
    required this.label,
    this.superAdminOnly = false,
    this.section,
  });

  final String route;
  final IconData icon;
  final String label;
  final bool superAdminOnly;

  /// Clé de section [kAdminSections] pour le gating par périmètre. `null`
  /// = destination toujours visible (dashboard / vue d'ensemble).
  final String? section;
}

const List<_NavEntry> _mainEntries = [
  _NavEntry(
    route: AdminDesktopRoutes.dashboard,
    icon: FluentIcons.view_dashboard,
    label: 'Tableau de bord',
  ),
  _NavEntry(
    route: AdminDesktopRoutes.competitions,
    icon: FluentIcons.trophy2,
    label: 'Compétitions',
    section: 'competitions',
  ),
  _NavEntry(
    route: AdminDesktopRoutes.matches,
    icon: FluentIcons.game,
    label: 'Matchs',
    section: 'matches',
  ),
  _NavEntry(
    route: AdminDesktopRoutes.streams,
    icon: FluentIcons.video,
    label: 'Streams live',
    section: 'streams',
  ),
  _NavEntry(
    route: AdminDesktopRoutes.payouts,
    icon: FluentIcons.money,
    label: 'Paiements',
    section: 'payouts',
  ),
  _NavEntry(
    route: AdminDesktopRoutes.recordings,
    icon: FluentIcons.video,
    label: 'Enregistrements',
    section: 'recordings',
  ),
  _NavEntry(
    route: AdminDesktopRoutes.auditLog,
    icon: FluentIcons.compliance_audit,
    label: "Journal d'audit",
    section: 'audit',
  ),
];

const List<_NavEntry> _superEntries = [
  _NavEntry(
    route: AdminDesktopRoutes.superDashboard,
    icon: FluentIcons.org,
    label: "Vue d'ensemble",
    superAdminOnly: true,
  ),
  _NavEntry(
    route: AdminDesktopRoutes.superUsers,
    icon: FluentIcons.people,
    label: 'Utilisateurs',
    superAdminOnly: true,
    section: 'users',
  ),
  _NavEntry(
    route: AdminDesktopRoutes.superPaymentsValidation,
    icon: FluentIcons.receipt_check,
    label: 'Validation paiements',
    superAdminOnly: true,
    section: 'payments',
  ),
  _NavEntry(
    route: AdminDesktopRoutes.superPayouts,
    icon: FluentIcons.send,
    label: 'Versements',
    superAdminOnly: true,
    section: 'payouts',
  ),
  _NavEntry(
    route: AdminDesktopRoutes.superInvitations,
    icon: FluentIcons.add_friend,
    label: 'Invitations admin',
    superAdminOnly: true,
    section: 'invitations',
  ),
  _NavEntry(
    route: AdminDesktopRoutes.superRevenue,
    icon: FluentIcons.chart,
    label: 'Revenus',
    superAdminOnly: true,
    section: 'revenue',
  ),
  _NavEntry(
    route: AdminDesktopRoutes.superBroadcast,
    icon: FluentIcons.megaphone,
    label: 'Diffusion',
    superAdminOnly: true,
    section: 'broadcast',
  ),
  _NavEntry(
    route: AdminDesktopRoutes.superPromoBanner,
    icon: FluentIcons.photo2,
    label: 'Bannière promo',
    superAdminOnly: true,
    section: 'promo',
  ),
  _NavEntry(
    route: AdminDesktopRoutes.superReintegration,
    icon: FluentIcons.follow_user,
    label: 'Réintégrations',
    superAdminOnly: true,
    section: 'reintegration',
  ),
  _NavEntry(
    route: AdminDesktopRoutes.superSupport,
    icon: FluentIcons.chat,
    label: 'Support',
    superAdminOnly: true,
    section: 'support',
  ),
  _NavEntry(
    route: AdminDesktopRoutes.superAppUpdate,
    icon: FluentIcons.cloud_download,
    label: 'Mise à jour app',
    superAdminOnly: true,
    section: 'app_update',
  ),
  _NavEntry(
    route: AdminDesktopRoutes.superTutorialBanners,
    icon: FluentIcons.video,
    label: 'Bannières tuto',
    superAdminOnly: true,
    section: 'tutorial',
  ),
  _NavEntry(
    route: AdminDesktopRoutes.superAntiCheat,
    icon: FluentIcons.shield,
    label: 'Anti-triche',
    superAdminOnly: true,
    section: 'anticheat',
  ),
];

/// Coquille de navigation desktop — barre latérale Fluent (NavigationView)
/// entourant le contenu routé par GoRouter (ShellRoute).
///
/// La sélection du menu est dérivée de la route courante ; cliquer sur un
/// item fait un `context.go(...)`. Les sections super-admin n'apparaissent
/// que si le profil courant a le rôle `super_admin`.
class AdminDesktopShell extends ConsumerWidget {
  const AdminDesktopShell({
    required this.child,
    required this.currentPath,
    super.key,
  });

  /// Contenu de la route active (injecté par le ShellRoute).
  final Widget child;

  /// Chemin de la route active (ex. `/competitions`).
  final String currentPath;

  /// Une destination sans `section` (dashboard / vue d'ensemble) reste
  /// toujours visible ; sinon on applique le périmètre de l'admin courant.
  static bool _entryVisible(_NavEntry e, Profile? profile) =>
      e.section == null || adminCanSection(profile, e.section!);

  List<_NavEntry> _visibleEntries({
    required bool isSuperAdmin,
    required Profile? profile,
  }) =>
      [
        ..._mainEntries,
        if (isSuperAdmin) ..._superEntries,
      ].where((e) => _entryVisible(e, profile)).toList();

  int? _selectedIndex(List<_NavEntry> entries) {
    // Correspondance par préfixe : `/competitions/xyz` sélectionne
    // l'item `/competitions`. Le dashboard (`/`) ne matche que lui-même.
    for (var i = 0; i < entries.length; i++) {
      final route = entries[i].route;
      if (route == AdminDesktopRoutes.dashboard) {
        if (currentPath == route) return i;
        continue;
      }
      if (currentPath == route || currentPath.startsWith('$route/')) {
        return i;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(currentProfileProvider).valueOrNull;
    final isSuperAdmin = profile?.isSuperAdmin ?? false;
    final entries =
        _visibleEntries(isSuperAdmin: isSuperAdmin, profile: profile);
    final selected = _selectedIndex(entries);

    // Active l'abonnement Realtime (paiements/litiges/messages/réintégrations)
    // dès que le shell est monté — sinon le provider ne s'instancierait qu'à
    // la première ouverture de la cloche.
    ref.watch(desktopNotificationsProvider);

    final visibleMain =
        _mainEntries.where((e) => _entryVisible(e, profile)).toList();
    final visibleSuper =
        _superEntries.where((e) => _entryVisible(e, profile)).toList();

    final items = <NavigationPaneItem>[
      ...visibleMain.map((e) => _paneItem(context, e)),
      if (isSuperAdmin && visibleSuper.isNotEmpty) ...[
        PaneItemSeparator(),
        PaneItemHeader(
          header: Text(
            'SUPER ADMIN',
            style: GoogleFonts.bebasNeue(
              color: ArenaColors.tierGold,
              fontSize: 14,
              letterSpacing: 1.5,
            ),
          ),
        ),
        ...visibleSuper.map((e) => _paneItem(context, e)),
      ],
    ];

    return NavigationView(
      titleBar: TitleBar(
        isBackButtonVisible: false,
        // Barre native masquée (TitleBarStyle.hidden) → cette barre Fluent
        // gère le déplacement de la fenêtre + le double-clic agrandir.
        onDragStarted: windowManager.startDragging,
        onDoubleTap: toggleMaximize,
        captionControls: const DesktopWindowCaption(),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'ARENA',
              style: GoogleFonts.bebasNeue(
                color: ArenaColors.bone,
                fontSize: 22,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              'ADMIN',
              style: GoogleFonts.bebasNeue(
                color: ArenaColors.neonRed,
                fontSize: 22,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
        endHeader: Padding(
          padding: const EdgeInsets.only(right: 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (profile != null)
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Text(
                    profile.username,
                    style: GoogleFonts.spaceGrotesk(
                      color: ArenaColors.silver,
                      fontSize: 13,
                    ),
                  ),
                ),
              const DesktopNotificationBell(),
              const SizedBox(width: 4),
              IconButton(
                icon: const Icon(FluentIcons.contact, size: 16),
                onPressed: () => context.go(AdminDesktopRoutes.profile),
              ),
              const SizedBox(width: 4),
              IconButton(
                icon: const Icon(FluentIcons.sign_out, size: 16),
                onPressed: () async {
                  await ref.read(signOutProvider)();
                },
              ),
            ],
          ),
        ),
      ),
      pane: NavigationPane(
        selected: selected,
        displayMode: PaneDisplayMode.expanded,
        size: const NavigationPaneSize(openWidth: 240),
        items: items,
        footerItems: [
          PaneItemSeparator(),
          _paneItem(
            context,
            const _NavEntry(
              route: AdminDesktopRoutes.profile,
              icon: FluentIcons.contact_card,
              label: 'Mon profil',
            ),
          ),
        ],
      ),
      paneBodyBuilder: (item, body) => child,
    );
  }

  PaneItem _paneItem(BuildContext context, _NavEntry entry) {
    return PaneItem(
      icon: Icon(entry.icon, size: 18),
      title: Text(entry.label),
      body: const SizedBox.shrink(),
      onTap: () => context.go(entry.route),
    );
  }
}
