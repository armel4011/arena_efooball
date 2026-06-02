import 'package:arena/core/router/router_refresh.dart';
import 'package:arena/features_admin/auth_admin/admin_auth_providers.dart';
import 'package:arena/features_admin_desktop/auth/desktop_login_screen.dart';
import 'package:arena/features_admin_desktop/auth/desktop_totp_setup_screen.dart';
import 'package:arena/features_admin_desktop/auth/desktop_totp_verify_screen.dart';
import 'package:arena/features_admin_desktop/dashboard/desktop_dashboard_page.dart';
import 'package:arena/features_admin_desktop/profile/desktop_profile_page.dart';
import 'package:arena/features_admin_desktop/shared/desktop_placeholder_page.dart';
import 'package:arena/features_admin_desktop/shell/admin_desktop_shell.dart';
import 'package:arena/features_shared/auth_common/shared_auth_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Routes de l'app ARENA Admin **Desktop** (Windows).
///
/// Reprend la même arborescence que `AdminRoutes` (mobile) — mêmes guards
/// (session → rôle admin → TOTP setup → TOTP verify) — mais les écrans
/// authentifiés vivent dans un ShellRoute qui fournit la barre latérale
/// Fluent ([AdminDesktopShell]).
abstract final class AdminDesktopRoutes {
  static const login = '/login';
  static const totpSetup = '/totp/setup';
  static const totpVerify = '/totp/verify';

  // Coeur admin (dans le shell)
  static const dashboard = '/';
  static const competitions = '/competitions';
  static const competitionsCreate = '/competitions/create';
  static const competitionDetail = '/competitions/:id';
  static const matches = '/matches';
  static const bracket = '/competitions/:id/bracket';
  static const streams = '/streams';
  static const payouts = '/payouts';
  static const auditLog = '/audit';
  static const profile = '/profile';

  // Super-admin (dans le shell)
  static const superDashboard = '/super';
  static const superInvitations = '/super/invitations';
  static const superUsers = '/super/users';
  static const superRevenue = '/super/revenue';
  static const superPaymentsValidation = '/super/payments';
  static const superBroadcast = '/super/broadcast';
  static const superReintegration = '/super/reintegration';

  /// Routes accessibles sans authentification complète.
  static const unauthenticated = <String>{login, totpSetup, totpVerify};

  /// URL concrète `/competitions/<id>`.
  static String competitionDetailPath(String id) => '/competitions/$id';

  /// URL concrète `/competitions/<id>/bracket`.
  static String bracketPath(String id) => '/competitions/$id/bracket';
}

