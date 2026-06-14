// Tests UI du flux ARGENT — P1 : choix du moyen de paiement.
//
// PaymentMethodPickerPage est l'entrée du flux d'inscription payante.
// C'est un StatefulWidget auto-contenu (pas de Riverpod / Supabase) : il
// reçoit le montant + un callback `onConfirm(PaymentMethod)`. On vérifie le
// rendu des deux moyens (MTN / Orange), la sélection par défaut, le changement
// de sélection, et que `onConfirm` renvoie bien le moyen choisi.
//
// On cible les tuiles via leur badge stable ('MTN' / 'OM') plutôt que via les
// libellés localisés, pour ne pas coupler le test aux strings l10n.

import 'package:arena/features_shared/widgets/arena_button.dart';
import 'package:arena/features_user/payments/payment_method.dart';
import 'package:arena/features_user/payments/payment_method_picker_page.dart';
import 'package:arena/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _scoped({
  int amountXaf = 1500,
  String contextLabel = 'Coupe ARENA',
  ValueChanged<PaymentMethod>? onConfirm,
}) {
  return MaterialApp(
    locale: const Locale('fr'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: PaymentMethodPickerPage(
      amountXaf: amountXaf,
      contextLabel: contextLabel,
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

  testWidgets('affiche les deux moyens Mobile Money + le montant formaté',
      (tester) async {
    await bumpViewport(tester);
    await tester.pumpWidget(_scoped(amountXaf: 1500));
    await tester.pumpAndSettle();

    // Les deux badges de moyen de paiement sont rendus.
    expect(find.text('MTN'), findsOneWidget);
    expect(find.text('OM'), findsOneWidget);
    expect(find.byType(PaymentMethodLogo), findsNWidgets(2));

    // Le montant est affiché avec séparateur de milliers : 1500 → "1 500".
    expect(find.text('1 500'), findsOneWidget);

    // Un unique bouton de validation.
    expect(find.byType(ArenaButton), findsOneWidget);
  });

  testWidgets('sélection par défaut = MTN MoMo (une seule coche visible)',
      (tester) async {
    await bumpViewport(tester);
    await tester.pumpWidget(_scoped());
    await tester.pumpAndSettle();

    // Seule la tuile sélectionnée affiche l'icône check.
    expect(find.byIcon(Icons.check), findsOneWidget);
  });

  testWidgets('confirme MTN MoMo par défaut (sans interaction)',
      (tester) async {
    await bumpViewport(tester);
    PaymentMethod? confirmed;
    await tester.pumpWidget(_scoped(onConfirm: (m) => confirmed = m));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(ArenaButton));
    await tester.pumpAndSettle();

    expect(confirmed, PaymentMethod.mtnMoMo);
  });

  testWidgets('sélectionner Orange puis confirmer renvoie orangeMoney',
      (tester) async {
    await bumpViewport(tester);
    PaymentMethod? confirmed;
    await tester.pumpWidget(_scoped(onConfirm: (m) => confirmed = m));
    await tester.pumpAndSettle();

    // Tape la tuile Orange (le badge 'OM' est descendant de l'InkWell tapable).
    await tester.tap(find.text('OM'));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(ArenaButton));
    await tester.pumpAndSettle();

    expect(confirmed, PaymentMethod.orangeMoney);
  });
}
