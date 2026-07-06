import 'package:arena/core/utils/supported_countries.dart';
import 'package:arena/data/models/profile.dart';

/// VOLET 3 — vocabulaire canonique des « sections » de la console admin
/// qu'un super-admin peut restreindre lorsqu'il génère un code d'invitation.
///
/// Les `key` sont alignées sur les grandes destinations de la navigation
/// admin réelle :
///   • mobile  → boutons d'action du dashboard (AdminDashboardPage) + du
///     dashboard super-admin ;
///   • desktop → entrées de la barre latérale Fluent (AdminDesktopShell).
///
/// La section `payouts` correspond aussi à la vérification faite côté DB
/// (RPC `generate_payouts` / `mark_payout_paid` rejettent 42501 hors
/// section 'payouts'). Garder ce vocabulaire synchronisé avec les valeurs
/// écrites dans `invitation_codes.allowed_sections` (et propagées vers
/// `profiles.admin_allowed_sections`).
class AdminSection {
  const AdminSection(this.key, this.labelFr);

  /// Clé stable stockée en base (`allowed_sections` / `admin_allowed_sections`).
  final String key;

  /// Libellé français affiché (multi-sélection + périmètre).
  final String labelFr;
}

/// Liste canonique des sections restreignables.
const List<AdminSection> kAdminSections = <AdminSection>[
  AdminSection('competitions', 'Compétitions'),
  AdminSection('matches', 'Matchs'),
  AdminSection('streams', 'Streams live'),
  AdminSection('recordings', 'Enregistrements'),
  AdminSection('disputes', 'Litiges'),
  AdminSection('audit', "Journal d'audit"),
  AdminSection('payments', 'Validation des paiements'),
  AdminSection('payouts', 'Versements'),
  AdminSection('users', 'Utilisateurs'),
  AdminSection('invitations', 'Invitations admin'),
  AdminSection('revenue', 'Revenus'),
  AdminSection('broadcast', 'Diffusion'),
  AdminSection('promo', 'Bannière promo'),
  AdminSection('tutorial', 'Tutoriels'),
  AdminSection('reintegration', 'Réintégrations'),
  AdminSection('support', 'Support'),
  AdminSection('app_update', 'Mise à jour app'),
  AdminSection('anticheat', 'Anti-triche'),
];

/// Libellé FR d'une section (fallback = la clé si inconnue).
String adminSectionLabelFr(String key) {
  for (final s in kAdminSections) {
    if (s.key == key) return s.labelFr;
  }
  return key;
}

/// Vrai si [profile] peut accéder à la section [key].
///
/// Un admin sans scope de sections (NULL ou liste vide) voit TOUT — c'est
/// le comportement inchangé des admins existants. Un profil `null` (encore
/// en hydratation) est traité comme non restreint pour ne pas masquer la
/// nav pendant le boot ; la RLS/les RPC protègent la donnée côté serveur.
bool adminCanSection(Profile? profile, String key) {
  final sections = profile?.adminAllowedSections;
  if (sections == null || sections.isEmpty) return true;
  return sections.contains(key);
}

/// Vrai si [profile] peut agir sur le pays [code] (ISO alpha-2).
///
/// Même sémantique que [adminCanSection] : NULL/vide = tous les pays.
bool adminCanCountry(Profile? profile, String code) {
  final countries = profile?.adminAllowedCountries;
  if (countries == null || countries.isEmpty) return true;
  return countries.contains(code);
}

/// Vrai si [profile] a un périmètre pays restreint (au moins un pays listé).
bool adminHasCountryScope(Profile? profile) {
  final countries = profile?.adminAllowedCountries;
  return countries != null && countries.isNotEmpty;
}

/// Libellé lisible d'une liste de codes pays (drapeau + nom), séparés par
/// des virgules. Ex. `['CM','SN']` → `🇨🇲 Cameroun, 🇸🇳 Sénégal`. Code
/// inconnu → affiché tel quel. Vide si liste nulle/vide.
String adminCountriesLabel(List<String>? codes) {
  if (codes == null || codes.isEmpty) return '';
  return codes.map((c) {
    for (final sc in kSupportedCountries) {
      if (sc.code == c) return '${sc.flag} ${sc.name}';
    }
    return c;
  }).join(', ');
}

/// Mappe un chemin de route admin (mobile ou desktop) vers sa clé de
/// section [kAdminSections], ou `null` si la destination n'est pas
/// restreignable (dashboard, vue d'ensemble super-admin, profil…).
///
/// Sert de garde de défense-en-profondeur dans le `redirect` des routers :
/// un admin restreint qui tape un deep-link vers une section masquée est
/// renvoyé à l'accueil (la RLS/les RPC protègent déjà la donnée côté
/// serveur ; ceci ferme aussi l'accès UI).
String? adminSectionForLocation(String location) {
  // Sous-arbre super-admin — vérifié en premier (préfixes plus longs).
  if (location.startsWith('/super/users')) return 'users';
  if (location.startsWith('/super/payments')) return 'payments';
  if (location.startsWith('/super/payouts')) return 'payouts';
  if (location.startsWith('/super/invitations')) return 'invitations';
  if (location.startsWith('/super/revenue')) return 'revenue';
  if (location.startsWith('/super/broadcast')) return 'broadcast';
  if (location.startsWith('/super/promo-banner')) return 'promo';
  if (location.startsWith('/super/tutorial')) return 'tutorial';
  if (location.startsWith('/super/reintegration')) return 'reintegration';
  if (location.startsWith('/super/support')) return 'support';
  if (location.startsWith('/super/messages')) return 'support';
  if (location.startsWith('/super/app-update')) return 'app_update';
  if (location.startsWith('/super/anticheat')) return 'anticheat';
  // /super et /super/ (dashboard) → non restreignable.
  if (location == '/super' || location == '/super/') return null;

  // Coeur admin.
  if (location.startsWith('/competitions')) return 'competitions';
  if (location.startsWith('/matches')) return 'matches';
  if (location.startsWith('/streams')) return 'streams';
  if (location.startsWith('/payouts')) return 'payouts';
  if (location.startsWith('/recordings')) return 'recordings';
  if (location.startsWith('/audit')) return 'audit';
  if (location.startsWith('/disputes')) return 'disputes';
  return null;
}
