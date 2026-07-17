// Tests UI — MatchLockedView : le rebours doit suivre l'horaire quand celui-ci
// change SOUS le widget. Le parent le reconstruit à chaque tick du stream
// realtime du match, sans jamais le démonter : l'horaire peut apparaître (round
// précédent terminé), changer (reprogrammation admin) ou disparaître.
//
// Deux précautions de banc d'essai :
//  * `opensAt` est piloté par un ValueNotifier DANS un ProviderScope monté une
//    seule fois — un second `pumpWidget` recréerait le scope et les providers,
//    et remonterait le widget (initState), donc ne testerait PAS didUpdateWidget.
//  * on n'assert JAMAIS que le texte du rebours décroît : `tester.pump(1s)`
//    avance l'horloge fake, alors que `_formatCountdown` lit `DateTime.now()`
//    réel — le texte est figé par construction. La vie du ticker s'observe sur
//    son effet réel : l'invalidation de `matchByIdProvider` à l'ouverture.
//
// `matchGameTypeProvider` reste en chargement perpétuel : le bloc « règles +
// vidéo » se rend alors vide, ce qui isole le rebours sans monter le repo des
// règles ni le stream des bannières tuto.

import 'dart:async';

import 'package:arena/data/models/arena_match.dart';
import 'package:arena/data/models/competition_enums.dart';
import 'package:arena/data/repositories/match_repository.dart';
import 'package:arena/features_user/match_room/match_room_providers.dart';
import 'package:arena/features_user/match_room/widgets/match_locked_view.dart';
import 'package:arena/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Le rebours est le seul texte au format mm:ss / hh:mm:ss de l'écran.
String? _countdown(WidgetTester tester) {
  final re = RegExp(r'^(\d{2}:)?\d{2}:\d{2}$');
  final found = tester
      .widgetList<Text>(find.byType(Text))
      .map((t) => t.data)
      .whereType<String>()
      .where(re.hasMatch);
  return found.isEmpty ? null : found.first;
}

/// Garde `matchByIdProvider` vivant : sans écouteur, `ref.invalidate` sur un
/// provider jamais lu ne recrée rien et le compteur resterait muet.
class _Watcher extends ConsumerWidget {
  const _Watcher();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(matchByIdProvider('m-1'));
    return const SizedBox.shrink();
  }
}

void main() {
  setUpAll(TestWidgetsFlutterBinding.ensureInitialized);

  /// Monte l'écran une fois ; le notifier rendu permet de faire varier
  /// `opensAt` in-place. `creations` compte les (re)créations du stream match.
  Future<ValueNotifier<DateTime?>> mount(
    WidgetTester tester, {
    required DateTime? opensAt,
    List<int>? creations,
  }) async {
    await tester.binding.setSurfaceSize(const Size(800, 1800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final notifier = ValueNotifier<DateTime?>(opensAt);
    addTearDown(notifier.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          matchGameTypeProvider.overrideWith(
            (ref, matchId) => Completer<GameType>().future,
          ),
          matchByIdProvider.overrideWith((ref, matchId) {
            if (creations != null) creations[0]++;
            return const Stream<ArenaMatch?>.empty();
          }),
        ],
        child: MaterialApp(
          locale: const Locale('fr'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Column(
              children: [
                const _Watcher(),
                Expanded(
                  child: ValueListenableBuilder<DateTime?>(
                    valueListenable: notifier,
                    builder: (context, value, _) => MatchLockedView(
                      matchId: 'm-1',
                      scheduledAt: value,
                      opensAt: value,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    return notifier;
  }

  testWidgets("sans horaire → message d'attente, aucun rebours",
      (tester) async {
    await mount(tester, opensAt: null);
    expect(_countdown(tester), isNull);
    expect(find.text('Horaire à venir'), findsOneWidget);
  });

  testWidgets('horaire posé après le montage (null → valeur) → un rebours vivant',
      (tester) async {
    final creations = [0];
    // Monté SANS horaire : le round suivant n'est pas encore programmé.
    final opensAt = await mount(tester, opensAt: null, creations: creations);
    expect(_countdown(tester), isNull);

    final baseline = creations[0];

    // Le round précédent se termine : l'horaire arrive par le stream realtime.
    // Il est déjà atteint (cas réel d'un round posé à maintenant+5min vu après
    // coup) → au premier tick le ticker doit déverrouiller l'accès.
    opensAt.value = DateTime.now().subtract(const Duration(seconds: 1));
    await tester.pump();

    // Le rebours s'affiche, borné à 0.
    expect(_countdown(tester), '00:00');

    // ...et il VIT : sans didUpdateWidget aucun Timer n'est posé, donc rien
    // n'invalide jamais le match et le joueur reste bloqué sur cet écran.
    await tester.pump(const Duration(seconds: 1));
    expect(
      creations[0],
      greaterThan(baseline),
      reason: "le ticker doit invalider matchByIdProvider à l'ouverture",
    );
  });

  testWidgets('horaire reprogrammé (valeur → autre valeur) → le rebours suit',
      (tester) async {
    final opensAt =
        await mount(tester, opensAt: DateTime.now().add(const Duration(minutes: 10)));
    expect(_countdown(tester), startsWith('09:'));

    // L'admin repousse le match : le rebours repart du nouvel horaire.
    opensAt.value = DateTime.now().add(const Duration(hours: 3));
    await tester.pump();
    expect(_countdown(tester), startsWith('02:5'));

    opensAt.value = null; // purge le ticker avant la fin du test
    await tester.pump();
  });

  testWidgets('horaire retiré (valeur → null) → rebours arrêté, sans crash',
      (tester) async {
    final opensAt =
        await mount(tester, opensAt: DateTime.now().add(const Duration(minutes: 10)));
    expect(_countdown(tester), isNotNull);

    opensAt.value = null;
    await tester.pump();
    expect(_countdown(tester), isNull);

    // Un ticker survivant déréférencerait `widget.opensAt!` devenu null.
    await tester.pump(const Duration(seconds: 2));
    expect(tester.takeException(), isNull);
  });
}
