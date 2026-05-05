import 'package:arena/core/i18n/supported_locale.dart';
import 'package:arena/core/services/onboarding_service.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists & resolves the user-facing locale.
///
/// Resolution order:
/// 1. Stored preference (after the user picks one in Settings)
/// 2. Device locale (via PlatformDispatcher) — narrowed to a supported one
/// 3. Fallback to French (V1.0 launch market is francophone Africa)
class I18nService {
  const I18nService(this._prefs);

  static const _key = 'app_locale';

  final SharedPreferences _prefs;

  SupportedLocale resolveInitial() {
    final stored = _prefs.getString(_key);
    if (stored != null && stored.isNotEmpty) {
      return SupportedLocale.fromLanguageCode(stored);
    }
    final device =
        WidgetsBinding.instance.platformDispatcher.locale.languageCode;
    return SupportedLocale.fromLanguageCode(device);
  }

  Future<void> save(SupportedLocale locale) {
    return _prefs.setString(_key, locale.locale.languageCode);
  }

  Future<void> clear() => _prefs.remove(_key);
}

final i18nServiceProvider = Provider<I18nService>((ref) {
  return I18nService(ref.watch(sharedPreferencesProvider));
});

/// Active locale across the app. Update via
/// `ref.read(currentLocaleProvider.notifier).setLocale(...)`.
class LocaleController extends Notifier<SupportedLocale> {
  @override
  SupportedLocale build() => ref.watch(i18nServiceProvider).resolveInitial();

  Future<void> setLocale(SupportedLocale locale) async {
    await ref.read(i18nServiceProvider).save(locale);
    state = locale;
  }
}

final currentLocaleProvider =
    NotifierProvider<LocaleController, SupportedLocale>(
  LocaleController.new,
);
