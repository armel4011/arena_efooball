import 'package:arena/data/models/promo_banner.dart';
import 'package:arena/data/repositories/promo_banner_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import '_supabase_mocks.dart';

void main() {
  late MockSupabaseClient client;
  late PromoBannerRepository repo;

  setUp(() {
    client = MockSupabaseClient();
    repo = PromoBannerRepository(client);
  });

  QueryProbe stub(String table, Object? result) =>
      stubFrom(client, table, result);

  Map<String, dynamic> bannerRow({
    String id = 'b1',
    String imageUrl = 'https://cdn/img.png',
    String redirectType = 'web_link',
    String redirectTarget = 'https://arena.gg',
    bool isActive = true,
  }) =>
      {
        'id': id,
        'image_url': imageUrl,
        'redirect_type': redirectType,
        'redirect_target': redirectTarget,
        'is_active': isActive,
        'updated_by': 'super1',
        'created_at': '2026-06-01T10:00:00.000Z',
        'updated_at': '2026-06-02T10:00:00.000Z',
      };

  group('getCurrent', () {
    test('order updated_at desc + limit 1 + parse la bannière', () async {
      final from = stub('promo_banner', [bannerRow()]);
      final banner = await repo.getCurrent();
      expect(banner, isNotNull);
      expect(banner!.id, 'b1');
      expect(banner.imageUrl, 'https://cdn/img.png');
      expect(banner.redirectType, PromoRedirectType.webLink);
      expect(banner.redirectTarget, 'https://arena.gg');
      expect(banner.isActive, isTrue);
      expect(banner.updatedBy, 'super1');
      expect(from.hasFilter('order', 'updated_at'), isTrue);
      expect(from.filters.any((f) => f == 'order:updated_at=false'), isTrue);
      expect(from.filters.any((f) => f == 'limit:_=1'), isTrue);
    });

    test('liste vide → null', () async {
      stub('promo_banner', <Map<String, dynamic>>[]);
      expect(await repo.getCurrent(), isNull);
    });

    test('parse tous les redirect_type', () async {
      stub('promo_banner', [bannerRow(redirectType: 'whatsapp')]);
      final banner = await repo.getCurrent();
      expect(banner!.redirectType, PromoRedirectType.whatsapp);
    });
  });

  group('saveActive', () {
    test('payload insert: image, redirect wire, target, is_active true, '
        'updated_by inclus', () async {
      final from = stub('promo_banner', null);
      await repo.saveActive(
        imageUrl: 'https://cdn/new.png',
        redirectType: PromoRedirectType.internalPage,
        redirectTarget: '/streams',
        updatedBy: 'super1',
      );
      // stubFrom renvoie le même builder pour les 2 appels : le dernier
      // (insert) écrase le probe → insertedValues contient le payload insert,
      // updatedValues contient le payload update.
      final ins = from.insertedValues! as Map<String, dynamic>;
      expect(ins['image_url'], 'https://cdn/new.png');
      expect(ins['redirect_type'], 'internal_page');
      expect(ins['redirect_target'], '/streams');
      expect(ins['is_active'], true);
      expect(ins['updated_by'], 'super1');

      final upd = from.updatedValues!;
      expect(upd['is_active'], false);
      expect(upd['updated_at'], isA<String>());
      expect(from.filters.any((f) => f == 'eq:is_active=true'), isTrue);
    });

    test('updatedBy omis → pas de clé updated_by dans le payload insert',
        () async {
      final from = stub('promo_banner', null);
      await repo.saveActive(
        imageUrl: 'https://cdn/new.png',
        redirectType: PromoRedirectType.webLink,
        redirectTarget: 'https://x.gg',
      );
      final ins = from.insertedValues! as Map<String, dynamic>;
      expect(ins.containsKey('updated_by'), isFalse);
      expect(ins['redirect_type'], 'web_link');
    });
  });

  group('deactivate', () {
    test('update is_active=false + updated_at, filtre is_active=true', () async {
      final from = stub('promo_banner', null);
      await repo.deactivate();
      final upd = from.updatedValues!;
      expect(upd['is_active'], false);
      expect(upd['updated_at'], isA<String>());
      expect(from.filters.any((f) => f == 'eq:is_active=true'), isTrue);
    });
  });
}
