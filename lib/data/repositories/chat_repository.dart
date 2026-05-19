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
    // 1. Liste tous les friend channels où je suis membre.
    final rows = await _client
        .from(_channelsTable)
        .select('id, friendship_id, friendships!inner(requester_id, addressee_id, status)')
        .eq('type', 'friend')
        .eq('friendships.status', 'accepted')
        .or(
          'requester_id.eq.$me,addressee_id.eq.$me',
          referencedTable: 'friendships',
        );
    final all =
        <({String channelId, String friendshipId, String peerId})>[];
    for (final row in rows as List<dynamic>) {
      final map = row as Map<String, dynamic>;
      final f = map['friendships'] as Map<String, dynamic>?;
      if (f == null) continue;
      final requester = f['requester_id'] as String?;
      final addressee = f['addressee_id'] as String?;
      final peer = requester == me ? addressee : requester;
      if (peer == null) continue;
      all.add(
        (
          channelId: map['id'] as String,
          friendshipId: map['friendship_id'] as String,
          peerId: peer,
        ),
      );
    }
    if (all.isEmpty) return all;

    // 2. Filtre les channels masqués pour moi (hidden=true dans
    // chat_channel_user_state). RLS limite déjà les rows à moi.
    final ids = [for (final c in all) c.channelId];
    final hiddenRows = await _client
        .from(_userStateTable)
        .select('channel_id')
        .eq('hidden', true)
        .inFilter('channel_id', ids);
    final hidden = {
      for (final r in hiddenRows as List<dynamic>)
        (r as Map<String, dynamic>)['channel_id'] as String,
    };
    return [for (final c in all) if (!hidden.contains(c.channelId)) c];
  }

  /// Renvoie l'ensemble des match_ids pour lesquels un `chat_channel`
  /// de type=match existe déjà (et n'est pas masqué pour moi). Alimente
  /// l'inbox DIRECT pour n'afficher que les vraies conversations.
  Future<Set<String>> openedMatchChannelIds(List<String> matchIds) async {
    if (matchIds.isEmpty) return const {};
    final rows = await _client
        .from(_channelsTable)
        .select('id, match_id')
        .eq('type', 'match')
        .inFilter('match_id', matchIds);
    final byMatch = <String, String>{};
    for (final r in rows as List<dynamic>) {
      final map = r as Map<String, dynamic>;
      byMatch[map['match_id'] as String] = map['id'] as String;
    }
    if (byMatch.isEmpty) return const {};

    // Retire les channels masqués pour moi.
    final hiddenRows = await _client
        .from(_userStateTable)
        .select('channel_id')
        .eq('hidden', true)
        .inFilter('channel_id', byMatch.values.toList());
    final hiddenChannelIds = {
      for (final r in hiddenRows as List<dynamic>)
        (r as Map<String, dynamic>)['channel_id'] as String,
    };
    return {
      for (final e in byMatch.entries)
        if (!hiddenChannelIds.contains(e.value)) e.key,
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
/// Au passage, un-hide pour moi (si la conv était "supprimée pour moi"
/// elle ré-apparaît dans l'inbox) + invalide les providers inbox pour
/// déclencher le refresh.
final matchChannelProvider =
    FutureProvider.family.autoDispose<ChatChannel, String>((ref, matchId) async {
  final repo = ref.watch(chatRepositoryProvider);
  final channel = await repo.ensureMatchChannel(matchId);
  await repo.unhideChannelForMe(channel.id);
  ref.invalidate(myOpenedMatchChannelIdsProvider);
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
