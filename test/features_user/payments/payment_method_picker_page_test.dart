// Tests UI du flux ARGENT — P1 : choix de l'opérateur.
//
// PaymentMethodPickerPage reçoit les options de paiement (déjà filtrées sur
// le pays) + un callback `onConfirm(CompetitionPaymentOption)`. On vérifie le
// rendu des opérateurs, la sélection par défaut, le changement de sélection,
// et que `onConfirm` renvoie bien l'option choisie.
//
// On cible les tuiles via leur badge stable ('MTN' / 'OM' / 'WAV').

import 'package:arena/data/models/competition_payment_option.dart';
import 'package:arena/features_shared/widgets/arena_button.dart';
import 'package:arena/features_user/payments/payment_method.dart';
import 'package:arena/features_user/payments/payment_method_picker_page.dart';
import 'package:arena/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _options = <CompetitionPaymentOption>[
  CompetitionPaymentOption(
    id: 'o1',
    competitionId: 'c1',
    countryCode: 'CM',
    operatorLabel: 'MTN MoMo',
    transferCode: '*126*1#',
  ),
  CompetitionPaymentOption(
    id: 'o2',
    competitionId: 'c1',
    countryCode: 'CM',
    operatorLabel: 'Orange Money',
    transferCode: '#150*1#',
  ),
];

Widget _scoped({
  int amountXaf = 1500,
  String contextLabel = 'Coupe ARENA',
  List<CompetitionPaymentOption> options = _options,
  ValueChanged<CompetitionPaymentOption>? onConfirm,
}) {
  return MaterialApp(
    locale: const Locale('fr'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: PaymentMethodPickerPage(
      amountXaf: amountXaf,
      contextLabel: contextLabel,
      options: options,
      onConfirm: onConfirm,
    ),
  );
}

void main() {
  setUpAll(TestWidgetsFlutterBinding.ensureInitialized);

  Future<void> bumpViewport(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
  }

  testWidgets('affiche les opérateurs + le montant formaté', (tester) async {
    await bumpViewport(tester);
    await tester.pumpWidget(_scoped(amountXaf: 1500));
    await tester.pumpAndSettle();

    // Les deux badges d'opérateur sont rendus.
    expect(find.text('MTN'), findsOneWidget);
    expect(find.text('OM'), findsOneWidget);
    expect(find.byType(PaymentOperatorLogo), findsNWidgets(2));

    // Le montant est affiché avec séparateur de milliers : 1500 → "1 500".
    expect(find.text('1 500'), findsOneWidget);

    // Un unique bouton de validation.
    expect(find.byType(ArenaButton), findsOneWidget);
  });

  testWidgets('sélection par défaut = 1re option (une seule coche visible)',
      (tester) async {
    await bumpViewport(tester);
    await tester.pumpWidget(_scoped());
    await tester.pumpAndSettle();

    // Seule la tuile sélectionnée affiche l'icône check.
    expect(find.byIcon(Icons.check), findsOneWidget);
  });

  testWidgets('confirme la 1re option par défaut (sans interaction)',
      (tester) async {
    await bumpViewport(tester);
    CompetitionPaymentOption? confirmed;
    await tester.pumpWidget(_scoped(onConfirm: (o) => confirmed = o));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(ArenaButton));
    await tester.pumpAndSettle();

    expect(confirmed?.id, 'o1');
  });

  testWidgets("sélectionner Orange puis confirmer renvoie l'option Orange",
      (tester) async {
    await bumpViewport(tester);
    CompetitionPaymentOption? confirmed;
    await tester.pumpWidget(_scoped(onConfirm: (o) => confirmed = o));
    await tester.pumpAndSettle();

    // Tape la tuile Orange (le badge 'OM' est descendant de l'InkWell tapable).
    await tester.tap(find.text('OM'));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(ArenaButton));
    await tester.pumpAndSettle();

    expect(confirmed?.id, 'o2');
  });
}
