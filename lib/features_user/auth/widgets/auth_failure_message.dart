import 'package:arena/data/repositories/auth_failure.dart';

/// Maps an [AuthFailure] to a French message.
///
/// Ton : vouvoiement, sobre et professionnel — concis, sans jargon
/// technique ni détail interne. Affiché via `AuthErrorBanner`.
String authFailureToMessage(AuthFailure failure) {
  return switch (failure) {
    InvalidCredentialsFailure() => 'Email ou mot de passe incorrect.',
    EmailAlreadyRegisteredFailure() =>
      'Un compte existe déjà avec cet email.',
    WeakPasswordFailure() =>
      'Mot de passe trop faible : 8 caractères minimum.',
    EmailNotConfirmedFailure() =>
      'Confirmez votre inscription via le lien reçu par email.',
    UserBannedFailure() =>
      'Ce compte est suspendu. Contactez le support.',
    WrongAppForRoleFailure() =>
      "Ce compte est administrateur. Utilisez l'application ARENA Admin.",
    NetworkFailure() =>
      'Pas de connexion internet. Vérifiez votre réseau et réessayez.',
    RateLimitedFailure() =>
      'Trop de tentatives. Réessayez dans quelques minutes.',
    InvalidInvitationCodeFailure() =>
      "Code d'invitation invalide, expiré ou déjà utilisé.",
    InvalidTotpCodeFailure() =>
      'Code à 6 chiffres incorrect.',
    TotpReplayFailure() =>
      'Ce code a déjà été utilisé. Attendez le suivant.',
    AdminLockedFailure() =>
      'Compte verrouillé après 3 tentatives. Réessayez dans 30 minutes.',
    BackendUnavailableFailure() =>
      'Service momentanément indisponible. Réessayez plus tard.',
    UsernameAlreadyTakenFailure() =>
      'Ce pseudo est déjà utilisé. Choisissez-en un autre.',
    SsoCancelledFailure() => 'Connexion annulée.',
    SsoIdTokenMissingFailure() =>
      'Connexion impossible. Vérifiez votre réseau et réessayez.',
    SsoConfigMissingFailure() =>
      'Connexion indisponible pour le moment. Contactez le support.',
    InvalidPasswordResetCodeFailure() =>
      'Code incorrect. Vérifiez votre email.',
    ExpiredPasswordResetCodeFailure() =>
      'Code expiré. Demandez un nouveau code.',
    UnknownAuthFailure() => 'Une erreur est survenue. Réessayez.',
  };
}
