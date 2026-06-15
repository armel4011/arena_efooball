// Tests UI — WizardStepPrizes (étape 3 du wizard, extraite de la page).
//
// Présentation pure : on l'alimente directement avec des contrôleurs + un
// total, et on vérifie le rendu (info, sélecteur de récompensés, total) ainsi
// que l'affichage conditionnel des blocs selon le nombre de récompensés.

import 'package:arena/features_admin/competitions_admin/widgets/wizard_step_prizes.dart';
import 'package:arena/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

List<TextEditingController> _ctrls(int n, String v) =>
    List.generate(n, (_) => TextEditingController(text: v));

Widget _scoped({required int rewardedCount, required int shareTotal}) {
  final top = _ctrls(4, '25');
  final blocks = _ctrls(5, '0');
  return MaterialApp(
    locale: const Locale('fr'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: SingleChildScrollView(
        child: WizardStepPrizes(
          rewardedCount: rewardedCount,
          currency: 'XAF',
          topShareCtrls: top,
          blockShareCtrls: blocks,
          shareTotal: shareTotal,
          onRewardedCountChanged: (_) {},
          onChanged: () {},
        ),
      ),
    ),
  );
}

void main() {
  setUpAll(TestWidgetsFlutterBinding.ensureInitialized);

  Future<void> bumpViewport(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(900, 2400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
  }

  testWidgets('rewardedCount=4 → pas de blocs, total affiché', (tester) async {
    await bumpViewport(tester);
    await tester.pumpWidget(_scoped(rewardedCount: 4, shareTotal: 100));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Nombre de récompensés'), findsOneWidget);
    expect(find.textContaining('La cagnotte de la compétition'), findsOneWidget);
    // Aucun bloc (premier bloc à lastRank 8 > 4).
    expect(find.textContaining('place'), findsWidgets); // ShareRow 1-4
  });

  testWidgets('rewardedCount=8 → le 1er bloc (5-8) apparaît', (tester) async {
    await bumpViewport(tester);
    await tester.pumpWidget(_scoped(rewardedCount: 8, shareTotal: 100));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.textContaining('5ème – 8ème'), findsOneWidget);
  });
}
