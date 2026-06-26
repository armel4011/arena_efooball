import 'package:arena/core/router/router_refresh.dart';
import 'package:arena/data/models/competition.dart';
import 'package:arena/features/splash/splash_router.dart';
import 'package:arena/features_admin/audit/admin_audit_log_page.dart';
import 'package:arena/features_admin/auth_admin/admin_auth_providers.dart';
import 'package:arena/features_admin/auth_admin/invitation_redeem_screen.dart';
import 'package:arena/features_admin/auth_admin/login_admin_screen.dart';
import 'package:arena/features_admin/auth_admin/splash_admin_screen.dart';
import 'package:arena/features_admin/auth_admin/totp_setup_screen.dart';
import 'package:arena/features_admin/auth_admin/totp_verify_screen.dart';
import 'package:arena/features_admin/bracket_admin/admin_bracket_management_page.dart';
import 'package:arena/features_admin/competitions_admin/admin_competition_detail_page.dart';
import 'package:arena/features_admin/competitions_admin/admin_competitions_list_page.dart';
import 'package:arena/features_admin/competitions_admin/create_competition_page.dart';
import 'package:arena/features_admin/dashboard/admin_dashboard_page.dart';
import 'package:arena/features_admin/disputes_admin/admin_disputes_list_page.dart';
import 'package:arena/features_admin/disputes_admin/admin_disputes_page.dart';
import 'package:arena/features_admin/matches_admin/admin_matches_list_page.dart';
import 'package:arena/features_admin/profile_admin/admin_profile_page.dart';
import 'package:arena/features_admin/streams_admin/admin_stream_moderation_page.dart';
import 'package:arena/features_admin/streams_admin/admin_watch_stream_page.dart';
import 'package:arena/features_admin/super_admin/admin_chat_thread_page.dart';
import 'package:arena/features_admin/super_admin/super_admin_broadcast.dart';
import 'package:arena/features_admin/super_admin/super_admin_dashboard.dart';
import 'package:arena/features_admin/super_admin/super_admin_invitations.dart';
import 'package:arena/features_admin/super_admin/super_admin_payments_validation_page.dart';
import 'package:arena/features_admin/super_admin/super_admin_payouts_page.dart';
import 'package:arena/features_admin/super_admin/super_admin_promo_banner.dart';
import 'package:arena/features_admin/super_admin/super_admin_reintegration_requests.dart';
import 'package:arena/features_admin/super_admin/super_admin_revenue.dart';
import 'package:arena/features_admin/super_admin/super_admin_support_inbox.dart';
import 'package:arena/features_admin/super_admin/super_admin_support_thread.dart';
import 'package:arena/features_admin/super_admin/super_admin_tutorial_video.dart';
import 'package:arena/features_admin/super_admin/super_admin_users.dart';
import 'package:arena/features_shared/presentation/dev_preview_page.dart';
import 'package:arena/features_user/auth/auth_providers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Routes for the Admin app.
///
/// PHASE 2bis wires the auth flow (splash, login, invitation, TOTP).
/// PHASE 11 adds the operational screens — dashboard, competitions
/// (list / create / detail), matches, bracket, streams, payouts,
/// disputes, audit log + super-admin (dashboard, invitations, users,
/// revenue).
abstract final class AdminRoutes {
  static const home = '/';
  static const splash = '/splash';
  static const login = '/login';
  static const invitation = '/invitation';
  static const totpSetup = '/totp/setup';
  static const totpVerify = '/totp/verify';

  // Admin core
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
  static const disputesList = '/disputes-list';
  static const auditLog = '/audit';
  static const profile = '/profile';

  // Super-admin
  static const superDashboard = '/super';
  static const superInvitations = '/super/invitations';
  static const superUsers = '/super/users';
  static const superRevenue = '/super/revenue';
  static const superPaymentsValidation = '/super/payments';
  static const superPayouts = '/super/payouts';
  static const superBroadcast = '/super/broadcast';
  static const superPromoBanner = '/super/promo-banner';
  static const superTutorialVideo = '/super/tutorial-video';
  static const superReintegration = '/super/reintegration';
  static const superChatThread = '/super/messages/:userId';
  static const superSupport = '/super/support';
  static const superSupportThread = '/super/support/:channelId';

  static const devPreview = '/_dev/widgets';
  static const intro = '/intro';

  /// Routes reachable while not yet fully authenticated (no session OR
  /// session without TOTP confirmation).
  static const unauthenticated = <String>{
    splash,
    login,
    invitation,
    totpSetup,
    totpVerify,
  };

  /// Builds the concrete `/competitions/<id>` URL.
  static String competitionDetailPath(String id) => '/competitions/$id';

  /// Builds the concrete `/competitions/<id>/edit` URL.
  static String competitionEditPath(String id) => '/competitions/$id/edit';

