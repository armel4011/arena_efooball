import 'package:arena/core/router/router_refresh.dart';
import 'package:arena/core/services/onboarding_service.dart';
import 'package:arena/data/models/competition_enums.dart';
import 'package:arena/data/models/competition_payment_option.dart';
import 'package:arena/dev/bracket_showcase_page.dart';
import 'package:arena/dev/design_showcase_page.dart';
import 'package:arena/features/splash/splash_router.dart';
import 'package:arena/features_shared/presentation/dev_preview_page.dart';
import 'package:arena/features_user/auth/auth_providers.dart';
import 'package:arena/features_user/auth/banned_account_page.dart';
import 'package:arena/features_user/auth/cgu_acceptance_page.dart';
import 'package:arena/features_user/auth/forgot_password_page.dart';
import 'package:arena/features_user/auth/link_existing_account_page.dart';
import 'package:arena/features_user/auth/login_user_screen.dart';
import 'package:arena/features_user/auth/register_user_screen.dart';
import 'package:arena/features_user/auth/reset_password_code_page.dart';
import 'package:arena/features_user/auth/reset_password_page.dart';
import 'package:arena/features_user/auth/splash_user_screen.dart';
import 'package:arena/features_user/chat/chat_page.dart';
import 'package:arena/features_user/chat/friend_chat_page.dart';
import 'package:arena/features_user/chat/messages_inbox_page.dart';
import 'package:arena/features_user/chat/support_chat_page.dart';
import 'package:arena/features_user/competitions/competition_detail_page.dart';
import 'package:arena/features_user/competitions/registration_confirm_page.dart';
import 'package:arena/features_user/draughts/ui/draughts_game_screen.dart';
import 'package:arena/features_user/home/main_layout.dart';
import 'package:arena/features_user/match_room/match_alarm_screen.dart';
import 'package:arena/features_user/match_room/match_room_page.dart';
import 'package:arena/features_user/notifications/notifications_page.dart';
import 'package:arena/features_user/onboarding/onboarding_page.dart';
import 'package:arena/features_user/payments/mobile_money_details_page.dart';
import 'package:arena/features_user/payments/payment_failed_page.dart';
import 'package:arena/features_user/payments/payment_history_page.dart';
import 'package:arena/features_user/payments/payment_method.dart';
import 'package:arena/features_user/payments/payment_method_picker_page.dart';
import 'package:arena/features_user/payments/payment_processing_page.dart';
import 'package:arena/features_user/payments/payment_success_page.dart';
import 'package:arena/features_user/payouts/payout_kyc_page.dart';
import 'package:arena/features_user/profile/about_page.dart';
import 'package:arena/features_user/profile/admin_messages_page.dart';
import 'package:arena/features_user/profile/delete_account_page.dart';
import 'package:arena/features_user/profile/edit_profile_page.dart';
import 'package:arena/features_user/profile/friends_page.dart';
import 'package:arena/features_user/profile/friends_search_page.dart';
import 'package:arena/features_user/profile/match_history_page.dart';
import 'package:arena/features_user/profile/public_profile_page.dart';
import 'package:arena/features_user/profile/settings_page.dart';
import 'package:arena/features_user/recording/match_in_progress_overlay.dart';
import 'package:arena/features_user/recording/recording_error_page.dart';
import 'package:arena/features_user/streaming/live_streams_page.dart';
import 'package:arena/features_user/streaming/watch_stream_page.dart';
import 'package:flutter/foundation.dart';
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
  static const resetPasswordCode = '/reset-password/code';
  static const resetPassword = '/reset-password';
  static const linkAccount = '/link-account';
  static const cguAcceptance = '/cgu-acceptance';
  static const banned = '/banned';
  static const competitionDetail = '/competitions/:id';
  static const matchRoom = '/match/:id';
  static const matchAlarm = '/match-alarm/:id';
  static const matchChat = '/chat/match/:id';
  static const friendChat = '/chat/friend/:friendshipId';
  static const liveStreams = '/streams';
  static const watchStream = '/streams/watch/:id';
  static const profileEdit = '/profile/edit';
  static const profileDelete = '/profile/delete';
  static const matchHistory = '/profile/match-history';
  static const publicProfile = '/profile/u/:username';
  static const friends = '/friends';
  static const friendsSearch = '/friends/search';
  static const registrationConfirm = '/competitions/:id/register/confirm';
  static const settings = '/settings';
  static const messagesInbox = '/messages';
  static const notifications = '/notifications';
  static const adminMessages = '/admin-messages';
  static const supportChat = '/support-chat';
  static const about = '/about';
  static const recordingError = '/recording/error';
  static const matchInProgressPreview = '/recording/preview';
  static const paymentMethodPicker = '/payments/method';
  static const paymentMomoDetails = '/payments/momo';
  static const paymentProcessing = '/payments/processing';
  static const paymentSuccess = '/payments/success';
  static const paymentFailed = '/payments/failed';
  static const paymentHistory = '/payments/history';
  static const payoutKyc = '/payouts/kyc';
  static const devPreview = '/_dev/widgets';
  static const devShowcase = '/dev/showcase';
  static const devBracketShowcase = '/dev/bracket-showcase';
  static const devDraughts = '/dev/draughts';
  static const intro = '/intro';

  /// Builds the concrete `/competitions/<id>/register/confirm` URL.
  static String registrationConfirmPath(String id) =>
      '/competitions/$id/register/confirm';

  /// Builds the concrete `/competitions/<id>` URL — go_router parses
  /// `:id` server-side, but `context.go` needs a real path.
  static String competitionPath(String id) => '/competitions/$id';

  /// Builds the concrete `/match/<id>` URL.
  static String matchPath(String id) => '/match/$id';

  /// Builds the concrete `/match-alarm/<id>` URL (écran de réveil du rappel).
  static String matchAlarmPath(String id) => '/match-alarm/$id';

  /// Builds the concrete `/chat/match/<id>` URL.
  static String matchChatPath(String matchId) => '/chat/match/$matchId';

  /// Builds the concrete `/chat/friend/<friendshipId>` URL.
  static String friendChatPath(String friendshipId) =>
      '/chat/friend/$friendshipId';

  /// Builds `/profile/u/<username>` — profil public d'un autre joueur.
  /// Le username vient de `profiles.username` (case sensitive côté URL
  /// mais le repo lookup est case-insensitive via ilike).
  static String publicProfilePath(String username) =>
      '/profile/u/${Uri.encodeComponent(username)}';

  /// Builds the concrete `/streams/watch/<matchId>` URL — points at
  /// the Agora viewer for a publicly streamed match (PHASE 8.7).
  static String watchStreamPath(String matchId) => '/streams/watch/$matchId';

  /// Routes the user can be on without being authenticated.
  static const unauthenticated = <String>{
    splash,
    login,
    register,
    forgotPassword,
    resetPasswordCode,
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
    initialLocation: UserRoutes.intro,
    debugLogDiagnostics: true,
    refreshListenable: refresh,
    redirect: (context, state) {
      final loc = state.matchedLocation;
      final onboardingDone = ref.read(onboardingCompletedProvider);
      final session = ref.read(currentSessionProvider);

      // Cold-start splash (branding pack v2) — exempt du redirect, le
      // callback du SplashPage repart sur `/` qui déclenche la chaîne
      // onboarding/auth/CGU.
      if (loc == UserRoutes.intro) return null;

      // Always allow the dev preview during phases 1 → 11.
      if (loc == UserRoutes.devPreview) return null;
      // Design system showcase (restyle premium 2026-05-25) — debug only,
      // page non listée dans la navigation principale.
      if (loc == UserRoutes.devShowcase) return null;
      // Bracket showcase (1024 joueurs synthétiques) — debug only, accès
      // via lien depuis le design showcase.
      if (loc == UserRoutes.devBracketShowcase) return null;
      // Aperçu du plateau de dames (pseudo-3D) — debug only.
      if (loc == UserRoutes.devDraughts) return null;

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
      // qui ont atterri ici sans `cgu_accepted_at`.
      //
      // `valueOrNull` retourne null pendant qu'un fetch est en vol
      // (typique : un token refresh Supabase invalide
      // `currentProfileProvider` et le repasse en `AsyncLoading` quelques
      // ms le temps de re-fetch). Pendant ce trou, on NE doit PAS
      // décider que "tout est OK → home" sinon on arrache l'utilisateur
      // de la page CGU à chaque refresh de token (flip-flop).
      final profileAsync = ref.read(currentProfileProvider);
      final profile = profileAsync.valueOrNull;

      // 3-strikes : un compte banni à vie est confiné sur /banned tant
      // que sa requête de réintégration n'a pas été approuvée (le
      // trigger DB flippe permanent_ban=false → la prochaine émission
      // de currentProfileProvider sort de cette branche).
      if (profile != null && profile.permanentBan) {
        return loc == UserRoutes.banned ? null : UserRoutes.banned;
      }

      // Inversement : un user qui n'est plus banni à vie ne doit pas
      // rester coincé sur /banned (peut survenir juste après l'approval).
      if (profile != null &&
          !profile.permanentBan &&
          loc == UserRoutes.banned) {
        return UserRoutes.home;
      }

      if (profile != null && !profile.hasAcceptedCgu) {
        return loc == UserRoutes.cguAcceptance
            ? null
            : UserRoutes.cguAcceptance;
      }

      // Si le profil n'est pas encore résolu, on reste où on est —
      // surtout pas de "redirect vers home" qui écraserait /cgu-acceptance
      // pendant qu'on attend la prochaine émission du provider.
      if (profile == null) return null;

      // CGU OK + profil chargé — on évacue des écrans d'auth et CGU.
      if (UserRoutes.unauthenticated.contains(loc) ||
          loc == UserRoutes.onboarding ||
          loc == UserRoutes.cguAcceptance) {
        return UserRoutes.home;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: UserRoutes.intro,
        name: 'user.intro',
        builder: (context, state) => const SplashPage(
          nextRoute: UserRoutes.home,
        ),
      ),
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
        path: UserRoutes.resetPasswordCode,
        name: 'user.resetPasswordCode',
        builder: (context, state) {
          final email = state.uri.queryParameters['email'] ?? '';
          return ResetPasswordCodePage(email: email);
        },
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
        path: UserRoutes.banned,
        name: 'user.banned',
        builder: (context, state) => const BannedAccountPage(),
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
        path: UserRoutes.matchAlarm,
        name: 'user.matchAlarm',
        builder: (context, state) => MatchAlarmScreen(
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
        path: UserRoutes.friendChat,
        name: 'user.friendChat',
        builder: (context, state) => FriendChatPage(
          friendshipId: state.pathParameters['friendshipId'] ?? '',
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
        path: UserRoutes.profileEdit,
        name: 'user.profileEdit',
        builder: (context, state) => const EditProfilePage(),
      ),
      GoRoute(
        path: UserRoutes.profileDelete,
        name: 'user.profileDelete',
        builder: (context, state) => const DeleteAccountPage(),
      ),
      GoRoute(
        path: UserRoutes.matchHistory,
        name: 'user.matchHistory',
        builder: (context, state) => const MatchHistoryPage(),
      ),
      GoRoute(
        path: UserRoutes.publicProfile,
        name: 'user.publicProfile',
        builder: (context, state) {
          final raw = state.pathParameters['username'] ?? '';
          return PublicProfilePage(username: Uri.decodeComponent(raw));
        },
      ),
      GoRoute(
        path: UserRoutes.friends,
        name: 'user.friends',
        builder: (context, state) => const FriendsPage(),
      ),
      GoRoute(
        path: UserRoutes.friendsSearch,
        name: 'user.friendsSearch',
        builder: (context, state) => const FriendsSearchPage(),
      ),
      GoRoute(
        path: UserRoutes.registrationConfirm,
        name: 'user.registrationConfirm',
        builder: (context, state) {
          final extra = state.extra as RegistrationConfirmArgs?;
          return RegistrationConfirmPage(
            competitionId: state.pathParameters['id'] ?? '',
            competitionName: extra?.competitionName ?? 'Compétition',
            game: extra?.game,
            gameLabel: extra?.gameLabel ?? '',
            gameEmoji: extra?.gameEmoji ?? '🎮',
            dateLabel: extra?.dateLabel ?? '',
            formatLabel: extra?.formatLabel ?? '',
            entryFeeXaf: extra?.entryFeeXaf ?? 0,
            totalPrizeXaf: extra?.totalPrizeXaf ?? 0,
            prizeDistribution:
                extra?.prizeDistribution ?? const [50, 25, 15, 10],
            androidStoreUrl: extra?.androidStoreUrl,
            iosStoreUrl: extra?.iosStoreUrl,
          );
        },
      ),
      GoRoute(
        path: UserRoutes.settings,
        name: 'user.settings',
        builder: (context, state) => const SettingsPage(),
      ),
      GoRoute(
        path: UserRoutes.messagesInbox,
        name: 'user.messagesInbox',
        builder: (context, state) => const MessagesInboxPage(),
      ),
      GoRoute(
        path: UserRoutes.notifications,
        name: 'user.notifications',
        builder: (context, state) => const NotificationsPage(),
      ),
      GoRoute(
        path: UserRoutes.adminMessages,
        name: 'user.adminMessages',
        builder: (context, state) => const AdminMessagesPage(),
      ),
      GoRoute(
        path: UserRoutes.supportChat,
        name: 'user.supportChat',
        builder: (context, state) => const SupportChatPage(),
      ),
      GoRoute(
        path: UserRoutes.about,
        name: 'user.about',
        builder: (context, state) => const AboutPage(),
      ),
      GoRoute(
        path: UserRoutes.recordingError,
        name: 'user.recordingError',
        builder: (context, state) => const RecordingErrorPage(),
      ),
      GoRoute(
        path: UserRoutes.matchInProgressPreview,
        name: 'user.matchInProgressPreview',
        builder: (context, state) => const MatchInProgressOverlay(),
      ),
      GoRoute(
        path: UserRoutes.paymentMethodPicker,
        name: 'user.paymentMethodPicker',
        builder: (context, state) {
          final extra = state.extra as PaymentPickerArgs?;
          return PaymentMethodPickerPage(
            amountXaf: extra?.amountXaf ?? 0,
            contextLabel: extra?.contextLabel ?? '',
            options: extra?.options ?? const [],
          );
        },
      ),
      GoRoute(
        path: UserRoutes.paymentMomoDetails,
        name: 'user.paymentMomoDetails',
        builder: (context, state) {
          final extra = state.extra as PaymentMomoArgs?;
          return MobileMoneyDetailsPage(
            operator: extra?.operator ?? _fallbackOperator,
            amountXaf: extra?.amountXaf ?? 0,
            competitionId: extra?.competitionId ?? '',
            competitionName: extra?.competitionName ?? '',
          );
        },
      ),
      GoRoute(
        path: UserRoutes.paymentProcessing,
        name: 'user.paymentProcessing',
        builder: (context, state) {
          final extra = state.extra as PaymentProcessingArgs?;
          return PaymentProcessingPage(
            paymentId: extra?.paymentId ?? '',
            operator: extra?.operator ?? _fallbackOperator,
            amountXaf: extra?.amountXaf ?? 0,
            competitionName: extra?.competitionName ?? '',
            maskedPhone: extra?.maskedPhone ?? '+••• •• •• ••',
          );
        },
      ),
      GoRoute(
        path: UserRoutes.paymentSuccess,
        name: 'user.paymentSuccess',
        builder: (context, state) {
          final extra = state.extra as PaymentResultArgs?;
          return PaymentSuccessPage(
            amountXaf: extra?.amountXaf ?? 0,
            operator: extra?.operator ?? _fallbackOperator,
            transactionId: extra?.transactionId ?? '—',
            dateLabel: extra?.dateLabel ?? '',
            tournamentName: extra?.tournamentName ?? 'COMPÉTITION',
            competitionId: extra?.competitionId,
          );
        },
      ),
      GoRoute(
        path: UserRoutes.paymentFailed,
        name: 'user.paymentFailed',
        builder: (context, state) {
          final extra = state.extra as PaymentFailedArgs?;
          return PaymentFailedPage(
            reason: extra?.reason ?? PaymentFailReason.unknown,
            adminReason: extra?.adminReason,
            operator: extra?.operator,
          );
        },
      ),
      GoRoute(
        path: UserRoutes.paymentHistory,
        name: 'user.paymentHistory',
        builder: (context, state) => const PaymentHistoryPage(),
      ),
      GoRoute(
        path: UserRoutes.payoutKyc,
        name: 'user.payoutKyc',
        builder: (context, state) {
          final extra = state.extra as PayoutKycArgs?;
          return PayoutKycPage(pendingAmountXaf: extra?.pendingAmountXaf ?? 0);
        },
      ),
      // Routes outillage dev — réservées aux builds debug (jamais
      // atteignables par URL en release). Cf. audit quick-wins.
      if (kDebugMode) ...[
        GoRoute(
          path: UserRoutes.devPreview,
          name: 'user.dev.preview',
          builder: (context, state) => const DevPreviewPage(),
        ),
        GoRoute(
          path: UserRoutes.devShowcase,
          name: 'user.dev.showcase',
          builder: (context, state) => const DesignShowcasePage(),
        ),
        GoRoute(
          path: UserRoutes.devBracketShowcase,
          name: 'user.dev.bracketShowcase',
          builder: (context, state) => const BracketShowcasePage(),
        ),
        GoRoute(
          path: UserRoutes.devDraughts,
          name: 'user.dev.draughts',
          builder: (context, state) => const DraughtsGameScreen(),
        ),
      ],
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

/// Opérateur de repli quand une route paiement est atteinte sans `extra`
/// (deep-link direct / hot-reload). En pratique ces routes reçoivent
/// toujours leur `PaymentOperator` via `extra`.
const _fallbackOperator = PaymentOperator(
  label: 'MTN MoMo',
  code: 'MTN_MOMO',
  countryCode: 'CM',
);

/// Args carried into `PaymentMethodPickerPage` (P1). Porte les options de
/// paiement DÉJÀ filtrées sur le pays choisi par le joueur.
class PaymentPickerArgs {
  const PaymentPickerArgs({
    required this.amountXaf,
    required this.contextLabel,
    required this.options,
  });

  final int amountXaf;
  final String contextLabel;
  final List<CompetitionPaymentOption> options;
}

/// Args carried into `MobileMoneyDetailsPage` (P2) once la P1 a renvoyé
/// l'opérateur choisi. La P2 a besoin de l'ID compétition (pour persister
/// le paiement) + de l'opérateur (label + code de transfert + pays).
class PaymentMomoArgs {
  const PaymentMomoArgs({
    required this.operator,
    required this.amountXaf,
    required this.competitionId,
    required this.competitionName,
  });
  final PaymentOperator operator;
  final int amountXaf;
  final String competitionId;
  final String competitionName;
}

/// Args carried into `PaymentProcessingPage` (P3) — page d'attente de
/// validation super-admin (15 min max).
class PaymentProcessingArgs {
  const PaymentProcessingArgs({
    required this.paymentId,
    required this.operator,
    required this.amountXaf,
    required this.competitionName,
    required this.maskedPhone,
  });

  final String paymentId;
  final PaymentOperator operator;
  final int amountXaf;
  final String competitionName;
  final String maskedPhone;
}

/// Args carried into `PaymentSuccessPage` (P4).
class PaymentResultArgs {
  const PaymentResultArgs({
    required this.operator,
    required this.amountXaf,
    required this.transactionId,
    required this.dateLabel,
    this.tournamentName = 'COMPÉTITION',
    this.competitionId,
  });

  final PaymentOperator operator;
  final int amountXaf;
  final String transactionId;
  final String dateLabel;

  /// Permet à P4 d'offrir un CTA "VOIR LA COMPÉTITION" qui route
  /// directement vers /competitions/:id maintenant que le joueur est
  /// inscrit (trigger DB).
  final String? competitionId;
  final String tournamentName;
}

/// Args carried into `PaymentFailedPage` (P5).
class PaymentFailedArgs {
  const PaymentFailedArgs({
    required this.reason,
    this.adminReason,
    this.operator,
  });
  final PaymentFailReason reason;
  final String? adminReason;
  final PaymentOperator? operator;
}

/// Args carried into `PayoutKycPage` (P7) when a payout > 100 000 XAF
/// triggers the regulatory KYC funnel.
class PayoutKycArgs {
  const PayoutKycArgs({required this.pendingAmountXaf});
  final int pendingAmountXaf;
}

/// Args carried into `RegistrationConfirmPage` (#12). The competition page
/// already has the metadata in memory when the user taps "S'inscrire", so
/// we forward it via `extra` rather than re-fetching from Supabase.
class RegistrationConfirmArgs {
  const RegistrationConfirmArgs({
    required this.competitionName,
    required this.game,
    required this.gameLabel,
    required this.gameEmoji,
    required this.dateLabel,
    required this.formatLabel,
    required this.entryFeeXaf,
    required this.totalPrizeXaf,
    required this.prizeDistribution,
    this.androidStoreUrl,
    this.iosStoreUrl,
  });

  final String competitionName;

  /// Jeu de la compétition — sert au dialogue de contrôle d'installation
  /// (jeux externes) affiché AU-DESSUS du checkout.
  final GameType game;
  final String gameLabel;
  final String gameEmoji;
  final String dateLabel;
  final String formatLabel;
  final int entryFeeXaf;
  final int totalPrizeXaf;

  /// Pourcentages de gains par rang (ex. `[50, 25, 15, 10]`).
  final List<int> prizeDistribution;

  /// Item 1 prompt 2026-05-19 — liens stores du jeu (null = pas affiché).
  final String? androidStoreUrl;
  final String? iosStoreUrl;
}
