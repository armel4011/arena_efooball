import 'dart:io';

import 'package:arena/data/models/profile.dart';
import 'package:arena/data/repositories/auth_failure.dart';
import 'package:arena/data/repositories/profile_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Wraps Supabase Auth + the `profiles` row that lives alongside.
///
/// Always returns typed [AuthFailure] subclasses on errors — never
/// re-throws Supabase's own exception types.
class AuthRepository {
  const AuthRepository({
    required SupabaseClient client,
    required ProfileRepository profiles,
  })  : _client = client,
        _profiles = profiles;

  final SupabaseClient _client;
  final ProfileRepository _profiles;

  /// Currently authenticated session, or null if anonymous.
  Session? get currentSession => _client.auth.currentSession;

  /// Currently authenticated Supabase user, or null.
  User? get currentUser => _client.auth.currentUser;

  /// Stream of auth state transitions (signed-in, signed-out, refreshed).
  Stream<AuthState> authStateChanges() => _client.auth.onAuthStateChange;

  Future<Profile> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final user = await _runAuth(() async {
      final res = await _client.auth.signInWithPassword(
        email: email.trim().toLowerCase(),
        password: password,
      );
      return res.user;
    });
    return _profileForUserOrThrow(user);
  }

  /// Sign up + insert the matching `profiles` row.
  ///
  /// CGU/Privacy timestamps are passed in by the caller (the screen
  /// holds the checkbox state). [marketingConsent] is optional.
  Future<Profile> signUpWithEmail({
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
    String? referredBy,
  }) async {
    // Pre-validate username uniqueness BEFORE auth.signUp so a clash
    // doesn't leave us with an orphan auth.users row that can't be
    // reused (Supabase rejects re-registering the same email).
    if (await _profiles.usernameExists(username)) {
      throw const UsernameAlreadyTakenFailure();
    }

    final user = await _runAuth(() async {
      final res = await _client.auth.signUp(
        email: email.trim().toLowerCase(),
        password: password,
        data: {'username': username},
      );
      return res.user;
    });

    if (user == null) {
      throw const UnknownAuthFailure();
    }

    // The `profiles` row is created here client-side. If you prefer a
    // server-side trigger, drop this insert.
    final profile = Profile(
      id: user.id,
      username: username,
      email: user.email ?? email.trim().toLowerCase(),
      countryCode: countryCode,
      preferredLanguage: preferredLanguage,
      preferredCurrency: preferredCurrency,
      whatsappNumber: whatsappNumber,
      cguAcceptedAt: cguAcceptedAt,
      cguVersionAccepted: cguVersionAccepted,
      privacyPolicyAcceptedAt: privacyPolicyAcceptedAt,
      marketingConsent: marketingConsent,
      // Lot D.1 — code parrain saisi à l'inscription. Le trigger DB
      // `ensure_referral_code` pose le code propre du joueur, on garde
      // referredBy comme lien sortant.
      referredBy: referredBy,
    );
    try {
      return await _profiles.create(profile);
    } on PostgrestException catch (e) {
      // Race fallback — the pre-check passed but a concurrent signup
      // claimed the same username before our INSERT landed.
      if (e.code == '23505' && e.message.contains('username')) {
        throw UsernameAlreadyTakenFailure(e);
      }
      rethrow;
    }
  }

  /// Native Google Sign-In → Supabase `signInWithIdToken`.
  ///
  /// Flow :
  /// 1. Picker natif Google (`google_sign_in`) — l'utilisateur choisit
  ///    son compte ou annule.
  /// 2. L'idToken reçu (signé par Google, `aud == webClientId`) est
  ///    échangé contre une session Supabase via `signInWithIdToken`.
  /// 3. On charge le `profiles` row associé. S'il n'existe pas (premier
  ///    Google sign-in pour cet email), on le crée avec des valeurs par
  ///    défaut et le router redirigera vers `/cgu-acceptance` (cf.
  ///    `user_router.dart`).
  ///
  /// [webClientId] doit être le **Web** OAuth Client ID (pas l'Android !),
  /// car Supabase vérifie `aud == webClientId`. Le passer en
  /// `serverClientId` à `GoogleSignIn` garantit que l'idToken aura la
  /// bonne audience même sur Android natif.
  Future<Profile> signInWithGoogle({required String webClientId}) async {
    if (webClientId.isEmpty) {
      throw const SsoConfigMissingFailure();
    }

    final GoogleSignInAccount? account;
    final GoogleSignInAuthentication auth;
    try {
      final googleSignIn = GoogleSignIn(serverClientId: webClientId);
      // Force le picker à chaque fois — évite qu'un compte précédent
      // reste accroché silencieusement après un sign-out.
      await googleSignIn.signOut();
      account = await googleSignIn.signIn();
      if (account == null) {
        throw const SsoCancelledFailure();
      }
      auth = await account.authentication;
    } on AuthFailure {
      rethrow;
    } on SocketException catch (e) {
      throw NetworkFailure(e);
    } catch (e) {
      throw UnknownAuthFailure(e);
    }

    final idToken = auth.idToken;
    if (idToken == null) {
      throw const SsoIdTokenMissingFailure();
    }

    final user = await _runAuth(() async {
      final res = await _client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: auth.accessToken,
      );
      return res.user;
    });

    if (user == null) {
      throw const UnknownAuthFailure();
    }

    final existing = await _profiles.getById(user.id);
    if (existing != null) return existing;

    // Première connexion Google pour cet utilisateur — crée un profil
    // minimal. `cgu_accepted_at` reste NULL : le router redirige vers
    // `/cgu-acceptance` avant tout autre écran.
    final email = user.email ?? account.email;
    final suggested = _suggestUsername(email);
    final profile = Profile(
      id: user.id,
      username: suggested,
      email: email,
      countryCode: 'CI',
      authProvider: 'google',
      authProviderId: account.id,
    );
    try {
      return await _profiles.create(profile);
    } on PostgrestException catch (e) {
      // Race / collision sur le username auto-suggéré — réessaie avec un
      // suffixe court basé sur l'uid Supabase (toujours stable, déjà unique).
      if (e.code == '23505' && e.message.contains('username')) {
        final fallback = profile.copyWith(
          username: '${suggested}_${user.id.substring(0, 6)}',
        );
        return _profiles.create(fallback);
      }
      rethrow;
    }
  }

  Future<void> signOut() => _client.auth.signOut();

  /// Demande à Supabase d'envoyer un email contenant un code à 6 chiffres
  /// (`{{ .Token }}` dans le template recovery). L'utilisateur saisit
  /// ensuite ce code via [verifyPasswordResetCode] pour hydrater une
  /// session recovery, puis appelle [updatePassword].
  Future<void> sendPasswordResetEmail({required String email}) async {
    await _runAuth<bool>(() async {
      await _client.auth.resetPasswordForEmail(email.trim().toLowerCase());
      return true;
    });
  }

  /// Vérifie le code à 6 chiffres reçu par email et hydrate une session
  /// recovery temporaire. Une fois cette méthode résolue avec succès,
  /// [updatePassword] peut être appelée pour fixer le nouveau mot de passe.
  Future<void> verifyPasswordResetCode({
    required String email,
    required String code,
  }) async {
    await _runAuth<bool>(() async {
      await _client.auth.verifyOTP(
        email: email.trim().toLowerCase(),
        token: code.trim(),
        type: OtpType.recovery,
      );
      return true;
    });
  }

  Future<void> updatePassword(String newPassword) async {
    await _runAuth<bool>(() async {
      await _client.auth.updateUser(UserAttributes(password: newPassword));
      return true;
    });
  }

  // ─── internals ───────────────────────────────────────────────────────

  Future<Profile> _profileForUserOrThrow(User? user) async {
    if (user == null) throw const UnknownAuthFailure();
    final profile = await _profiles.getById(user.id);
    if (profile == null) {
      // The Supabase user exists but no profile row — possible if the
      // signup transaction was interrupted. Treat as a recoverable error.
      throw const UnknownAuthFailure('profile row missing for auth user');
    }
    return profile;
  }

  /// Wraps a Supabase auth call in our typed-failure mapper.
  ///
  /// Hiérarchie gotrue (v2.20.0) :
  ///   AuthException
  ///   ├── AuthApiException                 (réponses HTTP 4xx/5xx du serveur)
  ///   ├── AuthWeakPasswordException        (extends AuthException directement)
  ///   ├── AuthSessionMissingException
  ///   ├── AuthPKCEGrantCodeExchangeError
  ///   ├── AuthRetryableFetchException
  ///   └── AuthUnknownException
  ///
  /// `AuthWeakPasswordException` n'hérite pas d'`AuthApiException` —
  /// elle DOIT être catchée explicitement avant le bloc générique
  /// `AuthException`, sinon elle tombe sur `_mapGeneric` qui ne sait
  /// pas mapper le password Pwned/HIBP → `UnknownAuthFailure` opaque.
  Future<T> _runAuth<T>(Future<T> Function() body) async {
    try {
      return await body();
    } on AuthWeakPasswordException catch (e) {
      throw WeakPasswordFailure(e);
    } on AuthApiException catch (e) {
      throw _mapApi(e);
    } on AuthException catch (e) {
      throw _mapGeneric(e);
    } on SocketException catch (e) {
      throw NetworkFailure(e);
    }
  }

  AuthFailure _mapApi(AuthApiException e) {
    final statusCode = e.statusCode;
    final errorCode = e.code; // Supabase ErrorCode officiel (plus stable que le msg)
    final msg = e.message.toLowerCase();

    // ── Priorité 1 : code Supabase officiel (case-insensitive, locale-stable).
    switch (errorCode) {
      case 'weak_password':
      case 'same_password':
        return WeakPasswordFailure(e);
      case 'email_exists':
        return EmailAlreadyRegisteredFailure(e);
      case 'user_banned':
        return UserBannedFailure(e);
      case 'email_not_confirmed':
      case 'phone_not_confirmed':
        return EmailNotConfirmedFailure(e);
      case 'invalid_credentials':
        return InvalidCredentialsFailure(e);
      case 'over_email_send_rate_limit':
      case 'over_request_rate_limit':
        return RateLimitedFailure(e);
    }

    // ── Priorité 2 : heuristiques message-based (fallback si code absent).
    if (msg.contains('otp') || msg.contains('token')) {
      if (msg.contains('expired')) {
        return ExpiredPasswordResetCodeFailure(e);
      }
      if (msg.contains('invalid') || msg.contains('not found')) {
        return InvalidPasswordResetCodeFailure(e);
      }
    }
    if (msg.contains('invalid') &&
        (msg.contains('credentials') || msg.contains('login'))) {
      return InvalidCredentialsFailure(e);
    }
    if (msg.contains('already') && msg.contains('registered')) {
      return EmailAlreadyRegisteredFailure(e);
    }
    if (msg.contains('weak') && msg.contains('password')) {
      return WeakPasswordFailure(e);
    }
    if (msg.contains('pwned') || msg.contains('compromised')) {
      return WeakPasswordFailure(e);
    }
    if (msg.contains('not confirmed') || msg.contains('email_not_confirmed')) {
      return EmailNotConfirmedFailure(e);
    }
    if (msg.contains('banned') || msg.contains('blocked')) {
      return UserBannedFailure(e);
    }
    if (statusCode == '429' ||
        msg.contains('rate limit') ||
        msg.contains('over_email_send_rate_limit')) {
      return RateLimitedFailure(e);
    }
    if (statusCode == '422' || statusCode == '400') {
      return InvalidCredentialsFailure(e);
    }
    return UnknownAuthFailure(e);
  }

  /// Forme un username acceptable à partir de l'email Google : préfixe
  /// avant `@`, minuscules, caractères non-alphanumériques retirés,
  /// fallback `joueur` si vide.
  String _suggestUsername(String email) {
    final prefix = email.split('@').first;
    final cleaned = prefix.toLowerCase().replaceAll(RegExp('[^a-z0-9_]'), '');
    if (cleaned.isEmpty) return 'joueur';
    return cleaned.length > 24 ? cleaned.substring(0, 24) : cleaned;
  }

  AuthFailure _mapGeneric(AuthException e) {
    final msg = e.message.toLowerCase();
    if (msg.contains('network') || msg.contains('connection')) {
      return NetworkFailure(e);
    }
    return UnknownAuthFailure(e);
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    client: ref.watch(supabaseClientProvider),
    profiles: ref.watch(profileRepositoryProvider),
  );
});
