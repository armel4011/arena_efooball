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

/// Persiste `matchId → (fichier local, joueur)` au moment du commit (Phase 3).
///
/// La réclamation admin (« Réclamer la vidéo ») peut arriver bien APRÈS la fin
/// du match — il faut donc retrouver, hors mémoire, le fichier exact qui a été
/// hashé pour l'uploader. On stocke le chemin du fichier qu'on a hashé : son
/// SHA-256 correspond au commitment, donc `proof-verify` validera.
///
/// ⚠️ Le fichier vit en cache : si l'OS l'a purgé avant la réclamation, l'upload
/// ne peut aboutir (charge contre le joueur, par design). Une rétention en
/// dossier persistant est une amélioration ultérieure.
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
    final map = _read()..[matchId] = {'path': filePath, 'player': playerId};
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
}

final proofFileStoreProvider = Provider<ProofFileStore>(
  (ref) => ProofFileStore(ref.watch(sharedPreferencesProvider)),
);
