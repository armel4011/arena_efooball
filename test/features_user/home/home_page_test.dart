// Smoke tests de la HomePage v2 (PHASE 3 → wave 1 polish).
//
// La page consomme `currentProfileProvider` + plusieurs streams temps
// réel (matches, lives, comps, pending payments). On override le
// profil et on accepte que les autres providers tombent dans leur
// fallback (loading → empty) côté UI — la HomePage gère ces états sans
// crash. On vérifie juste que les section headers v2 sont rendus.

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
    // La home v2 a 4 sections empilées dans un ListView, scrollable.
    await tester.binding.setSurfaceSize(const Size(800, 2000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
  }

  testWidgets('renders all 4 main section headers', (tester) async {
    await bumpViewport(tester);
    await tester.pumpWidget(_scoped(_profile()));
    // `pumpAndSettle` boucle à l'infini parce que la card LIVE pulse
    // sans fin (animation continue). Un pump simple suffit pour valider
    // le rendu initial.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('⚡ Prochains matchs'), findsOneWidget);
    expect(find.text('🔴 Lives en cours'), findsOneWidget);
    expect(find.text('🏆 Compétitions actives'), findsOneWidget);
  });

  testWidgets('header surfaces the username', (tester) async {
    await bumpViewport(tester);
    await tester.pumpWidget(_scoped(_profile()));
    // `pumpAndSettle` boucle à l'infini parce que la card LIVE pulse
    // sans fin (animation continue). Un pump simple suffit pour valider
    // le rendu initial.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    // Le pseudo apparaît dans le header v2 (textuel — pas d'uppercase).
    expect(find.text('Drogba'), findsWidgets);
  });
}
