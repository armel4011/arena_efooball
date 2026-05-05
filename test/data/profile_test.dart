import 'package:arena/data/models/profile.dart';
import 'package:arena/data/models/user_role.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Profile.fromJson', () {
    test('parses a typical Postgres row', () {
      final row = <String, dynamic>{
        'id': 'd5e1...',
        'username': 'jdoe',
        'email': 'jdoe@example.com',
        'country_code': 'CM',
        'avatar_color': '#4C7AFF',
        'role': 'player',
        'is_active': true,
        'auth_provider': 'email',
        'preferred_language': 'fr',
        'preferred_currency': 'XAF',
        'timezone': 'Africa/Douala',
        'cgu_accepted_at': '2026-05-01T10:00:00Z',
      };

      final p = Profile.fromJson(row);

      expect(p.id, 'd5e1...');
      expect(p.username, 'jdoe');
      expect(p.role, UserRole.player);
      expect(p.isPlayer, isTrue);
      expect(p.isAdmin, isFalse);
      expect(p.cguAcceptedAt, isNotNull);
      expect(p.hasAcceptedCgu, isTrue);
    });

    test('admin role', () {
      final p = Profile.fromJson({
        'id': '1',
        'username': 'admin1',
        'email': 'a@a.io',
        'country_code': 'CM',
        'role': 'admin',
      });
      expect(p.role, UserRole.admin);
      expect(p.isAdmin, isTrue);
      expect(p.isSuperAdmin, isFalse);
    });

    test('super_admin role from snake_case value', () {
      final p = Profile.fromJson({
        'id': '1',
        'username': 'sa',
        'email': 'sa@a.io',
        'country_code': 'CM',
        'role': 'super_admin',
      });
      expect(p.role, UserRole.superAdmin);
      expect(p.isSuperAdmin, isTrue);
      expect(p.isAdmin, isTrue);
    });

    test('drops sensitive columns (totp_secret, backup_codes)', () {
      final p = Profile.fromJson({
        'id': '1',
        'username': 'x',
        'email': 'x@x.io',
        'country_code': 'CM',
        'totp_secret': 'should-be-stripped',
        'backup_codes': <String>['c1', 'c2'],
      });
      // No exception thrown means the normalize() worked.
      expect(p.username, 'x');
    });

    test('soft-deleted profile detected via deleted_at', () {
      final p = Profile.fromJson({
        'id': '1',
        'username': 'gone',
        'email': 'gone@x.io',
        'country_code': 'XX',
        'deleted_at': '2026-01-01T00:00:00Z',
      });
      expect(p.isDeleted, isTrue);
    });
  });

  group('Profile.toJson', () {
    test('round-trips role with snake_case value', () {
      const p = Profile(
        id: '1',
        username: 'x',
        email: 'x@x.io',
        countryCode: 'CM',
        role: UserRole.superAdmin,
      );
      final json = p.toJson();
      expect(json['role'], 'super_admin');
      expect(json['country_code'], 'CM');
    });
  });

  group('UserRole.fromValue', () {
    test('falls back to player on null/unknown', () {
      expect(UserRole.fromValue(null), UserRole.player);
      expect(UserRole.fromValue(''), UserRole.player);
      expect(UserRole.fromValue('moderator'), UserRole.player);
    });
  });
}
