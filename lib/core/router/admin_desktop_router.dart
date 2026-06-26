import 'package:arena/core/router/router_refresh.dart';
import 'package:arena/data/models/competition.dart';
import 'package:arena/features_admin/auth_admin/admin_auth_providers.dart';
import 'package:arena/features_admin_desktop/audit/desktop_audit_log_page.dart';
import 'package:arena/features_admin_desktop/auth/desktop_invitation_redeem_screen.dart';
import 'package:arena/features_admin_desktop/auth/desktop_login_screen.dart';
import 'package:arena/features_admin_desktop/auth/desktop_totp_setup_screen.dart';
import 'package:arena/features_admin_desktop/auth/desktop_totp_verify_screen.dart';
import 'package:arena/features_admin_desktop/communication/desktop_broadcast_page.dart';
import 'package:arena/features_admin_desktop/communication/desktop_chat_thread_page.dart';
import 'package:arena/features_admin_desktop/communication/desktop_support_page.dart';
import 'package:arena/features_admin_desktop/competitions/desktop_bracket_page.dart';
import 'package:arena/features_admin_desktop/competitions/desktop_competition_detail_page.dart';
import 'package:arena/features_admin_desktop/competitions/desktop_competitions_list_page.dart';
import 'package:arena/features_admin_desktop/competitions/desktop_create_competition_page.dart';
import 'package:arena/features_admin_desktop/dashboard/desktop_dashboard_page.dart';
import 'package:arena/features_admin_desktop/finance/desktop_disputes_page.dart';
import 'package:arena/features_admin_desktop/finance/desktop_payments_validation_page.dart';
import 'package:arena/features_admin_desktop/finance/desktop_payouts_page.dart';
import 'package:arena/features_admin_desktop/finance/desktop_super_payouts_page.dart';
import 'package:arena/features_admin_desktop/matches/desktop_matches_list_page.dart';
import 'package:arena/features_admin_desktop/profile/desktop_profile_page.dart';
import 'package:arena/features_admin_desktop/shell/admin_desktop_shell.dart';
import 'package:arena/features_admin_desktop/streams/desktop_stream_moderation_page.dart';
import 'package:arena/features_admin_desktop/streams/desktop_watch_stream_page.dart';
import 'package:arena/features_admin_desktop/super_admin/desktop_invitations_page.dart';
import 'package:arena/features_admin_desktop/super_admin/desktop_promo_banner_page.dart';
import 'package:arena/features_admin_desktop/super_admin/desktop_reintegration_page.dart';
import 'package:arena/features_admin_desktop/super_admin/desktop_revenue_page.dart';
import 'package:arena/features_admin_desktop/super_admin/desktop_super_dashboard_page.dart';
import 'package:arena/features_admin_desktop/super_admin/desktop_tutorial_banners_page.dart';
import 'package:arena/features_admin_desktop/super_admin/desktop_users_page.dart';
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
  static const invitation = '/invitation';
  static const totpSetup = '/totp/setup';
  static const totpVerify = '/totp/verify';

  // Coeur admin (dans le shell)
  static const dashboard = '/';
  static const competitions = '/competitions';
  static const competitionsCreate = '/competitions/create';
  static const competitionDetail = '/competitions/:id';
  static const competitionEdit = '/competitions/:id/edit';
  static const matches = '/matches';
  static const bracket = '/competitions/:id/bracket';
  static const streams = '/streams';
  static const streamWatch = '/streams/watch/:matchId';
  static const payouts = '/payouts';
  static const disputes = '/disputes/:matchId';
  static const auditLog = '/audit';
  static const profile = '/profile';

  // Super-admin (dans le shell)
  static const superDashboard = '/super';
  static const superInvitations = '/super/invitations';
  static const superUsers = '/super/users';
  static const superRevenue = '/super/revenue';
  static const superPaymentsValidation = '/super/payments';
  static const superPayouts = '/super/payouts';
  static const superBroadcast = '/super/broadcast';
  static const superPromoBanner = '/super/promo-banner';
  static const superReintegration = '/super/reintegration';
  static const superSupport = '/super/support';
  static const superTutorialBanners = '/super/tutorial-banners';
  static const superChatThread = '/super/messages/:userId';

  /// Routes accessibles sans authentification complète.
  static const unauthenticated = <String>{
    login,
    invitation,
    totpSetup,
    totpVerify,
  };

  /// URL concrète `/competitions/<id>`.
  static String competitionDetailPath(String id) => '/competitions/$id';

  /// URL concrète `/competitions/<id>/edit`.
  static String competitionEditPath(String id) => '/competitions/$id/edit';

  /// URL concrète `/competitions/<id>/bracket`.
  static String bracketPath(String id) => '/competitions/$id/bracket';

  /// URL concrète `/streams/watch/<matchId>`.
  static String streamWatchPath(String matchId) => '/streams/watch/$matchId';

  /// URL concrète `/disputes/<matchId>`.
  static String disputePath(String matchId) => '/disputes/$matchId';

  /// URL concrète `/super/messages/<userId>`.
  static String superChatThreadPath(String userId) => '/super/messages/$userId';
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
        path: AdminDesktopRoutes.invitation,
        name: 'desktop.invitation',
        builder: (context, state) => const DesktopInvitationRedeemScreen(),
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

          // ─── Compétitions (Vague 2) ────────────────────────────────
          GoRoute(
            path: AdminDesktopRoutes.competitions,
            name: 'desktop.competitions',
            builder: (context, state) => const DesktopCompetitionsListPage(),
          ),
          GoRoute(
            path: AdminDesktopRoutes.competitionsCreate,
            name: 'desktop.competitionsCreate',
            builder: (context, state) => DesktopCreateCompetitionPage(
              editing: state.extra as Competition?,
            ),
          ),
          GoRoute(
            path: AdminDesktopRoutes.competitionDetail,
            name: 'desktop.competitionDetail',
            builder: (context, state) => DesktopCompetitionDetailPage(
              competitionId: state.pathParameters['id'] ?? '',
            ),
          ),
          GoRoute(
            path: AdminDesktopRoutes.competitionEdit,
            name: 'desktop.competitionEdit',
            builder: (context, state) => DesktopCreateCompetitionPage(
              editing: state.extra as Competition?,
            ),
          ),
          GoRoute(
            path: AdminDesktopRoutes.bracket,
            name: 'desktop.bracket',
            builder: (context, state) => DesktopBracketPage(
              competitionId: state.pathParameters['id'] ?? '',
            ),
          ),
          GoRoute(
            path: AdminDesktopRoutes.matches,
            name: 'desktop.matches',
            builder: (context, state) => const DesktopMatchesListPage(),
          ),

          // ─── Streams (Vague 5) ─────────────────────────────────────
          GoRoute(
            path: AdminDesktopRoutes.streams,
            name: 'desktop.streams',
            builder: (context, state) => const DesktopStreamModerationPage(),
          ),
          GoRoute(
            path: AdminDesktopRoutes.streamWatch,
            name: 'desktop.streamWatch',
            builder: (context, state) => DesktopWatchStreamPage(
              matchId: state.pathParameters['matchId'] ?? '',
            ),
          ),

          // ─── Finance (Vague 3) ─────────────────────────────────────
          GoRoute(
            path: AdminDesktopRoutes.payouts,
            name: 'desktop.payouts',
            builder: (context, state) => const DesktopPayoutsPage(),
          ),
          GoRoute(
            path: AdminDesktopRoutes.disputes,
            name: 'desktop.disputes',
            builder: (context, state) => DesktopDisputesPage(
              matchId: state.pathParameters['matchId'] ?? '',
            ),
          ),

          // ─── Audit + profil (Vague 4 / 1) ──────────────────────────
          GoRoute(
            path: AdminDesktopRoutes.auditLog,
            name: 'desktop.auditLog',
            builder: (context, state) => const DesktopAuditLogPage(),
          ),
          GoRoute(
            path: AdminDesktopRoutes.profile,
            name: 'desktop.profile',
            builder: (context, state) => const DesktopProfilePage(),
          ),

          // ─── Super-admin (Vagues 3 + 4) ────────────────────────────
          GoRoute(
            path: AdminDesktopRoutes.superDashboard,
            name: 'desktop.superDashboard',
            builder: (context, state) => const DesktopSuperDashboardPage(),
          ),
          GoRoute(
            path: AdminDesktopRoutes.superInvitations,
            name: 'desktop.superInvitations',
            builder: (context, state) => const DesktopInvitationsPage(),
          ),
          GoRoute(
            path: AdminDesktopRoutes.superUsers,
            name: 'desktop.superUsers',
            builder: (context, state) => const DesktopUsersPage(),
          ),
          GoRoute(
            path: AdminDesktopRoutes.superRevenue,
            name: 'desktop.superRevenue',
            builder: (context, state) => const DesktopRevenuePage(),
          ),
          GoRoute(
            path: AdminDesktopRoutes.superPaymentsValidation,
            name: 'desktop.superPaymentsValidation',
            builder: (context, state) =>
                const DesktopPaymentsValidationPage(),
          ),
          GoRoute(
            path: AdminDesktopRoutes.superPayouts,
            name: 'desktop.superPayouts',
            builder: (context, state) => const DesktopSuperPayoutsPage(),
          ),
          GoRoute(
            path: AdminDesktopRoutes.superBroadcast,
            name: 'desktop.superBroadcast',
            builder: (context, state) => const DesktopBroadcastPage(),
          ),
          GoRoute(
            path: AdminDesktopRoutes.superPromoBanner,
            name: 'desktop.superPromoBanner',
            builder: (context, state) => const DesktopPromoBannerPage(),
          ),
          GoRoute(
            path: AdminDesktopRoutes.superReintegration,
            name: 'desktop.superReintegration',
            builder: (context, state) => const DesktopReintegrationPage(),
          ),
          GoRoute(
            path: AdminDesktopRoutes.superSupport,
            name: 'desktop.superSupport',
            builder: (context, state) => const DesktopSupportPage(),
          ),
          GoRoute(
            path: AdminDesktopRoutes.superTutorialBanners,
            name: 'desktop.superTutorialBanners',
            builder: (context, state) => const DesktopTutorialBannersPage(),
          ),
          GoRoute(
            path: AdminDesktopRoutes.superChatThread,
            name: 'desktop.superChatThread',
            builder: (context, state) => DesktopChatThreadPage(
              userId: state.pathParameters['userId'] ?? '',
            ),
          ),
        ],
      ),
    ],
  );
});
