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
  // ─── CEMAC (Afrique centrale, zone XAF) — les 6 États membres ───────────
  SupportedCountry('CM', 'Cameroun', '🇨🇲', '+237'),
  SupportedCountry('GA', 'Gabon', '🇬🇦', '+241'),
  SupportedCountry('TD', 'Tchad', '🇹🇩', '+235'),
  SupportedCountry('CF', 'Centrafrique', '🇨🇫', '+236'),
  SupportedCountry('CG', 'Congo', '🇨🇬', '+242'),
  SupportedCountry('GQ', 'Guinée équatoriale', '🇬🇶', '+240'),
  // ─── UEMOA (Afrique de l'Ouest, zone XOF) — les 8 États membres ─────────
  SupportedCountry('SN', 'Sénégal', '🇸🇳', '+221'),
  SupportedCountry('CI', "Côte d'Ivoire", '🇨🇮', '+225'),
  SupportedCountry('BJ', 'Bénin', '🇧🇯', '+229'),
  SupportedCountry('BF', 'Burkina Faso', '🇧🇫', '+226'),
  SupportedCountry('ML', 'Mali', '🇲🇱', '+223'),
  SupportedCountry('NE', 'Niger', '🇳🇪', '+227'),
  SupportedCountry('TG', 'Togo', '🇹🇬', '+228'),
  SupportedCountry('GW', 'Guinée-Bissau', '🇬🇼', '+245'),
  // ─── Autres pays supportés ──────────────────────────────────────────────
  SupportedCountry('GN', 'Guinée', '🇬🇳', '+224'),
  SupportedCountry('CD', 'RD Congo', '🇨🇩', '+243'),
  SupportedCountry('MG', 'Madagascar', '🇲🇬', '+261'),
];

/// Les 6 États de la zone CEMAC (Afrique centrale, franc CFA BEAC / XAF).
const Set<String> kCemacCountryCodes = {'CM', 'GA', 'TD', 'CF', 'CG', 'GQ'};

/// `true` si [countryCode] (ISO alpha-2, casse indifférente) est un pays CEMAC.
bool isCemacCountry(String? countryCode) {
  if (countryCode == null || countryCode.isEmpty) return false;
  return kCemacCountryCodes.contains(countryCode.toUpperCase());
}

/// `true` si le paiement depuis [countryCode] exige de saisir un NUMÉRO
/// DESTINATAIRE (numéro à copier + étapes + tuto), parce que le code marchand
/// n'ouvre là-bas que le menu de l'opérateur : les pays CEMAC **sauf le
/// Cameroun**.
///
/// Le destinataire ARENA étant camerounais, payer depuis le Gabon ou le Tchad
/// est un transfert TRANSFRONTALIER — d'où le choix du pays de destination puis
/// la saisie du numéro. Depuis le Cameroun le paiement est DOMESTIQUE : le code
/// marchand suffit, comme en zone UEMOA (décision produit 2026-07-16).
bool needsRecipientNumberFlow(String? countryCode) {
  if (countryCode == null || countryCode.isEmpty) return false;
  final code = countryCode.toUpperCase();
  return code != 'CM' && isCemacCountry(code);
}

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
///
/// Robuste aux saisies où l'utilisateur inclut DÉJÀ l'indicatif (cause du
/// bug « indicatif en double ») : un préfixe `00`, `+` ou l'indicatif nu en
/// tête est retiré avant de re-préfixer, à condition qu'il reste ensuite un
/// numéro local de longueur plausible (pour ne pas tronquer un vrai numéro
/// commençant par les mêmes chiffres que l'indicatif).
String buildE164Phone({required String countryCode, required String local}) {
  final dial = dialCodeFor(countryCode);
  final dialDigits = dial.replaceAll(RegExp(r'\D'), '');
  var digits = local.replaceAll(RegExp(r'\D'), '');

  // Préfixe international '00' (ex. 00237...) → équivalent au '+'.
  if (digits.startsWith('00')) digits = digits.substring(2);

  // Indicatif déjà saisi en tête → ne pas le dupliquer.
  if (digits.startsWith(dialDigits)) {
    final rest = digits.substring(dialDigits.length);
    final restNo0 = rest.startsWith('0') ? rest.substring(1) : rest;
    if (restNo0.length >= 7 && restNo0.length <= 12) {
      digits = rest;
    }
  }

  if (digits.startsWith('0')) digits = digits.substring(1);
  return '$dial$digits';
}

/// Inverse de [buildE164Phone] : retire l'indicatif E.164 en tête d'un numéro
/// STOCKÉ (`+237699…` → `699…`) pour l'afficher/éditer comme numéro local.
/// Renvoie '' si l'entrée est vide.
String stripDialCode(String? e164, String countryCode) {
  final n = e164?.trim() ?? '';
  if (n.isEmpty) return '';
  final dial = dialCodeFor(countryCode);
  if (n.startsWith(dial)) return n.substring(dial.length);
  // Repli si le `+` manque : compare sur les chiffres.
  final digits = n.replaceAll(RegExp(r'\D'), '');
  final dialDigits = dial.replaceAll(RegExp(r'\D'), '');
  if (digits.startsWith(dialDigits)) return digits.substring(dialDigits.length);
  return digits;
}

/// Valide un numéro local : 7 à 12 chiffres une fois le `0` de tête
/// éventuel retiré (couvre les opérateurs Orange/MTN/Moov/Wave en
/// Afrique francophone).
bool isLocalPhoneValid(String local) {
  final digits = local.replaceAll(RegExp(r'\D'), '');
  final stripped = digits.startsWith('0') ? digits.substring(1) : digits;
  return stripped.length >= 7 && stripped.length <= 12;
}
