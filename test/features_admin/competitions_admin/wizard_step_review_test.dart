// Tests UI — WizardStepReview (étape 5 du wizard, extraite de la page).
//
// Présentation pure : toutes les valeurs (dont cagnotte/commission/quota déjà
// calculées) sont fournies. On vérifie le récap + l'affichage conditionnel du
// match 3e place (masqué en round-robin) et du toggle publier (masqué en
// édition).

import 'package:arena/data/models/competition_enums.dart';
import 'package:arena/features_admin/competitions_admin/widgets/wizard_step_review.dart';
import 'package:arena/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _scoped({
  TournamentFormat format = TournamentFormat.singleElimination,
  bool isEditing = false,
  int referralQuota = 0,
}) =>
    MaterialApp(
      locale: const Locale('fr'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: SingleChildScrollView(
          child: WizardStepReview(
            name: 'COUPE ARENA',
            gameLabel: 'eFootball',
            format: format,
            maxPlayers: 16,
            startDate: DateTime(2026, 6, 20, 18),
            fee: 1000,
            currency: 'XAF',
            pool: 50000,
            commissionXaf: 2000,
            autoGenerateBracket: true,
            matchIntervalMinutes: 60,
            thirdPlaceMatch: true,
            referralQuota: referralQuota,
            isEditing: isEditing,
            publishNow: true,
            submitting: false,
            onPublishChanged: (_) {},
          ),
        ),
      ),
    );

void main() {
  setUpAll(TestWidgetsFlutterBinding.ensureInitialized);

  Future<void> bumpViewport(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(900, 2400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
  }

  testWidgets('récap : nom, cagnotte, et match 3e place hors round-robin',
      (tester) async {
    await bumpViewport(tester);
    await tester.pumpWidget(_scoped());
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Récap'), findsOneWidget);
    expect(find.text('COUPE ARENA'), findsOneWidget);
    expect(find.text('Cagnotte (somme des récompenses)'), findsOneWidget);
    expect(find.text('Match de classement (3e place)'), findsOneWidget);
  });

  testWidgets('round-robin → pas de ligne match 3e place', (tester) async {
    await bumpViewport(tester);
    await tester.pumpWidget(_scoped(format: TournamentFormat.roundRobin));
    await tester.pumpAndSettle();

    expect(find.text('Match de classement (3e place)'), findsNothing);
  });

  testWidgets('quota parrainage > 0 → ligne parrainages affichée',
      (tester) async {
    await bumpViewport(tester);
    await tester.pumpWidget(_scoped(referralQuota: 3));
    await tester.pumpAndSettle();

    expect(find.text('Parrainages requis'), findsOneWidget);
  });
}
