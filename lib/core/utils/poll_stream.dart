/// Stream qui émet le résultat de [fetch] toutes les [interval].
///
/// Pattern de downgrade Realtime → HTTP polling pour scaler.
/// 1 connexion WebSocket par client par stream Supabase devient
/// prohibitif au-delà de 50k users actifs concurrents (limite Pro plan
/// = 500 channels). À l'inverse, le polling reste linéaire avec les
/// requêtes/s — supporté par PostgREST sans plafond.
///
/// Le 1er fetch est immédiat ; chaque tick suivant attend [interval]
/// (cancel-safe via `await for` côté Riverpod).
Stream<T> pollStream<T>(
  Duration interval,
  Future<T> Function() fetch,
) async* {
  yield await fetch();
  while (true) {
    await Future<void>.delayed(interval);
    yield await fetch();
  }
}
