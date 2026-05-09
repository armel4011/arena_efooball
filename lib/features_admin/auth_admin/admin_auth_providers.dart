import 'dart:io';

import 'package:arena/data/models/profile.dart';
import 'package:arena/data/repositories/auth_failure.dart';
import 'package:arena/data/repositories/auth_repository.dart';
import 'package:arena/data/repositories/profile_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// =============================================================================
// AdminAuthRepository
// =============================================================================
//
// Wraps the admin-specific flows on top of the existing AuthRepository:
//   * sign-in (email + password) **with role gate** — admin/super_admin only
//   * invitation-code redeem (PHASE 2bis backend)
//   * TOTP setup (QR + secret) and verify (login)
//
// Several methods talk to Edge Functions that don't exist yet (PHASE 12.5).
// They throw [BackendUnavailableFailure] with a clear message so the UI
// can stay wired and surface "feature pending" to the user instead of
// silently no-op'ing.

/// Outcome of [AdminAuthRepository.setupTotp] — the QR data + the manual
/// fallback secret so the user can type it instead of scanning.
@immutable
class TotpSetupChallenge {
  const TotpSetupChallenge({
    required this.otpauthUri,
    required this.secret,
  });

  /// `otpauth://totp/...` URI to encode in a QR code.
  final String otpauthUri;

  /// Base32 secret displayed below the QR for manual entry.
  final String secret;
}

class AdminAuthRepository {
  const AdminAuthRepository({
    required SupabaseClient client,
    required AuthRepository auth,
    required ProfileRepository profiles,
  })  : _client = client,
        _auth = auth,
        _profiles = profiles;

  // ignore: unused_field
  final SupabaseClient _client;
  final AuthRepository _auth;
  // ignore: unused_field
  final ProfileRepository _profiles;

  /// Sign in via email + password and enforce admin role.
  ///
  /// Returns the [Profile] on success. Throws [WrongAppForRoleFailure]
  /// if the account is a player.
  Future<Profile> signInAdmin({
    required String email,
    required String password,
  }) async {
    final profile = await _auth.signInWithEmail(
      email: email,
      password: password,
    );
    if (!profile.isAdmin) {
      // Sign back out — we don't want to leave a player session hanging
      // in the admin app.
      await _auth.signOut();
      throw const WrongAppForRoleFailure();
    }
    return profile;
  }

  /// Validate an invitation code + register a new admin.
  ///
  /// Calls the Edge Function `register-admin` (PHASE 12.5). Until then,
  /// throws [BackendUnavailableFailure].
  Future<Profile> redeemInvitation({
    required String code,
    required String email,
    required String password,
    required String username,
    required DateTime cguAcceptedAt,
    required String cguVersionAccepted,
  }) async {
    return _runEdge<Profile>(() async {
      // PHASE 12.5 — invoke `register-admin` edge function. The function
      // verifies the code, creates the auth user, inserts the profile
      // with the role from the invitation, marks the invitation as used,
      // and returns the profile JSON.
      throw const BackendUnavailableFailure(
        'register-admin edge function not deployed yet',
      );
    });
  }

  /// Begin TOTP setup for the currently signed-in admin.
  ///
  /// Calls Edge Function `setup-totp` which generates the secret server
  /// side, stores it on the profile (encrypted), and returns the otpauth
  /// URI + base32 secret.
  Future<TotpSetupChallenge> setupTotp() async {
    return _runEdge<TotpSetupChallenge>(() async {
      throw const BackendUnavailableFailure(
        'setup-totp edge function not deployed yet',
      );
    });
  }

  /// Verify the 6-digit TOTP code right after setup → flips
  /// `profiles.totp_enabled` to true and returns the 10 backup codes.
  Future<List<String>> verifyTotpSetup(String code) async {
    return _runEdge<List<String>>(() async {
      throw const BackendUnavailableFailure(
        'verify-totp-setup edge function not deployed yet',
      );
    });
  }

  /// Verify the TOTP code at login (after email + password). On success,
  /// the temporary auth token is exchanged for a real Supabase session.
  Future<Profile> verifyTotpLogin(String code) async {
    return _runEdge<Profile>(() async {
      throw const BackendUnavailableFailure(
        'admin-verify-totp edge function not deployed yet',
      );
    });
  }

