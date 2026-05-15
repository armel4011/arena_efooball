import 'package:arena/data/models/profile.dart';
import 'package:arena/data/repositories/auth_failure.dart';
import 'package:arena/data/repositories/auth_repository.dart';
import 'package:arena/data/repositories/profile_repository.dart';
import 'package:arena/features_shared/auth_common/shared_auth_providers.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Les providers cross-cutting (authStateChanges, currentSession,
// currentProfile, signOut, enforceRoleForFlavor) sont définis dans
// `features_shared/auth_common/shared_auth_providers.dart`. On les
// re-exporte ici pour préserver les imports existants côté user.
export 'package:arena/features_shared/auth_common/shared_auth_providers.dart';

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
      enforceRoleForFlavor(profile);
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
      enforceRoleForFlavor(profile);
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
    required String whatsappNumber,
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
            whatsappNumber: whatsappNumber,
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

/// Async controller pour l'envoi de l'email de réinitialisation.
///
/// `data == true` une fois l'email parti — la page affiche alors un
/// CTA "J'ai reçu mon code" qui ouvre la page de saisie du code.
class ForgotPasswordController extends AsyncNotifier<bool> {
  @override
  Future<bool> build() async => false;

  Future<void> sendResetEmail(String email) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref
          .read(authRepositoryProvider)
          .sendPasswordResetEmail(email: email);
      return true;
    });
  }

  void reset() => state = const AsyncData(false);
}

final forgotPasswordControllerProvider =
    AsyncNotifierProvider<ForgotPasswordController, bool>(
  ForgotPasswordController.new,
);

/// Async controller pour la vérification du code OTP à 6 chiffres.
/// Hydrate une session recovery côté Supabase qui permettra ensuite
/// d'appeler [ResetPasswordController.updatePassword].
class VerifyPasswordResetCodeController extends AsyncNotifier<bool> {
  @override
  Future<bool> build() async => false;

  Future<void> verify({required String email, required String code}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(authRepositoryProvider).verifyPasswordResetCode(
            email: email,
            code: code,
          );
      return true;
    });
  }

  void reset() => state = const AsyncData(false);
}

final verifyPasswordResetCodeControllerProvider =
    AsyncNotifierProvider<VerifyPasswordResetCodeController, bool>(
  VerifyPasswordResetCodeController.new,
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

  /// Persiste l'acceptation des CGU sur le profil. Pour les comptes SSO
  /// (Google sign-in qui crée un profil minimal), c'est aussi le moment
  /// où on collecte le pays et le numéro WhatsApp manquants.
  ///
  /// Si [countryCode] ou [whatsappNumber] sont null, le champ correspondant
  /// n'est pas modifié — utile pour les rares comptes legacy qui passent
  /// par cette page sans avoir besoin de mettre à jour ces champs.
  Future<void> accept({
    required String cguVersion,
    bool marketingConsent = false,
    String? countryCode,
    String? whatsappNumber,
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
      final patch = <String, dynamic>{
        'cgu_accepted_at': now.toIso8601String(),
        'cgu_version_accepted': cguVersion,
        'privacy_policy_accepted_at': now.toIso8601String(),
        'marketing_consent': marketingConsent,
      };
      if (countryCode != null) patch['country_code'] = countryCode;
      if (whatsappNumber != null) patch['whatsapp_number'] = whatsappNumber;
      await ref.read(profileRepositoryProvider).update(session.user.id, patch);
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
