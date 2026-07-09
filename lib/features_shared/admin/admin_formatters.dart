import 'package:intl/intl.dart';

/// Formateurs PURS partagés par les deux consoles admin (mobile + desktop).
/// Élimine des copies dispersées (`_money` défini 5×, `_moneyShort` 2×).
/// Aucune dépendance UI — juste du texte.

/// Montant XAF formaté avec séparateurs de milliers français (« 1 234 »).
/// Arrondi à l'entier (les montants ARENA sont entiers en pratique).
String adminMoney(num xaf) => NumberFormat('#,###', 'fr').format(xaf.round());

/// Montant XAF abrégé pour les tuiles KPI : « 1.2M » / « 12.3K » / « 850 ».
String adminMoneyShort(num xaf) {
  if (xaf.abs() >= 1000000) {
    return '${(xaf / 1000000).toStringAsFixed(1)}M';
  }
  if (xaf.abs() >= 1000) {
    return '${(xaf / 1000).toStringAsFixed(1)}K';
  }
  return xaf.round().toString();
}
