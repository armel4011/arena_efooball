import 'package:sentry_flutter/sentry_flutter.dart';

/// Wrap [body] dans une transaction Sentry nommée `op/description`.
///
/// Phase 4 observabilité (audit 2026-05-19) : permet de mesurer la
/// latence des chemins critiques (création compét., soumission score,
/// validation paiement) en plus du sampling HTTP auto. La transaction
/// est marquée `internalError` si [body] throw, puis ré-throwée.
///
/// Le sample rate global est `tracesSampleRate` de `SentryFlutter.init`
/// (20% en release, 100% en debug). Cet helper ne le surcharge pas.
///
/// Exemple :
/// ```dart
/// final id = await traceAsync('admin.competition.create', 'p11.a8', () {
///   return repo.create(payload);
/// });
/// ```
Future<T> traceAsync<T>(
  String op,
  String description,
  Future<T> Function() body,
) async {
  final tx = Sentry.startTransaction(op, op, description: description);
  try {
    final result = await body();
    tx.status = const SpanStatus.ok();
    return result;
  } catch (e, st) {
    tx
      ..status = const SpanStatus.internalError()
      ..throwable = e;
    await Sentry.captureException(e, stackTrace: st);
    rethrow;
  } finally {
    await tx.finish();
  }
}

/// Wrap [body] dans un span enfant de la transaction Sentry courante.
/// À utiliser DANS une opération déjà tracée (par ex. INSERT cascade
/// pendant la création compét.). Crée une mesure isolée du parent.
Future<T> traceSpan<T>(
  String op,
  String description,
  Future<T> Function() body,
) async {
  final span = Sentry.getSpan()?.startChild(op, description: description);
  try {
    final result = await body();
    span?.status = const SpanStatus.ok();
    return result;
  } catch (e) {
    span?.status = const SpanStatus.internalError();
    rethrow;
  } finally {
    await span?.finish();
  }
}
