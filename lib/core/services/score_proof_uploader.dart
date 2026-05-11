import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Result of letting the user pick a proof file.
class PickedProof {
  const PickedProof({
    required this.path,
    required this.bytes,
    required this.mimeType,
    required this.displayName,
  });

  final String path;
  final int bytes;
  final String mimeType;
  final String displayName;
}

/// Picks a screenshot or short clip from the gallery / file system and
/// uploads it to the `match-proofs` Supabase bucket. The storage path
/// layout mirrors the anti-cheat recordings:
///
///   match-proofs/{matchId}/{userId}/{epochMs}.{ext}
///
/// RLS only lets a player drop a file into a match they actually play
/// in — see migration `20260511020000_phase8_match_proofs_storage.sql`.
class ScoreProofUploader {
  ScoreProofUploader(this._client);

  final SupabaseClient _client;

  static const _bucket = 'match-proofs';
  static const _allowedImageExts = {'jpg', 'jpeg', 'png', 'webp'};
  static const _allowedVideoExts = {'mp4', 'mov', 'webm'};

  /// Opens the system picker. Returns null if the user cancelled.
  /// Throws if the picked file's extension isn't allowed or it exceeds
  /// the 50 MiB bucket limit.
  Future<PickedProof?> pick() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.media,
      allowMultiple: false,
      withData: false,
    );
    if (result == null || result.files.isEmpty) return null;
    final f = result.files.single;
    final path = f.path;
    if (path == null || path.isEmpty) {
      throw const FormatException('Fichier sans chemin local');
    }
    final ext = _extOf(path);
    final isImage = _allowedImageExts.contains(ext);
    final isVideo = _allowedVideoExts.contains(ext);
    if (!isImage && !isVideo) {
      throw FormatException(
        'Format non supporté (.$ext). Joins une photo (jpg/png/webp) '
        'ou une vidéo (mp4/mov/webm).',
      );
    }
    final size = await File(path).length();
    if (size > 50 * 1024 * 1024) {
      throw const FormatException(
        'Fichier trop lourd — limite 50 Mo.',
      );
    }
    return PickedProof(
      path: path,
      bytes: size,
      mimeType: _mimeFor(ext),
      displayName: f.name,
    );
  }

  /// Uploads [proof] under
  /// `match-proofs/{matchId}/{userId}/{epochMs}.{ext}` and returns the
  /// storage path (NOT a signed URL — the consumer signs it on demand
  /// since the bucket is private).
  Future<String> upload({
    required String matchId,
    required String userId,
    required PickedProof proof,
  }) async {
    final ext = _extOf(proof.path);
    final fileName =
        ext.isEmpty ? '${DateTime.now().millisecondsSinceEpoch}'
            : '${DateTime.now().millisecondsSinceEpoch}.$ext';
    final storagePath = '$matchId/$userId/$fileName';
    await _client.storage.from(_bucket).upload(
          storagePath,
          File(proof.path),
          fileOptions: FileOptions(
            cacheControl: '3600',
            upsert: false,
            contentType: proof.mimeType,
          ),
        );
    return storagePath;
  }

  static String _extOf(String filePath) {
    final dot = filePath.lastIndexOf('.');
    if (dot < 0 || dot == filePath.length - 1) return '';
    return filePath.substring(dot + 1).toLowerCase();
  }

  static String _mimeFor(String ext) {
    switch (ext) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'mp4':
        return 'video/mp4';
      case 'mov':
        return 'video/quicktime';
      case 'webm':
        return 'video/webm';
    }
    return 'application/octet-stream';
  }
}

final scoreProofUploaderProvider = Provider<ScoreProofUploader>((ref) {
  return ScoreProofUploader(Supabase.instance.client);
});
