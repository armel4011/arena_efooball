import 'package:arena/core/services/secure_local_storage.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const key = 'sb-mamfuexzadeejtjrtzrq-auth-token';
  late SecureLocalStorage storage;

  setUp(() {
    FlutterSecureStorage.setMockInitialValues(<String, String>{});
    SharedPreferences.setMockInitialValues(<String, Object>{});
    storage = SecureLocalStorage(persistSessionKey: key);
  });

  test('fromUrl construit la même clé que supabase_flutter par défaut', () {
    final s = SecureLocalStorage.fromUrl(
      'https://mamfuexzadeejtjrtzrq.supabase.co',
    );
    expect(s.persistSessionKey, key);
  });

  test('persist → has/accessToken → remove : round-trip', () async {
    expect(await storage.hasAccessToken(), isFalse);
    expect(await storage.accessToken(), isNull);

    await storage.persistSession('session-json');
    expect(await storage.hasAccessToken(), isTrue);
    expect(await storage.accessToken(), 'session-json');

    await storage.removePersistedSession();
    expect(await storage.hasAccessToken(), isFalse);
    expect(await storage.accessToken(), isNull);
  });

  test(
    'initialize migre la session SharedPreferences (clair) vers le secure '
    'storage puis purge la version en clair',
    () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        key: 'legacy-session',
      });

      await storage.initialize();

      // Recopiée dans le secure storage.
      expect(await storage.accessToken(), 'legacy-session');
      // Purgée du stockage en clair.
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(key), isNull);
    },
  );

  test(
    'initialize ne migre pas si une session chiffrée existe déjà '
    '(idempotent, ne déconnecte pas)',
    () async {
      await storage.persistSession('secure-session');
      SharedPreferences.setMockInitialValues(<String, Object>{
        key: 'legacy-should-be-ignored',
      });

      await storage.initialize();

      // La session chiffrée prime, l'ancienne valeur en clair est ignorée.
      expect(await storage.accessToken(), 'secure-session');
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(key), 'legacy-should-be-ignored');
    },
  );

  test('initialize sans session existante est un no-op', () async {
    await storage.initialize();
    expect(await storage.hasAccessToken(), isFalse);
  });
}
