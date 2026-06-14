import 'dart:io';

import 'package:arena/core/services/persistent_cache.dart';
import 'package:arena/data/models/chat_channel.dart';
import 'package:arena/data/models/chat_message.dart';
import 'package:arena/data/repositories/match_repository.dart';
import 'package:arena/data/repositories/profile_repository.dart';
import 'package:arena/features_shared/auth_common/shared_auth_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Reads + writes over `chat_channels` / `chat_messages`. Persistent
/// messages only — Agora RTM (presence, typing) lands in PHASE 12.5.
class ChatRepository {
  const ChatRepository(this._client);

  static const _channelsTable = 'chat_channels';
  static const _messagesTable = 'chat_messages';

  final SupabaseClient _client;

  /// Liste les chat_channels type='friend' non-supprimés où le user
  /// courant est l'un des 2 membres de la friendship accepted.
  /// Retourne pour chaque channel le triplet (channel, peer profile,
  /// friendship_id) prêt à rendre dans l'inbox.
  ///
  /// Item 3 wave C (test phone 2026-05-19) — lacune wave A : les
  /// friend chats n'apparaissaient nulle part dans l'inbox.
  Future<List<({String channelId, String friendshipId, String peerId})>>
      listMyFriendChannels(String me) async {
    // **Joint serveur** : on embed `friendships` (peer info) ET
    // `chat_channel_user_state` (hidden flag) en une seule requete au
    // lieu de 2 sequentielles. La RLS sur chat_channel_user_state
    // filtre deja a `auth.uid() = user_id` → l'embed retourne 0 ou 1
    // row par channel.
    final rows = await _client
        .from(_channelsTable)
        .select(
          'id, friendship_id, '
          'friendships!inner(requester_id, addressee_id, status), '
          'chat_channel_user_state(hidden)',
        )
        .eq('type', 'friend')
        .eq('friendships.status', 'accepted')
        .or(
          'requester_id.eq.$me,addressee_id.eq.$me',
          referencedTable: 'friendships',
        );
    final result =
        <({String channelId, String friendshipId, String peerId})>[];
    for (final row in rows as List<dynamic>) {
      final map = row as Map<String, dynamic>;
      // Skip si masque pour moi (hidden=true dans ma user_state row).
      final states = map['chat_channel_user_state'] as List<dynamic>?;
      final hidden = states != null &&
          states.any((s) => (s as Map<String, dynamic>)['hidden'] == true);
      if (hidden) continue;
      final f = map['friendships'] as Map<String, dynamic>?;
      if (f == null) continue;
      final requester = f['requester_id'] as String?;
      final addressee = f['addressee_id'] as String?;
      final peer = requester == me ? addressee : requester;
      if (peer == null) continue;
      result.add(
        (
          channelId: map['id'] as String,
          friendshipId: map['friendship_id'] as String,
          peerId: peer,
        ),
      );
    }
    return result;
  }

  /// Map matchId → channelId pour les channels type='match' existants.
  /// Utilisé par myUnreadCountsProvider pour résoudre les channels
  /// derrière les match_ids retournés par openedMatchChannelIds.
  Future<Map<String, String>> matchChannelIdsFor(List<String> matchIds) async {
    if (matchIds.isEmpty) return const {};
    final rows = await _client
        .from(_channelsTable)
        .select('id, match_id')
        .eq('type', 'match')
        .inFilter('match_id', matchIds);
    return {
      for (final r in rows as List<dynamic>)
        (r as Map<String, dynamic>)['match_id'] as String:
            r['id'] as String,
    };
  }

  /// Renvoie l'ensemble des match_ids pour lesquels un `chat_channel`
  /// de type=match existe déjà (et n'est pas masqué pour moi). Alimente
  /// l'inbox DIRECT pour n'afficher que les vraies conversations.
  Future<Set<String>> openedMatchChannelIds(List<String> matchIds) async {
    if (matchIds.isEmpty) return const {};
    // **Joint serveur** : 1 query (channels + user_state embed) au lieu
    // de 2 (channels puis hidden filter). Voir listMyFriendChannels
    // pour le pattern detaille.
    final rows = await _client
        .from(_channelsTable)
        .select('id, match_id, chat_channel_user_state(hidden)')
        .eq('type', 'match')
        .inFilter('match_id', matchIds);
    final result = <String>{};
    for (final r in rows as List<dynamic>) {
      final map = r as Map<String, dynamic>;
      final states = map['chat_channel_user_state'] as List<dynamic>?;
      final hidden = states != null &&
          states.any((s) => (s as Map<String, dynamic>)['hidden'] == true);
      if (hidden) continue;
      result.add(map['match_id'] as String);
    }
    return result;
  }

