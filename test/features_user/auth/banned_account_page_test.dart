// Tests UI — BannedAccountPage (écran /banned + canal Arena Requête).
//
// ConsumerStatefulWidget : flux `myReintegrationRequestProvider`. Sans demande
// en cours (null), la page affiche le formulaire de réintégration. On override
// le provider directement (court-circuite la session) et on vérifie le rendu.

import 'package:arena/data/repositories/reintegration_requests_repository.dart';
import 'package:arena/features_user/auth/banned_account_page.dart';
import 'package:arena/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _scoped() => ProviderScope(
      overrides: [
        myReintegrationRequestProvider.overrideWith((ref) async => null),
      ],
      child: const MaterialApp(
        locale: Locale('fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: BannedAccountPage(),
      ),
    );

void main() {
  setUpAll(TestWidgetsFlutterBinding.ensureInitialized);

  Future<void> bumpViewport(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
  }

  testWidgets('sans demande → titre, formulaire Arena Requête et déconnexion',
      (tester) async {
    await bumpViewport(tester);
    await tester.pumpWidget(_scoped());
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    // ArenaAppBar met le titre en majuscules.
    expect(find.text('COMPTE SUSPENDU'), findsOneWidget);
    expect(find.text('📨 ARENA REQUÊTE'), findsOneWidget);
    expect(find.text('SE DÉCONNECTER'), findsOneWidget);
  });
}
