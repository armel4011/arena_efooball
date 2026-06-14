import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:arena/core/utils/error_reporter.dart';
import 'package:go_router/go_router.dart';

/// Listens to incoming deep links and routes them inside the app.
///
/// Le flow de réinitialisation par OTP (PHASE 2.4) n'utilise plus de
/// deep link — l'utilisateur copie un code à 6 chiffres depuis l'email
/// et le saisit dans l'app. Ce service reste en place comme stub pour
/// les futurs deep links (Google OAuth web fallback, notifications tap,
/// share intents, etc.).
class DeepLinkService {
  DeepLinkService({required GoRouter router}) : _router = router;

  // ignore: unused_field
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
      unawaited(reportError(e, st, context: 'DeepLinkService.getInitialLink'));
    }

    // Warm: links received while the app is alive.
    _sub = _appLinks.uriLinkStream.listen(
      _handle,
      onError: (Object e, StackTrace st) {
        unawaited(reportError(e, st, context: 'DeepLinkService.uriLinkStream'));
      },
    );
  }

  void _handle(Uri uri) {
    if (uri.scheme != 'com.arena.app') return;
    // Aucun handler actif pour l'instant — voir docstring de classe.
  }

  Future<void> dispose() async {
    await _sub?.cancel();
    _sub = null;
  }
}
