// Politique de gardes admin PARTAGÉE (mobile + desktop). Comme les deux
// routers délèguent à `adminRouteDenial`, ce test unique verrouille la parité :
// si une route `/super/*` cessait d'être gardée, il échoue pour LES DEUX
// consoles à la fois. Cf. P1 audit 2026-07-13 (desktop sans garde /super).

import 'package:arena/data/models/profile.dart';
import 'package:arena/data/models/user_role.dart';
import 'package:arena/features_shared/admin_route_policy.dart';
import 'package:flutter_test/flutter_test.dart';

Profile _profile({
  UserRole role = UserRole.admin,
  List<String>? sections,
}) =>
    Profile(
      id: 'a1',
      username: 'admin',
      countryCode: 'CM',
      role: role,
      adminAllowedSections: sections,
    );

// Surface canonique des routes super-admin (union mobile + desktop).
const _superRoutes = <String>[
  '/super',
  '/super/invitations',
  '/super/users',
  '/super/revenue',
  '/super/payments',
  '/super/payouts',
  '/super/broadcast',
  '/super/promo-banner',
  '/super/tutorial-video',
  '/super/tutorial-banners',
  '/super/reintegration',
  '/super/support',
  '/super/messages/u1',
  '/super/app-update',
  '/super/anticheat',
];

// Routes du cœur admin (accessibles à un admin simple non restreint).
const _coreRoutes = <String>[
  '/',
  '/competitions',
  '/matches',
  '/streams',
  '/payouts',
  '/disputes/m1',
  '/recordings',
  '/audit',
  '/profile',
];

void main() {
  final simpleAdmin = _profile(role: UserRole.admin);
  final superAdmin = _profile(role: UserRole.superAdmin);

  group('rôle super-admin sur /super/*', () {
    test('un admin simple est refusé sur TOUTE route /super/* (les 2 consoles)',
        () {
      for (final r in _superRoutes) {
        expect(
          adminRouteDenial(r, simpleAdmin),
          AdminRouteDenial.insufficientRole,
          reason: 'route $r doit exiger super_admin',
        );
      }
    });

    test('un super-admin non restreint accède à toutes les routes /super/*', () {
      for (final r in _superRoutes) {
        expect(adminRouteDenial(r, superAdmin), isNull, reason: r);
      }
    });

    test('un admin simple accède au cœur admin', () {
      for (final r in _coreRoutes) {
        expect(adminRouteDenial(r, simpleAdmin), isNull, reason: r);
      }
    });
  });

  group('périmètre de section', () {
    test('admin restreint : hors section refusé, dans section autorisé', () {
      final scoped = _profile(sections: const ['competitions']);
      expect(adminRouteDenial('/competitions/x', scoped), isNull);
      expect(
        adminRouteDenial('/matches', scoped),
        AdminRouteDenial.sectionOutOfScope,
      );
    });

    test('super-admin restreint à une section : le rôle passe, la section filtre',
        () {
      final scopedSuper =
          _profile(role: UserRole.superAdmin, sections: const ['users']);
      expect(adminRouteDenial('/super/users', scopedSuper), isNull);
      expect(
        adminRouteDenial('/super/payments', scopedSuper),
        AdminRouteDenial.sectionOutOfScope,
      );
      // Le dashboard /super (section null) reste accessible.
      expect(adminRouteDenial('/super', scopedSuper), isNull);
    });
  });

  group('robustesse', () {
    test('profil null (hydratation) → jamais bloqué', () {
      for (final r in [..._superRoutes, ..._coreRoutes]) {
        expect(adminRouteDenial(r, null), isNull, reason: r);
      }
    });
  });
}
