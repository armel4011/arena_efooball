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
  ///
  /// NOTE i18n (2026-06-13) : FR + EN activés — `isMultiLanguage` devient vrai,
  /// donc le sélecteur de langue (LanguageSwitcher) s'affiche dans les
  /// Paramètres. L'arabe (RTL) reste différé. Ces defaults sont la SOURCE
  /// effective des flags tant que le lecteur `app_config` n'est pas réparé
  /// (cf. note dans feature_flags_service.dart : la table est en clé/valeur
  /// `supported_languages`, mais fromMap lit `enabled_languages` au niveau
  /// racine d'une seule ligne → fetch retombe toujours sur ces defaults).
  factory FeatureFlags.defaultsV1_0() {
    return const FeatureFlags(
      enabledLanguages: [SupportedLocale.fr, SupportedLocale.en],
      enabledCurrencies: [Currency.xaf, Currency.xof, Currency.usd],
      enabledRegions: ['francophone_africa'],
      streamingEnabled: false,
      chatModerationEnabled: true,
      antiCheatRequired: true,
      maxPlayersPerCompetition: 256,
    );
  }

  /// Construit les flags depuis la config `app_config` **agrégée**.
  ///
  /// `app_config` est une table CLÉ/VALEUR (`{key, value}`), agrégée par
  /// `FeatureFlagsService.fetch` en une map `{clé: valeur jsonb}`. On lit donc
  /// les clés RÉELLES de la table :
  ///   * `supported_languages`  (`List<String>`) → [enabledLanguages]
  ///   * `supported_currencies` (`List<String>`) → [enabledCurrencies]
  ///   * `feature_flags` (objet jsonb) → sous-clés `streaming_finals_only`,
  ///     `anti_cheat_recording`, `chat_moderation`.
  /// Toute clé absente retombe sur `defaultsV1_0`.
  ///
  /// (Ancien bug 2026-06-13 : `fromMap` lisait `enabled_languages` au niveau
  /// racine d'UNE SEULE ligne — jamais présent → `fetch` retombait toujours
  /// sur les defaults. Cf. `FeatureFlagsService`.)
  factory FeatureFlags.fromConfig(Map<String, dynamic> config) {
    List<String> stringList(Object? v) =>
        v is List ? v.whereType<String>().toList() : const [];

    final defaults = FeatureFlags.defaultsV1_0();
    final ff = config['feature_flags'];
    final featureFlags =
        ff is Map<String, dynamic> ? ff : const <String, dynamic>{};

    return FeatureFlags(
      enabledLanguages: stringList(config['supported_languages'])
          .map(SupportedLocale.fromLanguageCode)
          .toList()
          .ifEmpty(defaults.enabledLanguages),
      enabledCurrencies: stringList(config['supported_currencies'])
          .map(Currency.fromCode)
          .toList()
          .ifEmpty(defaults.enabledCurrencies),
      // Pas de clé `enabled_regions` en base → reste sur le défaut.
      enabledRegions: defaults.enabledRegions,
      streamingEnabled: (featureFlags['streaming_finals_only'] as bool?) ??
          defaults.streamingEnabled,
      chatModerationEnabled: (featureFlags['chat_moderation'] as bool?) ??
          defaults.chatModerationEnabled,
      antiCheatRequired: (featureFlags['anti_cheat_recording'] as bool?) ??
          defaults.antiCheatRequired,
      maxPlayersPerCompetition:
          (config['max_players_per_competition'] as int?) ??
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
