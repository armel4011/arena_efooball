import 'package:arena/core/i18n/feature_flags.dart';
import 'package:arena/data/repositories/profile_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Reads `app_config` from Supabase with a robust local fallback.
///
/// `app_config` est une table CLÉ/VALEUR (`{key text, value jsonb}`) seedée en
/// PHASE 0 (`supported_languages`, `supported_currencies`, `feature_flags`,
/// …). On lit TOUTES les lignes et on les agrège en une map `{clé: valeur}`
/// passée à [FeatureFlags.fromConfig]. Tant qu'aucune ligne n'existe ou que
/// Supabase est injoignable, [FeatureFlags.defaultsV1_0] est utilisé (offline /
/// cold start).
///
/// (Avant le 2026-06-13, `fetch` lisait UNE seule ligne via `maybeSingle()` et
/// `fromMap` y cherchait des clés racine `enabled_*` jamais présentes dans une
/// table clé/valeur → les flags retombaient TOUJOURS sur les defaults. Corrigé.)
class FeatureFlagsService {
  const FeatureFlagsService(this._client);

  static const _table = 'app_config';

  final SupabaseClient _client;

  Future<FeatureFlags> fetch() async {
    try {
      final rows = await _client.from(_table).select('key, value');
      final config = <String, dynamic>{
        for (final row in rows)
          if (row['key'] is String) row['key'] as String: row['value'],
      };
      if (config.isEmpty) return FeatureFlags.defaultsV1_0();
      return FeatureFlags.fromConfig(config);
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint(
          '[feature_flags] Failed to read $_table — using defaults. $e',
        );
        debugPrintStack(stackTrace: st);
      }
      return FeatureFlags.defaultsV1_0();
    }
  }
}

final featureFlagsServiceProvider = Provider<FeatureFlagsService>((ref) {
  return FeatureFlagsService(ref.watch(supabaseClientProvider));
});

/// Active feature flags. Refresh by invalidating the provider.
final featureFlagsProvider = FutureProvider<FeatureFlags>((ref) {
  return ref.watch(featureFlagsServiceProvider).fetch();
});

/// Synchronous "best-effort" flags — returns defaults until the async
/// fetch resolves. Useful for places that can't easily await
/// (e.g. in router redirects, MaterialApp.localeResolutionCallback).
final featureFlagsSyncProvider = Provider<FeatureFlags>((ref) {
  return ref.watch(featureFlagsProvider).maybeWhen(
        data: (flags) => flags,
        orElse: FeatureFlags.defaultsV1_0,
      );
});
