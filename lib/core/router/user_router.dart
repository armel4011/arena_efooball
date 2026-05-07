import 'package:arena/core/router/router_refresh.dart';
import 'package:arena/core/services/onboarding_service.dart';
import 'package:arena/features_shared/presentation/dev_preview_page.dart';
import 'package:arena/features_user/auth/auth_providers.dart';
import 'package:arena/features_user/auth/cgu_acceptance_page.dart';
import 'package:arena/features_user/auth/forgot_password_page.dart';
import 'package:arena/features_user/auth/link_existing_account_page.dart';
import 'package:arena/features_user/auth/login_user_screen.dart';
import 'package:arena/features_user/auth/register_user_screen.dart';
import 'package:arena/features_user/auth/reset_password_page.dart';
import 'package:arena/features_user/auth/splash_user_screen.dart';
import 'package:arena/features_user/chat/chat_page.dart';
import 'package:arena/features_user/competitions/competition_detail_page.dart';
import 'package:arena/features_user/home/main_layout.dart';
import 'package:arena/features_user/match/match_room_page.dart';
import 'package:arena/features_user/onboarding/onboarding_page.dart';
import 'package:arena/features_user/streaming/live_streams_page.dart';
import 'package:arena/features_user/streaming/watch_stream_page.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Routes for the User app.
///
/// PHASE 2 sets up the auth flow + onboarding gate via `redirect`.
/// PHASE 4+ will add /competitions, /match/:id, etc.
abstract final class UserRoutes {
  static const home = '/';
  static const onboarding = '/onboarding';
  static const splash = '/splash';
  static const login = '/login';
  static const register = '/register';
  static const forgotPassword = '/forgot-password';
  static const resetPassword = '/reset-password';
  static const linkAccount = '/link-account';
  static const cguAcceptance = '/cgu-acceptance';
  static const competitionDetail = '/competitions/:id';
  static const matchRoom = '/match/:id';
  static const matchChat = '/chat/match/:id';
  static const liveStreams = '/streams';
  static const watchStream = '/streams/watch/:id';
  static const devPreview = '/dev/preview';

  /// Builds the concrete `/competitions/<id>` URL — go_router parses
  /// `:id` server-side, but `context.go` needs a real path.
  static String competitionPath(String id) => '/competitions/$id';

  /// Builds the concrete `/match/<id>` URL.
  static String matchPath(String id) => '/match/$id';

  /// Builds the concrete `/chat/match/<id>` URL.
  static String matchChatPath(String matchId) => '/chat/match/$matchId';

  /// Builds the concrete `/streams/watch/<matchId>` URL — points at
  /// the Agora viewer for a publicly streamed match (PHASE 8.7).
  static String watchStreamPath(String matchId) => '/streams/watch/$matchId';

  /// Routes the user can be on without being authenticated.
  static const unauthenticated = <String>{
    splash,
    login,
    register,
    forgotPassword,
    resetPassword,
    linkAccount,
  };
}

