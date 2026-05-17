import 'package:arena/core/i18n/feature_flags.dart';
import 'package:arena/data/repositories/profile_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Reads `app_config` from Supabase with a robust local fallback.
///
/// The `app_config` table is a single-row key/value (or single-row JSONB)
/// table seeded by migrations in PHASE 0. Until the row exists or
/// Supabase is reachable, [FeatureFlags.defaultsV1_0] is used so the app
/// stays functional offline / on cold start.
class FeatureFlagsService {
  const FeatureFlagsService(this._client);

  static const _table = 'app_config';

  final SupabaseClient _client;

  Future<FeatureFlags> fetch() async {
    try {
      final row = await _client
          .from(_table)
          .select()
          .limit(1)
          .maybeSingle();
      if (row == null) return FeatureFlags.defaultsV1_0();
      return FeatureFlags.fromMap(row);
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
