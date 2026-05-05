import 'package:arena/data/repositories/auth_failure.dart';

/// Maps an [AuthFailure] to a French message.
///
/// Phase 2 keeps the strings inline; PHASE 1 BIS's ARB infrastructure
/// will absorb these once we have ARB keys for each `failure.code`.
String authFailureToMessage(AuthFailure failure) {
  return switch (failure) {
    InvalidCredentialsFailure() => 'Email ou mot de passe incorrect.',
    EmailAlreadyRegisteredFailure() =>
      'Un compte existe déjà avec cet email.',
    WeakPasswordFailure() =>
      'Mot de passe trop faible (8 caractères minimum).',
    EmailNotConfirmedFailure() =>
      'Vérifie tes emails pour confirmer ton inscription.',
    UserBannedFailure() =>
      'Ce compte est suspendu. Contacte le support.',
    WrongAppForRoleFailure() =>
      "Ce compte est administrateur. Télécharge l'app ARENA Admin.",
    NetworkFailure() =>
      'Pas de connexion. Vérifie ton réseau et réessaie.',
    RateLimitedFailure() =>
      'Trop de tentatives. Patiente quelques minutes avant de réessayer.',
    InvalidInvitationCodeFailure() =>
      "Code d'invitation invalide, expiré, ou déjà utilisé.",
    InvalidTotpCodeFailure() =>
      'Code à 6 chiffres incorrect. Réessaie.',
    TotpReplayFailure() =>
      'Ce code vient d\'être utilisé. Attends le prochain.',
    AdminLockedFailure() =>
      'Compte verrouillé après 3 tentatives. Réessaie dans 30 min.',
    BackendUnavailableFailure() =>
      'Cette fonctionnalité arrive en PHASE 12.5 (Edge Functions).',
    UnknownAuthFailure() => 'Une erreur est survenue. Réessaie.',
  };
}
