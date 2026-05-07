import 'package:arena/core/router/router_refresh.dart';
import 'package:arena/features_admin/auth_admin/invitation_redeem_screen.dart';
import 'package:arena/features_admin/auth_admin/login_admin_screen.dart';
import 'package:arena/features_admin/auth_admin/splash_admin_screen.dart';
import 'package:arena/features_admin/auth_admin/totp_setup_screen.dart';
import 'package:arena/features_admin/auth_admin/totp_verify_screen.dart';
import 'package:arena/features_shared/presentation/dev_preview_page.dart';
import 'package:arena/features_user/auth/auth_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Route names for the Admin app.
///
/// PHASE 2bis wires the auth flow (splash, login, invitation, TOTP).
/// PHASE 11 will add /dashboard, /competitions, /matches, /payouts,
/// /disputes, /streams.
abstract final class AdminRoutes {
  static const home = '/';
  static const splash = '/splash';
  static const login = '/login';
  static const invitation = '/invitation';
  static const totpSetup = '/totp/setup';
  static const totpVerify = '/totp/verify';
  static const devPreview = '/dev/preview';

  /// Routes reachable while not yet fully authenticated (no session OR
  /// session without TOTP confirmation).
  static const unauthenticated = <String>{
    splash,
    login,
    invitation,
    totpSetup,
    totpVerify,
  };
}

final adminRouterProvider = Provider<GoRouter>((ref) {
  final refresh = RouterRefreshListenable(
    ref,
    [currentSessionProvider, currentProfileProvider],
  );
  ref.onDispose(refresh.dispose);

  return GoRouter(
    initialLocation: AdminRoutes.splash,
    debugLogDiagnostics: true,
    refreshListenable: refresh,
    redirect: (context, state) {
      final loc = state.matchedLocation;
      final session = ref.read(currentSessionProvider);

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

      // TOTP enabled — keep them out of the auth screens.
      if (AdminRoutes.unauthenticated.contains(loc)) {
        return AdminRoutes.home;
      }
      return null;
    },
    routes: [
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
        builder: (context, state) => const _AdminHomePlaceholder(),
      ),
      GoRoute(
        path: AdminRoutes.devPreview,
        name: 'admin.dev.preview',
        builder: (context, state) => const DevPreviewPage(),
      ),
    ],
  );
});

class _AdminHomePlaceholder extends ConsumerWidget {
  const _AdminHomePlaceholder();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(currentProfileProvider).valueOrNull;
    return Scaffold(
      appBar: AppBar(
        title: Text('Admin — ${profile?.username ?? ''}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(signOutProvider)(),
          ),
        ],
      ),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'PHASE 11 — Admin dashboard / competitions / matches'
            ' / payouts / disputes viendront ici.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
