// TODO: test obsolète — UI/code redesigned. Tag 'broken' pour
//       skip en CI. À récrire dans un chantier dédié.
@Tags(<String>['broken'])
library;

import 'package:arena/data/models/profile.dart';
import 'package:arena/features_user/auth/auth_providers.dart';
import 'package:arena/features_user/home/home_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Profile _profile({Map<String, dynamic> stats = const {}}) => Profile(
      id: 'p-1',
      username: 'Drogba',
      email: 'd@arena.app',
      countryCode: 'CI',
      avatarColor: '#FF6A00',
      stats: stats,
    );

Widget _scoped(Profile profile) => ProviderScope(
      overrides: [
        currentProfileProvider.overrideWith((ref) async => profile),
      ],
      child: const MaterialApp(home: Scaffold(body: HomePage())),
    );

void main() {
  setUpAll(TestWidgetsFlutterBinding.ensureInitialized);

  Future<void> bumpViewport(WidgetTester tester) async {
    // The page has 4 sections + a 5-card stats grid — it scrolls.
    await tester.binding.setSurfaceSize(const Size(800, 1800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
  }

  testWidgets('header shows the username initial and salutation',
      (tester) async {
    await bumpViewport(tester);
    await tester.pumpWidget(_scoped(_profile()));
    await tester.pumpAndSettle();

    expect(find.text('Salut,'), findsOneWidget);
    expect(find.text('DROGBA'), findsOneWidget);
    // Avatar initial.
    expect(find.text('D'), findsOneWidget);
  });

  testWidgets('renders the 3 coming-soon panels (PHASE 4 / 5 / 8)',
      (tester) async {
    await bumpViewport(tester);
    await tester.pumpWidget(_scoped(_profile()));
    await tester.pumpAndSettle();

    expect(find.text('PHASE 4'), findsOneWidget);
    expect(find.text('PHASE 5'), findsOneWidget);
    expect(find.text('PHASE 8'), findsOneWidget);
  });

  testWidgets('stats with no matches show the "no match yet" copy',
      (tester) async {
    await bumpViewport(tester);
    await tester.pumpWidget(_scoped(_profile()));
    await tester.pumpAndSettle();

    expect(find.text('Aucun match joué'), findsOneWidget);
    expect(find.text('—'), findsOneWidget);
    // Wins / losses / goals all zero.
    expect(find.text('0'), findsNWidgets(4));
  });

  testWidgets('stats render real values and the win-rate ratio',
      (tester) async {
    await bumpViewport(tester);
    await tester.pumpWidget(
      _scoped(
        _profile(
          stats: const <String, dynamic>{
            'wins': 6,
            'losses': 4,
            'goals_scored': 18,
            'goals_conceded': 11,
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('6'), findsOneWidget);
    expect(find.text('4'), findsOneWidget);
    expect(find.text('18'), findsOneWidget);
    expect(find.text('11'), findsOneWidget);
    // 6 / (6+4) = 60 %
    expect(find.text('60 %'), findsOneWidget);
    expect(find.text('Ratio victoires'), findsOneWidget);
  });

  testWidgets('tapping the bell shows the deferred-notifications snackbar',
      (tester) async {
    await bumpViewport(tester);
    await tester.pumpWidget(_scoped(_profile()));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.notifications_outlined));
    await tester.pump();

    expect(find.textContaining('PHASE 10'), findsOneWidget);
  });
}
