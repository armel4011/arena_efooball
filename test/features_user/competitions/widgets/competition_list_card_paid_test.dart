import 'package:arena/data/models/competition.dart';
import 'package:arena/data/models/competition_enums.dart';
import 'package:arena/features_user/competitions/widgets/competition_list_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await initializeDateFormatting('fr');
  });

  testWidgets('paid competition card renders without layout crash',
      (tester) async {
    // Regression : `CrossAxisAlignment.stretch` dans `_PriceFooter` sans
    // `IntrinsicHeight` faisait crasher silencieusement la card en
    // production (BoxConstraints forces an infinite height), si bien
    // qu'aucune compet. payante n'apparaissait dans la liste.
    await tester.binding.setSurfaceSize(const Size(400, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final paid = Competition(
      id: 'p-1',
      name: 'Tournoi du weekend',
      game: GameType.efootball,
      format: TournamentFormat.singleElimination,
      startDate: DateTime(2026, 6, 1, 11),
      status: CompetitionStatus.registrationOpen,
      maxPlayers: 64,
      currentPlayers: 0,
      registrationFee: 5000,
      registrationCurrency: 'XAF',
      prizePoolLocal: 240000,
      prizePoolCurrency: 'XAF',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: CompetitionListCard(
              competition: paid,
              isRegistered: false,
              hasPendingPayment: false,
              onTap: () {},
              onRegister: () {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // La presence du nom suffit a prouver que la card s'est rendue
    // sans crash de layout (sinon Text n'aurait pas pu se peindre).
    // Le bandeau de titre rend le nom en MAJUSCULES (restyle premium).
    expect(find.text('TOURNOI DU WEEKEND'), findsOneWidget);
    // Le badge tier "PREMIUM" confirme que la branche payante (isPaid)
    // a bien ete rendue, ce qui n'etait pas le cas avec le bug de layout.
    expect(find.textContaining('PREMIUM'), findsOneWidget);
    expect(find.textContaining('GAGNER'), findsWidgets);
    // Pas d'exception de layout au pump (le matcher integre de Flutter
    // throw sinon).
    expect(tester.takeException(), isNull);
  });
}
