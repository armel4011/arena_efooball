import 'dart:convert';
import 'dart:typed_data';

import 'package:arena/core/utils/supported_countries.dart';
import 'package:arena/data/models/profile.dart';

/// Construit le CSV (octets, BOM UTF-8) de l'annuaire WhatsApp des
/// utilisateurs pour l'export super-admin.
///
/// Colonnes : Username · Pays (code ISO) · Indicatif · Numéro WhatsApp (tel
/// que saisi) · Numéro complet E.164 (indicatif + numéro). Le numéro complet
/// est reconstruit via [buildE164Phone] à partir du `country_code` (le numéro
/// est stocké sans préfixe pays). Les comptes sans numéro WhatsApp sont
/// inclus avec des colonnes numéro vides.
///
/// Structuration pensée pour Excel (le tableur des admins) :
///   * Séparateur `;` + première ligne `sep=;` → Excel (toutes locales, FR
///     inclus) répartit correctement chaque valeur dans SA colonne. Avec la
///     virgule par défaut, Excel FR (séparateur de liste = `;`) mettait tout
///     dans une seule colonne → fichier illisible.
///   * Colonnes téléphone (Indicatif, Numéro WhatsApp, Numéro complet) émises
///     en FORMAT TEXTE Excel (`="..."`) : sinon Excel convertit ces longues
///     chaînes en nombre → notation scientifique (2,37E+11), perte du « + »
///     et des zéros de tête.
///   * BOM UTF-8 (`EF BB BF`) → Excel ouvre correctement les accents.
Uint8List buildWhatsappCsvBytes(List<Profile> users) {
  const sep = ';';
  const eol = '\r\n';

  // Cellule texte standard : entourée de guillemets, guillemets internes
  // doublés (échappement CSV).
  String cell(String v) => '"${v.replaceAll('"', '""')}"';

  // Cellule forçant le format TEXTE dans Excel via la formule `="..."`.
  // Indispensable pour les numéros : préserve le « + », les zéros de tête et
  // évite la notation scientifique. Vide → cellule vide.
  String textCell(String v) =>
      v.isEmpty ? '' : '="${v.replaceAll('"', '""')}"';

  final buffer = StringBuffer()
    // Force le séparateur `;` côté Excel, indépendamment de la locale.
    ..write('sep=$sep$eol')
    ..write(
      ['Username', 'Pays', 'Indicatif', 'Numéro WhatsApp', 'Numéro complet']
          .map(cell)
          .join(sep),
    )
    ..write(eol);

  for (final u in users) {
    final local = u.whatsappNumber?.trim() ?? '';
    final full = local.isEmpty
        ? ''
        : buildE164Phone(countryCode: u.countryCode, local: local);
    buffer
      ..write(
        [
          cell(u.username),
          cell(u.countryCode),
          textCell(dialCodeFor(u.countryCode)),
          textCell(local),
          textCell(full),
        ].join(sep),
      )
      ..write(eol);
  }

  return Uint8List.fromList([
    0xEF, 0xBB, 0xBF, // BOM UTF-8
    ...utf8.encode(buffer.toString()),
  ]);
}
