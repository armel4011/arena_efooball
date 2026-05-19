import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

/// Observe les providers Riverpod et capture les exceptions vers Sentry.
///
/// Phase 4 observabilité (audit 2026-05-19) : sans cet observer, une
/// exception qui throw depuis un FutureProvider est swallow par
/// `AsyncValue.error` et ne remonte ni dans la console ni dans Sentry
/// — on découvre le bug seulement parce que l'UI affiche un message
/// d'erreur. Ici on capture systématiquement + breadcrumb.
class SentryProviderObserver extends ProviderObserver {
  const SentryProviderObserver();

  @override
  void providerDidFail(
    ProviderBase<Object?> provider,
    Object error,
    StackTrace stackTrace,
    ProviderContainer container,
  ) {
    Sentry.addBreadcrumb(
      Breadcrumb(
        category: 'riverpod',
        message: 'provider ${provider.name ?? provider.runtimeType} failed',
        level: SentryLevel.error,
      ),
    );
    Sentry.captureException(
      error,
      stackTrace: stackTrace,
      withScope: (scope) {
        scope.setTag('riverpod.provider', provider.name ?? '<anon>');
      },
    );
  }
}
