import 'package:arena/data/repositories/profile_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Streaming role requested from the Edge Function. Matches the
/// `RtcRole` enum on the server side: broadcaster = publisher,
/// audience = subscriber.
enum AgoraRole { broadcaster, audience }

/// Token + channel identity returned by `get_agora_token`.
class AgoraToken {
  const AgoraToken({
    required this.token,
    required this.channelName,
    required this.uid,
    required this.expiresAt,
    required this.role,
  });

  factory AgoraToken.fromJson(Map<String, dynamic> json) {
    return AgoraToken(
      token: json['token'] as String,
      channelName: json['channelName'] as String,
      uid: (json['uid'] as num).toInt(),
      expiresAt: (json['expiresAt'] as num).toInt(),
      role: json['role'] == 'broadcaster'
          ? AgoraRole.broadcaster
          : AgoraRole.audience,
    );
  }

  final String token;
  final String channelName;
  final int uid;
  final int expiresAt;
  final AgoraRole role;

  bool get isExpired =>
      DateTime.now().millisecondsSinceEpoch ~/ 1000 >= expiresAt;
}

/// Thin wrapper around the `get_agora_token` Edge Function.
///
/// Keeps the network call out of `AgoraStreamingService` so tests can
/// drive the streaming state machine without touching Supabase.
class AgoraTokenClient {
  const AgoraTokenClient(this._client);

  final SupabaseClient _client;

  Future<AgoraToken> fetch({
    required String matchId,
    required AgoraRole role,
  }) async {
    final response = await _client.functions.invoke(
      'get_agora_token',
      body: {
        'matchId': matchId,
        'role': role == AgoraRole.broadcaster ? 'broadcaster' : 'audience',
      },
    );
    final data = response.data;
    if (data is! Map) {
      throw const AgoraTokenException('Edge Function returned non-JSON body');
    }
    if (data.containsKey('error')) {
      throw AgoraTokenException('Edge Function rejected: ${data['error']}');
    }
    return AgoraToken.fromJson(Map<String, dynamic>.from(data));
  }
}

class AgoraTokenException implements Exception {
  const AgoraTokenException(this.message);
  final String message;
  @override
  String toString() => 'AgoraTokenException: $message';
}

final agoraTokenClientProvider = Provider<AgoraTokenClient>((ref) {
  return AgoraTokenClient(ref.watch(supabaseClientProvider));
});
