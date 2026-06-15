// Tests UI — EditProfilePage (édition du profil).
//
// ConsumerStatefulWidget : `currentProfileProvider` (lu en initState pour
// pré-remplir, puis surveillé au build pour l'avatar). Smoke test du rendu du
// formulaire : titre, aperçu avatar, libellé du champ username.

import 'package:arena/data/models/profile.dart';
import 'package:arena/features_user/auth/auth_providers.dart';
import 'package:arena/features_user/profile/edit_profile_page.dart';
import 'package:arena/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _profile = Profile(
  id: 'p-1',
  username: 'Drogba',
  email: 'd@arena.app',
  countryCode: 'CI',
);

Widget _scoped() => ProviderScope(
      overrides: [
        currentProfileProvider.overrideWith((ref) => Stream.value(_profile)),
      ],
      child: const MaterialApp(
        locale: Locale('fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: EditProfilePage(),
      ),
    );

void main() {
  setUpAll(TestWidgetsFlutterBinding.ensureInitialized);

  Future<void> bumpViewport(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 2200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
  }

  testWidgets('rend le formulaire (titre + champ username)', (tester) async {
    await bumpViewport(tester);
    await tester.pumpWidget(_scoped());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(tester.takeException(), isNull);
    expect(find.text('MODIFIER'), findsOneWidget);
    expect(find.text("NOM D'UTILISATEUR"), findsOneWidget);
    expect(find.byType(TextFormField), findsWidgets);
  });
}
