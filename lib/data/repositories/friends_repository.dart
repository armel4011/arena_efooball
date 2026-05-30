import 'package:arena/core/services/persistent_cache.dart';
import 'package:arena/data/models/friendship.dart';
import 'package:arena/data/models/profile.dart';
import 'package:arena/data/repositories/profile_repository.dart';
import 'package:arena/features_shared/auth_common/shared_auth_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Phase 13 — Lecture / mutation des `friendships`.
///
/// - Lecture : SELECT direct sur la table (RLS `friendships_self_select`
///   garde l'isolation par paire).
/// - Mutation : passe systématiquement par les RPC `security definer`
///   (send_friend_request, accept_friend_request, decline_friend_request,
///   remove_friend, block_user, unblock_user). La table n'a pas de
///   policy INSERT/UPDATE/DELETE pour le rôle authenticated.
class FriendsRepository {
  const FriendsRepository(this._client);

  static const _table = 'friendships';
  static const _profilesTable = 'profiles';

  final SupabaseClient _client;

  // ───── Lectures ─────────────────────────────────────────────────────────

  /// Renvoie une friendship par id. Utilisé par `FriendChatPage` pour
  /// résoudre le peer profile depuis un friendship_id en URL.
  Future<Friendship?> getById(String id) async {
    final row = await _client
        .from(_table)
        .select()
        .eq('id', id)
        .maybeSingle();
    if (row == null) return null;
    return Friendship.fromJson(row);
  }

  /// Renvoie l'éventuelle row liant `me` et `target` (peu importe le statut).
  Future<Friendship?> findBetween({
    required String me,
    required String target,
  }) async {
    final rows = await _client
        .from(_table)
        .select()
        .or(
          'and(requester_id.eq.$me,addressee_id.eq.$target),'
          'and(requester_id.eq.$target,addressee_id.eq.$me)',
        )
        .limit(1);
    final list = rows as List<dynamic>;
    if (list.isEmpty) return null;
    return Friendship.fromJson(list.first as Map<String, dynamic>);
  }

  /// Toutes les amitiés acceptées de `me`. Renvoie les Friendship rows ;
  /// la résolution profil → `listFriendProfiles` ci-dessous.
  /// Cap à 200 (super-connectors gèrent leur liste, l'app affiche le
  /// reste via une recherche).
  Future<List<Friendship>> listAccepted(String me, {int limit = 200}) async {
    final rows = await _client
        .from(_table)
        .select()
        .or('requester_id.eq.$me,addressee_id.eq.$me')
        .eq('status', 'accepted')
        .order('updated_at', ascending: false)
        .limit(limit);
    return [
      for (final row in rows as List<dynamic>)
        Friendship.fromJson(row as Map<String, dynamic>),
    ];
  }

  /// Demandes pending entrantes (addressee = me). Pour l'onglet "Demandes".
  /// Cap à 100 (UX : un user qui en accumule plus n'a pas l'usage d'une
  /// liste exhaustive, qu'il fasse tri/accept/reject d'abord).
  Future<List<Friendship>> listIncomingPending(
    String me, {
    int limit = 100,
  }) async {
    final rows = await _client
        .from(_table)
        .select()
        .eq('addressee_id', me)
        .eq('status', 'pending')
        .order('created_at', ascending: false)
        .limit(limit);
    return [
      for (final row in rows as List<dynamic>)
        Friendship.fromJson(row as Map<String, dynamic>),
    ];
  }

  /// Demandes pending sortantes (requester = me). Cap à 100.
  Future<List<Friendship>> listOutgoingPending(
    String me, {
    int limit = 100,
  }) async {
    final rows = await _client
        .from(_table)
        .select()
        .eq('requester_id', me)
        .eq('status', 'pending')
        .order('created_at', ascending: false)
        .limit(limit);
    return [
      for (final row in rows as List<dynamic>)
        Friendship.fromJson(row as Map<String, dynamic>),
    ];
  }

