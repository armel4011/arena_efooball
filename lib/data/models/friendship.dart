import 'package:freezed_annotation/freezed_annotation.dart';

part 'friendship.freezed.dart';
part 'friendship.g.dart';

/// Mirror of `public.friendships` (Phase 13).
///
/// Une row par paire (least/greatest enforced via unique index). Le
/// statut décrit l'état courant :
///   - `pending`   : `requester_id` a envoyé la demande à `addressee_id`
///   - `accepted`  : les deux sont amis ; l'ordre requester/addressee
///                   n'a plus de signification
///   - `blocked`   : `blocked_by` (qui est requester_id ou addressee_id)
///                   a bloqué l'autre — seul le bloqueur peut unblock
@Freezed(fromJson: true, toJson: true)
sealed class Friendship with _$Friendship {
  const factory Friendship({
    required String id,
    required String requesterId,
    required String addresseeId,
    @Default('pending') String status,
    String? blockedBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _Friendship;

  const Friendship._();

  factory Friendship.fromJson(Map<String, dynamic> json) =>
      _$FriendshipFromJson(json);

  bool get isPending => status == 'pending';
  bool get isAccepted => status == 'accepted';
  bool get isBlocked => status == 'blocked';

  /// L'autre membre de la paire vu depuis `me`.
  String otherUserId(String me) =>
      requesterId == me ? addresseeId : requesterId;

  /// True si je suis celui qui a bloqué (peut donc débloquer).
  bool isBlockerMe(String me) => isBlocked && blockedBy == me;

  /// True si j'ai envoyé la requête (pending sortante).
  bool isOutgoingPending(String me) => isPending && requesterId == me;

  /// True si je suis la cible d'une requête (pending entrante).
  bool isIncomingPending(String me) => isPending && addresseeId == me;
}

/// État dérivé pour le CTA principal sur la page profil public d'un
/// joueur cible. Permet aux pages de switch dessus sans répéter la
/// logique de transition.
enum FriendCtaState {
  none, // aucune amitié → bouton "Ajouter"
  outgoingPending, // tu as envoyé une demande → "Demande envoyée"
  incomingPending, // tu as reçu une demande → "Accepter / Refuser"
  friends, // déjà amis → "Retirer l'ami"
  blockedByMe, // tu l'as bloqué → "Débloquer"
  blockedByThem, // il t'a bloqué → CTA "Ajouter" désactivé / cacher
}

extension FriendCtaResolver on Friendship? {
  /// Renvoie l'état pour `me` face à `target`. Si l'objet Friendship est
  /// null, c'est qu'aucun lien n'existe → [FriendCtaState.none].
  FriendCtaState ctaStateFor(String me) {
    final f = this;
    if (f == null) return FriendCtaState.none;
    if (f.isAccepted) return FriendCtaState.friends;
    if (f.isPending) {
      return f.isOutgoingPending(me)
          ? FriendCtaState.outgoingPending
          : FriendCtaState.incomingPending;
    }
    if (f.isBlocked) {
      return f.isBlockerMe(me)
          ? FriendCtaState.blockedByMe
          : FriendCtaState.blockedByThem;
    }
    return FriendCtaState.none;
  }
}
