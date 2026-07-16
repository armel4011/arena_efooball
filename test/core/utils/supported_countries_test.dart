import 'package:arena/core/utils/supported_countries.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('buildE164Phone', () {
    test('numéro local simple → indicatif ajouté', () {
      expect(
        buildE164Phone(countryCode: 'CM', local: '699000000'),
        '+237699000000',
      );
    });

    test('zéro national de tête retiré', () {
      expect(
        buildE164Phone(countryCode: 'CM', local: '0699000000'),
        '+237699000000',
      );
    });

    test('indicatif déjà saisi (chiffres) → PAS de doublon', () {
      expect(
        buildE164Phone(countryCode: 'CM', local: '237699000000'),
        '+237699000000',
      );
    });

    test('indicatif déjà saisi avec + → PAS de doublon', () {
      expect(
        buildE164Phone(countryCode: 'CM', local: '+237699000000'),
        '+237699000000',
      );
    });

    test('préfixe international 00 + indicatif → PAS de doublon', () {
      expect(
        buildE164Phone(countryCode: 'CM', local: '00237699000000'),
        '+237699000000',
      );
    });

    test('espaces / tirets ignorés', () {
      expect(
        buildE164Phone(countryCode: 'CM', local: '+237 6 99-00-00-00'),
        '+237699000000',
      );
    });

    test(
        'garde-fou : local court commençant par les chiffres de l indicatif '
        'n est PAS tronqué', () {
      // rest après 237 = 456 (3 chiffres) → longueur locale invalide → conservé.
      expect(
        buildE164Phone(countryCode: 'CM', local: '237456'),
        '+237237456',
      );
    });
  });

  group('stripDialCode', () {
    test('retire l indicatif E.164', () {
      expect(stripDialCode('+237699000000', 'CM'), '699000000');
    });

    test('numéro déjà doublé → retire un seul indicatif', () {
      expect(stripDialCode('+237237655869124', 'CM'), '237655869124');
    });

    test('null / vide → chaîne vide', () {
      expect(stripDialCode(null, 'CM'), '');
      expect(stripDialCode('   ', 'CM'), '');
    });
  });

  group('isCemacCountry', () {
    test('les 6 États CEMAC → true (casse indifférente)', () {
      for (final code in const ['CM', 'GA', 'TD', 'CF', 'CG', 'GQ']) {
        expect(isCemacCountry(code), isTrue, reason: code);
        expect(isCemacCountry(code.toLowerCase()), isTrue, reason: code);
      }
    });

    test('hors CEMAC (UEMOA / autres) → false', () {
      for (final code in const ['SN', 'CI', 'CD', 'GN', 'FR']) {
        expect(isCemacCountry(code), isFalse, reason: code);
      }
    });

    test('null / vide → false', () {
      expect(isCemacCountry(null), isFalse);
      expect(isCemacCountry(''), isFalse);
    });
  });

  group('needsRecipientNumberFlow', () {
    test('CEMAC hors Cameroun → true (transfert transfrontalier)', () {
      for (final code in const ['GA', 'TD', 'CF', 'CG', 'GQ']) {
        expect(needsRecipientNumberFlow(code), isTrue, reason: code);
        expect(
          needsRecipientNumberFlow(code.toLowerCase()),
          isTrue,
          reason: code,
        );
      }
    });

    test('Cameroun → false : paiement domestique, code marchand seul', () {
      expect(needsRecipientNumberFlow('CM'), isFalse);
      expect(needsRecipientNumberFlow('cm'), isFalse);
    });

    test('hors CEMAC (UEMOA / autres) → false', () {
      for (final code in const ['SN', 'CI', 'CD', 'GN', 'FR']) {
        expect(needsRecipientNumberFlow(code), isFalse, reason: code);
      }
    });

    test('null / vide → false', () {
      expect(needsRecipientNumberFlow(null), isFalse);
      expect(needsRecipientNumberFlow(''), isFalse);
    });
  });
}
