import 'package:arena/data/repositories/auth_failure.dart';
import 'package:arena/l10n/generated/app_localizations.dart';

/// Maps an [AuthFailure] to a user-facing message.
///
/// When [l10n] is provided (user app), the message is localized (fr/en/ar).
/// When omitted (admin app — which stays in French), the French fallback is
/// returned. Ton : vouvoiement, sobre et professionnel — concis, sans jargon.
String authFailureToMessage(AuthFailure failure, [AppLocalizations? l10n]) {
  String tr(String Function(AppLocalizations) pick, String fr) =>
      l10n == null ? fr : pick(l10n);
  return switch (failure) {
    InvalidCredentialsFailure() => tr(
        (l) => l.authErrInvalidCredentials,
        'Email ou mot de passe incorrect.',
      ),
    EmailAlreadyRegisteredFailure() => tr(
        (l) => l.authErrEmailAlreadyRegistered,
        'Un compte existe déjà avec cet email.',
      ),
    WeakPasswordFailure() => tr(
        (l) => l.authErrWeakPassword,
        'Mot de passe trop faible : 8 caractères minimum.',
      ),
    EmailNotConfirmedFailure() => tr(
        (l) => l.authErrEmailNotConfirmed,
        'Confirmez votre inscription via le lien reçu par email.',
      ),
    UserBannedFailure() => tr(
        (l) => l.authErrUserBanned,
        'Ce compte est suspendu. Contactez le support.',
      ),
    WrongAppForRoleFailure() => tr(
        (l) => l.authErrWrongApp,
        "Ce compte est administrateur. Utilisez l'application ARENA Admin.",
      ),
    NetworkFailure() => tr(
        (l) => l.authErrNetwork,
        'Pas de connexion internet. Vérifiez votre réseau et réessayez.',
      ),
    RateLimitedFailure() => tr(
        (l) => l.authErrRateLimited,
        'Trop de tentatives. Réessayez dans quelques minutes.',
      ),
    InvalidInvitationCodeFailure() => tr(
        (l) => l.authErrInvalidInvitation,
        "Code d'invitation invalide, expiré ou déjà utilisé.",
      ),
    InvalidTotpCodeFailure() => tr(
        (l) => l.authErrInvalidTotp,
        'Code à 6 chiffres incorrect.',
      ),
    TotpReplayFailure() => tr(
        (l) => l.authErrTotpReplay,
        'Ce code a déjà été utilisé. Attendez le suivant.',
      ),
    AdminLockedFailure() => tr(
        (l) => l.authErrAdminLocked,
        'Compte verrouillé après 3 tentatives. Réessayez dans 30 minutes.',
      ),
    BackendUnavailableFailure() => tr(
        (l) => l.authErrBackendUnavailable,
        'Service momentanément indisponible. Réessayez plus tard.',
      ),
    UsernameAlreadyTakenFailure() => tr(
        (l) => l.authErrUsernameTaken,
        'Ce pseudo est déjà utilisé. Choisissez-en un autre.',
      ),
    SsoCancelledFailure() => tr((l) => l.authErrSsoCancelled, 'Connexion annulée.'),
    SsoIdTokenMissingFailure() => tr(
        (l) => l.authErrSsoIdToken,
        'Connexion impossible. Vérifiez votre réseau et réessayez.',
      ),
    SsoConfigMissingFailure() => tr(
        (l) => l.authErrSsoConfig,
        'Connexion indisponible pour le moment. Contactez le support.',
      ),
    InvalidPasswordResetCodeFailure() => tr(
        (l) => l.authErrInvalidResetCode,
        'Code incorrect. Vérifiez votre email.',
      ),
    ExpiredPasswordResetCodeFailure() => tr(
        (l) => l.authErrExpiredResetCode,
        'Code expiré. Demandez un nouveau code.',
      ),
    UnknownAuthFailure() => tr(
        (l) => l.authErrUnknown,
        'Une erreur est survenue. Réessayez.',
      ),
  };
}
