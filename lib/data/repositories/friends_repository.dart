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
  Future<List<(Friendship, Profile)>> resolvePeers({
    required String me,
    required List<Friendship> friendships,
  }) async {
    if (friendships.isEmpty) return const [];
    final ids = {for (final f in friendships) f.otherUserId(me)};
    final rows = await _client
        .from(_profilesTable)
        .select()
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
final incomingFriendRequestsProvider =
    FutureProvider.autoDispose<List<(Friendship, Profile)>>((ref) async {
  final me = ref.watch(currentSessionProvider)?.user.id;
  if (me == null) return const [];
  final repo = ref.watch(friendsRepositoryProvider);
  final friendships = await repo.listIncomingPending(me);
  return repo.resolvePeers(me: me, friendships: friendships);
});

/// Demandes pending sortantes (visibilité utile dans l'onglet "Demandes").
final outgoingFriendRequestsProvider =
    FutureProvider.autoDispose<List<(Friendship, Profile)>>((ref) async {
  final me = ref.watch(currentSessionProvider)?.user.id;
  if (me == null) return const [];
  final repo = ref.watch(friendsRepositoryProvider);
  final friendships = await repo.listOutgoingPending(me);
  return repo.resolvePeers(me: me, friendships: friendships);
});

/// Liste amis acceptés + profil joueur.
final acceptedFriendsProvider =
    FutureProvider.autoDispose<List<(Friendship, Profile)>>((ref) async {
  final me = ref.watch(currentSessionProvider)?.user.id;
  if (me == null) return const [];
  final repo = ref.watch(friendsRepositoryProvider);
  final friendships = await repo.listAccepted(me);
  return repo.resolvePeers(me: me, friendships: friendships);
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
final publicProfileByUsernameProvider =
    FutureProvider.autoDispose.family<Profile?, String>((ref, username) {
  return ref.watch(friendsRepositoryProvider).findByUsername(username);
});

/// Compteur live de demandes pending entrantes — pour le badge.
final incomingFriendRequestsCountProvider =
    StreamProvider.autoDispose<int>((ref) {
  final me = ref.watch(currentSessionProvider)?.user.id;
  if (me == null) return Stream.value(0);
  return ref.watch(friendsRepositoryProvider).watchIncomingPendingCount(me);
});
