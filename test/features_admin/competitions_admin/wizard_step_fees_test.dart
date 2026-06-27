// Audit 2026-05-19 — couvre la conditional rendering de WizardStepFees
// (extrait de create_competition_page.dart 1254→787 lignes). Pas de
// mocking de Supabase — c'est un StatelessWidget pur.

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

void main() {
  group('WizardStepFees', () {
    testWidgets('fee = 0 → mode gratuit, montre le quota parrainage', (tester) async {
      final entryFee = TextEditingController(text: '0');
      final commission = TextEditingController(text: '0');
      final orange = TextEditingController();
      final mtn = TextEditingController();
      final referralQuota = TextEditingController(text: '0');

      await tester.pumpWidget(
        _wrap(
          WizardStepFees(
            entryFeeCtrl: entryFee,
            currency: 'XAF',
            commissionXafCtrl: commission,
            orangeMomoCtrl: orange,
            mtnMomoCtrl: mtn,
            referralQuotaCtrl: referralQuota,
            isEditing: false,
            savedTemplateCount: 0,
            onChanged: () {},
            onCurrencyChanged: (_) {},
            onSaveTemplate: () {},
            onOpenLibrary: () {},
          ),
        ),
      );

      expect(find.textContaining('Parrainage requis'), findsOneWidget);
      expect(find.textContaining('Codes marchands'), findsNothing);
    });

    testWidgets('fee > 0 → mode payant, montre les codes marchands', (tester) async {
      final entryFee = TextEditingController(text: '500');
      final commission = TextEditingController(text: '50');
      final orange = TextEditingController();
      final mtn = TextEditingController();
      final referralQuota = TextEditingController(text: '0');

      await tester.pumpWidget(
        _wrap(
          WizardStepFees(
            entryFeeCtrl: entryFee,
            currency: 'XAF',
            commissionXafCtrl: commission,
            orangeMomoCtrl: orange,
            mtnMomoCtrl: mtn,
            referralQuotaCtrl: referralQuota,
            isEditing: false,
            savedTemplateCount: 0,
            onChanged: () {},
            onCurrencyChanged: (_) {},
            onSaveTemplate: () {},
            onOpenLibrary: () {},
          ),
        ),
      );

      expect(find.textContaining('Codes marchands'), findsOneWidget);
      expect(find.textContaining('Parrainage requis'), findsNothing);
      expect(find.text('Code marchand Orange Money'), findsOneWidget);
      expect(find.text('Code marchand MTN MoMo'), findsOneWidget);
    });

    testWidgets('quota parrainage > 0 → affiche le mode de comptage', (tester) async {
      final entryFee = TextEditingController(text: '0');
      final commission = TextEditingController(text: '0');
      final orange = TextEditingController();
      final mtn = TextEditingController();
      final referralQuota = TextEditingController(text: '5');

      await tester.pumpWidget(
        _wrap(
          WizardStepFees(
            entryFeeCtrl: entryFee,
            currency: 'XAF',
            commissionXafCtrl: commission,
            orangeMomoCtrl: orange,
            mtnMomoCtrl: mtn,
            referralQuotaCtrl: referralQuota,
            isEditing: false,
            savedTemplateCount: 0,
            onChanged: () {},
            onCurrencyChanged: (_) {},
            onSaveTemplate: () {},
            onOpenLibrary: () {},
          ),
        ),
      );

      // Avec quota > 0, on affiche l'explication "Tout invité actif"
      // (le ModeChip de choix any/engaged a été retiré 2026-05-19).
      expect(
        find.textContaining('Tout invité actif compte'),
        findsOneWidget,
      );
    });
  });
}
