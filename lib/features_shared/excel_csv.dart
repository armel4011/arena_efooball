import 'dart:convert';
import 'dart:typed_data';

import 'package:csv/csv.dart';

/// Sérialise des lignes en CSV « Excel-friendly ».
///
/// - Séparateur `;` + première ligne `sep=;` → Excel (toutes locales, FR
///   inclus où le séparateur de liste est `;`) répartit chaque valeur dans SA
///   colonne. Avec la virgule par défaut, Excel FR mettait tout dans la
///   colonne A → fichier illisible.
/// - BOM UTF-8 (`EF BB BF`) → accents corrects à l'ouverture.
///
/// Les nombres restent NUMÉRIQUES (triables/calculables dans Excel). Pour
/// forcer une cellule en texte (numéros de téléphone : préserver le `+` et
/// les zéros de tête, éviter la notation scientifique), construire le CSV
/// manuellement avec la forme `="..."` (cf. `whatsapp_export.dart`) — le
/// converter CSV re-quote `="..."` et casserait l'astuce.
Uint8List buildExcelCsvBytes(List<List<dynamic>> rows) {
  const eol = '\r\n';
  final csv = const ListToCsvConverter(fieldDelimiter: ';', eol: eol)
      .convert(rows);
  final content = 'sep=;$eol$csv';
  return Uint8List.fromList([
    0xEF, 0xBB, 0xBF, // BOM UTF-8
    ...utf8.encode(content),
  ]);
}