  /// Utilisateurs que `me` a bloqués (`blocked_by = me`). Le bloqueur est
  /// le seul qui voit ces rows comme actionnables (unblock). Cap à 50
  /// (cas marginal, qui bloque 50+ users a un autre problème).
  Future<List<Friendship>> listBlockedByMe(String me, {int limit = 50}) async {
    final rows = await _client
        .from(_table)
        .select()
        .eq('status', 'blocked')
        .eq('blocked_by', me)
        .limit(limit);
    return [
      for (final row in rows as List<dynamic>)
        Friendship.fromJson(row as Map<String, dynamic>),
    ];
  }

  /// Convertit une liste de Friendship en couples (friendship, peer profile)
  /// en un seul round-trip via `in.(...)`.
  ///
  /// **Selection partielle** : on omet les colonnes lourdes (stats jsonb,
  /// fcm_token, voip_token, whatsapp_number, kyc_*, referral_*, totp_*,
  /// timezone, currencies) qui ne servent pas pour la liste d'amis —
  /// seuls username + avatar + badge actif/banni sont consommes par
  /// `friends_page.dart` et `public_profile_page.dart`. Reduit le
  /// payload de ~2 KB → ~150 octets par profil (×20-200 amis).
  ///
  /// On garde quand meme `email`, `country_code` car `Profile` les
  /// declare `required` (Freezed leverait sinon une exception missing-key).
  static const _peerColumns =
      'id, username, email, country_code, avatar_color, role, '
      'is_active, permanent_ban, deleted_at, created_at, updated_at';

  Future<List<(Friendship, Profile)>> resolvePeers({
    required String me,
    required List<Friendship> friendships,
  }) async {
    if (friendships.isEmpty) return const [];
    final ids = {for (final f in friendships) f.otherUserId(me)};
    final rows = await _client
        .from(_profilesTable)
        .select(_peerColumns)
        .inFilter('id', ids.toList());
    final byId = <String, Profile>{
      for (final row in rows as List<dynamic>)
        () {
          final p = Profile.fromJson(row as Map<String, dynamic>);
          return p.id;
        }(): Profile.fromJson(row as Map<String, dynamic>),
    };
    return [
      for (final f in friendships)
        if (byId[f.otherUserId(me)] != null)
          (f, byId[f.otherUserId(me)]!),
    ];
  }

  /// Recherche profils par username (ilike, case-insensitive). Exclut
  /// `me`, les comptes désactivés, supprimés ou bannis à vie.
  Future<List<Profile>> searchByUsername({
    required String query,
    required String me,
    int limit = 20,
  }) async {
    final trimmed = query.trim();
    if (trimmed.length < 2) return const [];
    final pattern = '%${trimmed.replaceAll('%', r'\%')}%';
    final rows = await _client
        .from(_profilesTable)
        .select()
        .ilike('username', pattern)
        .eq('is_active', true)
        .eq('permanent_ban', false)
        .filter('deleted_at', 'is', null)
        .neq('id', me)
        .limit(limit);
    return [
      for (final row in rows as List<dynamic>)
        Profile.fromJson(row as Map<String, dynamic>),
    ];
  }

  /// Récupère un profil public par username (case-insensitive).
  Future<Profile?> findByUsername(String username) async {
    final trimmed = username.trim();
    if (trimmed.isEmpty) return null;
    final row = await _client
        .from(_profilesTable)
        .select()
        .ilike('username', trimmed)
        .eq('is_active', true)
        .filter('deleted_at', 'is', null)
        .maybeSingle();
    if (row == null) return null;
    return Profile.fromJson(row);
  }

  /// Stream temps réel du compteur de demandes pending entrantes —
  /// alimente le badge dans le tab profil.
  Stream<int> watchIncomingPendingCount(String me) {
    return _client
        .from(_table)
        .stream(primaryKey: ['id'])
        .eq('addressee_id', me)
        .map(
          (rows) => rows.where((r) => r['status'] == 'pending').length,
        );
  }

  // ───── Streams realtime (listes + peers) ────────────────────────────────
  //
  // Ces 3 streams alimentent les providers `incomingFriendRequests*` /
  // `outgoingFriendRequests*` / `acceptedFriends*` en mode realtime —
  // l'utilisateur voit immediatement les demandes acceptees / declinees
  // / nouvelles amities sans pull-refresh.
  //
  // Pattern : `.stream(primaryKey: ['id'])` + 1 filtre serveur (.eq) +
  // filtre client sur le statut + `asyncMap()` qui re-resout les peers
  // a chaque update. Le re-fetch profils n'est pas optimal (1 select
  // a chaque event) mais les listes sont petites (cap a 50-200) et les
  // mutations rares — pas la peine de bricoler un cache pour V1.

