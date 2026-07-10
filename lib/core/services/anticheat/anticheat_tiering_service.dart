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

/// Résumé de coût egress anti-triche CHIFFRÉ à partir des décisions réelles
/// (`match_anticheat_plans`), renvoyé par la RPC `anticheat_cost_summary`.
///
/// Rend le coût du tiering MESURABLE (plus seulement projeté) : combien de
/// matchs décidés, combien egressés (tier livekit) vs natif seul, la
/// ventilation par raison, le coût egress réel estimé et l'économie vs le
/// scénario « sans tiering » (les 2 pistes de chaque match egressées).
@immutable
class AnticheatCostSummary {
  const AnticheatCostSummary({
    required this.decided,
    required this.livekit,
    required this.nativeOnly,
    required this.livekitFraction,
    required this.prize,
    required this.surveillance,
    required this.dispute,
    required this.random,
    required this.costPerEgressUsd,
    required this.actualCostUsd,
    required this.baselineCostUsd,
    required this.savingsUsd,
    required this.savingsPct,
  });

  factory AnticheatCostSummary.fromJson(Map<String, dynamic> json) {
    final reason = (json['by_reason'] as Map?)?.cast<String, dynamic>() ??
        const <String, dynamic>{};
    num n(Object? v) => v is num ? v : num.tryParse('$v') ?? 0;
    int i(Object? v) => n(v).toInt();
    return AnticheatCostSummary(
      decided: i(json['decided']),
      livekit: i(json['livekit']),
      nativeOnly: i(json['native_only']),
      livekitFraction: n(json['livekit_fraction']).toDouble(),
      prize: i(reason['prize']),
      surveillance: i(reason['surveillance']),
      dispute: i(reason['dispute']),
      random: i(reason['random']),
      costPerEgressUsd: n(json['cost_per_egress_usd']),
      actualCostUsd: n(json['actual_cost_usd']),
      baselineCostUsd: n(json['baseline_cost_usd']),
      savingsUsd: n(json['savings_usd']),
      savingsPct: n(json['savings_pct']),
    );
  }

  /// Résumé vide (aucun plan décidé) — provider natif = système dormant.
  static const empty = AnticheatCostSummary(
    decided: 0,
    livekit: 0,
    nativeOnly: 0,
    livekitFraction: 0,
    prize: 0,
    surveillance: 0,
    dispute: 0,
    random: 0,
    costPerEgressUsd: 0.034,
    actualCostUsd: 0,
    baselineCostUsd: 0,
    savingsUsd: 0,
    savingsPct: 0,
  );

  /// Nombre de matchs pour lesquels un plan a été figé.
  final int decided;

  /// Matchs egressés (tier livekit, 1 piste egressée).
  final int livekit;

  /// Matchs couverts par le seul commitment hash (0 egress).
  final int nativeOnly;

  /// Fraction egressée [0..1] = pression sur les egress concurrents LiveKit.
  final double livekitFraction;

  /// Ventilation des matchs egressés par raison de la décision.
  final int prize;
  final int surveillance;
  final int dispute;
  final int random;

  /// Coût unitaire modélisé d'un egress (1 piste), lu dans `app_config`.
  final num costPerEgressUsd;

  /// Coût egress réel estimé = [livekit] × [costPerEgressUsd].
  final num actualCostUsd;

  /// Coût du scénario « sans tiering » = [decided] × 2 × [costPerEgressUsd].
  final num baselineCostUsd;

  /// Économie apportée par le tiering + egress unique = baseline − réel.
  final num savingsUsd;

  /// Économie en % du baseline.
  final num savingsPct;
}

/// Lit / écrit les 3 seuils `anticheat_tier_*` dans `app_config` (jsonb) et
/// lit le résumé de coût agrégé (RPC `anticheat_cost_summary`).
/// Écriture réservée au super-admin (RLS `is_admin` sur `app_config`).
class AntiCheatTieringService {
  const AntiCheatTieringService(this._client);

  static const _table = 'app_config';
  static const kPrize = 'anticheat_tier_prize_threshold';
  static const kStrike = 'anticheat_tier_strike_threshold';
  static const kSample = 'anticheat_tier_sample_rate';

  final SupabaseClient _client;

  /// Résumé de coût egress agrégé depuis les plans réels. [since] borne la
  /// fenêtre sur `decided_at` (null = depuis toujours). Gate super-admin
  /// serveur ; renvoie [AnticheatCostSummary.empty] si la RPC échoue.
  Future<AnticheatCostSummary> fetchCostSummary({DateTime? since}) async {
    try {
      final res = await _client.rpc<dynamic>(
        'anticheat_cost_summary',
        params: {'p_since': since?.toUtc().toIso8601String()},
      );
      if (res is Map) {
        return AnticheatCostSummary.fromJson(
          res.cast<String, dynamic>(),
        );
      }
      return AnticheatCostSummary.empty;
    } catch (e) {
      if (kDebugMode) debugPrint('[anticheat] fetch cost summary failed: $e');
      return AnticheatCostSummary.empty;
    }
  }

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

/// Fenêtre d'agrégation du résumé de coût egress (super-admin).
enum AnticheatCostWindow {
  /// 30 derniers jours.
  last30d,

  /// Depuis toujours.
  allTime,
}

/// Résumé de coût egress agrégé pour une [AnticheatCostWindow] (super-admin).
final antiCheatCostSummaryProvider = FutureProvider.family
    .autoDispose<AnticheatCostSummary, AnticheatCostWindow>((ref, window) {
  final since = switch (window) {
    AnticheatCostWindow.last30d =>
      DateTime.now().toUtc().subtract(const Duration(days: 30)),
    AnticheatCostWindow.allTime => null,
  };
  return ref.watch(antiCheatTieringServiceProvider).fetchCostSummary(
        since: since,
      );
});
