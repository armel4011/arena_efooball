import 'package:flutter/widgets.dart';

/// Languages ARENA supports across the rollout.
///
/// V1.0 → only [fr] surfaced in pickers (others built but feature-flagged off)
/// V1.1 → [fr] + [en]
/// V1.2 → [fr] + [en] + [ar] (RTL)
enum SupportedLocale {
  fr(Locale('fr'), 'Français', TextDirection.ltr),
  en(Locale('en'), 'English', TextDirection.ltr),
  ar(Locale('ar'), 'العربية', TextDirection.rtl);

  const SupportedLocale(this.locale, this.displayName, this.textDirection);

  final Locale locale;
  final String displayName;
  final TextDirection textDirection;

  /// Resolve a language code (e.g. `"fr-CM"` from a device locale) to a
  /// [SupportedLocale]. Falls back to [SupportedLocale.fr] if unknown.
  static SupportedLocale fromLanguageCode(String? code) {
    if (code == null || code.isEmpty) return SupportedLocale.fr;
    final lower = code.toLowerCase().split(RegExp('[-_]')).first;
    return SupportedLocale.values.firstWhere(
      (l) => l.locale.languageCode == lower,
      orElse: () => SupportedLocale.fr,
    );
  }

  static List<Locale> get allFlutterLocales =>
      SupportedLocale.values.map((l) => l.locale).toList();
}
