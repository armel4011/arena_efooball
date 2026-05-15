import 'package:arena/core/flavors/flavor_config.dart';
import 'package:arena/data/models/profile.dart';
import 'package:arena/data/repositories/auth_failure.dart';
import 'package:arena/data/repositories/auth_repository.dart';
import 'package:arena/data/repositories/profile_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

/// Stream of Supabase auth-state changes (signed-in, signed-out, refreshed).
///
/// Returns an empty stream if Supabase isn't initialized (creds missing
/// in `.env`, or running in a test that didn't override the client).
final authStateChangesProvider = StreamProvider<sb.AuthState>((ref) {
  try {
    return ref.watch(authRepositoryProvider).authStateChanges();
  } catch (e) {
    if (kDebugMode) {
      debugPrint('[auth] authStateChanges unavailable — empty stream: $e');
    }
    return const Stream.empty();
  }
});

/// Latest [sb.Session] — null when signed out OR when Supabase isn't
/// initialized. Re-evaluated whenever the auth stream emits.
final currentSessionProvider = Provider<sb.Session?>((ref) {
  ref.watch(authStateChangesProvider);
  try {
    return ref.watch(authRepositoryProvider).currentSession;
  } catch (e) {
    if (kDebugMode) {
      debugPrint('[auth] currentSession unavailable — null: $e');
    }
    return null;
  }
});

/// Current authenticated [Profile], with role-based gating for the
/// active flavor (admin profile in user app → [WrongAppForRoleFailure],
/// and vice-versa).
final currentProfileProvider = FutureProvider<Profile?>((ref) async {
  final session = ref.watch(currentSessionProvider);
  if (session == null) return null;
  final profile =
      await ref.watch(profileRepositoryProvider).getById(session.user.id);
  if (profile == null) return null;
  _enforceRoleForFlavor(profile);
  return profile;
});

/// Async controller for the sign-in form.
class SignInController extends AsyncNotifier<Profile?> {
  @override
  Future<Profile?> build() async => null;

  Future<void> signIn({required String email, required String password}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(authRepositoryProvider);
      final profile = await repo.signInWithEmail(
        email: email,
        password: password,
      );
      _enforceRoleForFlavor(profile);
      return profile;
    });
  }

  void reset() => state = const AsyncData(null);
}

final signInControllerProvider =
    AsyncNotifierProvider<SignInController, Profile?>(SignInController.new);

/// Async controller pour le sign-in Google (native idToken flow).
///
/// Lit `GOOGLE_WEB_CLIENT_ID` depuis `.env`. Si la variable manque, la
/// failure typée [SsoConfigMissingFailure] est surfacée à l'UI au lieu
/// d'un crash opaque.
class GoogleSsoController extends AsyncNotifier<Profile?> {
  @override
  Future<Profile?> build() async => null;

  Future<void> signIn() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final webClientId = dotenv.maybeGet('GOOGLE_WEB_CLIENT_ID')?.trim() ?? '';
      final repo = ref.read(authRepositoryProvider);
      final profile = await repo.signInWithGoogle(webClientId: webClientId);
      _enforceRoleForFlavor(profile);
      return profile;
    });
  }

  void reset() => state = const AsyncData(null);
}

final googleSsoControllerProvider =
    AsyncNotifierProvider<GoogleSsoController, Profile?>(
  GoogleSsoController.new,
);

/// Async controller for the multi-step sign-up form.
class SignUpController extends AsyncNotifier<Profile?> {
  @override
  Future<Profile?> build() async => null;

  Future<void> signUp({
    required String email,
    required String password,
    required String username,
    required String countryCode,
    required String preferredLanguage,
    required String preferredCurrency,
    required DateTime cguAcceptedAt,
    required String cguVersionAccepted,
    required DateTime privacyPolicyAcceptedAt,
    bool marketingConsent = false,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      return ref.read(authRepositoryProvider).signUpWithEmail(
            email: email,
            password: password,
            username: username,
            countryCode: countryCode,
            preferredLanguage: preferredLanguage,
            preferredCurrency: preferredCurrency,
            cguAcceptedAt: cguAcceptedAt,
            cguVersionAccepted: cguVersionAccepted,
            privacyPolicyAcceptedAt: privacyPolicyAcceptedAt,
            marketingConsent: marketingConsent,
          );
    });
  }

  void reset() => state = const AsyncData(null);
}

