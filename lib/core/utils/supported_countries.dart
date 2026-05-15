/// Liste des pays supportés au signup ARENA, avec indicatif téléphonique
/// au format E.164.
///
/// Partagée entre :
///  - `register_user_screen.dart` (wizard inscription email/password)
///  - `cgu_acceptance_page.dart` (compléter profil pour les comptes SSO)
///
/// Pour ajouter un pays : ajouter une entrée + s'assurer que l'`appCurrency`
/// associée existe côté Supabase (futur multi-devise PHASE 14/15).
class SupportedCountry {
  const SupportedCountry(this.code, this.name, this.flag, this.dialCode);

  /// ISO 3166-1 alpha-2 (CM, SN, CI…).
  final String code;

  /// Libellé affiché dans le picker.
  final String name;

  /// Emoji drapeau.
  final String flag;

  /// Indicatif E.164 avec `+` (ex: `+237`).
  final String dialCode;
}

const List<SupportedCountry> kSupportedCountries = <SupportedCountry>[
  SupportedCountry('CM', 'Cameroun', '🇨🇲', '+237'),
  SupportedCountry('SN', 'Sénégal', '🇸🇳', '+221'),
  SupportedCountry('CI', "Côte d'Ivoire", '🇨🇮', '+225'),
  SupportedCountry('GA', 'Gabon', '🇬🇦', '+241'),
  SupportedCountry('BJ', 'Bénin', '🇧🇯', '+229'),
  SupportedCountry('TG', 'Togo', '🇹🇬', '+228'),
  SupportedCountry('BF', 'Burkina Faso', '🇧🇫', '+226'),
  SupportedCountry('ML', 'Mali', '🇲🇱', '+223'),
  SupportedCountry('NE', 'Niger', '🇳🇪', '+227'),
  SupportedCountry('TD', 'Tchad', '🇹🇩', '+235'),
  SupportedCountry('GN', 'Guinée', '🇬🇳', '+224'),
  SupportedCountry('CD', 'RD Congo', '🇨🇩', '+243'),
  SupportedCountry('MG', 'Madagascar', '🇲🇬', '+261'),
];

/// Retourne l'indicatif E.164 du pays (ex: `'CI'` → `'+225'`). Fallback
/// sur le 1er pays de la liste si le code est inconnu (évite un crash
/// si la DB contient un code legacy non listé).
String dialCodeFor(String countryCode) {
  return kSupportedCountries
      .firstWhere(
        (c) => c.code == countryCode,
        orElse: () => kSupportedCountries.first,
      )
      .dialCode;
}

/// Construit un numéro E.164 à partir d'un code pays + numéro local
/// éventuellement préfixé d'un `0` (convention nationale). Strip tous
/// les caractères non-chiffres avant.
String buildE164Phone({required String countryCode, required String local}) {
  final dial = dialCodeFor(countryCode);
  var digits = local.replaceAll(RegExp(r'\D'), '');
  if (digits.startsWith('0')) digits = digits.substring(1);
  return '$dial$digits';
}

/// Valide un numéro local : 7 à 12 chiffres une fois le `0` de tête
/// éventuel retiré (couvre les opérateurs Orange/MTN/Moov/Wave en
/// Afrique francophone).
bool isLocalPhoneValid(String local) {
  final digits = local.replaceAll(RegExp(r'\D'), '');
  final stripped = digits.startsWith('0') ? digits.substring(1) : digits;
  return stripped.length >= 7 && stripped.length <= 12;
}
