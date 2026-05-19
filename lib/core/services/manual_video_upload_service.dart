import 'dart:io';

import 'package:arena/core/services/recording_uploader.dart';
import 'package:arena/data/models/match_stream.dart';
import 'package:arena/data/repositories/match_stream_repository.dart';
import 'package:arena/data/repositories/profile_repository.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Outcome of a manual upload attempt.
class ManualUploadOutcome {
  const ManualUploadOutcome({
    required this.cancelled,
    this.result,
    this.session,
  });

  /// True when the user dismissed the OS picker without choosing a file.
  /// In that case [result] and [session] are both null.
  final bool cancelled;

  /// The successful upload — only present when [cancelled] is false and
  /// no exception was thrown.
  final UploadResult? result;

  /// The `streams` row that holds the upload — present whenever the
  /// session was opened (even if the upload itself failed afterwards).
  final MatchStream? session;
}

/// Picks a video from the user's gallery and uploads it as evidence
/// for a match.
///
/// The flow mirrors the auto-recording one (open a `streams` session,
/// upload, attach url) so dispute review only has to read from a
/// single table regardless of the source. We expose this on every
/// match — even when Agora streaming is off — so a player can always
/// hand in their own footage if they recorded with the iOS native
/// recorder, an external app, or a second device.
class ManualVideoUploadService {
  const ManualVideoUploadService({
    required MatchStreamRepository streamRepository,
    required RecordingUploader uploader,
    FilePickerWrapper? picker,
  })  : _repo = streamRepository,
        _uploader = uploader,
        _picker = picker ?? const _DefaultFilePickerWrapper();

  final MatchStreamRepository _repo;
  final RecordingUploader _uploader;
  final FilePickerWrapper _picker;

  Future<ManualUploadOutcome> pickAndUpload({
    required String matchId,
    required String playerId,
  }) async {
    final picked = await _picker.pickVideo();
    if (picked == null) {
      return const ManualUploadOutcome(cancelled: true);
    }

    if (picked.path == null && picked.bytes == null) {
      throw const RecordingUploadException(
        'Picker returned neither a path nor bytes',
      );
    }

    // Open a private session up-front so the file lands somewhere
    // even if the user backgrounds the app mid-upload.
    final session = await _repo.openSession(matchId: matchId, playerId: playerId);

    try {
      UploadResult uploadResult;
      if (picked.path != null) {
        uploadResult = await _uploader.upload(
          streamId: session.id,
          matchId: matchId,
          playerId: playerId,
          file: File(picked.path!),
        );
      } else {
        uploadResult = await _uploader.uploadBinary(
          streamId: session.id,
          matchId: matchId,
          playerId: playerId,
          bytes: picked.bytes!,
          filenameForExtension: picked.name ?? 'video.mp4',
        );
      }

      // Mark the session ended right away — the manual flow has no
      // "live recording" phase, so it transitions straight to closed.
      try {
        await _repo.markEnded(session.id);
      } catch (e, st) {
        if (kDebugMode) {
          debugPrint('[manual-upload] markEnded failed: $e\n$st');
        }
      }

      return ManualUploadOutcome(
        cancelled: false,
        result: uploadResult,
        session: session,
      );
    } catch (e, st) {
      // Best-effort: close the session so it doesn't show as active
      // forever in the player's history. The exception is rethrown so
      // the caller (ManualUploadButton) can surface it to the user ;
      // pas de Sentry ici car le caller capture la trace contextuelle.
      try {
        await _repo.markEnded(session.id);
      } catch (cleanupErr) {
        debugPrint(
          '[manual-upload] markEnded cleanup failed: $cleanupErr (after $e)',
        );
      }
      debugPrint('[manual-upload] pickAndUpload failed: $e\n$st');
      rethrow;
    }
  }
}

/// Subset of [PlatformFile] that the service actually consumes — kept
/// narrow so the test fake doesn't have to mimic every property.
class PickedVideo {
  const PickedVideo({this.path, this.bytes, this.name});

  final String? path;
  final List<int>? bytes;
  final String? name;
}

/// Seam over `file_picker` for tests.
// ignore: one_member_abstracts
abstract class FilePickerWrapper {
  Future<PickedVideo?> pickVideo();
}

class _DefaultFilePickerWrapper implements FilePickerWrapper {
  const _DefaultFilePickerWrapper();

  @override
  Future<PickedVideo?> pickVideo() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.video,
      allowMultiple: false,
      // We don't ask for in-memory bytes by default — the file path is
      // enough on Android / iOS and bypasses the 100 MB memory cap on
      // older devices.
      withData: false,
    );
    if (result == null || result.files.isEmpty) return null;
    final file = result.files.single;
    return PickedVideo(
      path: file.path,
      bytes: file.bytes,
      name: file.name,
    );
  }
}

final manualVideoUploadServiceProvider =
    Provider<ManualVideoUploadService>((ref) {
  return ManualVideoUploadService(
    streamRepository: ref.watch(matchStreamRepositoryProvider),
    uploader: ref.watch(recordingUploaderProvider),
  );
});

// Touch supabaseClientProvider so the import is not flagged unused —
// it's the transitive dependency of recordingUploaderProvider.
// ignore: unused_element
SupabaseClient _touchClientImport(Ref ref) =>
    ref.watch(supabaseClientProvider);