  /// Demandes pending entrantes en realtime (avec profil peer resolu).
  Stream<List<(Friendship, Profile)>> watchIncomingPendingWithPeers(String me) {
    return _client
        .from(_table)
        .stream(primaryKey: ['id'])
        .eq('addressee_id', me)
        .asyncMap((rows) async {
          final friendships = [
            for (final r in rows)
              if (r['status'] == 'pending') Friendship.fromJson(r),
          ];
          return resolvePeers(me: me, friendships: friendships);
        });
  }

  /// Demandes pending sortantes en realtime (avec profil peer resolu).
  Stream<List<(Friendship, Profile)>> watchOutgoingPendingWithPeers(String me) {
    return _client
        .from(_table)
        .stream(primaryKey: ['id'])
        .eq('requester_id', me)
        .asyncMap((rows) async {
          final friendships = [
            for (final r in rows)
              if (r['status'] == 'pending') Friendship.fromJson(r),
          ];
          return resolvePeers(me: me, friendships: friendships);
        });
  }

  /// Amitiés acceptées en realtime (avec profil peer resolu).
  /// Note : `.stream()` ne supporte pas OR cote serveur, donc on
  /// souscrit a TOUTE la table (la RLS `friendships_self_select` filtre
  /// deja a ce que `me` peut voir) et on filtre client.
  Stream<List<(Friendship, Profile)>> watchAcceptedWithPeers(String me) {
    return _client
        .from(_table)
        .stream(primaryKey: ['id'])
        .asyncMap((rows) async {
          final friendships = [
            for (final r in rows)
              if (r['status'] == 'accepted' &&
                  (r['requester_id'] == me || r['addressee_id'] == me))
                Friendship.fromJson(r),
          ]..sort((a, b) {
              final au = a.updatedAt ?? a.createdAt ?? DateTime(0);
              final bu = b.updatedAt ?? b.createdAt ?? DateTime(0);
              return bu.compareTo(au);
            });
          return resolvePeers(me: me, friendships: friendships);
        });
  }

  // ───── Mutations via RPC ────────────────────────────────────────────────

  Future<String> sendRequest(String targetId) async {
    final result = await _client.rpc<String>(
      'send_friend_request',
      params: {'p_target': targetId},
    );
    return result;
  }

  Future<void> accept(String friendshipId) async {
    await _client.rpc<void>(
      'accept_friend_request',
      params: {'p_friendship_id': friendshipId},
    );
  }

  Future<void> decline(String friendshipId) async {
    await _client.rpc<void>(
      'decline_friend_request',
      params: {'p_friendship_id': friendshipId},
    );
  }

  Future<void> remove(String targetId) async {
    await _client.rpc<void>(
      'remove_friend',
      params: {'p_target': targetId},
    );
  }

  Future<void> block(String targetId) async {
    await _client.rpc<void>(
      'block_user',
      params: {'p_target': targetId},
    );
  }

  Future<void> unblock(String targetId) async {
    await _client.rpc<void>(
      'unblock_user',
      params: {'p_target': targetId},
    );
  }
}

final friendsRepositoryProvider = Provider<FriendsRepository>((ref) {
  return FriendsRepository(ref.watch(supabaseClientProvider));
});

/// Demandes pending entrantes — liste affichée onglet "Demandes" + badge.
/// **Realtime** : un user qui accepte/decline ou un nouveau requesteur
/// apparait sans pull-refresh.
final incomingFriendRequestsProvider =
    StreamProvider.autoDispose<List<(Friendship, Profile)>>((ref) async* {
  final me = ref.watch(currentSessionProvider)?.user.id;
  if (me == null) {
    yield const [];
    return;
  }
  // Offline-safe : l'onglet "Demandes" reste fige sur les dernieres
  // demandes connues au lieu d'un _ErrorList reseau hors-ligne.
  final cache = await ref.watch(persistentCacheProvider.future);
  yield* cache.hydratePairs<Friendship, Profile>(
    namespace: 'friends.incoming.$me',
    source:
        ref.watch(friendsRepositoryProvider).watchIncomingPendingWithPeers(me),
    fromJsonA: Friendship.fromJson,
    fromJsonB: Profile.fromJson,
    toJsonA: (f) => f.toJson(),
    toJsonB: (p) => p.toJson(),
  );
});

