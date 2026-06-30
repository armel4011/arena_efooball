import 'package:arena/data/repositories/profile_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Seuils de tiering anti-triche (P0/P4) lus/écrits dans `app_config`.
///
/// Pilotent le RPC serveur `assign_anticheat_plan` : un match passe en tier
/// `livekit` (1 egress de l'élu) — plutôt que `native_only` (0 egress, P3
/// seul) — si SA cagnotte ≥ [prizeThreshold], OU si un joueur cumule ≥
/// [strikeThreshold] verdicts coupables, OU s'il porte un litige, OU par
/// échantillon aléatoire au taux [sampleRate]. Régler ces seuils ajuste la
/// FRACTION de matchs egressés = le nombre d'egress LiveKit concurrents
/// (capacité de matchs simultanés en compétition).
@immutable
class AntiCheatTieringConfig {
  const AntiCheatTieringConfig({
    required this.prizeThreshold,
    required this.strikeThreshold,
    required this.sampleRate,
  });

  /// Cagnotte (devise locale) à partir de laquelle un match est egressé.
  final num prizeThreshold;

  /// Nb de verdicts coupables d'un joueur le mettant « sous surveillance ».
  final int strikeThreshold;

  /// Probabilité [0..1] qu'un match quelconque soit egressé (échantillon).
  final double sampleRate;

  /// Valeurs par défaut alignées sur la migration `20260630120000`.
  static const fallback = AntiCheatTieringConfig(
    prizeThreshold: 5000,
    strikeThreshold: 1,
    sampleRate: 0.1,
  );

  AntiCheatTieringConfig copyWith({
    num? prizeThreshold,
    int? strikeThreshold,
    double? sampleRate,
  }) =>
      AntiCheatTieringConfig(
        prizeThreshold: prizeThreshold ?? this.prizeThreshold,
        strikeThreshold: strikeThreshold ?? this.strikeThreshold,
        sampleRate: sampleRate ?? this.sampleRate,
      );
}

/// Lit / écrit les 3 seuils `anticheat_tier_*` dans `app_config` (jsonb).
/// Écriture réservée au super-admin (RLS `is_admin` sur `app_config`).
class AntiCheatTieringService {
  const AntiCheatTieringService(this._client);

  static const _table = 'app_config';
  static const kPrize = 'anticheat_tier_prize_threshold';
  static const kStrike = 'anticheat_tier_strike_threshold';
  static const kSample = 'anticheat_tier_sample_rate';

  final SupabaseClient _client;

  /// Lit les 3 seuils, avec repli robuste sur [AntiCheatTieringConfig.fallback]
  /// par clé manquante / Supabase injoignable.
  Future<AntiCheatTieringConfig> fetch() async {
    try {
      final rows = await _client
          .from(_table)
          .select('key, value')
          .inFilter('key', [kPrize, kStrike, kSample]);
      final map = <String, dynamic>{
        for (final r in rows as List<dynamic>)
          (r as Map<String, dynamic>)['key'] as String: r['value'],
      };
      return AntiCheatTieringConfig(
        prizeThreshold:
            _asNum(map[kPrize]) ?? AntiCheatTieringConfig.fallback.prizeThreshold,
        strikeThreshold: (_asNum(map[kStrike]) ??
                AntiCheatTieringConfig.fallback.strikeThreshold)
            .toInt(),
        sampleRate: (_asNum(map[kSample]) ??
                AntiCheatTieringConfig.fallback.sampleRate)
            .toDouble(),
      );
    } catch (e) {
      if (kDebugMode) debugPrint('[anticheat] fetch tiering failed: $e');
      return AntiCheatTieringConfig.fallback;
    }
  }

  /// Persiste les 3 seuils (upsert par clé, jsonb numérique).
  Future<void> save(AntiCheatTieringConfig cfg) async {
    await _client.from(_table).upsert(
      [
        {'key': kPrize, 'value': cfg.prizeThreshold},
        {'key': kStrike, 'value': cfg.strikeThreshold},
        {'key': kSample, 'value': cfg.sampleRate},
      ],
      onConflict: 'key',
    );
  }

  /// `value` jsonb peut revenir num (number) ou String (clé encodée en texte).
  static num? _asNum(Object? v) {
    if (v is num) return v;
    if (v is String) return num.tryParse(v);
    return null;
  }
}

final antiCheatTieringServiceProvider =
    Provider<AntiCheatTieringService>((ref) {
  return AntiCheatTieringService(ref.watch(supabaseClientProvider));
});

/// Seuils actifs (async). Invalider pour rafraîchir après une sauvegarde admin.
final antiCheatTieringConfigProvider =
    FutureProvider<AntiCheatTieringConfig>((ref) {
  return ref.watch(antiCheatTieringServiceProvider).fetch();
});
