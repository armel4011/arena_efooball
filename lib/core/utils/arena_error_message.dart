import 'dart:io';

import 'package:arena/data/repositories/auth_failure.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Mappe une exception en message lisible pour les snackbars / dialogs.
///
/// Le pattern précédent (`'Échec : $e'`) expose la stack tech au user.
/// Cette fonction prend les exceptions les plus fréquentes côté repos
/// (`PostgrestException`, `AuthException`, `FunctionException`,
/// `SocketException`) et renvoie un texte FR concis. Le fallback reste
/// `e.toString()` pour ne rien masquer en dev.
String arenaErrorMessage(Object error) {
  if (error is AuthFailure) {
    return _authFailureMessage(error);
  }
  if (error is AuthException) {
    return error.message;
  }
  if (error is PostgrestException) {
    if (error.code == '23505') return 'Cette valeur est déjà utilisée.';
    if (error.code == '23503') return 'Référence invalide.';
    if (error.code == '42501') {
      // Nos gardes serveur « réservé au super-admin » (audit 2026-07-07 : verdict
      // de match à cagnotte, classement final d'une compétition à prix, actions
      // /super) lèvent un message FR explicite. On le surface pour qu'un admin
      // SIMPLE comprenne qu'il doit escalader, au lieu du générique. Les 42501
      // BRUTS de Postgres (« permission denied », « violates row-level security »)
      // restent masqués derrière le message générique (techniques, en anglais).
      final lower = error.message.toLowerCase();
      if (lower.contains('super-admin') || lower.contains('super_admin')) {
        return error.message;
      }
      return "Vous n'avez pas la permission.";
    }
    if (error.code == 'PGRST301') return 'Session expirée. Reconnectez-vous.';
    return error.message;
  }
  if (error is FunctionException) {
    return 'Erreur serveur (${error.status}). Réessayez plus tard.';
  }
  if (error is SocketException) {
    return 'Pas de connexion réseau.';
  }
  return error.toString();
}

String _authFailureMessage(AuthFailure e) {
  switch (e.code) {
    case 'invalid_credentials':
      return 'Email ou mot de passe incorrect.';
    case 'email_already_registered':
      return 'Cet email est déjà inscrit.';
    case 'weak_password':
      return 'Mot de passe trop faible.';
    case 'email_not_confirmed':
      return 'Email non confirmé.';
    case 'user_banned':
      return 'Compte suspendu.';
    case 'wrong_app_for_role':
      return 'Mauvaise application pour ce rôle.';
    case 'network':
      return 'Pas de connexion réseau.';
    case 'rate_limited':
      return 'Trop de tentatives. Réessayez plus tard.';
    case 'username_already_taken':
      return 'Ce pseudo est déjà pris.';
    case 'invalid_invitation_code':
      return "Code d'invitation invalide.";
    case 'invalid_totp_code':
      return 'Code TOTP incorrect.';
    case 'totp_replay':
      return 'Code TOTP déjà utilisé, attendez la rotation.';
    case 'admin_locked':
      return 'Compte verrouillé (30 min).';
    case 'backend_unavailable':
      return 'Service indisponible.';
    case 'sso_cancelled':
      return 'Connexion annulée.';
    case 'invalid_password_reset_code':
      return 'Code de réinitialisation invalide.';
    case 'expired_password_reset_code':
      return 'Code expiré (1h). Demandez-en un nouveau.';
    default:
      return e.cause?.toString() ?? "Erreur d'authentification.";
  }
}
