// Couvre WizardStepCountry — l'étape « Pays » du wizard de compétition
// (pays organisateur + éditeur d'options de paiement). StatelessWidget pur ;
// pas de Supabase. Vérifie le rendu conditionnel gratuit vs payant.

import 'package:arena/features_admin/competitions_admin/widgets/wizard_step_country.dart';
import 'package:arena/features_shared/payment_option_draft.dart';
import 'package:arena/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    locale: const Locale('fr'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: ListView(children: [child])),
  );
}

WizardStepCountry _step({
  required bool isPaid,
  required List<PaymentDraftCountry> countries,
}) {
  return WizardStepCountry(
    organizerCountry: 'CM',
    onOrganizerChanged: (_) {},
    isPaid: isPaid,
    loading: false,
    countries: countries,
    operatorTemplateCount: 0,
    onAddCountry: () {},
    onRemoveCountry: (_) {},
    onCountryCodeChanged: (_, __) {},
    onAddOperator: (_) {},
    onRemoveOperator: (_, __) {},
    onSaveOperator: (_, __) {},
    onOpenOperatorTemplates: (_) {},
    onChanged: () {},
  );
}

void main() {
  testWidgets("gratuite → note, pas d'éditeur de paiement", (tester) async {
    await tester.binding.setSurfaceSize(const Size(900, 2000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      _wrap(_step(isPaid: false, countries: const [])),
    );
    await tester.pump();

    final l10n = await AppLocalizations.delegate.load(const Locale('fr'));
    expect(tester.takeException(), isNull);
    expect(find.text(l10n.countryOrganizerLabel), findsOneWidget);
    expect(find.text(l10n.countryFreeNote), findsOneWidget);
    // Pas de section « options de paiement » en gratuit.
    expect(find.text(l10n.countryPaymentSectionTitle), findsNothing);
  });

  testWidgets("payante → éditeur d'options de paiement visible",
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(900, 2000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final countries = [PaymentDraftCountry(countryCode: 'CM')];
    addTearDown(() {
      for (final c in countries) {
        c.dispose();
      }
    });

    await tester.pumpWidget(
      _wrap(_step(isPaid: true, countries: countries)),
    );
    await tester.pump();

    final l10n = await AppLocalizations.delegate.load(const Locale('fr'));
    expect(tester.takeException(), isNull);
    expect(find.text(l10n.countryPaymentSectionTitle), findsOneWidget);
    expect(find.text(l10n.countryOperatorNameLabel), findsOneWidget);
  });
}
