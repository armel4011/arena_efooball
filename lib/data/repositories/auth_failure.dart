/// Typed error returned by AuthRepository.
///
/// Each variant carries a key — UI layers translate the key to a
/// human-readable message via the ARB strings. Wrapping Supabase errors
/// here keeps the rest of the app insulated from the SDK and makes
/// switching providers later trivial.
sealed class AuthFailure implements Exception {
  const AuthFailure(this.code, [this.cause]);

  /// Stable identifier for logging / breadcrumbs.
  final String code;

  /// Original error (Supabase `AuthException`, network error, etc.) — kept
  /// for logging / Sentry breadcrumbs only.
  final Object? cause;

  @override
  String toString() => 'AuthFailure($code, ${cause ?? ''})';
}

class InvalidCredentialsFailure extends AuthFailure {
  const InvalidCredentialsFailure([Object? cause])
      : super('invalid_credentials', cause);
}

class EmailAlreadyRegisteredFailure extends AuthFailure {
  const EmailAlreadyRegisteredFailure([Object? cause])
      : super('email_already_registered', cause);
}

class WeakPasswordFailure extends AuthFailure {
  const WeakPasswordFailure([Object? cause])
      : super('weak_password', cause);
}

class EmailNotConfirmedFailure extends AuthFailure {
  const EmailNotConfirmedFailure([Object? cause])
      : super('email_not_confirmed', cause);
}

class UserBannedFailure extends AuthFailure {
  const UserBannedFailure([Object? cause]) : super('user_banned', cause);
}

class WrongAppForRoleFailure extends AuthFailure {
  /// User has role admin/super_admin but tried to log in via the User app
  /// (or vice-versa). UI should surface "Téléchargez ARENA Admin".
  const WrongAppForRoleFailure([Object? cause])
      : super('wrong_app_for_role', cause);
}

class NetworkFailure extends AuthFailure {
  const NetworkFailure([Object? cause]) : super('network', cause);
}

/// Supabase rate limit hit (typically email confirmation, statusCode=429).
class RateLimitedFailure extends AuthFailure {
  const RateLimitedFailure([Object? cause]) : super('rate_limited', cause);
}

class UnknownAuthFailure extends AuthFailure {
  const UnknownAuthFailure([Object? cause]) : super('unknown', cause);
}

/// Username déjà pris par un autre profil (contrainte unique sur `username`).
class UsernameAlreadyTakenFailure extends AuthFailure {
  const UsernameAlreadyTakenFailure([Object? cause])
      : super('username_already_taken', cause);
}

/// Code d'invitation invalide / expiré / déjà utilisé.
class InvalidInvitationCodeFailure extends AuthFailure {
  const InvalidInvitationCodeFailure([Object? cause])
      : super('invalid_invitation_code', cause);
}

/// Code TOTP saisi incorrect (mauvais chiffres, secret désynchronisé).
class InvalidTotpCodeFailure extends AuthFailure {
  const InvalidTotpCodeFailure([Object? cause])
      : super('invalid_totp_code', cause);
}

/// Anti-replay TOTP : le code vient d'être utilisé dans la fenêtre courante.
class TotpReplayFailure extends AuthFailure {
  const TotpReplayFailure([Object? cause]) : super('totp_replay', cause);
}

/// Compte admin verrouillé (3 essais TOTP failed → 30 min de blocage).
class AdminLockedFailure extends AuthFailure {
  const AdminLockedFailure([Object? cause]) : super('admin_locked', cause);
}

/// Phase 2bis backend pas encore livré — les Edge Functions
/// (`generate-invitation-code`, `setup-totp`, `verify-totp-setup`,
/// `admin-verify-totp`) seront créées en PHASE 12.5. Permet aux écrans
/// d'exister avec un message clair en attendant.
class BackendUnavailableFailure extends AuthFailure {
  const BackendUnavailableFailure([Object? cause])
      : super('backend_unavailable', cause);
}
