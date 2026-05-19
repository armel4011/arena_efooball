import 'dart:io';

import 'package:arena/data/models/chat_channel.dart';
import 'package:arena/data/models/chat_message.dart';
import 'package:arena/data/repositories/match_repository.dart';
import 'package:arena/data/repositories/profile_repository.dart';
import 'package:arena/features_user/auth/auth_providers.dart';
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
    final rows = await _client
        .from(_channelsTable)
        .select('id, friendship_id, friendships!inner(requester_id, addressee_id, status)')
        .eq('type', 'friend')
        .isFilter('deleted_at', null)
        .eq('friendships.status', 'accepted')
        .or(
          'requester_id.eq.$me,addressee_id.eq.$me',
          referencedTable: 'friendships',
        );
    final out =
        <({String channelId, String friendshipId, String peerId})>[];
    for (final row in rows as List<dynamic>) {
      final map = row as Map<String, dynamic>;
      final f = map['friendships'] as Map<String, dynamic>?;
      if (f == null) continue;
      final requester = f['requester_id'] as String?;
      final addressee = f['addressee_id'] as String?;
      final peer = requester == me ? addressee : requester;
      if (peer == null) continue;
      out.add(
        (
          channelId: map['id'] as String,
          friendshipId: map['friendship_id'] as String,
          peerId: peer,
        ),
      );
    }
    return out;
  }

  /// Renvoie l'ensemble des match_ids pour lesquels un `chat_channel`
  /// de type=match existe déjà — passé en input la liste des matchs
  /// du joueur. Alimente l'inbox messages (DIRECT tab) pour ne lister
  /// que les conversations vraiment initiées (≠ tous mes matchs).
  Future<Set<String>> openedMatchChannelIds(List<String> matchIds) async {
    if (matchIds.isEmpty) return const {};
    final rows = await _client
        .from(_channelsTable)
        .select('match_id')
        .eq('type', 'match')
        .inFilter('match_id', matchIds);
    return {
      for (final r in rows as List<dynamic>)
        (r as Map<String, dynamic>)['match_id'] as String,
    };
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

  /// Hard delete d'un chat channel par un membre (sémantique WhatsApp
  /// "Supprimer pour tout le monde"). La FK chat_messages.channel_id
  /// est ON DELETE CASCADE → les messages disparaissent automatiquement.
  /// ensureMatchChannel/ensureFriendChannel créeront un nouveau channel
  /// au prochain accès → fresh start sans historique.
  ///
  /// V2 follow-up : feature "Supprimer pour moi seulement" via une
  /// table chat_channel_hidden (user_id, channel_id) qui filtrerait
  /// côté inbox sans toucher au channel partagé.
  Future<void> deleteChannel(String channelId) async {
    await _client.from(_channelsTable).delete().eq('id', channelId);
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
final matchChannelProvider =
    FutureProvider.family.autoDispose<ChatChannel, String>((ref, matchId) {
  return ref.watch(chatRepositoryProvider).ensureMatchChannel(matchId);
});

/// Realtime stream of all messages in a chat channel, oldest → newest.
final channelMessagesProvider =
    StreamProvider.family.autoDispose<List<ChatMessage>, String>((ref, channelId) {
  return ref.watch(chatRepositoryProvider).watchMessages(channelId);
});

/// Set des match_ids du joueur courant qui ont au moins un chat_channel
/// (= conversation initiée). Alimente l'inbox DIRECT pour n'afficher
/// que les vraies conversations.
final myOpenedMatchChannelIdsProvider =
    FutureProvider.autoDispose<Set<String>>((ref) async {
  final matches = await ref.watch(myAllMatchesProvider.future);
  if (matches.isEmpty) return const {};
  final ids = [for (final m in matches) m.id];
  return ref.watch(chatRepositoryProvider).openedMatchChannelIds(ids);
});

/// Item 3 wave C (2026-05-19) — friend chats du user courant, à
/// afficher dans la section AMIS de l'inbox DIRECT.
final myFriendChannelsProvider = FutureProvider.autoDispose<
    List<({String channelId, String friendshipId, String peerId})>>((ref) async {
  final me = ref.watch(currentSessionProvider)?.user.id;
  if (me == null) return const [];
  return ref.watch(chatRepositoryProvider).listMyFriendChannels(me);
});
