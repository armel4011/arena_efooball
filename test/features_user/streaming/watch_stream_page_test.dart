// Tests UI — WatchStreamPage (viewer Agora plein écran).
//
// ConsumerStatefulWidget : `agoraStreamingServiceProvider`. On le remplace par
// un mock dont `joinAsAudience` ne se résout jamais → la page reste sur son
// _LoadingLayer (spinner) sans toucher au natif Agora. Couvre le rendu initial
// « connexion en cours ».

import 'dart:async';

import 'package:arena/core/services/agora_streaming_service.dart';
import 'package:arena/features_user/streaming/watch_stream_page.dart';
import 'package:arena/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockAgora extends Mock implements AgoraStreamingService {}

void main() {
  setUpAll(TestWidgetsFlutterBinding.ensureInitialized);

  Future<void> bumpViewport(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
  }

  testWidgets('rendu initial → spinner pendant la connexion', (tester) async {
    final mock = _MockAgora();
    when(() => mock.stateStream)
        .thenAnswer((_) => const Stream<AgoraSessionState>.empty());
    when(() => mock.joinAsAudience(matchId: any(named: 'matchId')))
        // Ne se résout jamais → _hasJoined reste false → _LoadingLayer.
        .thenAnswer((_) => Completer<void>().future);
    when(mock.leave).thenAnswer((_) async {});

    await bumpViewport(tester);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          agoraStreamingServiceProvider.overrideWithValue(mock),
        ],
        child: const MaterialApp(
          locale: Locale('fr'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: WatchStreamPage(matchId: 'match-0001'),
        ),
      ),
    );
    // Un pump pour exécuter le postFrameCallback (_join) ; pas de pumpAndSettle
    // car le spinner anime à l'infini.
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
