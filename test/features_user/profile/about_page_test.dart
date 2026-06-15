// Test UI — AboutPage (page "À propos" du profil).
//
// Page statique (StatelessWidget sans paramètre). Smoke test : elle se
// construit sans exception et affiche ses cartes de liens. Couvre le chemin
// de build complet de la page.

import 'package:arena/features_user/profile/about_page.dart';
import 'package:arena/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUpAll(TestWidgetsFlutterBinding.ensureInitialized);

  Future<void> bumpViewport(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
  }

  testWidgets('se construit sans erreur et affiche des liens', (tester) async {
    await bumpViewport(tester);
    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: AboutPage(),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(AboutPage), findsOneWidget);
    // La page expose des liens cliquables (mentions, confidentialité, etc.).
    expect(find.byType(InkWell), findsWidgets);
  });
}
