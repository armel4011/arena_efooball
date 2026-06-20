// Tests unitaires — `matchAccessLock` : politique d'accès « T-5 min » à la
// salle de match. Logique pure (pas de widget), facile à couvrir exhaustivement.

import 'package:arena/data/models/arena_match.dart';
import 'package:arena/data/models/match_status.dart';
import 'package:arena/features_user/match_room/match_room_page.dart';
import 'package:flutter_test/flutter_test.dart';

ArenaMatch _match({
  MatchStatus status = MatchStatus.pending,
  DateTime? scheduledAt,
}) =>
    ArenaMatch(
      id: 'm-1',
      competitionId: 'c-1',
      status: status,
      scheduledAt: scheduledAt,
    );

void main() {
  test('match planifié au-delà de T-5 min → verrouillé jusqu\'à scheduledAt-5min',
      () {
    final at = DateTime.now().add(const Duration(hours: 1));
    final lock = matchAccessLock(_match(scheduledAt: at));
    expect(lock, isNotNull);
    expect(lock!.opensAt, at.subtract(const Duration(minutes: 5)));
  });

  test('match dans la fenêtre T-5 min → accès ouvert (null)', () {
    final at = DateTime.now().add(const Duration(minutes: 2));
    expect(matchAccessLock(_match(scheduledAt: at)), isNull);
  });

  test('match sans horaire (pending) → verrouillé sans rebours (opensAt null)',
      () {
    final lock = matchAccessLock(_match(scheduledAt: null));
    expect(lock, isNotNull);
    expect(lock!.opensAt, isNull);
  });

  test('match déjà en cours → accès ouvert quel que soit scheduledAt', () {
    final at = DateTime.now().add(const Duration(hours: 1));
    expect(
      matchAccessLock(
        _match(status: MatchStatus.inProgress, scheduledAt: at),
      ),
      isNull,
    );
  });

  test('match terminé → accès ouvert', () {
    expect(
      matchAccessLock(_match(status: MatchStatus.completed)),
      isNull,
    );
  });

  test('statut scheduled à venir (>T-5) → verrouillé', () {
    final at = DateTime.now().add(const Duration(minutes: 30));
    final lock = matchAccessLock(_match(status: MatchStatus.scheduled, scheduledAt: at));
    expect(lock, isNotNull);
    expect(lock!.opensAt, at.subtract(const Duration(minutes: 5)));
  });
}
