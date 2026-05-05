import 'package:arena/core/i18n/currency.dart';
import 'package:arena/core/i18n/supported_locale.dart';

/// Snapshot of platform-wide flags read from `app_config`.
///
/// Defaults reflect the V1.0 launch state (francophone Africa only).
class FeatureFlags {
  const FeatureFlags({
    required this.enabledLanguages,
    required this.enabledCurrencies,
    required this.enabledRegions,
    required this.streamingEnabled,
    required this.chatModerationEnabled,
    required this.antiCheatRequired,
    required this.maxPlayersPerCompetition,
  });

  /// V1.0 hard-coded defaults — used as fallback when `app_config` cannot
  /// be reached (cold start, network down, Supabase unconfigured).
  factory FeatureFlags.defaultsV1_0() {
    return const FeatureFlags(
      enabledLanguages: [SupportedLocale.fr],
      enabledCurrencies: [Currency.xaf, Currency.xof, Currency.usd],
      enabledRegions: ['francophone_africa'],
      streamingEnabled: false,
      chatModerationEnabled: true,
      antiCheatRequired: true,
      maxPlayersPerCompetition: 256,
    );
  }

  factory FeatureFlags.fromMap(Map<String, dynamic> map) {
    List<String> stringList(String key) {
      final v = map[key];
      if (v is List) return v.whereType<String>().toList();
      return const [];
    }

    final defaults = FeatureFlags.defaultsV1_0();

    return FeatureFlags(
      enabledLanguages: stringList('enabled_languages')
          .map(SupportedLocale.fromLanguageCode)
          .toList()
          .ifEmpty(defaults.enabledLanguages),
      enabledCurrencies: stringList('enabled_currencies')
          .map(Currency.fromCode)
          .toList()
          .ifEmpty(defaults.enabledCurrencies),
      enabledRegions: stringList('enabled_regions')
          .ifEmpty(defaults.enabledRegions),
      streamingEnabled:
          (map['streaming_enabled'] as bool?) ?? defaults.streamingEnabled,
      chatModerationEnabled: (map['chat_moderation_enabled'] as bool?) ??
          defaults.chatModerationEnabled,
      antiCheatRequired:
          (map['anti_cheat_required'] as bool?) ?? defaults.antiCheatRequired,
      maxPlayersPerCompetition: (map['max_players_per_competition'] as int?) ??
          defaults.maxPlayersPerCompetition,
    );
  }

  final List<SupportedLocale> enabledLanguages;
  final List<Currency> enabledCurrencies;
  final List<String> enabledRegions;
  final bool streamingEnabled;
  final bool chatModerationEnabled;
  final bool antiCheatRequired;
  final int maxPlayersPerCompetition;

  bool isLanguageEnabled(SupportedLocale locale) =>
      enabledLanguages.contains(locale);

  bool isCurrencyEnabled(Currency currency) =>
      enabledCurrencies.contains(currency);

  /// True when at least 2 languages are enabled — drives the visibility
  /// of language pickers in Settings.
  bool get isMultiLanguage => enabledLanguages.length > 1;

  bool get isMultiCurrency => enabledCurrencies.length > 1;
}

extension<T> on List<T> {
  List<T> ifEmpty(List<T> fallback) => isEmpty ? fallback : this;
}