  /// Returns the existing match channel for [matchId], or creates one
  /// on the fly. RLS makes sure only the two seated players (or an
  /// admin) can hit this insert path.
  Future<ChatChannel> ensureMatchChannel(String matchId) async {
    final existing = await _client
        .from(_channelsTable)
        .select()
        .eq('type', 'match')
        .eq('match_id', matchId)
        .maybeSingle();

    if (existing != null) {
      return ChatChannel.fromJson(existing);
    }

    final inserted = await _client
        .from(_channelsTable)
        .insert({
          'type': 'match',
          'match_id': matchId,
        })
        .select()
        .single();

    return ChatChannel.fromJson(inserted);
  }

  /// Realtime stream of the **latest** [limit] messages in a channel,
  /// oldest → newest after the client-side sort. We query the newest
  /// first server-side so the limit caps the right window, then sort
  /// ascending for the `reverse: true` ListView the chat UI uses.
  ///
  /// Older history (scroll-to-top) lands with the dedicated cursor
  /// fetcher in PHASE 12.5; until then a 200-row cap is enough for a
  /// match-scoped chat (PHASE 6 hard-caps the channel lifetime to one
  /// match).
  Stream<List<ChatMessage>> watchMessages(String channelId, {int limit = 200}) {
    return _client
        .from(_messagesTable)
        .stream(primaryKey: ['id'])
        .eq('channel_id', channelId)
        .order('created_at', ascending: false)
        .limit(limit)
        .map(
          (rows) => [
            for (final row in rows) ChatMessage.fromJson(row),
          ]..sort(_byCreatedAtAsc),
        );
  }

  static int _byCreatedAtAsc(ChatMessage a, ChatMessage b) {
    final ad = a.createdAt;
    final bd = b.createdAt;
    if (ad == null && bd == null) return 0;
    if (ad == null) return 1;
    if (bd == null) return -1;
    return ad.compareTo(bd);
  }

  /// Sends a text message. Content is trimmed and capped at 2000 chars
  /// (the DB length check would reject anything bigger).
  Future<void> sendMessage({
    required String channelId,
    required String senderId,
    required String content,
  }) async {
    final trimmed = content.trim();
    if (trimmed.isEmpty) return;
    final capped =
        trimmed.length > 2000 ? trimmed.substring(0, 2000) : trimmed;
    await _client.from(_messagesTable).insert({
      'channel_id': channelId,
      'sender_id': senderId,
      'content': capped,
      'type': 'text',
    });
  }

  static const _mediaBucket = 'chat-media';

  /// Upload [file] dans le bucket `chat-media` sous le path
  /// `<channelId>/<timestamp>_<filename>`, puis crée un message
  /// `type='image'|'video'|'audio'` avec `media_url` rempli.
  ///
  /// La caption optionnelle ([content]) sert pour les images
  /// commentées ; pas obligatoire (le check schema accepte content=0
  /// si media_url est rempli).
  Future<void> sendMediaMessage({
    required String channelId,
    required String senderId,
    required File file,
    required String mediaType, // 'image' | 'video' | 'audio'
    String content = '',
  }) async {
    assert(
      mediaType == 'image' || mediaType == 'video' || mediaType == 'audio',
      'mediaType invalide',
    );

    final fileName = file.path.split(RegExp(r'[/\\]')).last;
    final stamp = DateTime.now().millisecondsSinceEpoch;
    final path = '$channelId/${stamp}_$fileName';

    await _client.storage.from(_mediaBucket).upload(path, file);
    final publicPath = path; // on stocke le path interne — signed URL au read

    final cappedContent = content.trim().length > 2000
        ? content.trim().substring(0, 2000)
        : content.trim();

    await _client.from(_messagesTable).insert({
      'channel_id': channelId,
      'sender_id': senderId,
      'content': cappedContent,
      'type': mediaType == 'image' ? 'image' : 'text',
      'media_url': publicPath,
      'media_type': mediaType,
    });
  }