  /// Builds the concrete `/competitions/<id>/bracket` URL.
  static String bracketPath(String id) => '/competitions/$id/bracket';

  /// Builds the concrete `/disputes/<matchId>` URL.
  static String disputePath(String matchId) => '/disputes/$matchId';

  /// Builds the concrete `/streams/watch/<matchId>` URL.
  static String streamWatchPath(String matchId) => '/streams/watch/$matchId';

  /// Builds the concrete `/super/messages/<userId>` URL.
  static String superChatThreadPath(String userId) => '/super/messages/$userId';

  /// Builds the concrete `/super/support/<channelId>` URL.
  static String superSupportThreadPath(String channelId) =>
      '/super/support/$channelId';
}

final adminRouterProvider = Provider<GoRouter>((ref) {
  final refresh = RouterRefreshListenable(
    ref,
    [currentSessionProvider, currentProfileProvider, adminTotpSessionProvider],
  );
  ref.onDispose(refresh.dispose);

  return GoRouter(
    initialLocation: AdminRoutes.intro,
    debugLogDiagnostics: true,
    refreshListenable: refresh,
    redirect: (context, state) {
      final loc = state.matchedLocation;
      final session = ref.read(currentSessionProvider);

      // Cold-start splash (branding pack v2) — exempt du redirect, le
      // callback route ensuite vers AdminRoutes.splash.
      if (loc == AdminRoutes.intro) return null;

      if (loc == AdminRoutes.devPreview) return null;

      if (session == null) {
        return AdminRoutes.unauthenticated.contains(loc)
            ? null
            : AdminRoutes.splash;
      }

      // Session present — but TOTP must be set up & verified before
      // granting access to the admin home / dashboard.
      final profile = ref.read(currentProfileProvider).valueOrNull;
      if (profile == null) return null; // Still hydrating, let the screen render.

      if (!profile.isAdmin) {
        // Wrong-app guard — sign-out is handled in [AdminAuthRepository.signInAdmin]
        // when role check fails. Belt-and-braces : send them back to splash.
        return AdminRoutes.splash;
      }

      if (!profile.totpEnabled) {
        return loc == AdminRoutes.totpSetup ? null : AdminRoutes.totpSetup;
      }

      // TOTP enrôlé — mais il faut un 2e facteur VALIDÉ cette session
      // (`totp_enabled` = configuré ≠ vérifié). Sinon on force `/totp/verify`.
      final totpVerified =
          ref.read(adminTotpSessionProvider) == profile.id;
      if (!totpVerified) {
        return loc == AdminRoutes.totpVerify ? null : AdminRoutes.totpVerify;
      }

      // Garde super-admin : les routes `/super/*` (revenus, validation des
      // paiements, bannissements, codes d'invitation, broadcast…) exigent le
      // rôle super_admin, pas seulement admin. Sans ce contrôle elles sont
      // atteignables en deep-link par un admin simple ; la RLS protège la
      // donnée côté serveur, ceci ferme l'accès UI (défense en profondeur).
      if (loc.startsWith('/super') && !profile.isSuperAdmin) {
        return AdminRoutes.home;
      }

      // Pleinement authentifié — keep them out of the auth screens.
      if (AdminRoutes.unauthenticated.contains(loc)) {
        return AdminRoutes.home;
      }
      return null;
    },
    routes: [
      GoRoute(
        path: AdminRoutes.intro,
        name: 'admin.intro',
        builder: (context, state) => const SplashPage(
          isAdmin: true,
          nextRoute: AdminRoutes.splash,
        ),
      ),
      GoRoute(
        path: AdminRoutes.splash,
        name: 'admin.splash',
        builder: (context, state) => const SplashAdminScreen(),
      ),
      GoRoute(
        path: AdminRoutes.login,
        name: 'admin.login',
        builder: (context, state) => const LoginAdminScreen(),
      ),
      GoRoute(
        path: AdminRoutes.invitation,
        name: 'admin.invitation',
        builder: (context, state) => const InvitationRedeemScreen(),
      ),
      GoRoute(
        path: AdminRoutes.totpSetup,
        name: 'admin.totpSetup',
        builder: (context, state) => const TotpSetupScreen(),
      ),
      GoRoute(
        path: AdminRoutes.totpVerify,
        name: 'admin.totpVerify',
        builder: (context, state) => const TotpVerifyScreen(),
      ),
      GoRoute(
        path: AdminRoutes.home,
        name: 'admin.home',
        builder: (context, state) => const AdminDashboardPage(),
      ),
      GoRoute(
        path: AdminRoutes.competitions,
        name: 'admin.competitions',
        builder: (context, state) => const AdminCompetitionsListPage(),
      ),
      GoRoute(
        path: AdminRoutes.competitionsCreate,
        name: 'admin.competitionsCreate',
        builder: (context, state) => const CreateCompetitionPage(),
      ),
      GoRoute(
        path: AdminRoutes.competitionDetail,
        name: 'admin.competitionDetail',
        builder: (context, state) => AdminCompetitionDetailPage(
          competitionId: state.pathParameters['id'] ?? '',
        ),
      ),
      GoRoute(
        path: AdminRoutes.competitionEdit,
        name: 'admin.competitionEdit',
        builder: (context, state) => CreateCompetitionPage(
          editing: state.extra as Competition?,
        ),
      ),
      GoRoute(
        path: AdminRoutes.matches,
        name: 'admin.matches',
        builder: (context, state) => const AdminMatchesListPage(),
      ),
      GoRoute(
        path: AdminRoutes.bracket,
        name: 'admin.bracket',
        builder: (context, state) => AdminBracketManagementPage(
          competitionId: state.pathParameters['id'] ?? '',
        ),
      ),
      GoRoute(
        path: AdminRoutes.streams,
        name: 'admin.streams',
        builder: (context, state) => const AdminStreamModerationPage(),
      ),
      GoRoute(
        path: AdminRoutes.streamWatch,
        name: 'admin.streamWatch',
        builder: (context, state) => AdminWatchStreamPage(
          matchId: state.pathParameters['matchId'] ?? '',
        ),
      ),
      GoRoute(
        path: AdminRoutes.disputesList,
        name: 'admin.disputesList',
        builder: (context, state) => const AdminDisputesListPage(),
      ),
      GoRoute(
        path: AdminRoutes.disputes,
        name: 'admin.disputes',
        builder: (context, state) => AdminDisputesPage(
          matchId: state.pathParameters['matchId'] ?? '',
        ),
      ),
      GoRoute(
        path: AdminRoutes.auditLog,
        name: 'admin.auditLog',
        builder: (context, state) => const AdminAuditLogPage(),
      ),
      GoRoute(
        path: AdminRoutes.profile,
        name: 'admin.profile',
        builder: (context, state) => const AdminProfilePage(),
      ),
      GoRoute(
        path: AdminRoutes.superDashboard,
        name: 'admin.superDashboard',
        builder: (context, state) => const SuperAdminDashboard(),
      ),
      GoRoute(
        path: AdminRoutes.superInvitations,
        name: 'admin.superInvitations',
        builder: (context, state) => const SuperAdminInvitations(),
      ),
      GoRoute(
        path: AdminRoutes.superUsers,
        name: 'admin.superUsers',
        builder: (context, state) => const SuperAdminUsers(),
      ),
      GoRoute(
        path: AdminRoutes.superRevenue,
        name: 'admin.superRevenue',
        builder: (context, state) => const SuperAdminRevenue(),
      ),
      GoRoute(
        path: AdminRoutes.superPaymentsValidation,
        name: 'admin.superPaymentsValidation',
        builder: (context, state) =>
            const SuperAdminPaymentsValidationPage(),
      ),
      GoRoute(
        path: AdminRoutes.superPayouts,
        name: 'admin.superPayouts',
        builder: (context, state) => const SuperAdminPayoutsPage(),
      ),
      GoRoute(
        path: AdminRoutes.superBroadcast,
        name: 'admin.superBroadcast',
        builder: (context, state) => const SuperAdminBroadcast(),
      ),
      GoRoute(
        path: AdminRoutes.superPromoBanner,
        name: 'admin.superPromoBanner',
        builder: (context, state) => const SuperAdminPromoBanner(),
      ),
      GoRoute(
        path: AdminRoutes.superTutorialVideo,
        name: 'admin.superTutorialVideo',
        builder: (context, state) => const SuperAdminTutorialVideo(),
      ),
      GoRoute(
        path: AdminRoutes.superReintegration,
        name: 'admin.superReintegration',
        builder: (context, state) =>
            const SuperAdminReintegrationRequests(),
      ),
      GoRoute(
        path: AdminRoutes.superChatThread,
        name: 'admin.superChatThread',
        builder: (context, state) => AdminChatThreadPage(
          userId: state.pathParameters['userId'] ?? '',
        ),
      ),
      GoRoute(
        path: AdminRoutes.superSupport,
        name: 'admin.superSupport',
        builder: (context, state) => const SuperAdminSupportInbox(),
      ),
      GoRoute(
        path: AdminRoutes.superSupportThread,
        name: 'admin.superSupportThread',
        builder: (context, state) => SuperAdminSupportThread(
          channelId: state.pathParameters['channelId'] ?? '',
          username: state.extra is String ? state.extra! as String : 'Support',
        ),
      ),
      // Route outillage dev — réservée aux builds debug. Cf. audit quick-wins.
      if (kDebugMode)
        GoRoute(
          path: AdminRoutes.devPreview,
          name: 'admin.dev.preview',
          builder: (context, state) => const DevPreviewPage(),
        ),
    ],
  );
});
