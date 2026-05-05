import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:arena/core/router/user_router.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';

/// Listens to incoming deep links and routes them inside the app.
///
/// Currently only handles the Supabase password-recovery deep link
/// (`com.arena.app://reset-password`). Supabase 2.x already hydrates the
/// recovery session on its own internal `app_links` listener — we just
/// have to forward navigation to [UserRoutes.resetPassword].
class DeepLinkService {
  DeepLinkService({required GoRouter router}) : _router = router;

  final GoRouter _router;
  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _sub;

  /// Starts listening. Safe to call multiple times — the previous
  /// subscription is cancelled first.
  Future<void> start() async {
    await _sub?.cancel();

    // Cold start: an external link may have launched the app.
    try {
      final initial = await _appLinks.getInitialLink();
      if (initial != null) _handle(initial);
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('[deep-link] getInitialLink failed: $e\n$st');
      }
    }

    // Warm: links received while the app is alive.
    _sub = _appLinks.uriLinkStream.listen(
      _handle,
      onError: (Object e, StackTrace st) {
        if (kDebugMode) {
          debugPrint('[deep-link] uriLinkStream error: $e\n$st');
        }
      },
    );
  }

  void _handle(Uri uri) {
    if (uri.scheme != 'com.arena.app') return;
    if (uri.host == 'reset-password') {
      _router.go(UserRoutes.resetPassword);
    }
  }

  Future<void> dispose() async {
    await _sub?.cancel();
    _sub = null;
  }
}
