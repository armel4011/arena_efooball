import 'package:arena/data/models/profile.dart';
import 'package:arena/features_shared/admin_sections.dart';

/// Raison pour laquelle une route admin est refusée à un profil authentifié.
///
/// Les DEUX consoles (mobile `admin_router`, desktop `admin_desktop_router`)
/// évaluent l'autorisation via [adminRouteDenial] puis traduisent la raison
/// en cible de redirection concrète — cible qui diffère entre les deux
/// consoles (`AdminRoutes.home` vs `AdminDesktopRoutes.dashboard`).
enum AdminRouteDenial {
  /// Rôle insuffisant : admin simple sur une route super-admin (`/super/*`).
  insufficientRole,

  /// Section hors du périmètre d'un admin au scope restreint.
  sectionOutOfScope,
}

/// Politique d'AUTORISATION admin **partagée** (mobile + desktop).
///
/// Source unique de vérité pour « quel rôle / quelle section protège telle
/// route ». Ainsi une route ne peut jamais être protégée d'un côté et pas de
/// l'autre — c'est exactement la classe de bug du P1 (audit 2026-07-13) où le
/// router desktop n'appliquait pas la garde `/super/*` que le mobile avait.
///
/// Ne traite QUE le rôle et la section. L'AUTHENTIFICATION (session absente,
/// TOTP à configurer/vérifier, sortie des écrans d'auth) reste propre à chaque
/// router : les cibles de redirection y sont spécifiques à la console.
///
/// Retourne `null` si l'accès est autorisé. Un [profile] `null` (encore en
/// hydratation) n'est jamais bloqué — cohérent avec [adminCanSection] : la
/// RLS/les RPC protègent la donnée côté serveur, ceci ferme l'accès UI.
AdminRouteDenial? adminRouteDenial(String location, Profile? profile) {
  // 1. Règle de RÔLE — tout le sous-arbre `/super` exige super_admin.
  //    (Comportement identique aux deux routers historiques : `startsWith`.)
  if (location.startsWith('/super') &&
      profile != null &&
      !profile.isSuperAdmin) {
    return AdminRouteDenial.insufficientRole;
  }

  // 2. Règle de SECTION — périmètre restreint (défense en profondeur).
  final section = adminSectionForLocation(location);
  if (section != null && !adminCanSection(profile, section)) {
    return AdminRouteDenial.sectionOutOfScope;
  }

  return null;
}
