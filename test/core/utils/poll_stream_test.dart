// Audit 2026-05-19 — valide que `pollStream` fetch immédiatement puis à
// l'intervalle demandé. Couvre le downgrade Realtime → poll des 3
// providers (competitions_list, payments_history, watchActivePublic).
//
// Réécrit avec `fakeAsync` (temps VIRTUEL) le 2026-06-14 : la version
// d'origine utilisait des `Future.delayed` réels avec des intervalles
// serrés (50 ms) et comptait les émissions — intrinsèquement flaky sur un
// runner CI chargé (un tick de retard → 4 émissions au lieu de 3). En
// contrôlant l'horloge, le test devient déterministe.

import 'package:arena/core/utils/poll_stream.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('pollStream yield immédiat puis chaque intervalle', () {
    fakeAsync((async) {
      var calls = 0;
      final values = <int>[];
      final sub = pollStream(
        const Duration(milliseconds: 50),
        () async => ++calls,
      ).listen(values.add);

      // 1er fetch immédiat (résolution du Future via microtasks).
      async.flushMicrotasks();
      expect(values, [1]);

      // Chaque intervalle de 50 ms → exactement un tick de plus.
      async.elapse(const Duration(milliseconds: 50));
      expect(values, [1, 2]);

      async.elapse(const Duration(milliseconds: 50));
      expect(values, [1, 2, 3]);

      // Stoppe le polling, puis purge le timer en attente (la boucle
      // `while (true)` interne en reprogramme un) pour que fakeAsync ne
      // signale pas de timer pending à la sortie.
      sub.cancel();
      async.elapse(const Duration(milliseconds: 50));
    });
  });

  test('pollStream propage les exceptions du fetch', () {
    fakeAsync((async) {
      var calls = 0;
      final values = <int>[];
      final errors = <Object>[];
      final sub = pollStream(const Duration(milliseconds: 30), () async {
        calls++;
        if (calls == 2) throw StateError('boom');
        return calls;
      }).listen(values.add, onError: errors.add);

      async.flushMicrotasks();
      expect(values, [1]);

      // Le 2e fetch (à 30 ms) lève → l'erreur est propagée puis le stream
      // se termine (un async* qui throw clôt le générateur).
      async.elapse(const Duration(milliseconds: 30));
      expect(errors.length, 1);
      expect(errors.first, isA<StateError>());

      sub.cancel();
      async.elapse(const Duration(milliseconds: 30));
    });
  });
}
