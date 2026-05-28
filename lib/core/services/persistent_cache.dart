import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Cache JSON-on-disk via `SharedPreferences` — pour afficher la dernière
/// donnée connue **immédiatement** au cold start, avant que le
/// `StreamProvider` Supabase n'ait recu son premier event.
///
/// **Pourquoi** : entre le lancement de l'app et le premier event
/// realtime, il y a un trou de 1-3s (auth resume + WS handshake + fetch
/// initial). L'utilisateur voit un spinner sur la home, la liste comp,
/// etc. — c'est la zone de plus grosse perception de "lenteur app". Avec
/// le cache on remplit l'UI avec ce qu'on savait la dernière fois, et
/// le stream remplace dès qu'il a une donnée fraiche.
///
/// **Strategie d'invalidation** : aucune TTL explicite. Chaque émission
/// du stream `source` réécrit le cache → toujours aussi récent que la
/// dernière session ouverte. Si schema change (model breaking), on
/// incrémente `_schemaVersion` pour reset proprement.
class PersistentCache {
  PersistentCache(this._prefs);

  static const _schemaVersion = 'v1';
  static const _versionKey = 'arena.cache.schema';

  final SharedPreferences _prefs;

  /// A appeler au tout début (boot) pour purger le cache si on a change
  /// le format d'un modele entre 2 versions. No-op si la version stockee
  /// est deja a jour.
  static Future<void> ensureSchema(SharedPreferences prefs) async {
    final current = prefs.getString(_versionKey);
    if (current == _schemaVersion) return;
    // Schema bump : on droppe TOUS les caches arena.* pour eviter de
    // deserialiser de vieux JSON avec un nouveau model.
    final stale = prefs.getKeys().where((k) => k.startsWith('arena.cache.'));
    for (final k in stale) {
      await prefs.remove(k);
    }
    await prefs.setString(_versionKey, _schemaVersion);
  }

  String _key(String namespace) => 'arena.cache.$namespace';

  /// Lit une `List<T>` depuis le cache. Renvoie `null` si absent /
  /// invalide / vide — l'appelant decide alors d'afficher loader ou
  /// liste vide (pas de fausse "donnee absente" remontee comme vide).
  List<T>? readList<T>(
    String namespace,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    final raw = _prefs.getString(_key(namespace));
    if (raw == null) return null;
    try {
      final arr = jsonDecode(raw) as List<dynamic>;
      return [
        for (final r in arr) fromJson(r as Map<String, dynamic>),
      ];
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('[cache] readList($namespace) failed: $e\n$st');
      }
      // Cache corrompu (probable changement de modele non gere par
      // ensureSchema). On supprime pour qu'il se reconstruise propre.
      _prefs.remove(_key(namespace));
      return null;
    }
  }

  /// Ecrit une liste serialisee — fire & forget, le SharedPreferences
  /// I/O est rapide (<5ms) et on ne veut pas bloquer le stream sur le
  /// disque.
  Future<void> writeList<T>(
    String namespace,
    List<T> values,
    Map<String, dynamic> Function(T) toJson,
  ) async {
    try {
      final arr = [for (final v in values) toJson(v)];
      await _prefs.setString(_key(namespace), jsonEncode(arr));
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('[cache] writeList($namespace) failed: $e\n$st');
      }
    }
  }

  /// Stream helper : emit d'abord le cache existant (si non-null), puis
  /// chaque valeur de [source] (qu'on persiste au passage).
  ///
  /// Si le cache est absent au boot, on ne yield rien — l'appelant
  /// montre son loader normal, puis recoit la 1ere donnee live.
  Stream<List<T>> hydrate<T>({
    required String namespace,
    required Stream<List<T>> source,
    required T Function(Map<String, dynamic>) fromJson,
    required Map<String, dynamic> Function(T) toJson,
  }) async* {
    final cached = readList<T>(namespace, fromJson);
    if (cached != null && cached.isNotEmpty) {
      yield cached;
    }
    await for (final list in source) {
      yield list;
      // Persist en arriere-plan ; pas besoin d'await — le yield
      // precedent a deja transmis a l'UI.
      unawaited(writeList<T>(namespace, list, toJson));
    }
  }

  /// Variante pour `List<(A, B)>` (records) — utilise pour friends
  /// (`List<(Friendship, Profile)>`). Serialise chaque tuple comme
  /// `{"a": ..., "b": ...}`.
  Stream<List<(A, B)>> hydratePairs<A, B>({
    required String namespace,
    required Stream<List<(A, B)>> source,
    required A Function(Map<String, dynamic>) fromJsonA,
    required B Function(Map<String, dynamic>) fromJsonB,
    required Map<String, dynamic> Function(A) toJsonA,
    required Map<String, dynamic> Function(B) toJsonB,
  }) async* {
    final cached = readList<(A, B)>(namespace, (json) {
      final a = fromJsonA(json['a'] as Map<String, dynamic>);
      final b = fromJsonB(json['b'] as Map<String, dynamic>);
      return (a, b);
    });
    if (cached != null && cached.isNotEmpty) {
      yield cached;
    }
    await for (final list in source) {
      yield list;
      unawaited(
        writeList<(A, B)>(
          namespace,
          list,
          (pair) => {'a': toJsonA(pair.$1), 'b': toJsonB(pair.$2)},
        ),
      );
    }
  }
}

/// Provider singleton — instancie le cache une fois au boot. Resolu via
/// `ref.read(persistentCacheProvider.future)` puis cache-le côté caller
/// avec `await ref.watch(...)`.
final persistentCacheProvider = FutureProvider<PersistentCache>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  await PersistentCache.ensureSchema(prefs);
  return PersistentCache(prefs);
});
