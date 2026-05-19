// Audit 2026-05-19 — valide que `pollStream` fetch immédiatement puis à
// l'intervalle demandé. Couvre le downgrade Realtime → poll des 3
// providers (competitions_list, payments_history, watchActivePublic).

import 'package:arena/core/utils/poll_stream.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('pollStream yield immédiat puis chaque intervalle', () async {
    var calls = 0;
    Future<int> fetch() async => ++calls;

    final stream = pollStream(const Duration(milliseconds: 50), fetch);
    final values = <int>[];
    final sub = stream.listen(values.add);

    // 1er fetch est immédiat.
    await Future<void>.delayed(const Duration(milliseconds: 5));
    expect(values, [1]);

    // Après 75ms, on a eu le 1er tick (50ms).
    await Future<void>.delayed(const Duration(milliseconds: 70));
    expect(values.length, 2);

    // Après 130ms total, un 2e tick.
    await Future<void>.delayed(const Duration(milliseconds: 60));
    expect(values.length, 3);

    await sub.cancel();
  });

  test('pollStream propage les exceptions du fetch', () async {
    var calls = 0;
    Future<int> fetch() async {
      calls++;
      if (calls == 2) throw StateError('boom');
      return calls;
    }

    final stream = pollStream(const Duration(milliseconds: 30), fetch);
    final errors = <Object>[];
    final values = <int>[];
    final sub = stream.listen(values.add, onError: errors.add);

    await Future<void>.delayed(const Duration(milliseconds: 80));
    expect(values, [1]);
    expect(errors.length, 1);
    expect(errors.first, isA<StateError>());

    await sub.cancel();
  });
}
