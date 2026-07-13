import 'package:arena/data/models/payout.dart';

// Contrôles anti-fraude automatiques d'un versement, partagés par les consoles
// admin mobile et desktop (auparavant _buildChecks/_labelFor/_Check dupliqués).

/// Un contrôle anti-fraude auto affiché avant validation d'un versement.
class PayoutCheck {
  const PayoutCheck({required this.label, required this.ok});

  final String label;
  final bool ok;
}

/// Libellé FR d'une clé de contrôle auto (`payout.autoChecks`). Clé inconnue →
/// underscores remplacés par des espaces. Source unique des deux consoles.
String payoutCheckLabel(String key) {
  switch (key) {
    case 'kyc_verified':
    case 'kyc':
      return 'KYC vérifié';
    case 'no_dispute':
      return 'Aucun litige ouvert';
    case 'no_anti_cheat':
    case 'anti_cheat':
      return "Pas d'alerte anti-cheat";
    case 'not_banned':
    case 'account_active':
      return 'Compte non banni';
    case 'momo_valid':
    case 'payment_destination':
      return 'Destination paiement valide';
    default:
      return key.replaceAll('_', ' ');
  }
}

/// Construit la liste des contrôles auto d'un [payout]. [emptyLabel] = texte
/// affiché quand aucun contrôle n'est disponible (le libellé diffère
/// légèrement entre consoles, d'où le paramètre — comportement préservé).
List<PayoutCheck> buildPayoutChecks(
  Payout payout, {
  String emptyLabel = 'Aucun contrôle automatique',
}) {
  final raw = payout.autoChecks;
  if (raw.isEmpty) {
    return [PayoutCheck(label: emptyLabel, ok: false)];
  }
  return [
    for (final entry in raw.entries)
      PayoutCheck(label: payoutCheckLabel(entry.key), ok: entry.value == true),
  ];
}
