// Tests UI — DeleteAccountPage (flux RGPD #27, stepper 4 étapes).
//
// ConsumerStatefulWidget. La vérif des gains en attente (initState) lit le
// paymentRepository dans un try/catch tolérant : sans Supabase initialisé,
// l'erreur est avalée et l'écran reste utilisable. On couvre l'étape 0
// (avertissement) et le passage à l'étape 1.

import 'package:arena/data/models/profile.dart';
import 'package:arena/features_user/auth/auth_providers.dart';
import 'package:arena/features_user/profile/delete_account_page.dart';
import 'package:arena/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Profile _profile() => const Profile(
      id: 'p-1',
      username: 'Drogba',
      email: 'd@arena.app',
      countryCode: 'CI',
    );

Widget _scoped(Profile profile) => ProviderScope(
      overrides: [
        currentProfileProvider.overrideWith((ref) => Stream.value(profile)),
      ],
      child: const MaterialApp(
        locale: Locale('fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: DeleteAccountPage(),
      ),
    );

void main() {
  setUpAll(TestWidgetsFlutterBinding.ensureInitialized);

  Future<void> bumpViewport(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
  }

  testWidgets("démarre à l'étape 1/04 (avertissement)", (tester) async {
    await bumpViewport(tester);
    await tester.pumpWidget(_scoped(_profile()));
    await tester.pump();

    expect(find.text('SUPPRIMER'), findsOneWidget);
    expect(find.textContaining('ÉTAPE 01/04'), findsOneWidget);
    expect(find.text('Cette action est irréversible'), findsOneWidget);
  });

  testWidgets("« JE COMPRENDS, CONTINUER » avance à l'étape 2/04",
      (tester) async {
    await bumpViewport(tester);
    await tester.pumpWidget(_scoped(_profile()));
    await tester.pump();

    await tester.tap(find.text('JE COMPRENDS, CONTINUER'));
    await tester.pump();

    expect(find.textContaining('ÉTAPE 02/04'), findsOneWidget);
  });
}
