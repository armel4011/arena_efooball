// Tests UI — PayoutKycPage (P7 : capture KYC pour gros retraits).
//
// StatefulWidget pur (stepper local 3 étapes). On vérifie le rendu initial
// (étape 1, bouton « suivant » verrouillé tant que rien n'est capturé) et le
// flux capture → déverrouillage → passage à l'étape suivante.

import 'package:arena/features_user/payouts/payout_kyc_page.dart';
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

  testWidgets("démarre à l'étape 1 avec le bouton suivant verrouillé",
      (tester) async {
    await bumpViewport(tester);
    await tester.pumpWidget(
      _scoped(const PayoutKycPage(pendingAmountXaf: 150000)),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('VÉRIFIER'), findsOneWidget);
    expect(find.textContaining('ÉTAPE 01/3'), findsOneWidget);

    // Le bouton « suivant » est verrouillé tant qu'aucune photo n'est capturée :
    // le taper ne doit pas faire avancer le stepper.
    await tester.tap(find.text('SUIVANT (recto requis)'));
    await tester.pumpAndSettle();
    expect(find.textContaining('ÉTAPE 01/3'), findsOneWidget);
  });

  testWidgets("capture la photo puis avance à l'étape 2", (tester) async {
    await bumpViewport(tester);
    await tester.pumpWidget(
      _scoped(const PayoutKycPage(pendingAmountXaf: 150000)),
    );
    await tester.pumpAndSettle();

    // Prendre la photo → carte « Photo capturée » + bouton suivant déverrouillé.
    await tester.tap(find.text('📸 PRENDRE EN PHOTO'));
    await tester.pumpAndSettle();
    expect(find.text('Photo capturée'), findsOneWidget);

    // Passer à l'étape suivante.
    await tester.tap(find.text('SUIVANT (recto requis)'));
    await tester.pumpAndSettle();

    // On est à l'étape 2, la capture est de nouveau requise.
    expect(find.textContaining('ÉTAPE 02/3'), findsOneWidget);
    expect(find.text('Photo capturée'), findsNothing);
  });
}
