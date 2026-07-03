import 'package:arena/features_user/recording/overlay/recording_overlay.dart';
import 'package:arena/features_user/recording/overlay/recording_overlay_messages.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('overlayModeFromMessage', () {
    test('mode_code_sender → codeSender', () {
      expect(
        overlayModeFromMessage(RecordingOverlayMessages.modeCodeSender()),
        OverlayMode.codeSender,
      );
    });

    test('mode_recording → recording', () {
      expect(
        overlayModeFromMessage(RecordingOverlayMessages.modeRecording()),
        OverlayMode.recording,
      );
    });

    test('tick / warn / paused impliquent recording (rétro-compat)', () {
      for (final type in [
        RecordingOverlayMessages.tickType,
        RecordingOverlayMessages.warnType,
        RecordingOverlayMessages.pausedType,
      ]) {
        expect(
          overlayModeFromMessage({'type': type, 'elapsed': 1}),
          OverlayMode.recording,
          reason: type,
        );
      }
    });

    test('null pour un type inconnu ou un non-Map', () {
      expect(overlayModeFromMessage({'type': 'bogus'}), isNull);
      expect(overlayModeFromMessage('ask_pause'), isNull);
      expect(overlayModeFromMessage(null), isNull);
    });
  });

  group('roomCodeFromMessage', () {
    test("extrait le code d'un submit_room_code", () {
      expect(
        roomCodeFromMessage(RecordingOverlayMessages.submitRoomCode('ABC123')),
        'ABC123',
      );
    });

    test('null pour un autre type / non-Map / code non-String', () {
      expect(
        roomCodeFromMessage(RecordingOverlayMessages.modeRecording()),
        isNull,
      );
      expect(roomCodeFromMessage('submit_room_code'), isNull);
      expect(
        roomCodeFromMessage(
          {'type': RecordingOverlayMessages.submitRoomCodeType, 'code': 42},
        ),
        isNull,
      );
    });
  });

  group('RoomCodeOverlayPanel', () {
    Future<void> pump(
      WidgetTester tester, {
      required void Function(String) onSubmit,
      // ignore: avoid_positional_boolean_parameters
      Future<void> Function(bool)? onFocusChange,
    }) {
      return tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RoomCodeOverlayPanel(
              onSubmit: onSubmit,
              onFocusChange: onFocusChange ?? (_) async {},
            ),
          ),
        ),
      );
    }

    testWidgets('code valide → onSubmit en MAJUSCULES + badge « Envoyé »',
        (tester) async {
      String? sent;
      await pump(tester, onSubmit: (c) => sent = c);

      await tester.enterText(find.byType(TextField), '  abc12 ');
      await tester.tap(find.text('ENVOYER'));
      await tester.pump();

      expect(sent, 'ABC12');
      expect(find.text('Envoyé : ABC12'), findsOneWidget);
    });

    testWidgets("code trop court → onSubmit NON appelé + message d'erreur",
        (tester) async {
      var calls = 0;
      await pump(tester, onSubmit: (_) => calls++);

      await tester.enterText(find.byType(TextField), 'ab');
      await tester.tap(find.text('ENVOYER'));
      await tester.pump();

      expect(calls, 0);
      expect(find.textContaining('4 à 12'), findsOneWidget);
    });

    testWidgets('le focus du champ déclenche onFocusChange(true)',
        (tester) async {
      final focusEvents = <bool>[];
      await pump(
        tester,
        onSubmit: (_) {},
        onFocusChange: (f) async => focusEvents.add(f),
      );

      await tester.tap(find.byType(TextField));
      await tester.pump();

      expect(focusEvents, contains(true));
    });
  });

  group('RecordingOverlayButton (saisie inline du code)', () {
    testWidgets(
        'isCodeEntry:true → rend le champ + chrono ; submit → onSubmitCode',
        (tester) async {
      String? sent;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RecordingOverlayButton(
              tick: const OverlayTick(
                elapsedSeconds: 65,
                isWarning: false,
                isCodeEntry: true,
              ),
              onSubmitCode: (c) => sent = c,
              onFieldFocusChange: (_) async {},
            ),
          ),
        ),
      );

      // Chrono en tête + champ de saisie visible.
      expect(find.text('01:05'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'xyz99');
      await tester.tap(find.text('ENVOYER'));
      await tester.pump();

      expect(sent, 'XYZ99');
    });

    testWidgets('isCodeEntry:false → bouton chrono, pas de champ',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RecordingOverlayButton(
              tick: const OverlayTick(elapsedSeconds: 3, isWarning: false),
              onSubmitCode: (_) {},
              onFieldFocusChange: (_) async {},
            ),
          ),
        ),
      );

      expect(find.byType(TextField), findsNothing);
      expect(find.text('00:03'), findsOneWidget);
    });

    testWidgets(
        'isCodeView:true (AWAY) → affiche le code en lecture seule, pas de champ',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RecordingOverlayButton(
              tick: const OverlayTick(
                elapsedSeconds: 3,
                isWarning: false,
                isCodeView: true,
                roomCode: 'ROOM77',
                canSendCode: false,
              ),
              onSubmitCode: (_) {},
              onFieldFocusChange: (_) async {},
            ),
          ),
        ),
      );

      expect(find.text('ROOM77'), findsOneWidget);
      expect(find.textContaining('Recopie'), findsOneWidget);
      // Lecture seule : ni champ de saisie ni bouton Copier.
      expect(find.byType(TextField), findsNothing);
      expect(find.text('COPIER'), findsNothing);
    });
  });
}
