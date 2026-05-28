import 'package:arena/data/repositories/admin_chat_repository.dart';
import 'package:arena/data/repositories/friends_repository.dart';
import 'package:arena/data/repositories/notification_repository.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
    // Resume → invalide les StreamProviders qui dependent du WebSocket
    // Supabase. Les ecrans qui les consomment vont se re-render avec un
    // loader court (~1-2s) puis afficher l'etat a jour.
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
