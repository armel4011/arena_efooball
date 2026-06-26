import 'package:arena/core/utils/date_formatter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('fr');
  });

  test("aujourd'hui avec heure", () {
    final now = DateTime.now();
    final d = DateTime(now.year, now.month, now.day, 14, 30);
    final s = formatRelativeDate(d);
    expect(s, startsWith("Aujourd'hui"));
    expect(s, contains('14:30'));
  });

  test("demain", () {
    final t = DateTime.now().add(const Duration(days: 1));
    final d = DateTime(t.year, t.month, t.day, 9);
    expect(formatRelativeDate(d), startsWith('Demain'));
  });

  test("hier", () {
    final t = DateTime.now().subtract(const Duration(days: 1));
    final d = DateTime(t.year, t.month, t.day, 9);
    expect(formatRelativeDate(d), startsWith('Hier'));
  });

  test("date éloignée → préfixe le jour de la semaine (capitalisé)", () {
    final t = DateTime.now().add(const Duration(days: 10));
    final d = DateTime(t.year, t.month, t.day, 18);
    final s = formatRelativeDate(d, withTime: false);
    expect(
      s,
      matches(
        RegExp(r'^(Lundi|Mardi|Mercredi|Jeudi|Vendredi|Samedi|Dimanche) '),
      ),
    );
  });

  test("withTime: false omet l'heure", () {
    final now = DateTime.now();
    final d = DateTime(now.year, now.month, now.day, 14, 30);
    expect(formatRelativeDate(d, withTime: false), equals("Aujourd'hui"));
  });
}
