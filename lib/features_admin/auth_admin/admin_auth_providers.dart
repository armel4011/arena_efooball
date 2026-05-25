import 'dart:io';

import 'package:arena/data/models/profile.dart';
import 'package:arena/data/repositories/auth_failure.dart';
import 'package:arena/data/repositories/auth_repository.dart';
import 'package:arena/data/repositories/profile_repository.dart';
import 'package:arena/features_admin/auth_admin/invitation_redeem_screen.dart'
    show InvitationRedeemScreen;
import 'package:arena/features_admin/auth_admin/widgets/totp_gate.dart'
    show TotpGate;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Maps an Edge Function `FunctionException` body to a typed [AuthFailure].
/// Centralised so all admin EFs (TOTP + register-admin) share the same
/// error language.
AuthFailure _mapAdminEdgeError(FunctionException e) {
  final body = e.details;
  String? errorCode;
  if (body is Map && body['error'] is String) {
    errorCode = body['error'] as String;
  }
  switch (errorCode) {
    // ── TOTP ─────────────────────────────────────────────────────────
    case 'invalid_code':
      return InvalidTotpCodeFailure(e);
    case 'totp_not_configured':
    case 'no_secret_pending':
      return const BackendUnavailableFailure(
        'TOTP not configured for this account',
      );
    // ── register-admin ───────────────────────────────────────────────
    case 'invalid_invitation_code':
    case 'invitation_expired':
    case 'invitation_already_used':
    case 'invitation_email_mismatch':
      return InvalidInvitationCodeFailure(e);
    case 'email_already_registered':
      return EmailAlreadyRegisteredFailure(e);
    case 'username_already_taken':
      return UsernameAlreadyTakenFailure(e);
    case 'password_too_short':
    case 'password_no_uppercase':
    case 'password_no_lowercase':
    case 'password_no_digit':
    case 'password_no_symbol':
    case 'password_rejected':
      return WeakPasswordFailure(e);
    // ── Common ───────────────────────────────────────────────────────
    case 'forbidden_role':
      return WrongAppForRoleFailure(e);
    case 'unauthenticated':
      return InvalidCredentialsFailure(e);
  }
  if (e.status == 401) return InvalidTotpCodeFailure(e);
  if (e.status == 403) return WrongAppForRoleFailure(e);
  return UnknownAuthFailure(e);
}

