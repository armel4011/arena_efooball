import 'dart:io';

import 'package:arena/data/repositories/match_stream_repository.dart';
import 'package:arena/data/repositories/profile_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Hard cap on accepted upload size — must mirror the bucket's
/// `file_size_limit` (500 MB) configured in the storage migration.
const int kMatchRecordingMaxBytes = 500 * 1024 * 1024;

/// Bucket name — keep as a constant so a future rename only touches
/// one place.
const String kMatchRecordingsBucket = 'match-recordings';

/// Outcome of a successful upload.
class UploadResult {
  const UploadResult({
    required this.streamId,
    required this.objectPath,
  });

  /// `streams.id` row that now holds [objectPath] in its `url` column.
  final String streamId;

  /// Path inside [kMatchRecordingsBucket] (`{matchId}/{playerId}/{file}`).
  /// Combine with `client.storage.from(bucket).createSignedUrl(...)` to
  /// fetch a temporary playback URL — recordings are never public.
  final String objectPath;
}

/// Pushes a local recording (auto or manual) to Supabase Storage and
/// patches the matching `streams` row with the resulting object path.
///
/// Usage (auto-recording end of match):
/// ```dart
/// final result = await ref.read(recordingUploaderProvider).upload(
///   streamId: stream.id,
///   matchId: stream.matchId,
///   playerId: stream.playerId,
///   file: File(localPath),
/// );
/// ```
class RecordingUploader {
  const RecordingUploader({
    required SupabaseClient client,
    required MatchStreamRepository streamRepository,
  })  : _client = client,
        _repo = streamRepository;

  final SupabaseClient _client;
  final MatchStreamRepository _repo;

  /// Uploads [file] under `{matchId}/{playerId}/{timestamp}.{ext}` and
  /// patches the parent `streams` row's `url` field with the resulting
  /// object path.
  ///
  /// Throws [RecordingUploadException] on validation errors (missing
  /// file, too large, bad extension).
  Future<UploadResult> upload({
    required String streamId,
    required String matchId,
    required String playerId,
    required File file,
  }) async {
    if (!file.existsSync()) {
      throw const RecordingUploadException('File does not exist on disk');
    }

    final size = await file.length();
    if (size <= 0) {
      throw const RecordingUploadException('Recording is empty (0 bytes)');
    }
    if (size > kMatchRecordingMaxBytes) {
      throw RecordingUploadException(
        'Recording exceeds ${kMatchRecordingMaxBytes ~/ (1024 * 1024)} MB limit (got ${size ~/ (1024 * 1024)} MB)',
      );
    }

    final extension = _resolveExtension(file.path);
    if (extension == null) {
      throw const RecordingUploadException(
        'Unsupported file extension — expected .mp4, .mov or .webm',
      );
    }

    final ts = DateTime.now().toUtc().millisecondsSinceEpoch;
    final objectPath = '$matchId/$playerId/$ts.$extension';

    try {
      await _client.storage.from(kMatchRecordingsBucket).upload(
            objectPath,
            file,
            fileOptions: FileOptions(
              cacheControl: '3600',
              contentType: _mimeForExtension(extension),
            ),
          );
    } on StorageException catch (e, st) {
      if (kDebugMode) {
        debugPrint('[upload] storage upload failed: ${e.message}\n$st');
      }
      await Sentry.captureException(e, stackTrace: st);
      throw RecordingUploadException('Upload failed: ${e.message}');
    } on SocketException catch (e, st) {
      if (kDebugMode) {
        debugPrint('[upload] network error during upload: $e\n$st');
      }
      throw RecordingUploadException('Upload failed (network): $e');
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('[upload] storage upload failed: $e\n$st');
      }
      await Sentry.captureException(e, stackTrace: st);
      throw RecordingUploadException('Upload failed: $e');
    }

    try {
      await _repo.attachUrl(streamId, objectPath);
    } on PostgrestException catch (e, st) {
      // The file is already in Storage at this point — surface the
      // failure but keep the orphaned object so a retry has something
      // to attach to. Sentry capture so we can spot/cleanup orphans.
      if (kDebugMode) {
        debugPrint('[upload] attachUrl($streamId) failed: ${e.message}\n$st');
      }
      await Sentry.captureException(e, stackTrace: st);
      throw RecordingUploadException(
        'Stored to bucket but failed to attach URL: ${e.message}',
      );
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('[upload] attachUrl($streamId) failed: $e\n$st');
      }
      await Sentry.captureException(e, stackTrace: st);
      throw RecordingUploadException(
        'Stored to bucket but failed to attach URL: $e',
      );
    }

    return UploadResult(streamId: streamId, objectPath: objectPath);
  }

  /// Same shape as [upload] but works from raw bytes — used by the
  /// manual upload flow when `file_picker` returns memory bytes on web.
  Future<UploadResult> uploadBinary({
    required String streamId,
    required String matchId,
    required String playerId,
    required List<int> bytes,
    required String filenameForExtension,
  }) async {
    if (bytes.isEmpty) {
      throw const RecordingUploadException('Recording is empty (0 bytes)');
    }
    if (bytes.length > kMatchRecordingMaxBytes) {
      throw const RecordingUploadException(
        'Recording exceeds 500 MB limit',
      );
    }
    final extension = _resolveExtension(filenameForExtension);
    if (extension == null) {
      throw const RecordingUploadException(
        'Unsupported file extension — expected .mp4, .mov or .webm',
      );
    }

    final ts = DateTime.now().toUtc().millisecondsSinceEpoch;
    final objectPath = '$matchId/$playerId/$ts.$extension';

    try {
      await _client.storage.from(kMatchRecordingsBucket).uploadBinary(
            objectPath,
            Uint8List.fromList(bytes),
            fileOptions: FileOptions(
              cacheControl: '3600',
              contentType: _mimeForExtension(extension),
            ),
          );
    } on StorageException catch (e, st) {
      if (kDebugMode) {
        debugPrint('[uploadBinary] storage upload failed: ${e.message}\n$st');
      }
      await Sentry.captureException(e, stackTrace: st);
      throw RecordingUploadException('Upload failed: ${e.message}');
    } on SocketException catch (e, st) {
      throw RecordingUploadException('Upload failed (network): $e\n$st');
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('[uploadBinary] storage upload failed: $e\n$st');
      }
      await Sentry.captureException(e, stackTrace: st);
      throw RecordingUploadException('Upload failed: $e');
    }

    await _repo.attachUrl(streamId, objectPath);
    return UploadResult(streamId: streamId, objectPath: objectPath);
  }

  String? _resolveExtension(String path) {
    final lower = path.toLowerCase();
    for (final ext in const ['mp4', 'mov', 'webm']) {
      if (lower.endsWith('.$ext')) return ext;
    }
    return null;
  }

  String _mimeForExtension(String ext) {
    return switch (ext) {
      'mov' => 'video/quicktime',
      'webm' => 'video/webm',
      _ => 'video/mp4',
    };
  }
}

class RecordingUploadException implements Exception {
  const RecordingUploadException(this.message);
  final String message;
  @override
  String toString() => 'RecordingUploadException: $message';
}

final recordingUploaderProvider = Provider<RecordingUploader>((ref) {
  return RecordingUploader(
    client: ref.watch(supabaseClientProvider),
    streamRepository: ref.watch(matchStreamRepositoryProvider),
  );
});
