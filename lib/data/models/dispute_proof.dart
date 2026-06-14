/// Lightweight view of a proof file attached to a match (`match_events`
/// rows carrying `proof_path` / `proof_mime`), surfaced to admins in the
/// dispute-resolution screen.
///
/// The bucket `match-proofs` is private, so [path] is just the storage
/// key — the repository signs it on demand (cf. chat media).
class DisputeProof {
  const DisputeProof({
    required this.path,
    this.mime,
    this.playerId,
    this.createdAt,
  });

  /// Storage key inside the `match-proofs` bucket
  /// (`{matchId}/{userId}/{ts}.{ext}`).
  final String path;

  /// MIME type recorded at upload (`image/png`, `video/mp4`, …). May be
  /// null on older rows; [isVideo] then falls back to the extension.
  final String? mime;

  /// Profile id of the player who submitted the proof (`created_by`).
  final String? playerId;

  final DateTime? createdAt;

  static const _videoExts = {'mp4', 'mov', 'webm', 'm4v', 'mkv'};

  /// True when the proof is a video (so the UI offers an external player
  /// instead of an inline thumbnail). Prefers the MIME type, falling back
  /// to the file extension when the MIME is missing.
  bool get isVideo {
    final m = mime;
    if (m != null && m.isNotEmpty) {
      return m.toLowerCase().startsWith('video/');
    }
    return _videoExts.contains(_ext);
  }

  /// True when the proof is an image. Symmetric to [isVideo].
  bool get isImage {
    final m = mime;
    if (m != null && m.isNotEmpty) {
      return m.toLowerCase().startsWith('image/');
    }
    return !_videoExts.contains(_ext);
  }

  String get _ext {
    final dot = path.lastIndexOf('.');
    if (dot < 0 || dot == path.length - 1) return '';
    return path.substring(dot + 1).toLowerCase();
  }
}
