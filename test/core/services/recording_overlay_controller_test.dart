import 'dart:async';

import 'package:arena/core/services/recording_overlay_controller.dart';
import 'package:arena/features_user/recording/overlay/recording_overlay_messages.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeOverlayPlatform implements OverlayPlatform {
  bool granted = true;
  bool requestResult = true;
  bool overlayShown = false;
  bool codeSenderShown = false;
  bool resizedToRecording = false;
  bool resizedToCodeEntry = false;
  int showOverlayCount = 0;
  Object? lastSharedData;
  final sharedData = <Object>[];
  final _controller = StreamController<dynamic>.broadcast();

  void emit(dynamic event) => _controller.add(event);

  @override
  Future<bool> isPermissionGranted() async => granted;

  @override
  Future<bool> requestPermission() async => requestResult;

  @override
  Future<bool> isActive() async => overlayShown;

  @override
  Future<void> showOverlay() async {
    overlayShown = true;
    showOverlayCount++;
  }

  @override
  Future<void> showCodeSenderOverlay() async {
    overlayShown = true;
    codeSenderShown = true;
  }

  @override
  Future<void> resizeToRecording() async {
    resizedToRecording = true;
  }

  @override
  Future<void> resizeToCodeEntry() async {
    resizedToCodeEntry = true;
  }

  bool movedToTop = false;

  @override
  Future<void> moveToTop() async {
    movedToTop = true;
  }

  @override
  Future<void> closeOverlay() async {
    overlayShown = false;
  }

  @override
  Future<void> shareData(Object data) async {
    lastSharedData = data;
    sharedData.add(data);
  }

  @override
  Stream<dynamic> get overlayListener => _controller.stream;
}

