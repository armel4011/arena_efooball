import 'dart:io';

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
      if (kDebugMode) {
        debugPrint('[gallery] saveVideoToGallery failed: $e\n$st');
      }
      return null;
    }
  }

  /// Captures ARENA's foreground window into a PNG inside Download/ARENA/.
  /// When the game is in foreground the capture is whatever ARENA last
  /// rendered (limitation: a parallel MediaProjection session is needed
  /// to capture the underlying game — deferred to a later phase).
  Future<String?> takeScreenshot() async {
    if (!Platform.isAndroid) return null;
    try {
      return await _channel.invokeMethod<String>('takeScreenshot');
    } on MissingPluginException {
      if (kDebugMode) {
        debugPrint('[gallery] native handler not registered yet');
      }
      return null;
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('[gallery] takeScreenshot failed: $e\n$st');
      }
      return null;
    }
  }
}

final galleryExporterProvider = Provider<GalleryExporter>((_) => GalleryExporter());
