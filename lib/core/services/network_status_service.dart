import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Etat du reseau tel que percu par l'app — alimente le banner UI et
/// driver de la sync queue.
enum NetworkStatus {
  /// Internet disponible (WiFi ou cellulaire).
  online,

  /// Aucune interface reseau active. L'app travaille en mode cache /
  /// queue.
  offline,

  /// Etat inconnu au boot — pendant ~100ms avant le premier event de
  /// `Connectivity().checkConnectivity()`. Traite comme online (pas de
  /// banner) pour eviter le flash UX.
  unknown,
}

/// Service centralise du status reseau.
///
/// **Sources** :
///   * `connectivity_plus` (couche OS — WiFi/cellulaire actif ou non)
///
/// `connectivity_plus` indique uniquement l'**interface** reseau, pas la
/// joignabilite reelle d'Internet (ex : WiFi avec captive portal). Pour
/// V1 on accepte ce trade-off — la sync queue retry-era a la prochaine
/// transition online si la 1ere tentative echoue.
///
/// **Strategie** :
///   * online → tout normal (streams Supabase + flush sync queue)
///   * offline → bypass des fetchs, l'UI lit le cache uniquement
class NetworkStatusService {
  NetworkStatusService(this._connectivity);

  final Connectivity _connectivity;
  final _controller = StreamController<NetworkStatus>.broadcast();
  StreamSubscription<List<ConnectivityResult>>? _sub;
  NetworkStatus _current = NetworkStatus.unknown;

  NetworkStatus get current => _current;
  Stream<NetworkStatus> get stream => _controller.stream;

  /// A appeler au boot — recupere le status initial puis ecoute les
  /// changes.
  Future<void> start() async {
    try {
      final initial = await _connectivity.checkConnectivity();
      _emit(_map(initial));
    } catch (e) {
      if (kDebugMode) debugPrint('[network] checkConnectivity failed: $e');
      _emit(NetworkStatus.online); // fail-open
    }
    _sub = _connectivity.onConnectivityChanged.listen(
      (results) => _emit(_map(results)),
      onError: (Object e) {
        if (kDebugMode) debugPrint('[network] connectivity stream error: $e');
      },
    );
  }

  void dispose() {
    _sub?.cancel();
    _controller.close();
  }

  void _emit(NetworkStatus s) {
    if (s == _current) return;
    _current = s;
    _controller.add(s);
  }

  /// Mapping `ConnectivityResult` → `NetworkStatus`. Tous les types
  /// "online" (WiFi/mobile/ethernet/vpn) → online. Seul `none` → offline.
  /// Bluetooth / autre ne donnent pas Internet → offline.
  NetworkStatus _map(List<ConnectivityResult> results) {
    final hasNet = results.any(
      (r) =>
          r == ConnectivityResult.wifi ||
          r == ConnectivityResult.mobile ||
          r == ConnectivityResult.ethernet ||
          r == ConnectivityResult.vpn,
    );
    return hasNet ? NetworkStatus.online : NetworkStatus.offline;
  }
}

/// Service singleton — instancie 1 fois pour toute la session. Le start
/// est lance immediatement (no need to await — le 1er event arrive en
/// background et le banner se cache automatiquement quand `online`).
final networkStatusServiceProvider =
    Provider<NetworkStatusService>((ref) {
  final svc = NetworkStatusService(Connectivity())..start();
  ref.onDispose(svc.dispose);
  return svc;
});

/// Stream du status pour l'UI — alimente le banner.
final networkStatusProvider = StreamProvider<NetworkStatus>((ref) async* {
  final svc = ref.watch(networkStatusServiceProvider);
  yield svc.current;
  yield* svc.stream;
});

/// Helper sync : `true` quand offline. Utilise par les repositories qui
/// veulent skip un fetch reseau (pour lire du cache uniquement).
final isOfflineProvider = Provider<bool>((ref) {
  final s = ref.watch(networkStatusProvider).valueOrNull;
  return s == NetworkStatus.offline;
});
