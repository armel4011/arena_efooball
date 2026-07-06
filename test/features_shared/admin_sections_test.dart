// VOLET 3 — helpers de périmètre admin (sections + pays + mapping route).

import 'package:arena/data/models/profile.dart';
import 'package:arena/features_shared/admin_sections.dart';
import 'package:flutter_test/flutter_test.dart';

Profile _profile({List<String>? countries, List<String>? sections}) => Profile(
      id: 'a1',
      username: 'admin',
      countryCode: 'CM',
      adminAllowedCountries: countries,
      adminAllowedSections: sections,
    );

void main() {
  group('adminCanSection', () {
    test('profil null → tout autorisé', () {
      expect(adminCanSection(null, 'payouts'), isTrue);
    });

    test('sections null/vide → tout autorisé (admins existants)', () {
      expect(adminCanSection(_profile(), 'payouts'), isTrue);
      expect(adminCanSection(_profile(sections: const []), 'payouts'), isTrue);
    });

    test('restreint → seule la section listée passe', () {
      final p = _profile(sections: const ['payouts']);
      expect(adminCanSection(p, 'payouts'), isTrue);
      expect(adminCanSection(p, 'users'), isFalse);
    });
  });

  group('adminCanCountry / scope', () {
    test('vide → tous les pays', () {
      expect(adminCanCountry(_profile(), 'CM'), isTrue);
      expect(adminHasCountryScope(_profile()), isFalse);
    });

    test('restreint → hors liste refusé', () {
      final p = _profile(countries: const ['CM']);
      expect(adminCanCountry(p, 'CM'), isTrue);
      expect(adminCanCountry(p, 'SN'), isFalse);
      expect(adminHasCountryScope(p), isTrue);
    });
  });

  group('adminCountriesLabel', () {
    test('drapeau + nom, séparés par virgule ; vide si null', () {
      expect(adminCountriesLabel(null), '');
      expect(adminCountriesLabel(const ['CM']), contains('Cameroun'));
      expect(adminCountriesLabel(const ['CM', 'SN']), contains(', '));
    });
  });

  group('adminSectionForLocation', () {
    test('routes coeur admin', () {
      expect(adminSectionForLocation('/competitions'), 'competitions');
      expect(adminSectionForLocation('/competitions/abc'), 'competitions');
      expect(adminSectionForLocation('/payouts'), 'payouts');
      expect(adminSectionForLocation('/disputes-list'), 'disputes');
      expect(adminSectionForLocation('/audit'), 'audit');
    });

    test('sous-arbre super-admin', () {
      expect(adminSectionForLocation('/super/users'), 'users');
      expect(adminSectionForLocation('/super/payments'), 'payments');
      expect(adminSectionForLocation('/super/payouts'), 'payouts');
      expect(adminSectionForLocation('/super/invitations'), 'invitations');
      expect(adminSectionForLocation('/super/anticheat'), 'anticheat');
      expect(adminSectionForLocation('/super/tutorial-banners'), 'tutorial');
      expect(adminSectionForLocation('/super/messages/u1'), 'support');
    });

    test('destinations non restreignables → null', () {
      expect(adminSectionForLocation('/'), isNull);
      expect(adminSectionForLocation('/super'), isNull);
      expect(adminSectionForLocation('/profile'), isNull);
    });
  });
}
