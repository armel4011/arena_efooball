import 'dart:async';
import 'dart:io';

import 'package:arena/core/utils/error_reporter.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Guide MIUI/Xiaomi : sur ces ROM, l'OS tue les apps force-stopped et bloque
/// leur exécution background → le handler FCM background ne se réveille pas et
/// la preuve anti-triche réclamée n'est jamais uploadée (cf. livraison de
/// preuve, upload on-claim). On aide le joueur à activer, UNE fois, deux
/// réglages MIUI pour Arena :
///   * « Démarrage auto » (Security center),
///   * batterie « Sans restriction » (power keeper).
/// C'est un DÉBLOCAGE équitable (activer le mécanisme), pas une sanction.
///
/// Backed by le canal `arena/native` (MainActivity.kt). No-op hors Android.
class MiuiOptimizationService {
  MiuiOptimizationService({MethodChannel? channel})
      : _channel = channel ?? const MethodChannel('arena/native');

  final MethodChannel _channel;

  /// `true` sur un appareil Xiaomi / Redmi / POCO (MIUI). `false` ailleurs.
  Future<bool> isMiui() async {
    if (!Platform.isAndroid) return false;
    try {
      return (await _channel.invokeMethod<bool>('isMiui')) ?? false;
    } on MissingPluginException {
      return false;
    } catch (e, st) {
      unawaited(reportError(e, st, context: 'Miui.isMiui'));
      return false;
    }
  }

  /// Ouvre l'écran MIUI « Démarrage auto » (repli : page infos de l'app).
  Future<bool> openAutostart() =>
      _open('openMiuiAutostart', 'Miui.openAutostart');

  /// Ouvre l'écran MIUI d'économie de batterie par app (repli : page infos).
  Future<bool> openBatterySaver() =>
      _open('openMiuiBatterySaver', 'Miui.openBatterySaver');

  Future<bool> _open(String method, String ctx) async {
    if (!Platform.isAndroid) return false;
    try {
      return (await _channel.invokeMethod<bool>(method)) ?? false;
    } on MissingPluginException {
      return false;
    } catch (e, st) {
      unawaited(reportError(e, st, context: ctx));
      return false;
    }
  }
}

final miuiOptimizationServiceProvider =
    Provider<MiuiOptimizationService>((_) => MiuiOptimizationService());
