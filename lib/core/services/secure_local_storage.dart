import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// [LocalStorage] qui chiffre la session Supabase (access + refresh token)
/// au repos via `flutter_secure_storage`.
///
/// Par défaut, `supabase_flutter` persiste la session dans
/// `SharedPreferences`, **non chiffré** : sur un device rooté ou via une
/// sauvegarde `adb backup`, le refresh token est lisible en clair (audit sécu
/// 2026-06-13). On le remplace par un storage adossé à :
///  * Android : `EncryptedSharedPreferences` (clé AES dans le Keystore matériel)
///  * iOS/macOS : Keychain (`first_unlock_this_device`, non synchronisé iCloud)
///  * Windows : DPAPI (utilisé par le bootstrap desktop admin)
///
/// La clé `persistSessionKey` reste **identique** à celle de
/// `SharedPreferencesLocalStorage` (`sb-<ref>-auth-token`) et [initialize]
/// migre en douceur toute session déjà présente dans `SharedPreferences`, afin
/// de ne PAS déconnecter les utilisateurs déjà loggés au 1er lancement
/// post-update.
class SecureLocalStorage extends LocalStorage {
  SecureLocalStorage({required this.persistSessionKey});

  /// Construit la même clé que `supabase_flutter` par défaut
  /// (cf. `SharedPreferencesLocalStorage` : `sb-<host-1er-segment>-auth-token`),
  /// pour que la migration retrouve la session existante.
  factory SecureLocalStorage.fromUrl(String url) => SecureLocalStorage(
        persistSessionKey:
            'sb-${Uri.parse(url).host.split('.').first}-auth-token',
      );

  final String persistSessionKey;

  static const FlutterSecureStorage _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  @override
  Future<void> initialize() async {
    // Migration douce SharedPreferences (clair) → secure storage (chiffré).
    // Si le secure storage contient déjà la session, rien à faire.
    if (await _storage.containsKey(key: persistSessionKey)) {
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    final legacy = prefs.getString(persistSessionKey);
    if (legacy != null) {
      await _storage.write(key: persistSessionKey, value: legacy);
      await prefs.remove(persistSessionKey);
    }
  }

  @override
  Future<bool> hasAccessToken() =>
      _storage.containsKey(key: persistSessionKey);

  @override
  Future<String?> accessToken() => _storage.read(key: persistSessionKey);

  @override
  Future<void> removePersistedSession() =>
      _storage.delete(key: persistSessionKey);

  @override
  Future<void> persistSession(String persistSessionString) =>
      _storage.write(key: persistSessionKey, value: persistSessionString);
}
