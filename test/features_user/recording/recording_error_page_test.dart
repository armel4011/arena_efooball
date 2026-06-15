// Tests UI — RecordingErrorPage (écran #18 : enregistrement bloqué).
//
// StatelessWidget d'affichage avec 3 callbacks injectables (retry / forfeit /
// support). On vérifie le rendu (headline + cause + CTAs), l'injection de la
// cause dans la carte danger, et le câblage des boutons retry / forfeit.

import 'package:arena/features_shared/widgets/arena_button.dart';
import 'package:arena/features_user/recording/recording_error_page.dart';
import 'package:arena/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _scoped(Widget child) => MaterialApp(
      locale: const Locale('fr'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: child,
    );

void main() {
  setUpAll(TestWidgetsFlutterBinding.ensureInitialized);

  Future<void> bumpViewport(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
  }

  testWidgets('se construit et affiche le headline + la cause injectée',
      (tester) async {
    await bumpViewport(tester);
    await tester.pumpWidget(
      _scoped(const RecordingErrorPage(cause: 'FOREGROUND_SERVICE')),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('RECORDING IMPOSSIBLE'), findsOneWidget);
    // La cause passée en paramètre s'affiche dans la carte danger (RichText
    // multi-spans → findRichText pour traverser les TextSpan).
    expect(
      find.textContaining('FOREGROUND_SERVICE', findRichText: true),
      findsOneWidget,
    );
  });

  testWidgets('tap RÉESSAYER déclenche onRetry', (tester) async {
    await bumpViewport(tester);
    var retried = false;
    await tester.pumpWidget(
      _scoped(RecordingErrorPage(onRetry: () => retried = true)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('↻ RÉESSAYER'));
    await tester.pumpAndSettle();
    expect(retried, isTrue);
  });

  testWidgets('tap FORFAIT déclenche onForfeit', (tester) async {
    await bumpViewport(tester);
    var forfeited = false;
    await tester.pumpWidget(
      _scoped(RecordingErrorPage(onForfeit: () => forfeited = true)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('🏳 FORFAIT (perdre)'));
    await tester.pumpAndSettle();
    expect(forfeited, isTrue);
    // Deux ArenaButton : réessayer + forfait.
    expect(find.byType(ArenaButton), findsNWidgets(2));
  });
}
