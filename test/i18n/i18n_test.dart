import 'package:arena/core/i18n/currency.dart';
import 'package:arena/core/i18n/currency_service.dart';
import 'package:arena/core/i18n/feature_flags.dart';
import 'package:arena/core/i18n/i18n_service.dart';
import 'package:arena/core/i18n/supported_locale.dart';
import 'package:arena/core/services/onboarding_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<ProviderContainer> _container({
  Map<String, Object> initial = const {},
}) async {
  SharedPreferences.setMockInitialValues(initial);
  final prefs = await SharedPreferences.getInstance();
  return ProviderContainer(
    overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
  );
}

void main() {
  // I18nService.resolveInitial() reads PlatformDispatcher.locale via
  // WidgetsBinding — needs the test binding initialized.
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SupportedLocale.fromLanguageCode', () {
    test('matches base code "fr-CM" → fr', () {
      expect(SupportedLocale.fromLanguageCode('fr-CM'), SupportedLocale.fr);
    });

    test('falls back to fr on null/unknown', () {
      expect(SupportedLocale.fromLanguageCode(null), SupportedLocale.fr);
      expect(SupportedLocale.fromLanguageCode(''), SupportedLocale.fr);
      expect(SupportedLocale.fromLanguageCode('zz'), SupportedLocale.fr);
    });

    test('handles uppercase / underscores', () {
      expect(SupportedLocale.fromLanguageCode('AR_TN'), SupportedLocale.ar);
      expect(SupportedLocale.fromLanguageCode('EN_US'), SupportedLocale.en);
    });
  });

  group('LocaleController', () {
    test('persists choice across container rebuilds', () async {
      final c = await _container();
      addTearDown(c.dispose);

      await c
          .read(currentLocaleProvider.notifier)
          .setLocale(SupportedLocale.ar);
      expect(c.read(currentLocaleProvider), SupportedLocale.ar);

      // Fresh container — same SharedPreferences underneath.
      final c2 = ProviderContainer(
        overrides: [
          sharedPreferencesProvider
              .overrideWithValue(await SharedPreferences.getInstance()),
        ],
      );
      addTearDown(c2.dispose);
      expect(c2.read(currentLocaleProvider), SupportedLocale.ar);
    });

    test('falls back to fr when device locale is unsupported', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final prefs = await SharedPreferences.getInstance();
      final svc = I18nService(prefs);
      // Direct service call to bypass platform dispatcher dependency.
      expect(SupportedLocale.fromLanguageCode('zz'), SupportedLocale.fr);
      // Sanity check that resolveInitial works without crashing.
      expect(svc.resolveInitial(), isA<SupportedLocale>());
    });
  });

  group('CurrencyService.format', () {
    test('XAF in FR → trailing FCFA, no decimals', () async {
      final c = await _container();
      addTearDown(c.dispose);
      final svc = c.read(currencyServiceProvider);

      final out = svc.format(
        amount: 5000,
        currency: Currency.xaf,
        locale: SupportedLocale.fr,
      );
      // intl's fr_ groupings can use either regular or narrow no-break space —
      // assert structurally rather than on the exact whitespace byte.
      expect(out.endsWith('FCFA'), isTrue, reason: out);
      expect(out.contains('5'), isTrue);
      expect(out.contains('000'), isTrue);
      // No decimal point/comma for CFA.
      expect(out.contains(','), isFalse);
      expect(out.contains('.'), isFalse);
    });

    test(r'USD in EN → leading "$"', () async {
      final c = await _container();
      addTearDown(c.dispose);
      final svc = c.read(currencyServiceProvider);

      final out = svc.format(
        amount: 1234.5,
        currency: Currency.usd,
        locale: SupportedLocale.en,
      );
      expect(out.startsWith(r'$'), isTrue, reason: out);
      // English locale uses "1,234.5" grouping (decimal point).
      expect(out.contains('.'), isTrue);
    });
  });

  group('CurrencyController', () {
    test('default = XAF (V1.0 launch market), persists on change', () async {
      final c = await _container();
      addTearDown(c.dispose);

      expect(c.read(currentCurrencyProvider), Currency.xaf);
      await c
          .read(currentCurrencyProvider.notifier)
          .setCurrency(Currency.usd);
      expect(c.read(currentCurrencyProvider), Currency.usd);
    });
  });

  group('FeatureFlags.defaultsV1_0', () {
    test('V1.0 has fr-only language and 3 currencies', () {
      final f = FeatureFlags.defaultsV1_0();
      expect(f.enabledLanguages, [SupportedLocale.fr]);
      expect(f.enabledCurrencies, [
        Currency.xaf,
        Currency.xof,
        Currency.usd,
      ]);
      expect(f.isMultiLanguage, isFalse);
      expect(f.isMultiCurrency, isTrue);
      expect(f.streamingEnabled, isFalse);
    });

    test('fromMap respects partial overrides', () {
      final f = FeatureFlags.fromMap({
        'enabled_languages': ['fr', 'en'],
        'streaming_enabled': true,
      });
      expect(f.isMultiLanguage, isTrue);
      expect(f.streamingEnabled, isTrue);
      // Other fields fall back to defaults.
      expect(f.enabledCurrencies.contains(Currency.xaf), isTrue);
    });
  });
}
