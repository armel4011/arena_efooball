import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Etat du reseau tel que percu par l'app — alimente le banner UI et
/// driver de la sync queue.
enum NetworkStatus {
  /// Internet disponible et reactif (sonde de latence < seuil).
  online,

  /// Interface reseau active mais latence elevee / sonde lente — l'app
  /// reste fonctionnelle mais on previent l'utilisateur que ca rame.
  slow,

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
///   * une **sonde de latence** (HEAD vers `<SUPABASE_URL>/auth/v1/health`)
///     qui mesure la joignabilite *reelle* + la reactivite du reseau.
///
/// `connectivity_plus` seul indique uniquement l'**interface** reseau, pas
/// la joignabilite reelle d'Internet (ex : WiFi avec captive portal). La
/// sonde comble ce trou et permet de distinguer un reseau *lent* d'un
/// reseau normal.
///
/// **Classification** :
///   * pas d'interface             → offline
///   * interface + sonde rapide    → online
///   * interface + sonde lente     → slow   (latence > [_slowThresholdMs])
///   * interface + sonde en echec  → slow   (degrade, PAS offline — on
///     evite les faux negatifs ; offline reste strictement = pas
///     d'interface, signal fiable)
///
/// **Strategie d'usage** :
///   * online/slow → streams Supabase actifs + flush de la sync queue
///   * offline     → bypass des fetchs, l'UI lit le cache uniquement
class NetworkStatusService {
  NetworkStatusService(
    this._connectivity, {
    String? probeUrl,
  }) : _probeUrl = probeUrl;

  /// Latence (ms) au-dela de laquelle on bascule en `slow`.
  static const _slowThresholdMs = 1500;

  /// Timeout de la sonde — au-dela on considere le reseau degrade.
  static const _probeTimeout = Duration(seconds: 4);

  /// Cadence de la sonde periodique quand une interface est active.
  static const _probeInterval = Duration(seconds: 30);

  final Connectivity _connectivity;
  final String? _probeUrl;
  final _controller = StreamController<NetworkStatus>.broadcast();
  StreamSubscription<List<ConnectivityResult>>? _sub;
  Timer? _probeTimer;
  HttpClient? _httpClient;
  bool _hasInterface = false;
  bool _probing = false;
  NetworkStatus _current = NetworkStatus.unknown;

  NetworkStatus get current => _current;
  Stream<NetworkStatus> get stream => _controller.stream;

  /// `true` des qu'une interface est active (online OU slow) — utilise
  /// par la sync queue pour decider de flusher.
  bool get isConnected =>
      _current == NetworkStatus.online || _current == NetworkStatus.slow;

  /// A appeler au boot — recupere le status initial puis ecoute les
  /// changes et lance la sonde periodique.
  Future<void> start() async {
    try {
      final initial = await _connectivity.checkConnectivity();
      await _onInterface(_hasNet(initial));
    } catch (e) {
      if (kDebugMode) debugPrint('[network] checkConnectivity failed: $e');
      _emit(NetworkStatus.online); // fail-open
    }
    _sub = _connectivity.onConnectivityChanged.listen(
      (results) => unawaited(_onInterface(_hasNet(results))),
      onError: (Object e) {
        if (kDebugMode) debugPrint('[network] connectivity stream error: $e');
      },
    );
    // Sonde periodique tant qu'une interface est active.
    _probeTimer = Timer.periodic(_probeInterval, (_) {
      if (_hasInterface) unawaited(_runProbe());
    });
  }

  void dispose() {
    _sub?.cancel();
    _probeTimer?.cancel();
    _httpClient?.close(force: true);
    _controller.close();
  }

  /// Reaction a un changement d'interface OS. Si l'interface tombe, on
  /// passe offline immediatement (signal fiable, pas de sonde). Si elle
  /// remonte, on lance une sonde pour classer online vs slow.
  Future<void> _onInterface(bool hasInterface) async {
    _hasInterface = hasInterface;
    if (!hasInterface) {
      _emit(NetworkStatus.offline);
      return;
    }
    // Interface up — provisoirement online (evite le flash), puis on
    // affine avec la sonde.
    if (_current == NetworkStatus.offline ||
        _current == NetworkStatus.unknown) {
      _emit(NetworkStatus.online);
    }
    await _runProbe();
  }

  /// Sonde de latence : HEAD vers [_probeUrl]. Classe online / slow.
  /// No-op si aucune URL de sonde n'est configuree (on reste sur le
  /// signal d'interface seul).
  Future<void> _runProbe() async {
    final url = _probeUrl;
    if (url == null || url.isEmpty || !_hasInterface || _probing) return;
    _probing = true;
    final sw = Stopwatch()..start();
    try {
      _httpClient ??= HttpClient()
        ..connectionTimeout = _probeTimeout
        ..idleTimeout = _probeTimeout;
      final req = await _httpClient!
          .headUrl(Uri.parse(url))
          .timeout(_probeTimeout);
      final res = await req.close().timeout(_probeTimeout);
      await res.drain<void>();
      sw.stop();
      final slow = sw.elapsedMilliseconds > _slowThresholdMs;
      _emit(slow ? NetworkStatus.slow : NetworkStatus.online);
    } catch (e) {
      // Echec de sonde alors que l'interface est up → degrade (slow),
      // PAS offline : un timeout transitoire ou un endpoint capricieux
      // ne doit pas couper l'UI. Le vrai offline vient de l'interface.
      if (kDebugMode) debugPrint('[network] probe failed: $e');
      if (_hasInterface) _emit(NetworkStatus.slow);
    } finally {
      _probing = false;
    }
  }

  void _emit(NetworkStatus s) {
    if (s == _current) return;
    _current = s;
    _controller.add(s);
  }

  /// `true` si au moins une interface donnant Internet est active.
  /// Bluetooth / autre ne donnent pas Internet → false.
  bool _hasNet(List<ConnectivityResult> results) => results.any(
        (r) =>
            r == ConnectivityResult.wifi ||
            r == ConnectivityResult.mobile ||
            r == ConnectivityResult.ethernet ||
            r == ConnectivityResult.vpn,
      );
}

/// Service singleton — instancie 1 fois pour toute la session. Le start
/// est lance immediatement (no need to await — le 1er event arrive en
/// background et le banner se cache automatiquement quand `online`).
///
/// L'URL de sonde pointe sur l'endpoint health de Supabase Auth (200
/// rapide, pas d'auth requise). Si `SUPABASE_URL` est absent, la sonde
/// est desactivee et on retombe sur la detection d'interface seule.
final networkStatusServiceProvider =
    Provider<NetworkStatusService>((ref) {
  // `dotenv` n'est pas charge dans les widget tests — y acceder leverait
  // NotInitializedError. On garde donc la sonde optionnelle : sans URL,
  // le service retombe sur la detection d'interface seule.
  String? probeUrl;
  if (dotenv.isInitialized) {
    final base = dotenv.env['SUPABASE_URL']?.trim() ?? '';
    if (base.isNotEmpty) probeUrl = '$base/auth/v1/health';
  }
  final svc = NetworkStatusService(Connectivity(), probeUrl: probeUrl)
    ..start();
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