  /// Génère une signed URL (1h) pour télécharger un média de chat.
  /// Le path est ce qui a été stocké dans `chat_messages.media_url`.
  Future<String> signedMediaUrl(
    String path, {
    Duration expiresIn = const Duration(hours: 1),
  }) async {
    return _client.storage
        .from(_mediaBucket)
        .createSignedUrl(path, expiresIn.inSeconds);
  }

  /// Soft-delete d'un message par son sender. Pose `deleted_at = now()`
  /// et redact le `content` à vide ; la RLS chat_messages_soft_delete_self
  /// autorise l'UPDATE uniquement par le sender.
  Future<void> softDeleteMessage(String messageId) async {
    await _client
        .from(_messagesTable)
        .update({
          'deleted_at': DateTime.now().toUtc().toIso8601String(),
          'content': '',
          'media_url': null,
        })
        .eq('id', messageId);
  }

  static const _userStateTable = 'chat_channel_user_state';

  /// Sémantique WhatsApp "Supprimer pour moi" :
  ///   - hidden=true → masque la conv dans MON inbox (peer pas affecté)
  ///   - cleared_at=now() → masque les messages antérieurs côté MOI
  ///     (filtre client-side dans watchMessages)
  /// Upsert (insert si manquant, update sinon).
  Future<void> hideChannelForMe(String channelId) async {
    final me = _client.auth.currentUser?.id;
    if (me == null) return;
    await _client.from(_userStateTable).upsert({
      'user_id': me,
      'channel_id': channelId,
      'hidden': true,
      'cleared_at': DateTime.now().toUtc().toIso8601String(),
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    });
  }

  /// Inverse de hideChannelForMe : remet la conv dans mon inbox sans
  /// effacer cleared_at (l'historique antérieur reste filtré). Appelée
  /// automatiquement à chaque ensureXxxChannel — un user qui rouvre
  /// le chat veut le revoir dans son inbox.
  Future<void> unhideChannelForMe(String channelId) async {
    final me = _client.auth.currentUser?.id;
    if (me == null) return;
    // Upsert hidden=false (insert si row inexistante avec cleared_at=null,
    // update si existante sans toucher cleared_at).
    await _client.from(_userStateTable).upsert({
      'user_id': me,
      'channel_id': channelId,
      'hidden': false,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    });
  }

  /// Marque ce channel comme lu — pose last_read_at = now() dans ma
  /// row chat_channel_user_state. Le badge "messages non-lus" disparaît
  /// après. Préserve hidden (upsert ne touche que les columns spécifiées
  /// dans l'UPDATE part, et default sinon pour l'INSERT part).
  Future<void> markChannelAsRead(String channelId) async {
    final me = _client.auth.currentUser?.id;
    if (me == null) return;
    await _client.from(_userStateTable).upsert({
      'user_id': me,
      'channel_id': channelId,
      'last_read_at': DateTime.now().toUtc().toIso8601String(),
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    });
  }

  /// Compte les messages non-lus pour chaque channel passé en input.
  /// Returns un `Map<channelId, count>`. Un channel sans messages non-lus
  /// est absent de la map (≠ count=0 si la row n'a pas been initialisée
  /// pour ce user).
  ///
  /// Implémentation côté client (1 SELECT states + 1 SELECT messages).
  /// Cap à 500 messages totaux pour ne pas exploser à scale — UI
  /// affiche "99+" au-delà.
  Future<Map<String, int>> getUnreadCounts(List<String> channelIds) async {
    if (channelIds.isEmpty) return const {};
    final me = _client.auth.currentUser?.id;
    if (me == null) return const {};

    // 1. last_read_at par channel pour moi
    final stateRows = await _client
        .from(_userStateTable)
        .select('channel_id, last_read_at')
        .eq('user_id', me)
        .inFilter('channel_id', channelIds);
    final lastReadByChannel = <String, DateTime>{};
    for (final r in stateRows as List<dynamic>) {
      final map = r as Map<String, dynamic>;
      final ts = map['last_read_at'] as String?;
      if (ts != null) {
        lastReadByChannel[map['channel_id'] as String] = DateTime.parse(ts);
      }
    }

    // 2. Messages de ces channels, pas de moi, pas deleted
    final msgs = await _client
        .from(_messagesTable)
        .select('channel_id, created_at')
        .inFilter('channel_id', channelIds)
        .isFilter('deleted_at', null)
        .neq('sender_id', me)
        .limit(500);

    final counts = <String, int>{};
    for (final m in msgs as List<dynamic>) {
      final map = m as Map<String, dynamic>;
      final channelId = map['channel_id'] as String;
      final createdAt = DateTime.parse(map['created_at'] as String);
      final lastRead = lastReadByChannel[channelId];
      if (lastRead != null && !createdAt.isAfter(lastRead)) continue;
      counts[channelId] = (counts[channelId] ?? 0) + 1;
    }
    return counts;
  }

