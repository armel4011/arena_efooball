import 'dart:convert';

import 'package:arena/features_shared/excel_csv.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  String decode(List<int> bytes) => utf8.decode(bytes.sublist(3)); // strip BOM

  group('buildExcelCsvBytes', () {
    test('BOM UTF-8 + ligne sep=; en tête', () {
      final bytes = buildExcelCsvBytes(const [
        ['A', 'B'],
      ]);
      expect(bytes.sublist(0, 3), [0xEF, 0xBB, 0xBF]);
      expect(decode(bytes).split('\r\n').first, 'sep=;');
    });

    test('séparateur ; et nombres laissés numériques (non quotés)', () {
      final csv = decode(
        buildExcelCsvBytes(const [
          ['Marge nette (XAF)', 1000],
        ]),
      );
      expect(csv.split('\r\n')[1], 'Marge nette (XAF);1000');
    });

    test('cellule contenant ; est quotée', () {
      final csv = decode(
        buildExcelCsvBytes(const [
          ['a;b', 2],
        ]),
      );
      expect(csv.split('\r\n')[1], '"a;b";2');
    });
  });
}
