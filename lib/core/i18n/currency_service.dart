import 'package:arena/core/i18n/currency.dart';
import 'package:arena/core/i18n/i18n_service.dart';
import 'package:arena/core/i18n/supported_locale.dart';
import 'package:arena/core/services/onboarding_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Formats currency amounts according to the active locale.
///
/// Uses `intl.NumberFormat.currency` for grouping/decimals, then composes
/// the symbol position based on locale conventions:
/// - FR / AR → trailing symbol  ("5 000 FCFA")
/// - EN      → leading symbol   ("$5,000")
class CurrencyService {
  const CurrencyService(this._prefs);

  static const _key = 'app_currency';

  final SharedPreferences _prefs;

  Currency resolveInitial() {
    final stored = _prefs.getString(_key);
    if (stored != null && stored.isNotEmpty) {
      return Currency.fromCode(stored);
    }
    return Currency.xaf; // V1.0 launch market
  }

  Future<void> save(Currency currency) {
    return _prefs.setString(_key, currency.code);
  }

  String format({
    required num amount,
    required Currency currency,
    required SupportedLocale locale,
    bool withSymbol = true,
  }) {
    final number = NumberFormat.decimalPatternDigits(
      locale: locale.locale.toLanguageTag(),
      decimalDigits: currency.decimalDigits,
    ).format(amount);

    if (!withSymbol) return number;

    return switch (locale) {
      SupportedLocale.en => '${currency.symbol}$number',
      SupportedLocale.fr || SupportedLocale.ar =>
        '$number ${currency.symbol}',
    };
  }
}

final currencyServiceProvider = Provider<CurrencyService>((ref) {
  return CurrencyService(ref.watch(sharedPreferencesProvider));
});

class CurrencyController extends Notifier<Currency> {
  @override
  Currency build() => ref.watch(currencyServiceProvider).resolveInitial();

  Future<void> setCurrency(Currency currency) async {
    await ref.read(currencyServiceProvider).save(currency);
    state = currency;
  }
}

final currentCurrencyProvider = NotifierProvider<CurrencyController, Currency>(
  CurrencyController.new,
);

/// Convenience formatter that picks up the active locale + currency.
String formatAmount(WidgetRef ref, num amount) {
  final currency = ref.watch(currentCurrencyProvider);
  final locale = ref.watch(currentLocaleProvider);
  return ref.read(currencyServiceProvider).format(
        amount: amount,
        currency: currency,
        locale: locale,
      );
}