final userRouterProvider = Provider<GoRouter>((ref) {
  final refresh = RouterRefreshListenable(
    ref,
    [
      onboardingCompletedProvider,
      currentSessionProvider,
      currentProfileProvider,
    ],
  );
  ref.onDispose(refresh.dispose);

  return GoRouter(
    initialLocation: UserRoutes.home,
    debugLogDiagnostics: true,
    refreshListenable: refresh,
    redirect: (context, state) {
      final loc = state.matchedLocation;
      final onboardingDone = ref.read(onboardingCompletedProvider);
      final session = ref.read(currentSessionProvider);

      // Always allow the dev preview during phases 1 → 11.
      if (loc == UserRoutes.devPreview) return null;

      // Reset password is reachable from a deep link even if no session
      // yet (Supabase hydrates a recovery session before we land here).
      if (loc == UserRoutes.resetPassword) return null;

      if (!onboardingDone) {
        return loc == UserRoutes.onboarding ? null : UserRoutes.onboarding;
      }

      if (session == null) {
        // Not authenticated — only auth-related screens are allowed.
        if (UserRoutes.unauthenticated.contains(loc)) return null;
        return UserRoutes.splash;
      }

      // Authenticated. Force CGU acceptance for legacy / SSO accounts
      // that landed here without a `cgu_accepted_at` stamp.
      final profile = ref.read(currentProfileProvider).value;
      if (profile != null && !profile.hasAcceptedCgu) {
        return loc == UserRoutes.cguAcceptance
            ? null
            : UserRoutes.cguAcceptance;
      }

      // CGU OK — keep them out of auth + cgu screens.
      if (UserRoutes.unauthenticated.contains(loc) ||
          loc == UserRoutes.onboarding ||
          loc == UserRoutes.cguAcceptance) {
        return UserRoutes.home;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: UserRoutes.home,
        name: 'user.home',
        builder: (context, state) => const MainLayout(),
      ),
      GoRoute(
        path: UserRoutes.onboarding,
        name: 'user.onboarding',
        builder: (context, state) => Consumer(
          builder: (context, ref, _) => OnboardingPage(
            onFinish:
                ref.read(onboardingCompletedProvider.notifier).markCompleted,
          ),
        ),
      ),
      GoRoute(
        path: UserRoutes.splash,
        name: 'user.splash',
        builder: (context, state) => const SplashUserScreen(),
      ),
      GoRoute(
        path: UserRoutes.login,
        name: 'user.login',
        builder: (context, state) => const LoginUserScreen(),
      ),
      GoRoute(
        path: UserRoutes.register,
        name: 'user.register',
        builder: (context, state) => const RegisterUserScreen(),
      ),
      GoRoute(
        path: UserRoutes.forgotPassword,
        name: 'user.forgotPassword',
        builder: (context, state) => const ForgotPasswordPage(),
      ),
      GoRoute(
        path: UserRoutes.resetPassword,
        name: 'user.resetPassword',
        builder: (context, state) => const ResetPasswordPage(),
      ),
      GoRoute(
        path: UserRoutes.linkAccount,
        name: 'user.linkAccount',
        builder: (context, state) {
          final extra = state.extra;
          if (extra is LinkAccountArgs) {
            return LinkExistingAccountPage(
              email: extra.email,
              providerLabel: extra.providerLabel,
            );
          }
          return const LinkExistingAccountPage();
        },
      ),
      GoRoute(
        path: UserRoutes.cguAcceptance,
        name: 'user.cguAcceptance',
        builder: (context, state) => const CguAcceptancePage(),
      ),
      GoRoute(
        path: UserRoutes.competitionDetail,
        name: 'user.competitionDetail',
        builder: (context, state) => CompetitionDetailPage(
          competitionId: state.pathParameters['id'] ?? '',
        ),
      ),
      GoRoute(
        path: UserRoutes.matchRoom,
        name: 'user.matchRoom',
        builder: (context, state) => MatchRoomPage(
          matchId: state.pathParameters['id'] ?? '',
        ),
      ),
      GoRoute(
        path: UserRoutes.matchChat,
        name: 'user.matchChat',
        builder: (context, state) => ChatPage(
          matchId: state.pathParameters['id'] ?? '',
        ),
      ),
      GoRoute(
        path: UserRoutes.liveStreams,
        name: 'user.liveStreams',
        builder: (context, state) => const LiveStreamsPage(),
      ),
      GoRoute(
        path: UserRoutes.watchStream,
        name: 'user.watchStream',
        builder: (context, state) => WatchStreamPage(
          matchId: state.pathParameters['id'] ?? '',
        ),
      ),
      GoRoute(
        path: UserRoutes.devPreview,
        name: 'user.dev.preview',
        builder: (context, state) => const DevPreviewPage(),
      ),
    ],
  );
});

/// Args carried via `context.go(linkAccount, extra: ...)` from the social
/// sign-in handler when an email collision is detected (PHASE 2.3).
class LinkAccountArgs {
  const LinkAccountArgs({required this.email, required this.providerLabel});
  final String? email;
  final String providerLabel;
}