final signUpControllerProvider =
    AsyncNotifierProvider<SignUpController, Profile?>(SignUpController.new);

/// Sign-out helper exposed as a callback so screens can wire it directly.
final signOutProvider = Provider<Future<void> Function()>((ref) {
  return () async {
    await ref.read(authRepositoryProvider).signOut();
    ref.invalidate(currentProfileProvider);
  };
});

/// Deep link the password-reset email should land on. Picked up by
/// `app_links` and routed to [ResetPasswordPage] at app level.
const String kResetPasswordRedirect = 'com.arena.app://reset-password';

/// Async controller for the "forgot password" form.
///
/// `data == true` once the email has been sent successfully — the screen
/// uses that to flip into a "check your inbox" success state.
class ForgotPasswordController extends AsyncNotifier<bool> {
  @override
  Future<bool> build() async => false;

  Future<void> sendResetEmail(String email) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(authRepositoryProvider).sendPasswordResetEmail(
            email: email,
            redirectTo: kResetPasswordRedirect,
          );
      return true;
    });
  }

  void reset() => state = const AsyncData(false);
}

final forgotPasswordControllerProvider =
    AsyncNotifierProvider<ForgotPasswordController, bool>(
  ForgotPasswordController.new,
);

/// Async controller for the "reset password" form (deep-link landing).
///
/// Assumes the Supabase session has already been hydrated by the
/// recovery deep link before this controller is invoked.
class ResetPasswordController extends AsyncNotifier<bool> {
  @override
  Future<bool> build() async => false;

  Future<void> updatePassword(String newPassword) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(authRepositoryProvider).updatePassword(newPassword);
      return true;
    });
  }

  void reset() => state = const AsyncData(false);
}

final resetPasswordControllerProvider =
    AsyncNotifierProvider<ResetPasswordController, bool>(
  ResetPasswordController.new,
);

/// Async controller for the CGU acceptance screen.
///
/// Stamps `cgu_accepted_at`, `cgu_version_accepted`, `privacy_policy_accepted_at`
/// (and optionally `marketing_consent`) on the current profile, then
/// invalidates [currentProfileProvider] so router redirects pick up the
/// new state.
class AcceptCguController extends AsyncNotifier<bool> {
  @override
  Future<bool> build() async => false;

  Future<void> accept({
    required String cguVersion,
    bool marketingConsent = false,
  }) async {
    final session = ref.read(currentSessionProvider);
    if (session == null) {
      state = AsyncError(
        const UnknownAuthFailure('no session when accepting CGU'),
        StackTrace.current,
      );
      return;
    }

    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final now = DateTime.now().toUtc();
      await ref.read(profileRepositoryProvider).update(
        session.user.id,
        {
          'cgu_accepted_at': now.toIso8601String(),
          'cgu_version_accepted': cguVersion,
          'privacy_policy_accepted_at': now.toIso8601String(),
          'marketing_consent': marketingConsent,
        },
      );
      ref.invalidate(currentProfileProvider);
      return true;
    });
  }

  void reset() => state = const AsyncData(false);
}

final acceptCguControllerProvider =
    AsyncNotifierProvider<AcceptCguController, bool>(
  AcceptCguController.new,
);

void _enforceRoleForFlavor(Profile profile) {
  if (FlavorConfig.instance.isUser && profile.isAdmin) {
    throw const WrongAppForRoleFailure();
  }
  if (FlavorConfig.instance.isAdmin && !profile.isAdmin) {
    throw const WrongAppForRoleFailure();
  }
}
