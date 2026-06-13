import 'dart:convert';
import 'dart:typed_data';

import 'package:arena/core/utils/supported_countries.dart';
import 'package:arena/data/models/profile.dart';
import 'package:csv/csv.dart';

/// Construit le CSV (octets, BOM UTF-8) de l'annuaire WhatsApp des
/// utilisateurs pour l'export super-admin.
///
/// Colonnes : Username · Pays (code ISO) · Indicatif · Numéro WhatsApp (tel
/// que saisi) · Numéro complet E.164 (indicatif + numéro). Le numéro complet
/// est reconstruit via [buildE164Phone] à partir du `country_code` (le numéro
/// est stocké sans préfixe pays). Les comptes sans numéro WhatsApp sont
/// inclus avec des colonnes numéro vides.
///
/// Le BOM UTF-8 (`EF BB BF`) garantit qu'Excel ouvre correctement les accents.
Uint8List buildWhatsappCsvBytes(List<Profile> users) {
  final rows = <List<dynamic>>[
    ['Username', 'Pays', 'Indicatif', 'Numéro WhatsApp', 'Numéro complet'],
    for (final u in users)
      [
        u.username,
        u.countryCode,
        dialCodeFor(u.countryCode),
        u.whatsappNumber ?? '',
        if (u.whatsappNumber == null || u.whatsappNumber!.trim().isEmpty)
          ''
        else
          buildE164Phone(
            countryCode: u.countryCode,
            local: u.whatsappNumber!,
          ),
      ],
  ];
  final csv = const ListToCsvConverter().convert(rows);
  return Uint8List.fromList([0xEF, 0xBB, 0xBF, ...utf8.encode(csv)]);
}
