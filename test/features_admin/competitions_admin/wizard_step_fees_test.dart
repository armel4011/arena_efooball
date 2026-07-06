// Audit 2026-05-19 — couvre la conditional rendering de WizardStepFees.
// Depuis l'ajout de l'étape « Pays », les codes marchands (Orange/MTN) ont
// quitté cet écran : ils vivent dans WizardStepCountry. Ce test vérifie donc
// que l'étape Frais ne montre plus de codes marchands, quel que soit le mode.

import 'package:arena/features_admin/competitions_admin/widgets/wizard_step_fees.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    home: Scaffold(
      body: ListView(children: [child]),
    ),
  );
}

WizardStepFees _fees({
  required TextEditingController entryFee,
  required TextEditingController commission,
  required TextEditingController referralQuota,
}) {
  return WizardStepFees(
    entryFeeCtrl: entryFee,
    currency: 'XAF',
    commissionXafCtrl: commission,
    referralQuotaCtrl: referralQuota,
    isEditing: false,
    onChanged: () {},
    onCurrencyChanged: (_) {},
  );
}

void main() {
  group('WizardStepFees', () {
    testWidgets('fee = 0 → mode gratuit, montre le quota parrainage',
        (tester) async {
      await tester.pumpWidget(
        _wrap(
          _fees(
            entryFee: TextEditingController(text: '0'),
            commission: TextEditingController(text: '0'),
            referralQuota: TextEditingController(text: '0'),
          ),
        ),
      );

      expect(find.textContaining('Parrainage requis'), findsOneWidget);
      expect(find.textContaining('Codes marchands'), findsNothing);
    });

    testWidgets('fee > 0 → mode payant, PAS de codes marchands (→ étape Pays)',
        (tester) async {
      await tester.pumpWidget(
        _wrap(
          _fees(
            entryFee: TextEditingController(text: '500'),
            commission: TextEditingController(text: '50'),
            referralQuota: TextEditingController(text: '0'),
          ),
        ),
      );

      // Les codes marchands ont migré vers l'étape « Pays ».
      expect(find.textContaining('Codes marchands'), findsNothing);
      expect(find.text('Code marchand Orange Money'), findsNothing);
      expect(find.textContaining('Parrainage requis'), findsNothing);
    });

    testWidgets('quota parrainage > 0 → affiche le mode de comptage',
        (tester) async {
      await tester.pumpWidget(
        _wrap(
          _fees(
            entryFee: TextEditingController(text: '0'),
            commission: TextEditingController(text: '0'),
            referralQuota: TextEditingController(text: '5'),
          ),
        ),
      );

      expect(
        find.textContaining('Tout invité actif compte'),
        findsOneWidget,
      );
    });
  });
}