  /// Renvoie le `cleared_at` de ma row chat_channel_user_state pour ce
  /// channel, null s'il n'y a pas eu de clearing. Utilisé pour filtrer
  /// les messages dans watchMessages.
  Future<DateTime?> myChatClearedAt(String channelId) async {
    final me = _client.auth.currentUser?.id;
    if (me == null) return null;
    final row = await _client
        .from(_userStateTable)
        .select('cleared_at')
        .eq('user_id', me)
        .eq('channel_id', channelId)
        .maybeSingle();
    final raw = row?['cleared_at'] as String?;
    if (raw == null) return null;
    return DateTime.parse(raw);
  }

  /// Get-or-create un channel `type='friend'` pour la friendship donnée.
  /// Passe par la RPC `ensure_friend_channel` (security definer) qui
  /// vérifie que le caller est membre de la friendship et qu'elle est
  /// `accepted`.
  Future<ChatChannel> ensureFriendChannel(String friendshipId) async {
    final channelId = await _client.rpc<String>(
      'ensure_friend_channel',
      params: {'p_friendship_id': friendshipId},
    );
    final row = await _client
        .from(_channelsTable)
        .select()
        .eq('id', channelId)
        .single();
    return ChatChannel.fromJson(row);
  }
}

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return ChatRepository(ref.watch(supabaseClientProvider));
});

/// Auto-fetches (or creates) the chat channel attached to a match.
/// Au passage : un-hide + mark as read + invalide les providers inbox.
final matchChannelProvider =
    FutureProvider.family.autoDispose<ChatChannel, String>((ref, matchId) async {
  final repo = ref.watch(chatRepositoryProvider);
  final cache = await ref.watch(persistentCacheProvider.future);
  // Offline-safe : on fige sur le dernier canal connu (le user a deja
  // ouvert cette conv en ligne). Sans fallback : si offline ET jamais
  // ouvert, on rethrow (erreur inevitable, conv jamais chargee).
  final channel = await cache.fetchObjectOrCache<ChatChannel>(
    namespace: 'match_channel.$matchId',
    fetch: () => repo.ensureMatchChannel(matchId),
    fromJson: ChatChannel.fromJson,
    toJson: (c) => c.toJson(),
  );
  // Side-effects reseau best-effort — ignorees hors-ligne pour ne pas
  // faire echouer l'ouverture de la conv depuis le cache.
  try {
    await repo.unhideChannelForMe(channel.id);
    await repo.markChannelAsRead(channel.id);
    ref
      ..invalidate(myOpenedMatchChannelIdsProvider)
      ..invalidate(myUnreadCountsProvider);
  } catch (e) {
    if (PersistentCache.isOfflineError(e)) {
      // hors-ligne : on garde le canal en cache, rien a invalider
    } else {
      rethrow;
    }
  }
  return channel;
});

/// Cleared_at de ma chat_channel_user_state pour ce channel — utilisé
/// pour filtrer les messages que je voyais avant d'avoir "supprimé pour
/// moi" la conversation (sémantique WhatsApp).
final myChatClearedAtProvider =
    FutureProvider.family.autoDispose<DateTime?, String>((ref, channelId) {
  return ref.watch(chatRepositoryProvider).myChatClearedAt(channelId);
});

