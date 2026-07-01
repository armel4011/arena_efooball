import 'package:arena/core/services/anticheat/anticheat_provider.dart';
import 'package:arena/data/repositories/profile_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Lit / écrit le provider anti-triche actif depuis `app_config`
/// (table CLÉ/VALEUR, cf. `FeatureFlagsService`).
///
/// Clé : `anticheat_provider`, valeur jsonb = la chaîne `wire` du provider
/// (`"native_recorder"` | `"livekit_track_egress"`). Tant que la ligne
/// n'existe pas ou que Supabase est injoignable, on retombe sur
/// [AntiCheatProviderKind.fallback] (recorder natif — repli sûr).
class AntiCheatConfigService {
  const AntiCheatConfigService(this._client);

  static const _table = 'app_config';
  static const configKey = 'anticheat_provider';

  final SupabaseClient _client;

  /// Lit le provider actif, avec repli robuste sur [AntiCheatProviderKind.fallback].
  Future<AntiCheatProviderKind> fetch() async {
    try {
      final row = await _client
          .from(_table)
          .select('value')
          .eq('key', configKey)
          .maybeSingle();
      if (row == null) return AntiCheatProviderKind.fallback;
      return AntiCheatProviderKind.fromWire(row['value']);
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint(
          '[anticheat] Failed to read $configKey — using fallback. $e',
        );
        debugPrintStack(stackTrace: st);
      }
      return AntiCheatProviderKind.fallback;
    }
  }

  /// Persiste le provider actif (réservé au super-admin via RLS sur
  /// `app_config`). Upsert sur la clé pour rester idempotent.
  Future<void> setActive(AntiCheatProviderKind kind) async {
    await _client.from(_table).upsert(
      {'key': configKey, 'value': kind.wire},
      onConflict: 'key',
    );
  }
}

final antiCheatConfigServiceProvider =
    Provider<AntiCheatConfigService>((ref) {
  return AntiCheatConfigService(ref.watch(supabaseClientProvider));
});

/// Provider anti-triche actif (async). Invalider pour rafraîchir après un
/// changement admin.
final activeAntiCheatProviderProvider =
    FutureProvider<AntiCheatProviderKind>((ref) {
  return ref.watch(antiCheatConfigServiceProvider).fetch();
});

/// Variante synchrone "best-effort" — renvoie [AntiCheatProviderKind.fallback] tant que le fetch
/// async n'a pas résolu (utile dans le cycle de vie du match qui ne peut pas
/// facilement await).
final activeAntiCheatProviderSyncProvider =
    Provider<AntiCheatProviderKind>((ref) {
  return ref.watch(activeAntiCheatProviderProvider).maybeWhen(
        data: (kind) => kind,
        orElse: () => AntiCheatProviderKind.fallback,
      );
});
