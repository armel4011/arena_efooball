import 'dart:async';
import 'dart:io';

import 'package:arena/core/utils/error_reporter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_compress/video_compress.dart';

/// Couture sur le moteur de transcodage natif (video_compress) — permet de
/// faux-er le backend dans les tests sans dépendre du plugin.
// ignore: one_member_abstracts
abstract class VideoTranscoderBackend {
  /// Transcode [inputPath] en une variante basse résolution et renvoie le
  /// chemin du fichier produit (ou `null` si le moteur n'a rien renvoyé).
  Future<String?> compressToLowRes(String inputPath);
}

/// Backend réel : video_compress en qualité la plus basse (≈ proxy 360p léger).
class VideoCompressBackend implements VideoTranscoderBackend {
  const VideoCompressBackend({this.timeout = const Duration(minutes: 2)});

  /// Plafond au-delà duquel on considère l'encodeur natif bloqué. Sur
  /// certains chips (observé : `c2.qti.avc` MIUI/Qualcomm), le
  /// `GraphicBufferSource` famine en buffers et `compressVideo` ne rend
  /// JAMAIS la main (deadlock `waitForFreeSlotThenRelock`). Sans ce timeout,
  /// le commit anti-triche resterait bloqué indéfiniment. 2 min couvrent
  /// largement le transcodage d'une capture de 25 min (cas légitime le plus
  /// long) tout en bornant les hangs.
  final Duration timeout;

  @override
  Future<String?> compressToLowRes(String inputPath) async {
    // LowQuality = preset le plus agressif du plugin → fichier le plus petit,
    // ce qu'on veut pour un proxy de preuve (uploadé seulement sur litige).
    try {
      final info = await VideoCompress.compressVideo(
        inputPath,
        quality: VideoQuality.LowQuality,
        deleteOrigin: false,
      ).timeout(timeout);
      return info?.path;
    } on TimeoutException {
      // Encodeur natif bloqué : on annule la compression en cours (libère
      // au mieux le plugin) et on renvoie null → l'appelant retombe sur le
      // 540p, garantissant que le commit aboutit quand même.
      unawaited(VideoCompress.cancelCompression());
      return null;
    }
  }
}

/// Produit un proxy basse résolution (≈360p) d'une capture anti-triche pour
/// alléger le fichier engagé/uploadé (Phase 3). C'est ce proxy qui est hashé
/// (commitment) et livré sur réclamation — le 540p d'origine reste pour la
/// galerie/replay.
///
/// GARDE-FOU (plan) : si le transcodage échoue, ne renvoie rien — l'appelant
/// retombe alors sur le 540p (commit + upload du 540p). Ne lève jamais.
class ProofTranscoder {
  const ProofTranscoder(this._backend);

  final VideoTranscoderBackend _backend;

  /// Renvoie le chemin du proxy 360p, ou `null` si le transcodage a échoué /
  /// produit un fichier vide / s'est révélé plus lourd que l'original (auquel
  /// cas garder l'original est préférable).
  Future<String?> to360pProxy(String inputPath) async {
    try {
      final input = File(inputPath);
      final inputSize = input.existsSync() ? input.lengthSync() : 0;

      final outPath = await _backend.compressToLowRes(inputPath);
      if (outPath == null) return null;

      final out = File(outPath);
      if (!out.existsSync()) return null;
      final outSize = out.lengthSync();
      if (outSize <= 0) return null;

      // Si le « proxy » n'allège pas, autant garder l'original (et ne pas
      // laisser traîner un doublon plus lourd).
      if (inputSize > 0 && outSize >= inputSize) return null;

      return outPath;
    } catch (e, st) {
      unawaited(reportError(e, st, context: 'ProofTranscoder.to360pProxy'));
      return null;
    }
  }
}

final proofTranscoderProvider = Provider<ProofTranscoder>(
  (ref) => const ProofTranscoder(VideoCompressBackend()),
);
