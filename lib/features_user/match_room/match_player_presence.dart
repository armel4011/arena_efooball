import 'dart:async';

import 'package:arena/data/models/arena_match.dart';
import 'package:arena/data/repositories/profile_repository.dart'
    show supabaseClientProvider;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Présence Realtime des JOUEURS dans la salle d'un match (Supabase Presence).
///
/// Chaque participant qui `watch` [matchPresentUserIdsProvider] est compté
/// comme présent (track de son `user_id`) tant que le widget est monté. Sert
/// à ne démarrer une partie de dames — plateau + horloges — QUE lorsque les
/// deux joueurs sont effectivement dans la salle (sinon un joueur absent se
/// ferait flagger au temps alors qu'il n'a jamais rejoint).
///
/// Calqué sur `MatchViewersService` (channel `match-presence-{matchId}`), mais
/// expose l'ensemble des `user_id` présents plutôt qu'un simple compteur.
class MatchPlayerPresenceService {
  MatchPlayerPresenceService(this._client);

  final SupabaseClient _client;

  /// S'abonne au channel de présence du match et émet l'ensemble des
  /// `user_id` présents. Annuler l'abonnement untrack + ferme le channel.
  Stream<Set<String>> watch({
    required String matchId,
    required String selfId,
  }) {
    final controller = StreamController<Set<String>>();
    final channel = _client.channel(
      'match-presence-$matchId',
      opts: const RealtimeChannelConfig(self: true),
    );

    Set<String> snapshot() {
      final ids = <String>{};
      for (final state in channel.presenceState()) {
        for (final pres in state.presences) {
          final uid = pres.payload['user_id'];
          if (uid is String && uid.isNotEmpty) ids.add(uid);
        }
      }
      return ids;
    }

    channel
      ..onPresenceSync((_) {
        if (!controller.isClosed) controller.add(snapshot());
      })
      ..subscribe((status, error) async {
        if (status == RealtimeSubscribeStatus.subscribed) {
          await channel.track({'user_id': selfId});
        }
      });

    controller.onCancel = () async {
      try {
        await channel.untrack();
      } catch (e) {
        debugPrint('[presence] untrack failed (channel may be closed): $e');
      }
      try {
        await channel.unsubscribe();
      } catch (e) {
        debugPrint('[presence] unsubscribe failed: $e');
      }
      await controller.close();
    };

    return controller.stream;
  }
}

final matchPlayerPresenceServiceProvider =
    Provider<MatchPlayerPresenceService>((ref) {
  return MatchPlayerPresenceService(ref.watch(supabaseClientProvider));
});

/// Ensemble des `user_id` présents dans la salle d'un match. Le widget qui
/// watch ce provider track sa propre présence. Clé : `(matchId, selfId)`.
final matchPresentUserIdsProvider = StreamProvider.family
    .autoDispose<Set<String>, ({String matchId, String selfId})>((ref, key) {
  return ref
      .watch(matchPlayerPresenceServiceProvider)
      .watch(matchId: key.matchId, selfId: key.selfId);
});

/// `true` quand les DEUX joueurs du match sont présents dans la salle.
/// Faux tant qu'un joueur manque, qu'un slot est vide (bye), ou avant la
/// première synchro de présence.
bool bothPlayersPresent(Set<String> present, ArenaMatch match) {
  final p1 = match.player1Id;
  final p2 = match.player2Id;
  if (p1 == null || p2 == null) return false;
  return present.contains(p1) && present.contains(p2);
}
