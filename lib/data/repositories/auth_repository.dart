import 'dart:io';

import 'package:arena/data/models/profile.dart';
import 'package:arena/data/repositories/auth_failure.dart';
import 'package:arena/data/repositories/profile_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
    required DateTime cguAcceptedAt,
    required String cguVersionAccepted,
    required DateTime privacyPolicyAcceptedAt,
    bool marketingConsent = false,
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
      cguAcceptedAt: cguAcceptedAt,
      cguVersionAccepted: cguVersionAccepted,
      privacyPolicyAcceptedAt: privacyPolicyAcceptedAt,
      marketingConsent: marketingConsent,
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

  Future<void> signOut() => _client.auth.signOut();

  Future<void> sendPasswordResetEmail({
    required String email,
    required String redirectTo,
  }) async {
    await _runAuth<bool>(() async {
      await _client.auth.resetPasswordForEmail(
        email.trim().toLowerCase(),
        redirectTo: redirectTo,
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
  Future<T> _runAuth<T>(Future<T> Function() body) async {
    try {
      return await body();
    } on AuthApiException catch (e) {
      throw _mapApi(e);
    } on AuthException catch (e) {
      throw _mapGeneric(e);
    } on SocketException catch (e) {
      throw NetworkFailure(e);
    }
  }

  AuthFailure _mapApi(AuthApiException e) {
    final code = e.statusCode;
    final msg = e.message.toLowerCase();
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
    if (msg.contains('not confirmed') || msg.contains('email_not_confirmed')) {
      return EmailNotConfirmedFailure(e);
    }
    if (msg.contains('banned') || msg.contains('blocked')) {
      return UserBannedFailure(e);
    }
    if (code == '429' ||
        msg.contains('rate limit') ||
        msg.contains('over_email_send_rate_limit')) {
      return RateLimitedFailure(e);
    }
    if (code == '422' || code == '400') {
      return InvalidCredentialsFailure(e);
    }
    return UnknownAuthFailure(e);
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
