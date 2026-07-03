// Tests UI du flux MATCH — soumission du code de room (ShareCodeForm, step 1).
//
// Le joueur "home" saisit son code eFootball ; un code valide (4-12 car., mis
// en MAJUSCULES) appelle MatchRepository.setRoomCode puis bascule sur
// l'interstitiel. Un code trop court est rejeté sans appeler le repository.

import 'dart:async';

import 'package:arena/core/services/recording_overlay_controller.dart';
import 'package:arena/data/models/arena_match.dart';
import 'package:arena/data/repositories/match_repository.dart';
import 'package:arena/features_shared/auth_common/shared_auth_providers.dart';
import 'package:arena/features_shared/widgets/arena_button.dart';
import 'package:arena/features_user/match_room/widgets/share_code_form.dart';
import 'package:arena/features_user/recording/overlay/recording_overlay_messages.dart';
import 'package:arena/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _FakeUser extends Fake implements User {
  _FakeUser(this.id);
  @override
  final String id;
}

class _FakeSession extends Fake implements Session {
  _FakeSession(this.user);
  @override
  final User user;
}

class _FakeMatchRepo extends Fake implements MatchRepository {
  int setRoomCodeCalls = 0;
  String? lastCode;
  String? lastHost;

  @override
  Future<void> setRoomCode({
    required String matchId,
    required String hostProfileId,
    required String code,
  }) async {
    setRoomCodeCalls++;
    lastCode = code;
    lastHost = hostProfileId;
  }
}

/// Plateforme overlay fake : aucune méthode plateforme réelle, avec un
/// `emit()` pour simuler un message overlay→main (soumission de code).
class _FakeOverlayPlatform implements OverlayPlatform {
  final _controller = StreamController<dynamic>.broadcast();

  void emit(dynamic event) => _controller.add(event);

  @override
  Future<bool> isPermissionGranted() async => true;

  @override
  Future<bool> requestPermission() async => true;

  @override
  Future<bool> isActive() async => false;

  @override
  Future<void> showOverlay() async {}

  @override
  Future<void> showCodeSenderOverlay() async {}

  @override
  Future<void> resizeToRecording() async {}

  @override
  Future<void> closeOverlay() async {}

  @override
  Future<void> shareData(Object data) async {}

  @override
  Stream<dynamic> get overlayListener => _controller.stream;
}

// scheduledAt == null → pas de ForfeitTimerCard (pas de timer dans le test).
ArenaMatch _match() => const ArenaMatch(
      id: 'm1',
      competitionId: 'c1',
      player1Id: 'p1',
      player2Id: 'p2',
    );

Widget _scoped({
  required _FakeMatchRepo repo,
  String selfId = 'p1',
  RecordingOverlayController? overlay,
}) {
  return ProviderScope(
    overrides: [
      currentSessionProvider
          .overrideWith((ref) => _FakeSession(_FakeUser(selfId))),
      matchRepositoryProvider.overrideWithValue(repo),
      recordingOverlayControllerProvider.overrideWithValue(
        overlay ?? RecordingOverlayController(platform: _FakeOverlayPlatform()),
      ),
    ],
    child: MaterialApp(
      locale: const Locale('fr'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: SingleChildScrollView(child: ShareCodeForm(match: _match())),
      ),
    ),
  );
}

void main() {
  setUpAll(TestWidgetsFlutterBinding.ensureInitialized);

  Future<void> bumpViewport(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
  }

  final submitButton = find.widgetWithIcon(ArenaButton, Icons.send_outlined);

  testWidgets('code valide → setRoomCode (en MAJUSCULES) + interstitiel',
      (tester) async {
    await bumpViewport(tester);
    final repo = _FakeMatchRepo();
    await tester.pumpWidget(_scoped(repo: repo));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'abcd1');
    // Pas de pumpAndSettle après submit : l'interstitiel a un spinner infini.
    await tester.tap(submitButton);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(repo.setRoomCodeCalls, 1);
    expect(repo.lastCode, 'ABCD1'); // mis en majuscules
    expect(repo.lastHost, 'p1');
    // On a basculé sur l'interstitiel → le formulaire (bouton envoi) a disparu.
    expect(submitButton, findsNothing);
  });

  testWidgets('code trop court → rejeté sans appeler setRoomCode',
      (tester) async {
    await bumpViewport(tester);
    final repo = _FakeMatchRepo();
    await tester.pumpWidget(_scoped(repo: repo));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'ab');
    await tester.tap(submitButton);
    await tester.pumpAndSettle();

    expect(repo.setRoomCodeCalls, 0);
    // Le formulaire reste affiché.
    expect(submitButton, findsOneWidget);
  });

  testWidgets('bouton flottant : code reçu via overlay → setRoomCode',
      (tester) async {
    await bumpViewport(tester);
    final repo = _FakeMatchRepo();
    final platform = _FakeOverlayPlatform();
    final overlay = RecordingOverlayController(platform: platform);
    await tester.pumpWidget(_scoped(repo: repo, overlay: overlay));
    await tester.pump();

    // Tap le CTA overlay (icône open_in_new, distinct du bouton d'envoi).
    await tester.tap(find.widgetWithIcon(ArenaButton, Icons.open_in_new));
    await tester.pump();
    await tester.pump();

    // L'overlay renvoie un code tapé par le joueur.
    platform.emit(RecordingOverlayMessages.submitRoomCode('WXYZ9'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(repo.setRoomCodeCalls, 1);
    expect(repo.lastCode, 'WXYZ9');
    expect(repo.lastHost, 'p1');
    // Bascule sur l'interstitiel → le bouton d'envoi in-app a disparu.
    expect(submitButton, findsNothing);

    // Cleanup en zone async RÉELLE : dispose ferme le ReceivePort
    // (IsolateNameServer), primitive isolate que le fake-async de
    // testWidgets ne résout pas. Le contrôleur n'est pas auto-disposé
    // (injecté via overrideWithValue).
    await tester.runAsync(overlay.dispose);
  });
}
