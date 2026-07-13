// Libellés d'affichage liés aux paiements/versements, partagés par les
// consoles admin mobile et desktop (l'UI reste propre à chaque console).

/// Libellé lisible d'un code d'opérateur de paiement legacy
/// (`payer_method` / `provider_method`).
///
/// Source unique consommée par les écrans de validation paiement et de
/// versement des deux consoles — auparavant `_methodLabel` était dupliqué à
/// l'identique dans 4 fichiers. Retourne `—` pour un code inconnu/null.
String paymentMethodLabel(String? code) {
  switch (code) {
    case 'MTN_MOMO':
      return 'MTN MoMo';
    case 'ORANGE_MONEY':
      return 'Orange Money';
    default:
      return '—';
  }
}