/// Demandes pending sortantes (visibilité utile dans l'onglet "Demandes").
/// **Realtime** : quand la cible accepte, la demande disparait instantly.
/// Cache offline-safe identique aux demandes entrantes.
final outgoingFriendRequestsProvider =
    StreamProvider.autoDispose<List<(Friendship, Profile)>>((ref) async* {
  final me = ref.watch(currentSessionProvider)?.user.id;
  if (me == null) {
    yield const [];
    return;
  }
  final cache = await ref.watch(persistentCacheProvider.future);
  yield* cache.hydratePairs<Friendship, Profile>(
    namespace: 'friends.outgoing.$me',
    source:
        ref.watch(friendsRepositoryProvider).watchOutgoingPendingWithPeers(me),
    fromJsonA: Friendship.fromJson,
    fromJsonB: Profile.fromJson,
    toJsonA: (f) => f.toJson(),
    toJsonB: (p) => p.toJson(),
  );
});

/// Liste amis acceptés + profil joueur.
/// **Realtime** : nouvel ami apparait sans refresh, ami retire disparait.
/// **Cold start cache (Phase 2 offline)** : liste persistee → la page
/// "Mes amis" reste utilisable hors ligne avec la derniere photo connue.
final acceptedFriendsProvider =
    StreamProvider.autoDispose<List<(Friendship, Profile)>>((ref) async* {
  final me = ref.watch(currentSessionProvider)?.user.id;
  if (me == null) {
    yield const [];
    return;
  }
  final source =
      ref.watch(friendsRepositoryProvider).watchAcceptedWithPeers(me);
  final cache = await ref.watch(persistentCacheProvider.future);
  yield* cache.hydratePairs<Friendship, Profile>(
    namespace: 'friends.accepted.$me',
    source: source,
    fromJsonA: Friendship.fromJson,
    fromJsonB: Profile.fromJson,
    toJsonA: (f) => f.toJson(),
    toJsonB: (p) => p.toJson(),
  );
});

/// Liste des utilisateurs bloqués par `me`.
final blockedByMeProvider =
    FutureProvider.autoDispose<List<(Friendship, Profile)>>((ref) async {
  final me = ref.watch(currentSessionProvider)?.user.id;
  if (me == null) return const [];
  final repo = ref.watch(friendsRepositoryProvider);
  final friendships = await repo.listBlockedByMe(me);
  return repo.resolvePeers(me: me, friendships: friendships);
});

/// Friendship row entre `me` et `target` — null si rien.
final friendshipBetweenProvider =
    FutureProvider.autoDispose.family<Friendship?, String>((ref, targetId) {
  final me = ref.watch(currentSessionProvider)?.user.id;
  if (me == null) return Future.value(null);
  return ref
      .watch(friendsRepositoryProvider)
      .findBetween(me: me, target: targetId);
});

/// Profil public par username (utilisé par /profile/u/:username).
/// Offline-safe : renvoie le dernier profil connu pour ce username au
/// lieu d'un _ErrorState reseau (rethrow uniquement si offline ET jamais
/// charge → la page montre alors son erreur, cas rare).
final publicProfileByUsernameProvider =
    FutureProvider.autoDispose.family<Profile?, String>((ref, username) async {
  final cache = await ref.watch(persistentCacheProvider.future);
  return cache.fetchObjectOrCacheNullable<Profile>(
    namespace: 'public_profile.${username.toLowerCase()}',
    fetch: () => ref.watch(friendsRepositoryProvider).findByUsername(username),
    fromJson: Profile.fromJson,
    toJson: (p) => p.toJson(),
  );
});

/// Compteur live de demandes pending entrantes — pour le badge.
final incomingFriendRequestsCountProvider =
    StreamProvider.autoDispose<int>((ref) {
  final me = ref.watch(currentSessionProvider)?.user.id;
  if (me == null) return Stream.value(0);
  return ref.watch(friendsRepositoryProvider).watchIncomingPendingCount(me);
});
