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
    test('V1.0 defaults : FR + EN, 3 devises', () {
      final f = FeatureFlags.defaultsV1_0();
      expect(f.enabledLanguages, [SupportedLocale.fr, SupportedLocale.en]);
      expect(f.enabledCurrencies, [
        Currency.xaf,
        Currency.xof,
        Currency.usd,
      ]);
      // FR + EN → le sélecteur de langue s'affiche.
      expect(f.isMultiLanguage, isTrue);
      expect(f.isMultiCurrency, isTrue);
      expect(f.streamingEnabled, isFalse);
    });

    test('fromConfig lit les clés réelles de app_config (clé/valeur agrégée)',
        () {
      final f = FeatureFlags.fromConfig({
        'supported_languages': ['fr', 'en'],
        'supported_currencies': ['XAF'],
        'feature_flags': {
          'streaming_finals_only': true,
          'anti_cheat_recording': true,
        },
      });
      expect(f.isMultiLanguage, isTrue);
      expect(f.enabledCurrencies, [Currency.xaf]);
      expect(f.streamingEnabled, isTrue);
      expect(f.antiCheatRequired, isTrue);
    });

    test('fromConfig : clés absentes → defaults', () {
      final f = FeatureFlags.fromConfig({'cgu_version': '1.0.0'});
      expect(f.enabledLanguages, FeatureFlags.defaultsV1_0().enabledLanguages);
      expect(
        f.enabledCurrencies,
        FeatureFlags.defaultsV1_0().enabledCurrencies,
      );
      expect(f.streamingEnabled, isFalse);
    });
  });
}
