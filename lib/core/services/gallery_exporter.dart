import 'dart:async';
import 'dart:io';

import 'package:arena/core/utils/error_reporter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Publishes a finished recording from the app's private cache to the
/// user-visible Download/ARENA folder via the `arena/native`
/// MethodChannel (MediaStore.Downloads API, Android 10+ only).
///
/// Best-effort by design: callers should treat failures as "the file
/// stays in cache, no big deal" rather than blocking the recording
/// stop flow.
class GalleryExporter {
  GalleryExporter({MethodChannel? channel})
      : _channel = channel ?? const MethodChannel('arena/native');

  final MethodChannel _channel;

  /// Copies [localPath] into Download/ARENA/ via MediaStore. Returns the
  /// `content://` URI on success, null on iOS / pre-Android 10 / missing
  /// source / OS denial.
  Future<String?> saveVideoToGallery(String localPath) async {
    if (!Platform.isAndroid) return null;
    if (localPath.isEmpty) return null;
    try {
      return await _channel.invokeMethod<String>(
        'saveVideoToGallery',
        {'path': localPath},
      );
    } on MissingPluginException {
      if (kDebugMode) {
        debugPrint('[gallery] native handler not registered yet');
      }
      return null;
    } catch (e, st) {
      unawaited(
        reportError(
          e,
          st,
          context: 'GalleryExporter.saveVideoToGallery',
        ),
      );
      return null;
    }
  }
}

final galleryExporterProvider =
    Provider<GalleryExporter>((_) => GalleryExporter());
