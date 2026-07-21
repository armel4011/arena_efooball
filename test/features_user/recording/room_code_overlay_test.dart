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
        'roomCode reçu (AWAY) replié : PAS de pastille permanente du code',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RecordingOverlayButton(
              tick: const OverlayTick(
                elapsedSeconds: 5,
                isWarning: false,
                roomCode: 'ABC12',
              ),
              onSubmitCode: (_) {},
              onFieldFocusChange: (_) async {},
            ),
          ),
        ),
      );

      // Nouveau design : le code n'est plus une pastille toujours visible ; il
      // ne s'affiche que dans la carte ouverte par la clé (cf. test suivant).
      expect(find.text('ABC12'), findsNothing);
      expect(find.text('CODE SALLE'), findsNothing);
    });

    testWidgets(
        'roomCode reçu (AWAY) + saisie ouverte → champ LECTURE SEULE avec le code',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RecordingOverlayButton(
              tick: const OverlayTick(
                elapsedSeconds: 5,
                isWarning: false,
                isCodeEntry: true,
                roomCode: 'ABC12',
              ),
              onSubmitCode: (_) {},
              onFieldFocusChange: (_) async {},
            ),
          ),
        ),
      );
      await tester.pump();

      // Même carte que le HOME, mais lecture seule : titre « Code reçu de
      // l'hôte », pas d'ENVOYER, juste Fermer ; le code est dans le champ.
      expect(find.text("Code reçu de l'hôte"), findsOneWidget);
      expect(find.text('ENVOYER'), findsNothing);
      expect(find.text('Fermer'), findsOneWidget);
      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.readOnly, isTrue);
      expect(field.controller?.text, 'ABC12');
    });
  });

  group('ScoreEntryField (pénaltys)', () {
    Widget wrap({required bool allowPenalties}) => MaterialApp(
          home: Scaffold(
            body: ScoreEntryField(
              allowPenalties: allowPenalties,
              timerLabel: '00:10',
              onSubmit: (_, __, ___, ____, _____) {},
              onFocusChange: (_) async {},
              onClose: () {},
            ),
          ),
        );

    testWidgets('KO + score à égalité → le volet tirs au but apparaît',
        (tester) async {
      await tester.pumpWidget(wrap(allowPenalties: true));
      // Pas d'égalité encore → pas de volet.
      expect(find.text('Décidé aux tirs au but'), findsNothing);
      final fields = find.byType(TextField);
      await tester.enterText(fields.at(0), '2');
      await tester.enterText(fields.at(1), '2');
      await tester.pump();
      // Égalité 2-2 en KO → le volet pénaltys s'affiche.
      expect(find.text('Décidé aux tirs au but'), findsOneWidget);
    });

    testWidgets(
        'poule (allowPenalties=false) → jamais de volet, même à égalité',
        (tester) async {
      await tester.pumpWidget(wrap(allowPenalties: false));
      final fields = find.byType(TextField);
      await tester.enterText(fields.at(0), '1');
      await tester.enterText(fields.at(1), '1');
      await tester.pump();
      expect(find.text('Décidé aux tirs au but'), findsNothing);
    });

    testWidgets(
        'tirs au but égaux → Valider DÉSACTIVÉ (onSubmit non appelé), '
        'puis réactivé si corrigés', (tester) async {
      var submitted = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ScoreEntryField(
              allowPenalties: true,
              timerLabel: '00:10',
              onSubmit: (_, __, ___, ____, _____) => submitted = true,
              onFocusChange: (_) async {},
              onClose: () {},
            ),
          ),
        ),
      );
      await tester.enterText(find.byType(TextField).at(0), '2');
      await tester.enterText(find.byType(TextField).at(1), '2');
      await tester.pump();
      await tester.tap(find.text('Décidé aux tirs au but'));
      await tester.pump();
      // TAB égaux → invalide → Valider ignoré.
      await tester.enterText(find.byType(TextField).at(2), '3');
      await tester.enterText(find.byType(TextField).at(3), '3');
      await tester.pump();
      await tester.tap(find.text('VALIDER'));
      await tester.pump();
      expect(submitted, isFalse);
      // Corrigés → Valider actif.
      await tester.enterText(find.byType(TextField).at(3), '4');
      await tester.pump();
      await tester.tap(find.text('VALIDER'));
      await tester.pump();
      expect(submitted, isTrue);
    });
  });
}