void main() {
  late _FakeOverlayPlatform platform;
  late RecordingOverlayController controller;

  setUp(() {
    platform = _FakeOverlayPlatform();
    controller = RecordingOverlayController(platform: platform);
  });

  tearDown(() async {
    await controller.dispose();
  });

  test('start() shows overlay when permission already granted', () async {
    await controller.start();
    expect(platform.overlayShown, isTrue);
  });

  test('start() requests permission when missing and shows on grant', () async {
    platform
      ..granted = false
      ..requestResult = true;
    await controller.start();
    expect(platform.overlayShown, isTrue);
  });

  test('start() does not show overlay when permission denied', () async {
    platform
      ..granted = false
      ..requestResult = false;
    await controller.start();
    expect(platform.overlayShown, isFalse);
  });

  test('stop() closes overlay', () async {
    await controller.start();
    expect(platform.overlayShown, isTrue);
    await controller.stop();
    expect(platform.overlayShown, isFalse);
  });

  test('emits OverlayAction.pause when overlay broadcasts ask_pause', () async {
    await controller.start();

    final next = controller.actions.first;
    platform.emit(RecordingOverlayMessages.askPauseType);
    expect(await next, OverlayAction.pause);
  });

  test('emits OverlayAction.forfeit on ask_forfeit', () async {
    await controller.start();
    final next = controller.actions.first;
    platform.emit(RecordingOverlayMessages.askForfeitType);
    expect(await next, OverlayAction.forfeit);
  });

  test('emits OverlayAction.unknown on bogus payload', () async {
    await controller.start();
    final next = controller.actions.first;
    platform.emit('not_a_known_type');
    expect(await next, OverlayAction.unknown);
  });

  group('code-sender', () {
    test('showAsCodeSender affiche le panneau + pousse mode_code_sender',
        () async {
      final ok = await controller.showAsCodeSender();
      expect(ok, isTrue);
      expect(platform.codeSenderShown, isTrue);
      expect(controller.isShowing, isTrue);
      expect(
        platform.sharedData.any(
          (d) =>
              d is Map &&
              d['type'] == RecordingOverlayMessages.modeCodeSenderType,
        ),
        isTrue,
      );
    });

    test('showAsCodeSender renvoie false si permission refusée', () async {
      platform
        ..granted = false
        ..requestResult = false;
      final ok = await controller.showAsCodeSender();
      expect(ok, isFalse);
      expect(platform.codeSenderShown, isFalse);
      expect(controller.isShowing, isFalse);
    });

    test("roomCodeSubmissions émet le code d'un submit_room_code", () async {
      await controller.showAsCodeSender();
      final next = controller.roomCodeSubmissions.first;
      platform.emit(RecordingOverlayMessages.submitRoomCode('ABC123'));
      expect(await next, 'ABC123');
    });

    test("un submit_room_code n'émet PAS d'action parasite", () async {
      await controller.showAsCodeSender();
      OverlayAction? action;
      final sub = controller.actions.listen((a) => action = a);
      platform.emit(RecordingOverlayMessages.submitRoomCode('ABC123'));
      await Future<void>.delayed(Duration.zero);
      expect(action, isNull);
      await sub.cancel();
    });

    test('morphToRecording redimensionne quand un overlay est affiché',
        () async {
      await controller.showAsCodeSender();
      expect(platform.resizedToRecording, isFalse);
      await controller.morphToRecording();
      expect(platform.resizedToRecording, isTrue);
    });

    test('morphToRecording est un no-op si aucun overlay affiché', () async {
      await controller.morphToRecording();
      expect(platform.resizedToRecording, isFalse);
    });

    test('isShowing suit show → stop', () async {
      expect(controller.isShowing, isFalse);
      await controller.showAsCodeSender();
      expect(controller.isShowing, isTrue);
      await controller.stop();
      expect(controller.isShowing, isFalse);
    });

    test('startOrMorphToRecording sans overlay → start (showOverlay)',
        () async {
      await controller.startOrMorphToRecording();
      expect(platform.showOverlayCount, 1);
      expect(platform.resizedToRecording, isFalse);
      expect(controller.isShowing, isTrue);
    });

    test(
        'startOrMorphToRecording avec code-sender ouvert → morph, PAS de '
        '2ᵉ showOverlay', () async {
      await controller.showAsCodeSender();
      await controller.startOrMorphToRecording();
      // Le quirk MIUI #4 exige de NE JAMAIS re-showOverlay : on resize.
      expect(platform.showOverlayCount, 0);
      expect(platform.resizedToRecording, isTrue);
    });

    test(
        'process recréé (MIUI) : overlay natif encore actif mais mémoire '
        'perdue → morph, PAS de 2ᵉ showOverlay (anti panneau figé)', () async {
      // Le panneau code-sender a été montré par un process précédent (la
      // fenêtre native survit), puis l'app a été tuée/relancée : un NOUVEAU
      // controller démarre avec `_overlayShown = false` alors que le natif
      // est toujours `isActive`. Se fier au mémoire → 2ᵉ showOverlay → isolate
      // mort → panneau figé. On doit détecter le natif et morpher.
      platform.overlayShown = true; // fenêtre overlay native survivante
      final fresh = RecordingOverlayController(platform: platform);
      expect(fresh.isShowing, isFalse); // mémoire vierge du nouveau process
      await fresh.startOrMorphToRecording();
      expect(platform.showOverlayCount, 0); // JAMAIS de re-showOverlay
      expect(platform.resizedToRecording, isTrue); // morph par resize
      expect(fresh.isShowing, isTrue);
      await fresh.dispose();
    });
  });

  group('saisie inline du code (bouton recording)', () {
    bool tickCodeEntry(Object d) => d is Map && d['codeEntry'] == true;

    test('enterCodeEntry agrandit + pousse un tick codeEntry:true', () async {
      await controller.start();
      platform.sharedData.clear();
      await controller.enterCodeEntry();
      expect(platform.resizedToCodeEntry, isTrue);
      expect(platform.sharedData.any(tickCodeEntry), isTrue);
    });

    test('exitCodeEntry rétrécit + pousse un tick codeEntry:false', () async {
      await controller.start();
      await controller.enterCodeEntry();
      platform
        ..sharedData.clear()
        ..resizedToRecording = false;
      await controller.exitCodeEntry();
      expect(platform.resizedToRecording, isTrue);
      expect(platform.sharedData.any(tickCodeEntry), isFalse);
    });

    test('ask_enter_code ouvre la saisie (resize) sans émettre d’action',
        () async {
      await controller.start();
      OverlayAction? action;
      final sub = controller.actions.listen((a) => action = a);
      platform.emit(RecordingOverlayMessages.askEnterCodeType);
      await Future<void>.delayed(Duration.zero);
      expect(platform.resizedToCodeEntry, isTrue);
      expect(action, isNull);
      await sub.cancel();
    });

    test('ask_exit_code referme la saisie (resize retour bouton)', () async {
      await controller.start();
      await controller.enterCodeEntry();
      platform.resizedToRecording = false;
      OverlayAction? action;
      final sub = controller.actions.listen((a) => action = a);
      platform.emit(RecordingOverlayMessages.askExitCodeType);
      await Future<void>.delayed(Duration.zero);
      expect(platform.resizedToRecording, isTrue);
      expect(action, isNull);
      await sub.cancel();
    });

    test('submit_room_code émet le code ET referme la saisie', () async {
      await controller.start();
      await controller.enterCodeEntry();
      platform.resizedToRecording = false;
      final next = controller.roomCodeSubmissions.first;
      platform.emit(RecordingOverlayMessages.submitRoomCode('ABC123'));
      expect(await next, 'ABC123');
      await Future<void>.delayed(Duration.zero);
      expect(platform.resizedToRecording, isTrue);
    });

    test('les ticks périodiques gardent codeEntry:true pendant la saisie',
        () async {
      await controller.start();
      await controller.enterCodeEntry();
      platform.sharedData.clear();
      // Le tick périodique (via setLiveAvailable qui pousse un tick immédiat)
      // doit conserver codeEntry:true tant que la saisie est ouverte.
      controller.setLiveAvailable(true);
      expect(platform.sharedData.any(tickCodeEntry), isTrue);
    });
  });

  group('code de salle affiché (AWAY)', () {
    bool tickRoomCode(Object d, String code) =>
        d is Map && d['roomCode'] == code;

    test('setDisplayedRoomCode pousse un tick portant le code', () async {
      await controller.start();
      platform.sharedData.clear();
      controller.setDisplayedRoomCode('ABC123');
      expect(platform.sharedData.any((d) => tickRoomCode(d, 'ABC123')), isTrue);
    });

    test('le code est repropagé dans les ticks suivants (persistance)',
        () async {
      await controller.start();
      controller.setDisplayedRoomCode('XYZ789');
      platform.sharedData.clear();
      // Un autre push (setLiveAvailable) émet un tick immédiat qui DOIT encore
      // porter le code mémorisé (sinon il disparaîtrait du bouton).
      controller.setLiveAvailable(true);
      expect(platform.sharedData.any((d) => tickRoomCode(d, 'XYZ789')), isTrue);
    });

    test('mise à jour du code : le nouveau code remplace l’ancien', () async {
      await controller.start();
      controller.setDisplayedRoomCode('OLD111');
      platform.sharedData.clear();
      controller.setDisplayedRoomCode('NEW222');
      expect(platform.sharedData.any((d) => tickRoomCode(d, 'NEW222')), isTrue);
      expect(platform.sharedData.any((d) => tickRoomCode(d, 'OLD111')), isFalse);
    });

    test('code vide/null → aucune clé roomCode dans le tick', () async {
      await controller.start();
      controller.setDisplayedRoomCode('ABC123');
      platform.sharedData.clear();
      controller.setDisplayedRoomCode(null);
      // Le tick immédiat suivant (via setLiveAvailable) ne doit plus porter de
      // code (clé absente car roomCode null).
      controller.setLiveAvailable(true);
      expect(
        platform.sharedData.any((d) => d is Map && d.containsKey('roomCode')),
        isFalse,
      );
    });
  });

  group('OverlayTick', () {
    test('formatted pads MM:SS', () {
      expect(
        const OverlayTick(elapsedSeconds: 3, isWarning: false).formatted,
        '00:03',
      );
      expect(
        const OverlayTick(elapsedSeconds: 65, isWarning: false).formatted,
        '01:05',
      );
      expect(
        const OverlayTick(elapsedSeconds: 1500, isWarning: true).formatted,
        '25:00',
      );
    });

    test('fromMap reads warning vs tick type', () {
      final warn = OverlayTick.fromMap({
        'type': RecordingOverlayMessages.warnType,
        'elapsed': 1485,
      });
      expect(warn.isWarning, isTrue);
      expect(warn.elapsedSeconds, 1485);

      final tick = OverlayTick.fromMap({
        'type': RecordingOverlayMessages.tickType,
        'elapsed': 30,
      });
      expect(tick.isWarning, isFalse);
      expect(tick.elapsedSeconds, 30);
    });

    test('fromMap is null-safe', () {
      final empty = OverlayTick.fromMap(null);
      expect(empty.elapsedSeconds, 0);
      expect(empty.isWarning, isFalse);
    });

    test('fromMap lit roomCode (non vide) sinon null', () {
      final withCode = OverlayTick.fromMap({
        'type': RecordingOverlayMessages.tickType,
        'elapsed': 10,
        'roomCode': 'ABC123',
      });
      expect(withCode.roomCode, 'ABC123');

      final noCode = OverlayTick.fromMap({
        'type': RecordingOverlayMessages.tickType,
        'elapsed': 10,
      });
      expect(noCode.roomCode, isNull);

      final emptyCode = OverlayTick.fromMap({
        'type': RecordingOverlayMessages.tickType,
        'elapsed': 10,
        'roomCode': '',
      });
      expect(emptyCode.roomCode, isNull);
    });
  });
}
