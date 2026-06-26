/// Formatage de dates relatif côté USER (locale fr).
///
/// Règle produit (2026-06-26) :
///  * dates proches → « Aujourd'hui » / « Demain » (et « Hier » pour le passé
///    immédiat) ;
///  * dates plus éloignées → on préfixe le JOUR de la semaine (lundi…dimanche)
///    avant la date, ex. « Mardi 30 juin ».
///
/// L'heure est ajoutée par défaut (` · HH:mm`, séparateur déjà utilisé dans
/// l'app). La data locale 'fr' est initialisée au bootstrap
/// (`initializeDateFormatting('fr')`).
library;

import 'package:intl/intl.dart';

const String _kLocale = 'fr';

/// Formate une date (UTC ou locale) pour l'affichage user.
///
/// [date] est converti en heure locale. Si [withTime] est vrai (défaut), on
/// suffixe ` · HH:mm`. Exemples :
///  * « Aujourd'hui · 14:30 »
///  * « Demain · 09:00 »
///  * « Mardi 30 juin · 14:30 »
///  * « Mardi 30 juin 2027 · 14:30 » (année différente)
String formatRelativeDate(DateTime date, {bool withTime = true}) {
  final local = date.toLocal();
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final thatDay = DateTime(local.year, local.month, local.day);
  final diffDays = thatDay.difference(today).inDays;

  final String dayPart;
  switch (diffDays) {
    case 0:
      dayPart = "Aujourd'hui";
    case 1:
      dayPart = 'Demain';
    case -1:
      dayPart = 'Hier';
    default:
      // Jour de la semaine + date. On garde l'année seulement si elle diffère
      // de l'année courante (évite « 2026 » partout).
      final pattern = local.year == now.year ? 'EEEE d MMMM' : 'EEEE d MMMM y';
      dayPart = _capitalize(DateFormat(pattern, _kLocale).format(local));
  }

  if (!withTime) return dayPart;
  final time = DateFormat('HH:mm', _kLocale).format(local);
  return '$dayPart · $time';
}

String _capitalize(String s) =>
    s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';
