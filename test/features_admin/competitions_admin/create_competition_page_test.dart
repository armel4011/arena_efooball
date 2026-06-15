// Tests UI — CreateCompetitionPage (wizard admin de création de compétition).
//
// La page rend sans accès provider au build (les `ref.read` sont confinés à
// `_submit`/`_submitEdit`). Smoke test du shell + de l'étape 1 (Infos), qui
// verrouille le comportement avant l'extraction des steps inline en widgets.

import 'package:arena/features_admin/competitions_admin/create_competition_page.dart';
import 'package:arena/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _scoped() => const ProviderScope(
      child: MaterialApp(
        locale: Locale('fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: CreateCompetitionPage(),
      ),
    );

void main() {
  setUpAll(TestWidgetsFlutterBinding.ensureInitialized);

  Future<void> bumpViewport(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(900, 2000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
  }

  testWidgets("démarre à l'étape 1/5 (Infos) en mode création",
      (tester) async {
    await bumpViewport(tester);
    await tester.pumpWidget(_scoped());
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('CRÉER'), findsOneWidget);
    expect(find.textContaining('Étape 1 / 5'), findsOneWidget);
    // Premier champ de l'étape Infos.
    expect(find.text('Nom de la compétition'), findsOneWidget);
    // CTA de navigation.
    expect(find.text('SUIVANT →'), findsOneWidget);
  });
}