// =============================================================================
// AdminAuthRepository
// =============================================================================
//
// Wraps the admin-specific flows on top of the existing AuthRepository:
//   * sign-in (email + password) **with role gate** — admin/super_admin only
//   * invitation-code redeem (PHASE 2bis backend — still pending)
//   * TOTP setup (QR + secret), verify-setup, verify-login, step-up
//
// The 4 TOTP Edge Functions ship in Phase 12.5 (`setup-totp`,
// `verify-totp-setup`, `admin-verify-totp`, `admin-stepup-totp`). The
// only remaining stub is `register-admin` — still throws
// [BackendUnavailableFailure] so the invitation-redeem screen surfaces
// "feature pending" until that EF lands.

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
  /// Calls `register-admin` Edge Function which validates the code,
  /// creates the auth user (admin API, email auto-confirmed), inserts
  /// the profile with the role from the invitation, and stamps the
  /// invitation as used. Then signs in with the same credentials so
  /// the caller lands on the TOTP setup flow with a live session.
  Future<Profile> redeemInvitation({
    required String code,
    required String email,
    required String password,
    required String username,
    required DateTime cguAcceptedAt,
    required String cguVersionAccepted,
  }) async {
    return _runEdge<Profile>(() async {
      final res = await _client.functions.invoke(
        'register-admin',
        body: {
          'code': code,
          'email': email,
          'password': password,
          'username': username,
          'cguAcceptedAt': cguAcceptedAt.toUtc().toIso8601String(),
          'cguVersionAccepted': cguVersionAccepted,
        },
      );
      final data = res.data;
      if (data is! Map || data['profile'] is! Map) {
        throw const UnknownAuthFailure('register-admin:malformed_response');
      }
      // The EF doesn't grant a session — sign in to establish one so
      // the next step (TotpSetupScreen → setup-totp) has a valid JWT.
      await _auth.signInWithEmail(email: email, password: password);
      return Profile.fromJson(
        Map<String, dynamic>.from(data['profile'] as Map),
      );
    });
  }

  /// Begin TOTP setup for the currently signed-in admin.
  ///
  /// Calls Edge Function `setup-totp` which generates a 160-bit secret
  /// server-side, stores it on `profiles.totp_secret`, and returns the
  /// `otpauth://` URI + base32 fallback.
  Future<TotpSetupChallenge> setupTotp() async {
    return _runEdge<TotpSetupChallenge>(() async {
      final res = await _client.functions.invoke('setup-totp');
      final data = res.data;
      if (data is! Map ||
          data['otpauthUri'] is! String ||
          data['secret'] is! String) {
        throw const UnknownAuthFailure('setup-totp:malformed_response');
      }
      return TotpSetupChallenge(
        otpauthUri: data['otpauthUri'] as String,
        secret: data['secret'] as String,
      );
    });
  }

  /// Verify the 6-digit TOTP code right after setup → flips
  /// `profiles.totp_enabled` to true and returns the 10 backup codes.
  Future<List<String>> verifyTotpSetup(String code) async {
    return _runEdge<List<String>>(() async {
      final res = await _client.functions.invoke(
        'verify-totp-setup',
        body: {'code': code},
      );
      final data = res.data;
      if (data is! Map || data['backupCodes'] is! List) {
        throw const UnknownAuthFailure('verify-totp-setup:malformed_response');
      }
      return (data['backupCodes'] as List).whereType<String>().toList();
    });
  }

  /// Verify the TOTP code at login (after email + password). The
  /// Supabase session is already established at this point — this EF
  /// just confirms the 2nd factor and returns the full [Profile].
  Future<Profile> verifyTotpLogin(String code) async {
    return _runEdge<Profile>(() async {
      final res = await _client.functions.invoke(
        'admin-verify-totp',
        body: {'code': code},
      );
      final data = res.data;
      if (data is! Map || data['profile'] is! Map) {
        throw const UnknownAuthFailure('admin-verify-totp:malformed_response');
      }
      return Profile.fromJson(
        Map<String, dynamic>.from(data['profile'] as Map),
      );
    });
  }

  /// Step-up TOTP verification for sensitive admin actions. Called from
  /// [TotpGate] before validating payouts, resolving disputes, banning
  /// users, KYC override, etc.
  Future<void> stepUpTotp(String code) async {
    return _runEdge<void>(() async {
      final res = await _client.functions.invoke(
        'admin-stepup-totp',
        body: {'code': code},
      );
      final data = res.data;
      if (data is! Map || data['ok'] != true) {
        throw const UnknownAuthFailure('admin-stepup-totp:malformed_response');
      }
    });
  }

  /// Wrap an Edge-Function call in our typed-failure mapping.
  Future<T> _runEdge<T>(Future<T> Function() body) async {
    try {
      return await body();
    } on AuthFailure {
      rethrow;
    } on FunctionException catch (e) {
      throw _mapAdminEdgeError(e);
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
      final challenge = await ref.read(adminAuthRepositoryProvider).setupTotp();
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

/// Step-up TOTP controller — re-prompt before sensitive admin actions
/// (payout validation, dispute resolution, ban, KYC override). One
/// controller instance per [TotpGate] modal; state resets on dismiss.
class AdminTotpStepUpController extends AsyncNotifier<bool> {
  @override
  Future<bool> build() async => false;

  Future<void> verify(String code) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(adminAuthRepositoryProvider).stepUpTotp(code);
      return true;
    });
  }

  void reset() => state = const AsyncData(false);
}

final adminTotpStepUpControllerProvider =
    AsyncNotifierProvider<AdminTotpStepUpController, bool>(
  AdminTotpStepUpController.new,
);
