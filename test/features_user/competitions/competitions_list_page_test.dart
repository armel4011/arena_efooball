import 'package:arena/data/models/competition.dart';
import 'package:arena/data/models/competition_enums.dart';
import 'package:arena/data/repositories/competition_repository.dart';
import 'package:arena/data/repositories/tutorial_video_repository.dart';
import 'package:arena/features_user/competitions/competitions_list_page.dart';
import 'package:arena/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

Competition _comp({
  String id = 'c-1',
  String name = 'Coupe ARENA',
  GameType game = GameType.efootball,
  CompetitionStatus status = CompetitionStatus.registrationOpen,
  int maxPlayers = 16,
  int currentPlayers = 4,
}) =>
    Competition(
      id: id,
      name: name,
      game: game,
      format: TournamentFormat.singleElimination,
      startDate: DateTime(2026, 6, 1),
      status: status,
      maxPlayers: maxPlayers,
      currentPlayers: currentPlayers,
    );

Widget _scoped(List<Competition> items) => ProviderScope(
      overrides: [
        competitionsListProvider
            .overrideWith((ref, _) => Stream<List<Competition>>.value(items)),
        // Pas de vidéo install_check → le dialogue de contrôle s'affiche sans
        // WebView (non instanciable en test).
        installCheckVideoOnceProvider.overrideWith((ref, game) => null),
      ],
      child: const MaterialApp(
        locale: Locale('fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: CompetitionsListPage()),
      ),
    );

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await initializeDateFormatting('fr');
  });

  Future<void> bumpViewport(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
  }

  testWidgets('shows a per-game empty state on the default tab',
      (tester) async {
    await bumpViewport(tester);
    await tester.pumpWidget(_scoped(const []));
    await tester.pumpAndSettle();

    // La liste est organisée en onglets — un par jeu, désormais ordonnés
    // Dames · eFootball · Mobile FC · Dream League (plus d'onglet « Tous »).
    // L'onglet par défaut (Dames) sans compétition affiche un empty state
    // dédié au jeu, et expose les filtres en chips directs (statut + tarif)
    // au lieu de l'ancien menu groupé « FILTRES ».
    expect(find.byType(TabBar), findsOneWidget);
    // 4 onglets par jeu (Dames · eFootball · Mobile FC · Dream League). Le
    // « Prochain match » vit désormais sur chaque page de compétition, plus
    // dans cette liste.
    expect(find.byType(Tab), findsNWidgets(4));
    expect(find.text('Aucune compétition sur Jeu de Dames'), findsOneWidget);
    // Chips de statut (À venir par défaut) + chip de tarif distinctif.
    expect(find.text('À venir'), findsOneWidget);
    expect(find.text('En cours'), findsOneWidget);
    expect(find.text('Terminés'), findsOneWidget);
    expect(find.text('Gratuites'), findsOneWidget);
  });

  testWidgets('renders one card per competition under the default filter',
      (tester) async {
    // Bucket statut "À venir" par défaut → ne montre que les comps en
    // registrationOpen / draft / registrationClosed. On donne 2 comps
    // sur le jeu de l'onglet par défaut (Dames) pour vérifier qu'elles
    // rendent toutes. (Le titre est rendu en MAJUSCULES — restyle premium.)
    await bumpViewport(tester);
    await tester.pumpWidget(
      _scoped([
        _comp(id: 'c-1', name: 'Coupe Cameroun', game: GameType.draughts),
        _comp(id: 'c-2', name: 'Trophée RDC', game: GameType.draughts),
      ]),
    );
    await tester.pumpAndSettle();

    expect(find.text('COUPE CAMEROUN'), findsOneWidget);
    expect(find.text('TROPHÉE RDC'), findsOneWidget);
    // Deux comps gratuites pures (fee = 0, pas de gain) → chacune affiche un
    // badge tier "GRATUIT" + un label de frais "GRATUIT" (cf. restyle #10)
    // = 4 occurrences au total.
    expect(find.text('GRATUIT'), findsNWidgets(4));
  });

  testWidgets('switching tab filters by game (empty copy follows the tab)',
      (tester) async {
    await bumpViewport(tester);
    await tester.pumpWidget(_scoped(const []));
    await tester.pumpAndSettle();

    // Le filtrage par jeu se fait désormais via les onglets : on bascule
    // sur l'onglet « eFootball » (2e onglet, ordre Dames · eFootball · Mobile FC · Dream League)
    // et l'empty state suit le jeu.
    await tester.tap(find.byType(Tab).at(1));
    await tester.pumpAndSettle();

    expect(
      find.text('Aucune compétition sur eFootball'),
      findsOneWidget,
    );
  });

  testWidgets(
      "s'inscrire depuis la carte (jeu externe) ouvre le dialogue de contrôle",
      (tester) async {
    // Régression : l'inscription depuis la CARTE de la liste contournait le
    // dialogue de contrôle d'installation (seul le CTA de la page détail
    // l'ouvrait). Le dialogue doit s'ouvrir AVANT toute navigation.
    await bumpViewport(tester);
    await tester.pumpWidget(
      _scoped([_comp(id: 'c-ef', name: 'Ligue eFoot', game: GameType.efootball)]),
    );
    await tester.pumpAndSettle();

    // Onglet eFootball (index 1 : Dames · eFootball · Mobile FC · Dream League).
    await tester.tap(find.byType(Tab).at(1));
    await tester.pumpAndSettle();

    final registerBtn = find.text("S'INSCRIRE GRATUITEMENT");
    expect(registerBtn, findsOneWidget);
    await tester.ensureVisible(registerBtn);
    await tester.tap(registerBtn);
    await tester.pumpAndSettle();

    // Le dialogue de contrôle est bien affiché (jeu externe).
    expect(find.text("Avant de t'inscrire"), findsOneWidget);
    expect(find.text('Ouvrir le store'), findsOneWidget);

    // Annuler → le dialogue se ferme, aucune navigation (pas de routeur monté).
    await tester.tap(find.text('Annuler'));
    await tester.pumpAndSettle();
    expect(find.text("Avant de t'inscrire"), findsNothing);
  });
}
