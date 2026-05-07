import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

/// Outcome of a permission request, normalized across platforms.
///
/// We intentionally collapse `granted` and `limited` (iOS Photos) into a
/// single `granted` since both unlock the feature for our use cases.
enum PermissionOutcome {
  granted,
  denied,
  permanentlyDenied,
  restricted,
  unsupported,
}

extension PermissionOutcomeX on PermissionOutcome {
  bool get isGranted => this == PermissionOutcome.granted;
  bool get needsSettings => this == PermissionOutcome.permanentlyDenied;
}

/// Centralized permission requester for PHASE 8 (anti-cheat + streaming).
///
/// Wraps `permission_handler` and adds Android-specific flows that the
/// package does not handle out of the box (PACKAGE_USAGE_STATS, which can
/// only be granted via Settings, and SYSTEM_ALERT_WINDOW which requires a
/// dedicated overlay permission screen on Android 6+).
///
/// Native MediaProjection consent (screen recording) is requested at the
/// moment recording starts — the OS dialog is provided by the OEM and not
/// brokered by `permission_handler`.
class PermissionsService {
  PermissionsService({PermissionRequester? requester})
      : _requester = requester ?? const _DefaultPermissionRequester();

  final PermissionRequester _requester;

  /// Microphone permission.
  ///
  /// Required by both the anti-cheat recording (audio track) and Agora
  /// RTC streaming (broadcaster mic). Asked together with camera when
  /// streaming kicks in.
  Future<PermissionOutcome> requestMicrophone() {
    return _requester.request(Permission.microphone);
  }

  /// Camera permission.
  ///
  /// Only used by Agora RTC streaming for the front-facing camera overlay
  /// during finals. Anti-cheat recording does NOT need the camera.
  Future<PermissionOutcome> requestCamera() {
    return _requester.request(Permission.camera);
  }

  /// Notifications permission (Android 13+ runtime; iOS).
  ///
  /// Needed both for the foreground service ongoing notification ("ARENA
  /// enregistre votre match") and FCM push (PHASE 10).
  Future<PermissionOutcome> requestNotifications() {
    return _requester.request(Permission.notification);
  }

  /// Overlay / "Display over other apps" permission (Android only).
  ///
  /// Required by `flutter_overlay_window` to render the floating button
  /// on top of eFootball. The OS shows a full-screen settings page rather
  /// than a regular permission dialog.
  Future<PermissionOutcome> requestOverlay() {
    if (!Platform.isAndroid) return _unsupported();
    return _requester.request(Permission.systemAlertWindow);
  }

  /// PACKAGE_USAGE_STATS permission (Android only).
  ///
  /// Required by `app_usage` to detect when eFootball / FIFA enters the
  /// foreground. The OS does NOT expose this as a runtime dialog: the
  /// user must toggle it in Settings → Apps → Special access → Usage
  /// access. PHASE 8.2 will plug `app_usage.UsageStats.checkUsage…` to
  /// detect the actual grant state and open the right intent. For now
  /// we just open the app settings page so the wrapper has a stable
  /// signature and the caller can route the user there.
  Future<PermissionOutcome> requestUsageStats() async {
    if (!Platform.isAndroid) return _unsupported();
    final opened = await _requester.openSettings();
    return opened ? PermissionOutcome.denied : PermissionOutcome.denied;
  }

  /// Photo / video library permission for the manual upload flow.
  ///
  /// On Android 13+ this maps to READ_MEDIA_VIDEO; on Android 12- it
  /// falls back to READ_EXTERNAL_STORAGE. On iOS it asks for Photos.
  Future<PermissionOutcome> requestMediaLibrary() {
    final permission = Platform.isAndroid ? Permission.videos : Permission.photos;
    return _requester.request(permission);
  }

  /// Bundle for the anti-cheat recording start.
  ///
  /// Asks microphone + notifications. The MediaProjection consent dialog
  /// is shown by the OS later, when `flutter_screen_recording.start()` is
  /// invoked.
  Future<RecordingPermissionsBundle> requestRecordingBundle() async {
    final mic = await requestMicrophone();
    final notifs = await requestNotifications();
    return RecordingPermissionsBundle(microphone: mic, notifications: notifs);
  }

  /// Open the OS settings page for this app — used as the recovery flow
  /// when an outcome is `permanentlyDenied`.
  Future<bool> openAppSettingsPage() {
    return _requester.openSettings();
  }

  Future<PermissionOutcome> _unsupported() async {
    if (kDebugMode) {
      debugPrint('[permissions] requested permission unsupported on this OS');
    }
    return PermissionOutcome.unsupported;
  }
}

/// Result of [PermissionsService.requestRecordingBundle].
///
/// Both fields must be `granted` for recording to start safely. We keep
/// them separate so the UI can show a precise message ("autorise le micro"
/// vs "autorise les notifications") instead of a generic error.
class RecordingPermissionsBundle {
  const RecordingPermissionsBundle({
    required this.microphone,
    required this.notifications,
  });

  final PermissionOutcome microphone;
  final PermissionOutcome notifications;

  bool get allGranted => microphone.isGranted && notifications.isGranted;
}

/// Seam for tests — allows mocking the underlying `permission_handler`
/// calls without touching native code.
abstract class PermissionRequester {
  Future<PermissionOutcome> request(Permission permission);
  Future<bool> openSettings();
}

class _DefaultPermissionRequester implements PermissionRequester {
  const _DefaultPermissionRequester();

  @override
  Future<PermissionOutcome> request(Permission permission) async {
    final status = await permission.request();
    return _toOutcome(status);
  }

  @override
  Future<bool> openSettings() => openAppSettings();

  PermissionOutcome _toOutcome(PermissionStatus status) {
    if (status.isGranted || status.isLimited) return PermissionOutcome.granted;
    if (status.isPermanentlyDenied) return PermissionOutcome.permanentlyDenied;
    if (status.isRestricted) return PermissionOutcome.restricted;
    return PermissionOutcome.denied;
  }
}
