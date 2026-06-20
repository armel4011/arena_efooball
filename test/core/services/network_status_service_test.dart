import 'dart:async';

import 'package:arena/core/services/network_status_service.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:connectivity_plus_platform_interface/connectivity_plus_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

/// Fake plateforme `connectivity_plus` : pilote `checkConnectivity()` (état
/// initial) et `onConnectivityChanged` (transitions) sans canal natif.
class _FakeConnectivityPlatform extends Fake
    with MockPlatformInterfaceMixin
    implements ConnectivityPlatform {
  _FakeConnectivityPlatform(this.initial, this.changes);

  List<ConnectivityResult> initial;
  final Stream<List<ConnectivityResult>> changes;
  bool throwOnCheck = false;

  @override
  Future<List<ConnectivityResult>> checkConnectivity() async {
    if (throwOnCheck) throw Exception('checkConnectivity boom');
    return initial;
  }

  @override
  Stream<List<ConnectivityResult>> get onConnectivityChanged => changes;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late StreamController<List<ConnectivityResult>> changes;

  setUp(() => changes = StreamController<List<ConnectivityResult>>.broadcast());
  tearDown(() => changes.close());

  /// Construit le service avec la plateforme mockée, sonde désactivée
  /// (`probeUrl: null` → classification d'interface pure), et le démarre.
  Future<NetworkStatusService> startWith(
    List<ConnectivityResult> initial, {
    bool throwOnCheck = false,
  }) async {
    ConnectivityPlatform.instance =
        _FakeConnectivityPlatform(initial, changes.stream)
          ..throwOnCheck = throwOnCheck;
    final svc = NetworkStatusService(Connectivity(), probeUrl: null);
    addTearDown(svc.dispose);
    await svc.start();
    return svc;
  }

  group('classification initiale (interface seule)', () {
    test('wifi → online + isConnected', () async {
      final svc = await startWith([ConnectivityResult.wifi]);
      expect(svc.current, NetworkStatus.online);
      expect(svc.isConnected, isTrue);
    });

    test('aucune interface → offline + !isConnected', () async {
      final svc = await startWith([ConnectivityResult.none]);
      expect(svc.current, NetworkStatus.offline);
      expect(svc.isConnected, isFalse);
    });

    test('liste vide → offline', () async {
      final svc = await startWith(<ConnectivityResult>[]);
      expect(svc.current, NetworkStatus.offline);
    });

    test('mobile / ethernet / vpn comptent comme Internet → online', () async {
      for (final r in const [
        ConnectivityResult.mobile,
        ConnectivityResult.ethernet,
        ConnectivityResult.vpn,
      ]) {
        ConnectivityPlatform.instance =
            _FakeConnectivityPlatform([r], const Stream.empty());
        final svc = NetworkStatusService(Connectivity(), probeUrl: null);
        addTearDown(svc.dispose);
        await svc.start();
        expect(svc.current, NetworkStatus.online, reason: r.toString());
      }
    });

    test('bluetooth seul ne donne pas Internet → offline', () async {
      final svc = await startWith([ConnectivityResult.bluetooth]);
      expect(svc.current, NetworkStatus.offline);
    });
  });

  group('transitions', () {
    test("offline → online quand l'interface remonte", () async {
      final svc = await startWith([ConnectivityResult.none]);
      expect(svc.current, NetworkStatus.offline);

      changes.add([ConnectivityResult.wifi]);
      await pumpEventQueue();

      expect(svc.current, NetworkStatus.online);
    });

    test("online → offline quand l'interface tombe", () async {
      final svc = await startWith([ConnectivityResult.wifi]);
      expect(svc.current, NetworkStatus.online);

      changes.add([ConnectivityResult.none]);
      await pumpEventQueue();

      expect(svc.current, NetworkStatus.offline);
    });

    test("le stream émet la séquence des changements d'état", () async {
      final svc = await startWith([ConnectivityResult.none]);
      final seen = <NetworkStatus>[];
      final sub = svc.stream.listen(seen.add);

      changes.add([ConnectivityResult.wifi]);
      await pumpEventQueue();
      changes.add([ConnectivityResult.none]);
      await pumpEventQueue();

      await sub.cancel();
      expect(
        seen,
        containsAllInOrder([
          NetworkStatus.online,
          NetworkStatus.offline,
        ]),
      );
    });
  });

  group('robustesse', () {
    test('current = unknown avant start (pas de flash UI)', () {
      ConnectivityPlatform.instance =
          _FakeConnectivityPlatform([ConnectivityResult.wifi], changes.stream);
      final svc = NetworkStatusService(Connectivity(), probeUrl: null);
      addTearDown(svc.dispose);
      expect(svc.current, NetworkStatus.unknown);
      expect(svc.isConnected, isFalse);
    });

    test('checkConnectivity qui échoue → fail-open online', () async {
      final svc = await startWith(
        [ConnectivityResult.wifi],
        throwOnCheck: true,
      );
      expect(svc.current, NetworkStatus.online);
    });

    test('dispose est idempotent et ne lève pas', () async {
      final svc = await startWith([ConnectivityResult.wifi]);
      svc.dispose();
      // 2e dispose via addTearDown — ne doit pas planter.
    });
  });
}
