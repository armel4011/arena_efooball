import 'package:arena/data/repositories/admin_chat_repository.dart';
import 'package:arena/data/repositories/friends_repository.dart';
import 'package:arena/data/repositories/notification_repository.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Service léger qui invalide les `StreamProvider` Supabase temps réel
/// quand l'app revient au foreground.
///
/// **Pourquoi ce service ?** Le Supabase Realtime WebSocket peut tomber
/// silencieusement quand l'OS backgrounde l'app (Doze mode Android,
/// suspension iOS, switch entre apps, mode économie). Le client SDK ne
/// reconnecte pas toujours immédiatement, et même quand il reconnecte
/// les souscriptions actives n'ont pas reçu les events INSERT/UPDATE
/// qui se sont produits pendant le black-out → l'utilisateur voit des
/// données obsolètes en rouvrant l'app.
///
/// Stratégie : au lifecycle `resumed`, on invalide les providers temps
/// réel les plus critiques. Riverpod ferme leur subscription, le stream
/// repart de zéro avec un fetch initial frais + une nouvelle souscription
/// realtime → l'utilisateur voit l'état à jour en <2s.
///
/// On ne reconnecte PAS au lifecycle `paused` — ferme la connexion
/// inutilement et ne gagne rien (le système Android peut tuer le socket
/// par lui-même). On laisse Supabase gérer ça.
///
/// **Comment l'activer** : appeler `ref.watch(realtimeResumeServiceProvider)`
/// dans un widget racine de l'app (ex. MainLayout). Le provider est
/// keep-alive, donc une seule instance pour toute la session.
class RealtimeResumeService extends WidgetsBindingObserver {
  RealtimeResumeService(this._ref);

  final Ref _ref;
  bool _attached = false;

  void attach() {
    if (_attached) return;
    WidgetsBinding.instance.addObserver(this);
    _attached = true;
  }

  void detach() {
    if (!_attached) return;
    WidgetsBinding.instance.removeObserver(this);
    _attached = false;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;

    // Garde anti-rafale : si le socket Realtime est TOUJOURS ouvert au retour
    // au premier plan (court switch d'app, background bref), il n'a manqué
    // aucun event INSERT/UPDATE → inutile d'invalider. Invalider quand même
    // détruirait + rejoindrait 6 canaux d'un coup, ce qui empile des
    // jointures sur la limite de taux Supabase (`ChannelRateLimitReached`).
    // On ne force la re-souscription QUE lorsque le socket a réellement chuté
    // (Doze/suspension longue) — là, le SDK reconnecte de toute façon et on
    // veut en plus un fetch frais pour rattraper les events manqués.
    if (Supabase.instance.client.realtime.isConnected) return;

    _ref
      ..invalidate(userNotificationsProvider)
      ..invalidate(userAdminMessagesProvider)
      ..invalidate(incomingFriendRequestsProvider)
      ..invalidate(outgoingFriendRequestsProvider)
      ..invalidate(acceptedFriendsProvider)
      ..invalidate(incomingFriendRequestsCountProvider);
  }
}

/// Service singleton — keep-alive sur toute la session. A watcher dans
/// un widget racine (MainLayout) pour que l'observer reste attache.
final realtimeResumeServiceProvider = Provider<RealtimeResumeService>((ref) {
  final svc = RealtimeResumeService(ref)..attach();
  ref.onDispose(svc.detach);
  return svc;
});
