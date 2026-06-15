// Tests UI — OnboardingPage (4 slides au premier lancement).
//
// StatefulWidget sans dépendance réseau : [onFinish] est le seul contrat. On
// vérifie le rendu du 1er slide, le raccourci « Ignorer » → onFinish, et que
// « SUIVANT » fait défiler sans terminer l'onboarding avant le dernier slide.

import 'package:arena/features_user/onboarding/onboarding_page.dart';
import 'package:arena/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _scoped(Widget child) => MaterialApp(
      locale: const Locale('fr'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: child,
    );

void main() {
  setUpAll(TestWidgetsFlutterBinding.ensureInitialized);

  Future<void> bumpViewport(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
  }

  testWidgets('affiche le 1er slide et les CTA SUIVANT / Ignorer',
      (tester) async {
    await bumpViewport(tester);
    await tester.pumpWidget(_scoped(OnboardingPage(onFinish: () {})));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('TOURNOIS E-SPORT PANAFRICAINS'), findsOneWidget);
    expect(find.text('SUIVANT'), findsOneWidget);
    // Bouton bas « Ignorer ».
    expect(find.text('Ignorer'), findsOneWidget);
  });

  testWidgets('tap Ignorer déclenche onFinish', (tester) async {
    await bumpViewport(tester);
    var finished = false;
    await tester.pumpWidget(
      _scoped(OnboardingPage(onFinish: () => finished = true)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Ignorer'));
    await tester.pumpAndSettle();
    expect(finished, isTrue);
  });

  testWidgets('SUIVANT fait défiler sans terminer avant le dernier slide',
      (tester) async {
    await bumpViewport(tester);
    var finished = false;
    await tester.pumpWidget(
      _scoped(OnboardingPage(onFinish: () => finished = true)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('SUIVANT'));
    await tester.pumpAndSettle();

    // On a avancé d'un slide : onFinish ne doit pas encore avoir été appelé,
    // et le label reste « SUIVANT » (pas « COMMENCER »).
    expect(finished, isFalse);
    expect(find.text('SUIVANT'), findsOneWidget);
  });
}