final adminDesktopRouterProvider = Provider<GoRouter>((ref) {
  final refresh = RouterRefreshListenable(
    ref,
    [currentSessionProvider, currentProfileProvider, adminTotpSessionProvider],
  );
  ref.onDispose(refresh.dispose);

  return GoRouter(
    initialLocation: AdminDesktopRoutes.login,
    refreshListenable: refresh,
    redirect: (context, state) {
      final loc = state.matchedLocation;
      final session = ref.read(currentSessionProvider);

      if (session == null) {
        return AdminDesktopRoutes.unauthenticated.contains(loc)
            ? null
            : AdminDesktopRoutes.login;
      }

      final profile = ref.read(currentProfileProvider).valueOrNull;
      if (profile == null) return null; // hydratation en cours

      if (!profile.isAdmin) {
        // Mauvaise app — le sign-out est géré par AdminAuthRepository.
        return AdminDesktopRoutes.login;
      }

      if (!profile.totpEnabled) {
        return loc == AdminDesktopRoutes.totpSetup
            ? null
            : AdminDesktopRoutes.totpSetup;
      }

      final totpVerified = ref.read(adminTotpSessionProvider) == profile.id;
      if (!totpVerified) {
        return loc == AdminDesktopRoutes.totpVerify
            ? null
            : AdminDesktopRoutes.totpVerify;
      }

      if (AdminDesktopRoutes.unauthenticated.contains(loc)) {
        return AdminDesktopRoutes.dashboard;
      }
      return null;
    },
    routes: [
      // ─── Auth (hors shell — plein écran) ──────────────────────────
      GoRoute(
        path: AdminDesktopRoutes.login,
        name: 'desktop.login',
        builder: (context, state) => const DesktopLoginScreen(),
      ),
      GoRoute(
        path: AdminDesktopRoutes.totpSetup,
        name: 'desktop.totpSetup',
        builder: (context, state) => const DesktopTotpSetupScreen(),
      ),
      GoRoute(
        path: AdminDesktopRoutes.totpVerify,
        name: 'desktop.totpVerify',
        builder: (context, state) => const DesktopTotpVerifyScreen(),
      ),

      // ─── Écrans authentifiés (dans le shell à barre latérale) ─────
      ShellRoute(
        builder: (context, state, child) => AdminDesktopShell(
          currentPath: state.uri.path,
          child: child,
        ),
        routes: [
          GoRoute(
            path: AdminDesktopRoutes.dashboard,
            name: 'desktop.dashboard',
            builder: (context, state) => const DesktopDashboardPage(),
          ),
          GoRoute(
            path: AdminDesktopRoutes.competitions,
            name: 'desktop.competitions',
            builder: (context, state) => const DesktopPlaceholderPage(
              title: 'Compétitions',
              waveLabel: 'Vague 2',
            ),
          ),
          GoRoute(
            path: AdminDesktopRoutes.competitionsCreate,
            name: 'desktop.competitionsCreate',
            builder: (context, state) => const DesktopPlaceholderPage(
              title: 'Créer une compétition',
              waveLabel: 'Vague 2',
            ),
          ),
          GoRoute(
            path: AdminDesktopRoutes.competitionDetail,
            name: 'desktop.competitionDetail',
            builder: (context, state) => const DesktopPlaceholderPage(
              title: 'Détail compétition',
              waveLabel: 'Vague 2',
            ),
          ),
          GoRoute(
            path: AdminDesktopRoutes.bracket,
            name: 'desktop.bracket',
            builder: (context, state) => const DesktopPlaceholderPage(
              title: 'Gestion du bracket',
              waveLabel: 'Vague 2',
            ),
          ),
          GoRoute(
            path: AdminDesktopRoutes.matches,
            name: 'desktop.matches',
            builder: (context, state) => const DesktopPlaceholderPage(
              title: 'Matchs',
              waveLabel: 'Vague 2',
            ),
          ),
          GoRoute(
            path: AdminDesktopRoutes.streams,
            name: 'desktop.streams',
            builder: (context, state) => const DesktopPlaceholderPage(
              title: 'Streams live',
              waveLabel: 'Vague 5',
            ),
          ),
          GoRoute(
            path: AdminDesktopRoutes.payouts,
            name: 'desktop.payouts',
            builder: (context, state) => const DesktopPlaceholderPage(
              title: 'Paiements',
              waveLabel: 'Vague 3',
            ),
          ),
          GoRoute(
            path: AdminDesktopRoutes.auditLog,
            name: 'desktop.auditLog',
            builder: (context, state) => const DesktopPlaceholderPage(
              title: "Journal d'audit",
              waveLabel: 'Vague 4',
            ),
          ),
          GoRoute(
            path: AdminDesktopRoutes.profile,
            name: 'desktop.profile',
            builder: (context, state) => const DesktopProfilePage(),
          ),
          GoRoute(
            path: AdminDesktopRoutes.superDashboard,
            name: 'desktop.superDashboard',
            builder: (context, state) => const DesktopPlaceholderPage(
              title: "Vue d'ensemble",
              waveLabel: 'Vague 3',
            ),
          ),
          GoRoute(
            path: AdminDesktopRoutes.superInvitations,
            name: 'desktop.superInvitations',
            builder: (context, state) => const DesktopPlaceholderPage(
              title: 'Invitations admin',
              waveLabel: 'Vague 3',
            ),
          ),
          GoRoute(
            path: AdminDesktopRoutes.superUsers,
            name: 'desktop.superUsers',
            builder: (context, state) => const DesktopPlaceholderPage(
              title: 'Utilisateurs',
              waveLabel: 'Vague 3',
            ),
          ),
          GoRoute(
            path: AdminDesktopRoutes.superRevenue,
            name: 'desktop.superRevenue',
            builder: (context, state) => const DesktopPlaceholderPage(
              title: 'Revenus',
              waveLabel: 'Vague 3',
            ),
          ),
          GoRoute(
            path: AdminDesktopRoutes.superPaymentsValidation,
            name: 'desktop.superPaymentsValidation',
            builder: (context, state) => const DesktopPlaceholderPage(
              title: 'Validation des paiements',
              waveLabel: 'Vague 3',
            ),
          ),
          GoRoute(
            path: AdminDesktopRoutes.superBroadcast,
            name: 'desktop.superBroadcast',
            builder: (context, state) => const DesktopPlaceholderPage(
              title: 'Diffusion',
              waveLabel: 'Vague 4',
            ),
          ),
          GoRoute(
            path: AdminDesktopRoutes.superReintegration,
            name: 'desktop.superReintegration',
            builder: (context, state) => const DesktopPlaceholderPage(
              title: 'Demandes de réintégration',
              waveLabel: 'Vague 4',
            ),
          ),
        ],
      ),
    ],
  );
});
