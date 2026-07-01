import 'dart:convert';

import 'package:arena/data/models/profile.dart';
import 'package:arena/features_shared/whatsapp_export.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Décode les octets en retirant le BOM UTF-8 (3 premiers octets).
  String decode(List<int> bytes) => utf8.decode(bytes.sublist(3));

  group('buildWhatsappCsvBytes', () {
    test('commence par un BOM UTF-8 (accents corrects dans Excel)', () {
      final bytes = buildWhatsappCsvBytes(const []);
      expect(bytes.sublist(0, 3), [0xEF, 0xBB, 0xBF]);
    });

    test('ligne sep=; puis en-tête à 5 colonnes séparées par ;', () {
      final lines = decode(buildWhatsappCsvBytes(const [])).split('\r\n');
      expect(lines.first, 'sep=;');
      expect(
        lines[1],
        '"Username";"Pays";"Indicatif";"Numéro WhatsApp";"Numéro complet"',
      );
    });

    test('numéro E.164 stocké → local = indicatif retiré, complet tel quel',
        () {
      final csv = decode(
        buildWhatsappCsvBytes(const [
          Profile(
            id: '1',
            username: 'Alice',
            countryCode: 'CM',
            whatsappNumber: '+237699000000', // stocké en E.164
          ),
        ]),
      );
      // Pas de re-préfixe : le complet reste +237699000000 (pas +237237…).
      expect(
        csv.split('\r\n')[2],
        '"Alice";"CM";="+237";="699000000";="+237699000000"',
      );
    });

    test('numéro absent → cellules téléphone numéro vides (pas de crash)', () {
      final csv = decode(
        buildWhatsappCsvBytes(const [
          Profile(id: '2', username: 'Bob', countryCode: 'CM'),
        ]),
      );
      // Indicatif reste renseigné (dépend du pays), local + complet vides.
      expect(csv.split('\r\n')[2], '"Bob";"CM";="+237";;');
    });

    test('username avec ; et " est correctement échappé', () {
      final csv = decode(
        buildWhatsappCsvBytes(const [
          Profile(id: '3', username: 'a;"b', countryCode: 'CM'),
        ]),
      );
      expect(csv.split('\r\n')[2], '"a;""b";"CM";="+237";;');
    });
  });
}
