/// Dérivation PARTAGÉE du slug d'opérateur de paiement (MAJUSCULE) depuis un
/// libellé libre, et repli lisible inverse. Source unique réutilisée par
/// `PaymentOperator` (côté user) et les formulaires admin (tuto paiement par
/// opérateur) — évite un import features_admin → features_user.
library;

/// Dérive un slug MAJUSCULE depuis un libellé libre. Les 2 opérateurs connus
/// gardent leur slug canonique ; sinon "Wave" → "WAVE",
/// "Free Money" → "FREE_MONEY".
String operatorSlugForLabel(String label) {
  final l = label.toLowerCase();
  if (l.contains('mtn')) return 'MTN_MOMO';
  if (l.contains('orange')) return 'ORANGE_MONEY';
  final slug = label
      .toUpperCase()
      .replaceAll(RegExp('[^A-Z0-9]+'), '_')
      .replaceAll(RegExp(r'^_+|_+$'), '');
  return slug.isEmpty ? 'OPERATOR' : slug;
}

/// Repli lisible d'un slug (ex. `FREE_MONEY` → "Free Money").
String operatorReadableFromCode(String code) {
  switch (code) {
    case 'MTN_MOMO':
      return 'MTN MoMo';
    case 'ORANGE_MONEY':
      return 'Orange Money';
    default:
      final words = code
          .split('_')
          .where((w) => w.isNotEmpty)
          .map((w) => w[0].toUpperCase() + w.substring(1).toLowerCase());
      final joined = words.join(' ');
      return joined.isEmpty ? code : joined;
  }
}
