import 'dart:async';
import 'dart:convert';

import 'package:arena/core/utils/error_reporter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
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

  // v2 (audit 2026-06-14, M-3) : le profil (PII : email, WhatsApp, kycStatus)
  // n'est plus caché en clair dans SharedPreferences mais chiffré via
  // `flutter_secure_storage`. Le bump v1→v2 purge tout l'ancien cache clair —
  // dont le profil clair legacy — au prochain boot (cf. [ensureSchema]).
  static const _schemaVersion = 'v2';
  static const _versionKey = 'arena.cache.schema';

  /// Storage chiffré au repos pour les namespaces sensibles (PII).
  /// Mêmes options que `SecureLocalStorage` :
  ///  * Android : EncryptedSharedPreferences (clé AES dans le Keystore)
  ///  * iOS/macOS : Keychain (first_unlock_this_device)
  ///  * Windows : DPAPI
  static const FlutterSecureStorage _secure = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

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

  /// Lit un objet T unique depuis le cache. Renvoie null si absent
  /// ou invalide.
  T? readObject<T>(
    String namespace,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    final raw = _prefs.getString(_key(namespace));
    if (raw == null) return null;
    try {
      return fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (e, st) {
      unawaited(reportError(e, st,
          context: 'PersistentCache.readObject', hint: 'namespace=$namespace'));
      _prefs.remove(_key(namespace));
      return null;
    }
  }

  /// Persiste un objet T unique.
  Future<void> writeObject<T>(
    String namespace,
    T value,
    Map<String, dynamic> Function(T) toJson,
  ) async {
    try {
      await _prefs.setString(_key(namespace), jsonEncode(toJson(value)));
    } catch (e, st) {
      unawaited(reportError(e, st,
          context: 'PersistentCache.writeObject',
          hint: 'namespace=$namespace'));
    }
  }

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
      unawaited(reportError(e, st,
          context: 'PersistentCache.readList', hint: 'namespace=$namespace'));
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
      unawaited(reportError(e, st,
          context: 'PersistentCache.writeList', hint: 'namespace=$namespace'));
    }
  }

  /// `true` si [e] ressemble a une coupure reseau (offline / DNS / WS
  /// down). Sert aux helpers `fetch*OrCache` a decider s'ils avalent
  /// l'erreur (offline → on fige) ou la rethrow (erreur metier reelle,
  /// ex: RLS 42501).
  static bool isOfflineError(Object e) {
    final s = e.toString();
    return s.contains('SocketException') ||
        s.contains('Failed host lookup') ||
        s.contains('ClientException') ||
        s.contains('RealtimeSubscribeException') ||
        s.contains('Connection closed') ||
        s.contains('Connection refused') ||
        s.contains('Connection reset');
  }

  /// Variante **one-shot** (FutureProvider) de [hydrate] pour une liste.
  /// Tente [fetch] ; au succes persiste + renvoie la donnee fraiche. En
  /// cas d'erreur reseau, renvoie le dernier cache connu (UI figee) ou
  /// une liste vide si aucun cache (jamais d'ecran d'erreur offline). Les
  /// erreurs NON-reseau (RLS, parsing serveur, etc.) sont rethrow.
  Future<List<T>> fetchListOrCache<T>({
    required String namespace,
    required Future<List<T>> Function() fetch,
    required T Function(Map<String, dynamic>) fromJson,
    required Map<String, dynamic> Function(T) toJson,
  }) async {
    try {
      final data = await fetch();
      unawaited(writeList<T>(namespace, data, toJson));
      return data;
    } catch (e, st) {
      final cached = readList<T>(namespace, fromJson);
      if (cached != null) return cached;
      if (isOfflineError(e)) return <T>[];
      if (kDebugMode) {
        debugPrint('[cache] fetchListOrCache($namespace) rethrow: $e\n$st');
      }
      rethrow;
    }
  }

  /// Variante **one-shot** pour un objet unique. [offlineFallback], s'il
  /// est fourni, est renvoye quand on est offline ET qu'aucun cache
  /// n'existe (ex: `PlayerStats.empty()`), pour que l'UI affiche un etat
  /// coherent plutot qu'une erreur reseau. S'il est `null` (ex:
  /// `ChatChannel` qui n'a pas d'etat vide sensé), on rethrow l'erreur —
  /// l'UI montre alors son erreur uniquement dans le cas "offline ET
  /// jamais charge auparavant".
  Future<T> fetchObjectOrCache<T>({
    required String namespace,
    required Future<T> Function() fetch,
    required T Function(Map<String, dynamic>) fromJson,
    required Map<String, dynamic> Function(T) toJson,
    T? offlineFallback,
  }) async {
    try {
      final data = await fetch();
      unawaited(writeObject<T>(namespace, data, toJson));
      return data;
    } catch (e, st) {
      final cached = readObject<T>(namespace, fromJson);
      if (cached != null) return cached;
      if (offlineFallback != null && isOfflineError(e)) return offlineFallback;
      if (kDebugMode) {
        debugPrint('[cache] fetchObjectOrCache($namespace) rethrow: $e\n$st');
      }
      rethrow;
    }
  }

  /// Variante de [fetchObjectOrCache] pour un fetch qui peut renvoyer
  /// `null` (ex: `findByUsername` → joueur introuvable, `latestForUser`
  /// → jamais soumis). [fetchObjectOrCache] exige un T non-null ; ici on
  /// accepte `null` comme valeur métier legitime.
  ///
  /// Au succes : persiste si non-null (un `null` n'efface PAS le cache —
  /// un fetch qui repond null offline-puis-online ne doit pas ecraser la
  /// derniere donnee connue ; seul un vrai online-null le ferait, mais on
  /// reste prudent et on garde l'ancien). Sur erreur **reseau** : renvoie
  /// le dernier cache connu (qui peut être `null` si jamais charge). Les
  /// erreurs **metier** (RLS 42501, parsing) sont rethrow — on ne masque
  /// pas une erreur reelle derriere une donnee perimee.
  Future<T?> fetchObjectOrCacheNullable<T>({
    required String namespace,
    required Future<T?> Function() fetch,
    required T Function(Map<String, dynamic>) fromJson,
    required Map<String, dynamic> Function(T) toJson,
  }) async {
    try {
      final data = await fetch();
      if (data != null) {
        unawaited(writeObject<T>(namespace, data, toJson));
      }
      return data;
    } catch (e, st) {
      if (isOfflineError(e)) {
        return readObject<T>(namespace, fromJson);
      }
      if (kDebugMode) {
        debugPrint(
          '[cache] fetchObjectOrCacheNullable($namespace) rethrow: $e\n$st',
        );
      }
      rethrow;
    }
  }

  /// Stream helper : emit d'abord le cache existant (si non-null), puis
  /// chaque valeur de [source] (qu'on persiste au passage).
  ///
  /// **Offline-safe** : si [source] leve (SocketException, WebSocket
  /// down, etc.), l'exception est silencieusement avalee — l'AsyncValue
  /// reste sur la derniere valeur emise (le cache). L'UI ne montre
  /// JAMAIS d'ecran d'erreur reseau ; le user voit le bandeau "Hors
  /// ligne" et le contenu reste fige sur sa derniere version connue.
  ///
  /// Si le cache est absent au boot, on ne yield rien — l'appelant
  /// montre son loader normal, puis recoit la 1ere donnee live (ou
  /// reste sur le loader silencieusement si pas de reseau).
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
    try {
      await for (final list in source) {
        yield list;
        // Persist en arriere-plan ; pas besoin d'await — le yield
        // precedent a deja transmis a l'UI.
        unawaited(writeList<T>(namespace, list, toJson));
      }
    } catch (e, st) {
      // Swallow — l'UI reste figee sur le dernier yield (cache ou
      // derniere donnee live recue avant la coupure).
      if (kDebugMode) {
        debugPrint(
            '[cache] hydrate($namespace) source error swallowed: $e\n$st');
      }
    }
  }

  /// Variante pour un objet unique (vs liste). Utilisee pour
  /// `currentProfileProvider` qui retourne `Profile?`.
  Stream<T?> hydrateSingle<T>({
    required String namespace,
    required Stream<T?> source,
    required T Function(Map<String, dynamic>) fromJson,
    required Map<String, dynamic> Function(T) toJson,
  }) async* {
    final cached = readObject<T>(namespace, fromJson);
    if (cached != null) yield cached;
    try {
      await for (final value in source) {
        yield value;
        if (value != null) {
          unawaited(writeObject<T>(namespace, value, toJson));
        }
      }
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint(
            '[cache] hydrateSingle($namespace) source error swallowed: $e\n$st');
      }
    }
  }

  // ───────────────────────────────────────────────────────────────────────
  // Variantes CHIFFRÉES (PII) — adossées à flutter_secure_storage.
  // Mêmes contrats que readObject/writeObject/hydrateSingle, mais le blob
  // JSON est chiffré au repos. Réservé aux namespaces sensibles (profil).
  // I/O async (vs SharedPreferences sync) : surcoût ~10-50 ms acceptable car
  // hors de la 1re frame (l'appelant est un async generator).
  // ───────────────────────────────────────────────────────────────────────

  String _secureKey(String namespace) => 'arena.scache.$namespace';

  /// Lit un objet T depuis le cache chiffré. `null` si absent/invalide.
  Future<T?> readObjectSecure<T>(
    String namespace,
    T Function(Map<String, dynamic>) fromJson,
  ) async {
    String? raw;
    try {
      raw = await _secure.read(key: _secureKey(namespace));
    } catch (e, st) {
      unawaited(reportError(e, st,
          context: 'PersistentCache.readObjectSecure.read',
          hint: 'namespace=$namespace'));
      return null;
    }
    if (raw == null) return null;
    try {
      return fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (e, st) {
      unawaited(reportError(e, st,
          context: 'PersistentCache.readObjectSecure.decode',
          hint: 'namespace=$namespace'));
      unawaited(_secure.delete(key: _secureKey(namespace)));
      return null;
    }
  }

  /// Persiste un objet T dans le cache chiffré.
  Future<void> writeObjectSecure<T>(
    String namespace,
    T value,
    Map<String, dynamic> Function(T) toJson,
  ) async {
    try {
      await _secure.write(
        key: _secureKey(namespace),
        value: jsonEncode(toJson(value)),
      );
    } catch (e, st) {
      unawaited(reportError(e, st,
          context: 'PersistentCache.writeObjectSecure',
          hint: 'namespace=$namespace'));
    }
  }

  /// Équivalent chiffré de [hydrateSingle] : émet d'abord le cache chiffré
  /// (si présent), puis chaque valeur de [source] (persistée chiffrée).
  /// Offline-safe (erreur source avalée → l'UI reste figée sur le cache).
  Stream<T?> hydrateSingleSecure<T>({
    required String namespace,
    required Stream<T?> source,
    required T Function(Map<String, dynamic>) fromJson,
    required Map<String, dynamic> Function(T) toJson,
  }) async* {
    final cached = await readObjectSecure<T>(namespace, fromJson);
    if (cached != null) yield cached;
    try {
      await for (final value in source) {
        yield value;
        if (value != null) {
          unawaited(writeObjectSecure<T>(namespace, value, toJson));
        }
      }
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint(
          '[cache] hydrateSingleSecure($namespace) source error swallowed: $e\n$st',
        );
      }
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
    try {
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
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint(
            '[cache] hydratePairs($namespace) source error swallowed: $e\n$st');
      }
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
