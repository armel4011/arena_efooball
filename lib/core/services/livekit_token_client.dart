import 'package:arena/data/repositories/profile_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Jeton de capture LiveKit (publish-only) renvoyé par `livekit-token`.
///
/// Contrairement à l'Agora token (broadcaster/audience), il n'y a qu'un
/// seul rôle ici : le joueur publie son propre gameplay et ne s'abonne à
/// rien (anti-triche). Cf. Edge Function `livekit-token`.
class LiveKitToken {
  const LiveKitToken({
    required this.token,
    required this.url,
    required this.room,
    required this.identity,
    required this.expiresAt,
  });

  factory LiveKitToken.fromJson(Map<String, dynamic> json) {
    return LiveKitToken(
      token: json['token'] as String,
      url: json['url'] as String,
      room: json['room'] as String,
      identity: json['identity'] as String,
      expiresAt: (json['expiresAt'] as num).toInt(),
    );
  }

  final String token;

  /// URL serveur LiveKit (wss://…) renvoyée par le serveur — l'app ne la
  /// code jamais en dur, elle provient de la config Edge Function.
  final String url;
  final String room;
  final String identity;
  final int expiresAt;

  bool get isExpired =>
      DateTime.now().millisecondsSinceEpoch ~/ 1000 >= expiresAt;
}

/// Wrapper fin autour de l'Edge Function `livekit-token`.
///
/// Garde l'appel réseau hors de `LiveKitCaptureService` pour que les tests
/// pilotent la machine à états sans toucher Supabase ni LiveKit.
class LiveKitTokenClient {
  const LiveKitTokenClient(this._client);

  final SupabaseClient _client;

  Future<LiveKitToken> fetch({required String matchId}) async {
    final response = await _client.functions.invoke(
      'livekit-token',
      body: {'matchId': matchId},
    );
    final data = response.data;
    if (data is! Map) {
      throw const LiveKitTokenException('Edge Function returned non-JSON body');
    }
    if (data.containsKey('error')) {
      throw LiveKitTokenException('Edge Function rejected: ${data['error']}');
    }
    return LiveKitToken.fromJson(Map<String, dynamic>.from(data));
  }
}

class LiveKitTokenException implements Exception {
  const LiveKitTokenException(this.message);
  final String message;
  @override
  String toString() => 'LiveKitTokenException: $message';
}

final liveKitTokenClientProvider = Provider<LiveKitTokenClient>((ref) {
  return LiveKitTokenClient(ref.watch(supabaseClientProvider));
});
