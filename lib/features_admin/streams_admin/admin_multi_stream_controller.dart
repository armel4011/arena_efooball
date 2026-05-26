import 'dart:async';

import 'package:arena/core/services/agora_multi_streaming_service.dart';
import 'package:arena/data/models/match_stream.dart';
import 'package:arena/data/repositories/match_stream_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Émet l'état des tuiles multi-stream tel que le service le maintient,
/// en synchronisant en parallèle ses joins/leaves avec la liste des
/// streams publics actifs.
///
/// La sync est triggée par `ref.listen` sur [activePublicStreamsProvider]
/// avec `fireImmediately` — donc dès que la page subscribe à ce provider,
/// les joins partent. Au dispose (admin sort de la page), le service
/// autodispose `leaveAll` + `release`.
final adminMultiStreamStatesProvider = StreamProvider.autoDispose<
    Map<String, MultiTileState>>((ref) {
  final svc = ref.watch(agoraMultiStreamingServiceProvider);

  ref.listen<AsyncValue<List<MatchStream>>>(
    activePublicStreamsProvider,
    (prev, next) {
      final list = next.value;
      if (list == null) return;
      final wanted = list.map((s) => s.matchId).toSet();
      final current = svc.states.keys.toSet();
      for (final id in wanted.difference(current)) {
        unawaited(svc.joinAudience(id));
      }
      for (final id in current.difference(wanted)) {
        unawaited(svc.leave(id));
      }
    },
    fireImmediately: true,
  );

  // Émet l'état courant tout de suite (avant que statesStream ne fire),
  // pour éviter un AsyncLoading inutile à l'ouverture quand on a déjà
  // des tuiles en cours de join.
  return Stream<Map<String, MultiTileState>>.multi((controller) {
    controller.add(svc.states);
    final sub = svc.statesStream.listen(
      controller.add,
      onError: controller.addError,
    );
    controller.onCancel = sub.cancel;
  });
});
