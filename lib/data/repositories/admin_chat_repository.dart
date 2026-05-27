import 'dart:io';

import 'package:arena/data/repositories/profile_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// 1 message admin -> user dans `public.admin_chat_messages`.
///
/// Trois variantes possibles (au moins l'une de [text]/[imageUrl] est non
/// nulle, contrainte CHECK en DB) :
/// - texte seul : [text] != null, [imageUrl] == null
/// - image seule : [text] == null, [imageUrl] != null, [caption] peut etre null
/// - image + caption : [imageUrl] != null + [caption] != null
class AdminChatMessage {
  const AdminChatMessage({
    required this.id,
    required this.adminId,
    required this.recipientId,
    required this.sentAt,
    this.text,
    this.imageUrl,
    this.caption,
    this.readAt,
  });

  factory AdminChatMessage.fromJson(Map<String, dynamic> json) =>
      AdminChatMessage(
        id: json['id'] as String,
        adminId: json['admin_id'] as String,
        recipientId: json['recipient_id'] as String,
        text: json['text'] as String?,
        imageUrl: json['image_url'] as String?,
        caption: json['caption'] as String?,
        sentAt: DateTime.parse(json['sent_at'] as String),
        readAt: json['read_at'] == null
            ? null
            : DateTime.parse(json['read_at'] as String),
      );

  final String id;
  final String adminId;
  final String recipientId;
  final String? text;
  final String? imageUrl;
  final String? caption;
  final DateTime sentAt;
  final DateTime? readAt;

  bool get isUnread => readAt == null;
  bool get hasImage => imageUrl != null;
}

/// Une conversation = derniers messages echanges avec UN user (groupes
/// cote admin pour afficher la liste des conversations).
class AdminChatThreadSummary {
  const AdminChatThreadSummary({
    required this.userId,
    required this.username,
    required this.lastMessage,
    required this.lastSentAt,
    required this.unreadCount,
  });

  final String userId;
  final String username;
  final String lastMessage;
  final DateTime lastSentAt;
  final int unreadCount;
}

class AdminChatRepository {
  AdminChatRepository(this._client);

  final SupabaseClient _client;
  static const _table = 'admin_chat_messages';

  /// Stream des messages d'un fil (cote admin OU cote user). Realtime
  /// via `.stream()` qui souscrit a la publication supabase_realtime.
  Stream<List<AdminChatMessage>> watchThread({
    required String adminId,
    required String userId,
  }) {
    return _client
        .from(_table)
        .stream(primaryKey: ['id'])
        .order('sent_at')
        .map(
          (rows) => rows
              .where(
                (r) =>
                    r['admin_id'] == adminId &&
                    r['recipient_id'] == userId,
              )
              .map(AdminChatMessage.fromJson)
              .toList(),
        );
  }

  /// Cote user : stream tous les messages recus de n'importe quel admin.
  Stream<List<AdminChatMessage>> watchInbox(String userId) {
    return _client
        .from(_table)
        .stream(primaryKey: ['id'])
        .order('sent_at', ascending: false)
        .map(
          (rows) => rows
              .where((r) => r['recipient_id'] == userId)
              .map(AdminChatMessage.fromJson)
              .toList(),
        );
  }

  Future<void> send({
    required String adminId,
    required String recipientId,
    required String text,
  }) async {
    await _client.from(_table).insert({
      'admin_id': adminId,
      'recipient_id': recipientId,
      'text': text.trim(),
    });
  }

  /// Upload une image dans `notification_images/admin_chat/<adminId>/...`
  /// puis insere une row avec `image_url` + caption optionnelle.
  /// L'URL retournee est publique (bucket public-read).
  Future<void> sendImage({
    required String adminId,
    required String recipientId,
    required File file,
    String? caption,
  }) async {
    final ext = file.path.split('.').last.toLowerCase();
    final ts = DateTime.now().millisecondsSinceEpoch;
    final path = 'admin_chat/$adminId/$ts.$ext';
    final mime = switch (ext) {
      'png' => 'image/png',
      'webp' => 'image/webp',
      'gif' => 'image/gif',
      _ => 'image/jpeg',
    };
    await _client.storage.from('notification_images').upload(
          path,
          file,
          fileOptions: FileOptions(contentType: mime, upsert: false),
        );
    final url =
        _client.storage.from('notification_images').getPublicUrl(path);
    final trimmedCaption = caption?.trim();
    await _client.from(_table).insert({
      'admin_id': adminId,
      'recipient_id': recipientId,
      'image_url': url,
      if (trimmedCaption != null && trimmedCaption.isNotEmpty)
        'caption': trimmedCaption,
    });
  }

  /// Bulk insert pour broadcast cible (1 row par recipient, meme texte).
  Future<void> broadcast({
    required String adminId,
    required List<String> recipientIds,
    required String text,
  }) async {
    if (recipientIds.isEmpty) return;
    final rows = [
      for (final r in recipientIds)
        {
          'admin_id': adminId,
          'recipient_id': r,
          'text': text.trim(),
        },
    ];
    await _client.from(_table).insert(rows);
  }

  Future<void> markRead(String messageId) async {
    await _client
        .from(_table)
        .update({'read_at': DateTime.now().toIso8601String()})
        .eq('id', messageId);
  }

  /// Liste des fils d'un admin (group_by user_id, dernier message,
  /// nombre non-lus). One-shot — la list page de l'admin se rafraichit
  /// via un FutureProvider invalide a chaque envoi.
  Future<List<AdminChatThreadSummary>> listAdminThreads(String adminId) async {
    final rows = await _client
        .from(_table)
        .select('id, admin_id, recipient_id, text, image_url, caption, '
            'sent_at, read_at, '
            'profiles!admin_chat_messages_recipient_id_fkey(username)')
        .eq('admin_id', adminId)
        .order('sent_at', ascending: false);
    final byUser = <String, List<Map<String, dynamic>>>{};
    for (final r in rows) {
      final uid = r['recipient_id'] as String;
      byUser.putIfAbsent(uid, () => []).add(Map<String, dynamic>.from(r));
    }
    return [
      for (final entry in byUser.entries)
        AdminChatThreadSummary(
          userId: entry.key,
          username: ((entry.value.first['profiles']
                      as Map?)?['username'] as String?) ??
              'Inconnu',
          lastMessage: _previewOf(entry.value.first),
          lastSentAt: DateTime.parse(entry.value.first['sent_at'] as String),
          unreadCount:
              entry.value.where((r) => r['read_at'] == null).length,
        ),
    ];
  }

  static String _previewOf(Map<String, dynamic> row) {
    final caption = row['caption'] as String?;
    final text = row['text'] as String?;
    final hasImage = row['image_url'] != null;
    if (caption != null && caption.isNotEmpty) return caption;
    if (text != null && text.isNotEmpty) return text;
    if (hasImage) return '📷 Image';
    return '';
  }
}

final adminChatRepositoryProvider = Provider<AdminChatRepository>((ref) {
  return AdminChatRepository(ref.watch(supabaseClientProvider));
});
