import 'dart:async';
import 'dart:io';

import 'package:arena/core/utils/error_reporter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

/// Rétention DURABLE du fichier de preuve anti-triche (Phase 3, volet C).
///
/// Problème corrigé (incident 2026-07-01) : le proxy transcodé par
/// `video_compress` — comme le 540p — vit dans un répertoire de CACHE que
/// l'OS peut purger à tout moment. Une réclamation admin arrivant après la
/// purge trouvait le fichier absent → preuve définitivement perdue (charge
/// injuste contre le joueur).
///
/// Solution : au commit, on COPIE le fichier hashé dans un dossier APPLICATIF
/// persistant (`getApplicationSupportDirectory()/arena_proofs/`), à un chemin
/// déterministe `proof_<matchId>.mp4`. Ce répertoire n'est pas purgé par l'OS
/// comme le cache ; le fichier survit donc jusqu'à la réclamation (ou la purge
/// volontaire à J+30 ci-dessous). Copie (pas déplacement) : le 540p d'origine
/// reste disponible pour la galerie/replay.
class ProofArchive {
  const ProofArchive();

  /// Sous-dossier dédié dans le stockage applicatif persistant.
  static const _folder = 'arena_proofs';

  /// Fenêtre de rétention : au-delà, un proxy non réclamé est purgé. Aligné sur
  /// la fenêtre de litige (les captures serveur non contestées sont, elles,
  /// purgées à J+1 côté `cleanup-streams`, mais la preuve JOUEUR doit rester
  /// livrable tant qu'un litige peut être ouvert).
  static const retention = Duration(days: 30);

  Future<Directory> _dir() async {
    final base = await getApplicationSupportDirectory();
    final dir = Directory('${base.path}/$_folder');
    if (!dir.existsSync()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  /// Copie [sourcePath] dans le dossier persistant sous `proof_<matchId>.mp4`
  /// et renvoie le chemin durable. Renvoie `null` si la source est absente ou
  /// si la copie échoue (l'appelant retombe alors sur le chemin d'origine —
  /// garde-fou : jamais de régression, au pire on garde le comportement cache).
  Future<String?> persist({
    required String matchId,
    required String sourcePath,
  }) async {
    try {
      final src = File(sourcePath);
      if (!src.existsSync()) return null;
      final dir = await _dir();
      final dest = '${dir.path}/proof_$matchId.mp4';
      // Déjà dans l'archive (rejeu du commit) : rien à copier.
      if (sourcePath == dest) return dest;
      await src.copy(dest);
      return dest;
    } catch (e, st) {
      unawaited(reportError(e, st, context: 'ProofArchive.persist'));
      return null;
    }
  }

  /// Supprime les preuves archivées plus vieilles que [retention] (fichiers non
  /// réclamés après la fenêtre de litige). Best-effort, ne lève jamais.
  Future<void> purgeExpired() async {
    try {
      final dir = await _dir();
      final cutoff = DateTime.now().subtract(retention);
      for (final entity in dir.listSync()) {
        if (entity is! File) continue;
        try {
          if (entity.statSync().modified.isBefore(cutoff)) {
            entity.deleteSync();
          }
        } catch (_) {
          // Fichier verrouillé / déjà supprimé : on ignore et on continue.
        }
      }
    } catch (e, st) {
      unawaited(reportError(e, st, context: 'ProofArchive.purgeExpired'));
    }
  }
}

final proofArchiveProvider = Provider<ProofArchive>(
  (ref) => const ProofArchive(),
);
