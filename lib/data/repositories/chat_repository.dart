import 'package:arena/data/models/chat_channel.dart';
import 'package:arena/data/models/chat_message.dart';
import 'package:arena/data/repositories/match_repository.dart';
import 'package:arena/data/repositories/profile_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Reads + writes over `chat_channels` / `chat_messages`. Persistent
/// messages only — Agora RTM (presence, typing) lands in PHASE 12.5.
class ChatRepository {
  const ChatRepository(this._client);

  static const _channelsTable = 'chat_channels';
  static const _messagesTable = 'chat_messages';

  final SupabaseClient _client;

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
