// Tests UI — AdminDisputesListPage (file des litiges ouverts).
//
// Liste les litiges `open`/`escalated` via adminOpenDisputesProvider (polling).
// On override le StreamProvider pour rendre la page sans backend : état vide +
// tuile de litige. (E1 audit 2026-06-24 — disputes_admin 0 test UI.)

import 'package:arena/data/models/dispute.dart';
import 'package:arena/data/repositories/admin/admin_disputes_repository.dart';
import 'package:arena/features_admin/disputes_admin/admin_disputes_list_page.dart';
import 'package:arena/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _scoped(List<Dispute> disputes) {
  return ProviderScope(
    overrides: [
      adminOpenDisputesProvider.overrideWith((ref) => Stream.value(disputes)),
    ],
    child: const MaterialApp(
      locale: Locale('fr'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: AdminDisputesListPage(),
    ),
  );
}

void main() {
  setUpAll(TestWidgetsFlutterBinding.ensureInitialized);

  Future<void> bumpViewport(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(900, 2000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
  }

  testWidgets('liste vide : titre + état « Aucun litige ouvert »',
      (tester) async {
    await bumpViewport(tester);
    await tester.pumpWidget(_scoped(const []));
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('LITIGES'), findsOneWidget);
    expect(find.text('Aucun litige ouvert.'), findsOneWidget);
  });

  testWidgets('avec données : une tuile par litige (réf. match courte)',
      (tester) async {
    await bumpViewport(tester);
    await tester.pumpWidget(
      _scoped(const [
        Dispute(id: 'd1', matchId: 'abcdef123456', openedBy: 'u1'),
      ]),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.textContaining('M-ABCDEF'), findsOneWidget);
  });
}
