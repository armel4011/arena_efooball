// Tests UI — RegistrationConfirmPage (checkout d'inscription).
//
// ConsumerStatefulWidget piloté par ses paramètres de constructeur. Au build il
// lit `referralEligibilityProvider(id)` : sans session (currentSessionProvider
// retombe à null en test), l'éligibilité renvoie target=0 → pas de gating, et
// aucun accès Supabase. On vérifie donc le rendu sans override particulier.

import 'package:arena/features_user/competitions/registration_confirm_page.dart';
import 'package:arena/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _scoped({int entryFeeXaf = 1000}) => ProviderScope(
      child: MaterialApp(
        locale: const Locale('fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: RegistrationConfirmPage(
          competitionId: 'c-1',
          competitionName: 'COUPE ARENA',
          gameLabel: 'eFootball',
          gameEmoji: '⚽',
          dateLabel: '14/06 10:30',
          formatLabel: 'Élimination directe',
          entryFeeXaf: entryFeeXaf,
          totalPrizeXaf: 50000,
          prizeDistribution: const [50, 30, 20],
        ),
      ),
    );

void main() {
  setUpAll(TestWidgetsFlutterBinding.ensureInitialized);

  Future<void> bumpViewport(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
  }

  testWidgets('rend le checkout avec le nom et la répartition des gains',
      (tester) async {
    await bumpViewport(tester);
    await tester.pumpWidget(_scoped());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('CHECKOUT'), findsOneWidget);
    expect(find.text('COUPE ARENA'), findsOneWidget);
    expect(find.text('RÉPARTITION DES GAINS'), findsOneWidget);
  });
}
