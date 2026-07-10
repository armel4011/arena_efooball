import 'dart:convert';

import 'package:arena/core/services/onboarding_service.dart'
    show sharedPreferencesProvider;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Emplacement local du fichier de capture engagé pour un match donné.
class ProofFileEntry {
  const ProofFileEntry({required this.filePath, required this.playerId});

  final String filePath;
  final String playerId;
}

/// Persiste `matchId → (fichier local, joueur, date)` au moment du commit
/// (Phase 3).
///
/// La réclamation admin (« Réclamer la vidéo ») peut arriver bien APRÈS la fin
/// du match — il faut donc retrouver, hors mémoire, le fichier exact qui a été
/// hashé pour l'uploader. On stocke le chemin du fichier qu'on a hashé : son
/// SHA-256 correspond au commitment, donc `proof-verify` validera.
///
/// Rétention (volet C) : le chemin pointe désormais vers le dossier APPLICATIF
/// persistant (cf. `ProofArchive`), plus le cache purgeable de l'OS. La date de
/// commit ([put] estampille `ts`) permet à [purgeOlderThan] de nettoyer les
/// entrées périmées en même temps que les fichiers archivés (fenêtre de litige).
class ProofFileStore {
  ProofFileStore(this._prefs);

  final SharedPreferences _prefs;
  static const _key = 'arena.proof_files.v1';

  Map<String, dynamic> _read() {
    final raw = _prefs.getString(_key);
    if (raw == null || raw.isEmpty) return {};
    try {
      return (jsonDecode(raw) as Map).cast<String, dynamic>();
    } catch (_) {
      return {};
    }
  }

  Future<void> _write(Map<String, dynamic> map) =>
      _prefs.setString(_key, jsonEncode(map));

  Future<void> put({
    required String matchId,
    required String filePath,
    required String playerId,
  }) async {
    final map = _read()
      ..[matchId] = {
        'path': filePath,
        'player': playerId,
        'ts': DateTime.now().toUtc().millisecondsSinceEpoch,
      };
    await _write(map);
  }

  ProofFileEntry? get(String matchId) {
    final v = _read()[matchId];
    if (v is! Map) return null;
    final path = v['path'];
    final player = v['player'];
    if (path is! String || player is! String) return null;
    return ProofFileEntry(filePath: path, playerId: player);
  }

  Future<void> remove(String matchId) async {
    final map = _read();
    if (map.remove(matchId) != null) await _write(map);
  }

  /// Supprime les entrées plus vieilles que [maxAge] (par `ts`). Les entrées
  /// legacy sans `ts` sont conservées (on ne connaît pas leur âge — le fichier
  /// archivé associé sera, lui, purgé par `ProofArchive.purgeExpired`).
  /// Renvoie le nombre d'entrées retirées.
  Future<int> purgeOlderThan(Duration maxAge) async {
    final map = _read();
    if (map.isEmpty) return 0;
    final cutoff =
        DateTime.now().toUtc().subtract(maxAge).millisecondsSinceEpoch;
    var removed = 0;
    map.removeWhere((_, v) {
      if (v is! Map) return false;
      final ts = v['ts'];
      if (ts is! int) return false; // legacy sans date : on garde.
      final stale = ts < cutoff;
      if (stale) removed++;
      return stale;
    });
    if (removed > 0) await _write(map);
    return removed;
  }
}

final proofFileStoreProvider = Provider<ProofFileStore>(
  (ref) => ProofFileStore(ref.watch(sharedPreferencesProvider)),
);