  /// Wrap an Edge-Function call in our typed-failure mapping.
  Future<T> _runEdge<T>(Future<T> Function() body) async {
    try {
      return await body();
    } on AuthFailure {
      rethrow;
    } on SocketException catch (e) {
      throw NetworkFailure(e);
    } catch (e) {
      throw UnknownAuthFailure(e);
    }
  }
}

final adminAuthRepositoryProvider = Provider<AdminAuthRepository>((ref) {
  return AdminAuthRepository(
    client: ref.watch(supabaseClientProvider),
    auth: ref.watch(authRepositoryProvider),
    profiles: ref.watch(profileRepositoryProvider),
  );
});

// =============================================================================
// Controllers Riverpod
// =============================================================================

/// Sign-in controller for the admin app (email + password step).
///
/// Success doesn't mean fully authenticated — TOTP verification is the
/// next step (cf. [AdminTotpVerifyController]).
class AdminSignInController extends AsyncNotifier<Profile?> {
  @override
  Future<Profile?> build() async => null;

  Future<void> signIn({required String email, required String password}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      return ref
          .read(adminAuthRepositoryProvider)
          .signInAdmin(email: email, password: password);
    });
  }

  void reset() => state = const AsyncData(null);
}

final adminSignInControllerProvider =
    AsyncNotifierProvider<AdminSignInController, Profile?>(
  AdminSignInController.new,
);

/// Invitation-code redeem controller. Powers [InvitationRedeemScreen].
class InvitationRedeemController extends AsyncNotifier<Profile?> {
  @override
  Future<Profile?> build() async => null;

  Future<void> redeem({
    required String code,
    required String email,
    required String password,
    required String username,
    required DateTime cguAcceptedAt,
    required String cguVersionAccepted,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      return ref.read(adminAuthRepositoryProvider).redeemInvitation(
            code: code,
            email: email,
            password: password,
            username: username,
            cguAcceptedAt: cguAcceptedAt,
            cguVersionAccepted: cguVersionAccepted,
          );
    });
  }

  void reset() => state = const AsyncData(null);
}

final invitationRedeemControllerProvider =
    AsyncNotifierProvider<InvitationRedeemController, Profile?>(
  InvitationRedeemController.new,
);

/// TOTP-setup controller — fetches the QR challenge then verifies the
/// first 6-digit code. The screen reads `data` to know which step to
/// render (`null` = need challenge, [TotpSetupState.challenge] = show QR,
/// [TotpSetupState.backupCodes] = show recovery codes).
@immutable
class TotpSetupState {
  const TotpSetupState({this.challenge, this.backupCodes});
  final TotpSetupChallenge? challenge;
  final List<String>? backupCodes;
}

class AdminTotpSetupController extends AsyncNotifier<TotpSetupState> {
  @override
  Future<TotpSetupState> build() async => const TotpSetupState();

  Future<void> requestChallenge() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final challenge =
          await ref.read(adminAuthRepositoryProvider).setupTotp();
      return TotpSetupState(challenge: challenge);
    });
  }

  Future<void> verify(String code) async {
    final challenge = state.value?.challenge;
    if (challenge == null) return;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final codes =
          await ref.read(adminAuthRepositoryProvider).verifyTotpSetup(code);
      return TotpSetupState(challenge: challenge, backupCodes: codes);
    });
  }
}

final adminTotpSetupControllerProvider =
    AsyncNotifierProvider<AdminTotpSetupController, TotpSetupState>(
  AdminTotpSetupController.new,
);

/// TOTP-verify controller for the **login** step (after email + password).
class AdminTotpVerifyController extends AsyncNotifier<Profile?> {
  @override
  Future<Profile?> build() async => null;

  Future<void> verify(String code) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      return ref.read(adminAuthRepositoryProvider).verifyTotpLogin(code);
    });
  }

  void reset() => state = const AsyncData(null);
}

final adminTotpVerifyControllerProvider =
    AsyncNotifierProvider<AdminTotpVerifyController, Profile?>(
  AdminTotpVerifyController.new,
);