/// Realtime stream of all messages in a chat channel, oldest → newest.
/// Offline-safe : la liste reste figee sur les derniers messages connus
/// (cache) au lieu d'afficher une erreur reseau quand la conv est
/// ouverte hors-ligne.
final channelMessagesProvider =
    StreamProvider.family.autoDispose<List<ChatMessage>, String>(
        (ref, channelId) async* {
  final source = ref.watch(chatRepositoryProvider).watchMessages(channelId);
  final cache = await ref.watch(persistentCacheProvider.future);
  yield* cache.hydrate<ChatMessage>(
    namespace: 'chat_messages.$channelId',
    source: source,
    fromJson: ChatMessage.fromJson,
    toJson: (m) => m.toJson(),
  );
});

/// Set des match_ids du joueur courant qui ont au moins un chat_channel
/// (= conversation initiée). Alimente l'inbox DIRECT pour n'afficher
/// que les vraies conversations.
final myOpenedMatchChannelIdsProvider =
    FutureProvider.autoDispose<Set<String>>((ref) async {
  final matches = await ref.watch(myAllMatchesProvider.future);
  if (matches.isEmpty) return const {};
  final ids = [for (final m in matches) m.id];
  // Offline-safe : ce provider bloque l'inbox (cf. messages_inbox_page),
  // donc on fige sur les derniers channels ouverts connus au lieu de
  // remonter une erreur reseau. Cache une List<String> (wrapper {id}).
  final me = ref.watch(currentSessionProvider)?.user.id ?? 'anon';
  final cache = await ref.watch(persistentCacheProvider.future);
  final cached = await cache.fetchListOrCache<String>(
    namespace: 'inbox_opened_channels.$me',
    fetch: () async =>
        (await ref.watch(chatRepositoryProvider).openedMatchChannelIds(ids))
            .toList(),
    fromJson: (j) => j['id'] as String,
    toJson: (s) => {'id': s},
  );
  return cached.toSet();
});

/// Item 3 wave C (2026-05-19) — friend chats du user courant, à
/// afficher dans la section AMIS de l'inbox DIRECT.
final myFriendChannelsProvider = FutureProvider.autoDispose<
    List<({String channelId, String friendshipId, String peerId})>>((ref) async {
  final me = ref.watch(currentSessionProvider)?.user.id;
  if (me == null) return const [];
  return ref.watch(chatRepositoryProvider).listMyFriendChannels(me);
});

/// Map matchId → channelId pour mes matchs avec chat. Utilisé par
/// l'inbox pour résoudre les unread counts sur les rows match.
final myMatchChannelIdsMapProvider =
    FutureProvider.autoDispose<Map<String, String>>((ref) async {
  final matches = await ref.watch(myAllMatchesProvider.future);
  if (matches.isEmpty) return const {};
  final ids = [for (final m in matches) m.id];
  return ref.watch(chatRepositoryProvider).matchChannelIdsFor(ids);
});

/// Item 3 wave F (2026-05-19) — compteurs de messages non-lus par
/// channel, alimente les badges sur les rows inbox. `Map<channelId, int>`.
/// Channels sans messages non-lus sont absents (= 0).
///
/// Le provider est invalidé quand :
/// - L'utilisateur ouvre une conv (markChannelAsRead inside
///   matchChannelProvider / _friendChannelProvider)
/// - L'utilisateur supprime une conv (hideChannelForMe)
/// - Pull-to-refresh sur l'inbox
final myUnreadCountsProvider =
    FutureProvider.autoDispose<Map<String, int>>((ref) async {
  final me = ref.watch(currentSessionProvider)?.user.id;
  if (me == null) return const {};
  final repo = ref.watch(chatRepositoryProvider);
  // On veut counter tous les channels où je suis membre, pas que les
  // friend channels. Source : listMyFriendChannels + openedMatchChannelIds.
  final friends = await ref.watch(myFriendChannelsProvider.future);
  final matchIds = await ref.watch(myOpenedMatchChannelIdsProvider.future);
  final allChannelIds = <String>{
    ...friends.map((f) => f.channelId),
  };
  if (matchIds.isNotEmpty) {
    // Le openedMatchChannelIdsProvider rend des match_ids ; il faut
    // résoudre les channel_id correspondants. Petit fetch séparé.
    final matchChannels = await repo.matchChannelIdsFor(matchIds.toList());
    allChannelIds.addAll(matchChannels.values);
  }
  if (allChannelIds.isEmpty) return const {};
  return repo.getUnreadCounts(allChannelIds.toList());
});
