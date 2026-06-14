import 'package:flutter/foundation.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

/// Remontée d'erreur centralisée — remplace les `catch (e) { debugPrint(e) }`
/// qui avalaient l'erreur en prod (audit 2026-06-14, P0 observabilité).
///
/// Avant ce helper, ~50 `catch` côté repositories/services se contentaient
/// d'un `debugPrint` : invisible en release, donc Sentry n'avait jamais
/// connaissance de l'erreur. `reportError` :
///  * envoie systématiquement l'exception à Sentry (`captureException`) ;
///    l'appel est un no-op tolérant si `SentryFlutter.init` n'a pas tourné
///    (SENTRY_DSN absent, tests) — pas besoin de garder Sentry sous condition.
///  * conserve le `debugPrint` lisible **en debug uniquement**, pour ne rien
///    perdre du confort de dev.
///
/// À utiliser pour les erreurs **non bloquantes** qu'on avale volontairement
/// (le flux continue). Pour les erreurs qu'on relance, préférer `traceAsync`
/// (cf. `sentry_trace.dart`) ou un `rethrow` après l'appel.
///
/// Exemple :
/// ```dart
/// try {
///   await repo.sync();
/// } catch (e, st) {
///   reportError(e, st, context: 'SyncQueue.flush', hint: 'offline?');
/// }
/// ```
Future<void> reportError(
  Object error,
  StackTrace? stack, {
  /// Étiquette du site d'appel (`'PaymentRepository.submit'`) — posée en tag
  /// Sentry `arena.context` pour filtrer/regrouper les issues.
  String? context,

  /// Données structurées additionnelles (ids non-PII, statut, etc.).
  Map<String, dynamic>? extra,

  /// Indice humain libre (« offline? », « cache corrompu »).
  String? hint,

  /// Sévérité Sentry. `warning` par défaut : ce sont des erreurs avalées,
  /// pas des crashs. Monter à `error` pour un échec métier important.
  SentryLevel level = SentryLevel.warning,
}) async {
  if (kDebugMode) {
    final prefix = context == null ? '[error]' : '[$context]';
    debugPrint('$prefix $error${stack == null ? '' : '\n$stack'}');
  }
  await Sentry.captureException(
    error,
    stackTrace: stack,
    hint: hint == null ? null : Hint.withMap({'hint': hint}),
    withScope: (scope) {
      scope.level = level;
      if (context != null) {
        scope.setTag('arena.context', context);
      }
      if (extra != null) {
        for (final entry in extra.entries) {
          scope.setContexts(entry.key, entry.value);
        }
      }
    },
  );
}
