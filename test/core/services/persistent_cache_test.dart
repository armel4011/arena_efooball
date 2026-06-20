import 'dart:async';

import 'package:arena/core/services/persistent_cache.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Petit modèle de test : un objet sérialisable trivial.
@immutable
class _Item {
  const _Item(this.id, this.label);

  factory _Item.fromJson(Map<String, dynamic> j) =>
      _Item(j['id'] as String, j['label'] as String);

  final String id;
  final String label;

  Map<String, dynamic> toJson() => {'id': id, 'label': label};

  @override
  bool operator ==(Object o) => o is _Item && o.id == id && o.label == label;
  @override
  int get hashCode => Object.hash(id, label);
}

_Item _fromJson(Map<String, dynamic> j) => _Item.fromJson(j);
Map<String, dynamic> _toJson(_Item i) => i.toJson();

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences prefs;
  late PersistentCache cache;

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    FlutterSecureStorage.setMockInitialValues(<String, String>{});
    prefs = await SharedPreferences.getInstance();
    cache = PersistentCache(prefs);
  });

  group('isOfflineError', () {
    test('reconnaît les coupures réseau', () {
      for (final msg in const [
        'SocketException: failed',
        'Failed host lookup: api',
        'ClientException with SocketException',
        'RealtimeSubscribeException(...)',
        'Connection closed before full header',
        'Connection refused',
        'Connection reset by peer',
      ]) {
        expect(
          PersistentCache.isOfflineError(Exception(msg)),
          isTrue,
          reason: msg,
        );
      }
    });

    test('rejette une erreur métier (RLS, parsing)', () {
      expect(
        PersistentCache.isOfflineError(Exception('PostgrestException 42501')),
        isFalse,
      );
      expect(PersistentCache.isOfflineError(Exception('boom')), isFalse);
    });
  });

  group('ensureSchema', () {
    test('purge les caches arena.cache.* si version absente/différente', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'arena.cache.schema': 'v1',
        'arena.cache.home': '[]',
        'arena.cache.profile': '{}',
        'autre.cle': 'garde-moi',
      });
      final p = await SharedPreferences.getInstance();

      await PersistentCache.ensureSchema(p);

      expect(p.getString('arena.cache.home'), isNull);
      expect(p.getString('arena.cache.profile'), isNull);
      // La clé hors namespace n'est pas touchée.
      expect(p.getString('autre.cle'), 'garde-moi');
      // La version est bumpée à la version courante.
      expect(p.getString('arena.cache.schema'), 'v2');
    });

    test('no-op si la version stockée est déjà courante', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'arena.cache.schema': 'v2',
        'arena.cache.home': '[{"keep":1}]',
      });
      final p = await SharedPreferences.getInstance();

      await PersistentCache.ensureSchema(p);

      expect(p.getString('arena.cache.home'), '[{"keep":1}]');
    });
  });

  group('readObject / writeObject', () {
    test('round-trip', () async {
      await cache.writeObject<_Item>('it', const _Item('1', 'a'), _toJson);
      expect(cache.readObject<_Item>('it', _fromJson), const _Item('1', 'a'));
    });

    test('absent → null', () {
      expect(cache.readObject<_Item>('nope', _fromJson), isNull);
    });

    test('JSON corrompu → null et la clé est supprimée', () async {
      await prefs.setString('arena.cache.bad', '{not json');
      expect(cache.readObject<_Item>('bad', _fromJson), isNull);
      expect(prefs.getString('arena.cache.bad'), isNull);
    });
  });

  group('readList / writeList', () {
    test('round-trip', () async {
      await cache.writeList<_Item>(
        'list',
        const [_Item('1', 'a'), _Item('2', 'b')],
        _toJson,
      );
      expect(cache.readList<_Item>('list', _fromJson), const [
        _Item('1', 'a'),
        _Item('2', 'b'),
      ]);
    });

    test('absent → null (≠ liste vide)', () {
      expect(cache.readList<_Item>('nope', _fromJson), isNull);
    });

    test('JSON corrompu → null et la clé est supprimée', () async {
      await prefs.setString('arena.cache.badlist', 'xxx');
      expect(cache.readList<_Item>('badlist', _fromJson), isNull);
      expect(prefs.getString('arena.cache.badlist'), isNull);
    });
  });

  group('fetchListOrCache', () {
    test('succès → renvoie et persiste', () async {
      final res = await cache.fetchListOrCache<_Item>(
        namespace: 'l',
        fetch: () async => const [_Item('1', 'a')],
        fromJson: _fromJson,
        toJson: _toJson,
      );
      expect(res, const [_Item('1', 'a')]);
      await Future<void>.delayed(Duration.zero); // laisse le write fire&forget
      expect(cache.readList<_Item>('l', _fromJson), const [_Item('1', 'a')]);
    });

    test('erreur offline + cache présent → renvoie le cache', () async {
      await cache.writeList<_Item>('l', const [_Item('9', 'z')], _toJson);
      final res = await cache.fetchListOrCache<_Item>(
        namespace: 'l',
        fetch: () async => throw Exception('SocketException'),
        fromJson: _fromJson,
        toJson: _toJson,
      );
      expect(res, const [_Item('9', 'z')]);
    });

    test('erreur offline + aucun cache → liste vide', () async {
      final res = await cache.fetchListOrCache<_Item>(
        namespace: 'l',
        fetch: () async => throw Exception('Failed host lookup'),
        fromJson: _fromJson,
        toJson: _toJson,
      );
      expect(res, isEmpty);
    });

    test('erreur métier (non offline) + aucun cache → rethrow', () {
      expect(
        () => cache.fetchListOrCache<_Item>(
          namespace: 'l',
          fetch: () async => throw Exception('RLS 42501'),
          fromJson: _fromJson,
          toJson: _toJson,
        ),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('fetchObjectOrCache', () {
    test('succès → renvoie et persiste', () async {
      final res = await cache.fetchObjectOrCache<_Item>(
        namespace: 'o',
        fetch: () async => const _Item('1', 'a'),
        fromJson: _fromJson,
        toJson: _toJson,
      );
      expect(res, const _Item('1', 'a'));
      await Future<void>.delayed(Duration.zero);
      expect(cache.readObject<_Item>('o', _fromJson), const _Item('1', 'a'));
    });

    test('offline + cache → cache', () async {
      await cache.writeObject<_Item>('o', const _Item('9', 'z'), _toJson);
      final res = await cache.fetchObjectOrCache<_Item>(
        namespace: 'o',
        fetch: () async => throw Exception('Connection reset'),
        fromJson: _fromJson,
        toJson: _toJson,
      );
      expect(res, const _Item('9', 'z'));
    });

    test('offline + aucun cache + fallback → fallback', () async {
      final res = await cache.fetchObjectOrCache<_Item>(
        namespace: 'o',
        fetch: () async => throw Exception('SocketException'),
        fromJson: _fromJson,
        toJson: _toJson,
        offlineFallback: const _Item('0', 'empty'),
      );
      expect(res, const _Item('0', 'empty'));
    });

    test('offline + aucun cache + pas de fallback → rethrow', () {
      expect(
        () => cache.fetchObjectOrCache<_Item>(
          namespace: 'o',
          fetch: () async => throw Exception('SocketException'),
          fromJson: _fromJson,
          toJson: _toJson,
        ),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('fetchObjectOrCacheNullable', () {
    test('succès null → renvoie null SANS écraser le cache existant', () async {
      await cache.writeObject<_Item>('n', const _Item('1', 'a'), _toJson);
      final res = await cache.fetchObjectOrCacheNullable<_Item>(
        namespace: 'n',
        fetch: () async => null,
        fromJson: _fromJson,
        toJson: _toJson,
      );
      expect(res, isNull);
      // L'ancienne donnée connue est préservée.
      expect(cache.readObject<_Item>('n', _fromJson), const _Item('1', 'a'));
    });

    test('offline → renvoie le dernier cache (peut être null)', () async {
      final res = await cache.fetchObjectOrCacheNullable<_Item>(
        namespace: 'n',
        fetch: () async => throw Exception('SocketException'),
        fromJson: _fromJson,
        toJson: _toJson,
      );
      expect(res, isNull);
    });

    test('erreur métier → rethrow', () {
      expect(
        () => cache.fetchObjectOrCacheNullable<_Item>(
          namespace: 'n',
          fetch: () async => throw Exception('boom'),
          fromJson: _fromJson,
          toJson: _toJson,
        ),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('hydrate (stream)', () {
    test("émet le cache d'abord, puis la source, et persiste", () async {
      await cache.writeList<_Item>('h', const [_Item('c', 'cache')], _toJson);
      final out = await cache.hydrate<_Item>(
        namespace: 'h',
        source: Stream.fromIterable(const [
          [_Item('1', 'live')],
        ]),
        fromJson: _fromJson,
        toJson: _toJson,
      ).toList();

      expect(out.first, const [_Item('c', 'cache')]);
      expect(out.last, const [_Item('1', 'live')]);
      await Future<void>.delayed(Duration.zero);
      expect(cache.readList<_Item>('h', _fromJson), const [_Item('1', 'live')]);
    });

    test("cache vide → pas d'émission initiale", () async {
      final out = await cache.hydrate<_Item>(
        namespace: 'h',
        source: Stream.fromIterable(const [
          [_Item('1', 'live')],
        ]),
        fromJson: _fromJson,
        toJson: _toJson,
      ).toList();
      expect(out, const [
        [_Item('1', 'live')],
      ]);
    });

    test('erreur de la source est avalée (UI figée, pas exception)', () async {
      await cache.writeList<_Item>('h', const [_Item('c', 'cache')], _toJson);
      final controller = StreamController<List<_Item>>();
      final fut = cache.hydrate<_Item>(
        namespace: 'h',
        source: controller.stream,
        fromJson: _fromJson,
        toJson: _toJson,
      ).toList();

      controller
        ..add(const [_Item('1', 'live')])
        ..addError(Exception('SocketException'));
      await controller.close();

      final out = await fut; // ne doit PAS throw
      expect(out.last, const [_Item('1', 'live')]);
    });
  });

  group('hydrateSingle (stream)', () {
    test('émet le cache puis la source', () async {
      await cache.writeObject<_Item>('hs', const _Item('c', 'cache'), _toJson);
      final out = await cache.hydrateSingle<_Item>(
        namespace: 'hs',
        source: Stream.fromIterable(const [_Item('1', 'live')]),
        fromJson: _fromJson,
        toJson: _toJson,
      ).toList();
      expect(out.first, const _Item('c', 'cache'));
      expect(out.last, const _Item('1', 'live'));
    });
  });

  group('variantes chiffrées (secure storage)', () {
    test('writeObjectSecure → readObjectSecure round-trip', () async {
      await cache.writeObjectSecure<_Item>('s', const _Item('1', 'a'), _toJson);
      expect(
        await cache.readObjectSecure<_Item>('s', _fromJson),
        const _Item('1', 'a'),
      );
    });

    test('readObjectSecure absent → null', () async {
      expect(await cache.readObjectSecure<_Item>('none', _fromJson), isNull);
    });

    test('hydrateSingleSecure émet le cache chiffré puis la source', () async {
      await cache.writeObjectSecure<_Item>('hs', const _Item('c', 'x'), _toJson);
      final out = await cache.hydrateSingleSecure<_Item>(
        namespace: 'hs',
        source: Stream.fromIterable(const [_Item('1', 'live')]),
        fromJson: _fromJson,
        toJson: _toJson,
      ).toList();
      expect(out.first, const _Item('c', 'x'));
      expect(out.last, const _Item('1', 'live'));
    });
  });
}
