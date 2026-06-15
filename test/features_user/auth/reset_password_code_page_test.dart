// Tests UI — ResetPasswordCodePage (saisie du code OTP de reset).
//
// ConsumerStatefulWidget : `verifyPasswordResetCodeControllerProvider` dont le
// `build()` renvoie `false` sans accès Supabase → aucun override nécessaire. On
// vérifie le rendu du formulaire (titre, email cible, champ code, CTA).

import 'package:arena/features_user/auth/reset_password_code_page.dart';
import 'package:arena/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _scoped() => const ProviderScope(
      child: MaterialApp(
        locale: Locale('fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: ResetPasswordCodePage(email: 'joueur@arena.app'),
      ),
    );

void main() {
  setUpAll(TestWidgetsFlutterBinding.ensureInitialized);

  Future<void> bumpViewport(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
  }

  testWidgets('rend le formulaire de vérification du code', (tester) async {
    await bumpViewport(tester);
    await tester.pumpWidget(_scoped());
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('VÉRIFICATION'), findsOneWidget);
    expect(find.text('joueur@arena.app'), findsOneWidget);
    expect(find.text('VÉRIFIER'), findsOneWidget);
  });
}
