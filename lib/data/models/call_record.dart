import 'package:flutter/foundation.dart';

/// Statut d'un appel — miroir de l'enum SQL `call_status`.
enum CallStatus {
  ringing,
  accepted,
  declined,
  cancelled,
  missed,
  ended;

  static CallStatus fromValue(String? v) => switch (v) {
        'ringing' => CallStatus.ringing,
        'accepted' => CallStatus.accepted,
        'declined' => CallStatus.declined,
        'cancelled' => CallStatus.cancelled,
        'missed' => CallStatus.missed,
        _ => CallStatus.ended,
      };

  String get value => name;
}

/// Signalisation d'un appel 1v1 (table `calls`).
///
/// Ne porte QUE la signalisation (qui appelle qui, état de l'appel) ;
/// le flux audio passe par Agora RTC sur le canal [agoraChannel].
@immutable
class CallRecord {
  const CallRecord({
    required this.id,
    required this.scope,
    required this.scopeId,
    required this.callerId,
    required this.calleeId,
    required this.status,
    required this.agoraChannel,
    required this.createdAt,
    this.answeredAt,
    this.endedAt,
  });

  factory CallRecord.fromJson(Map<String, dynamic> json) => CallRecord(
        id: json['id'] as String,
        scope: json['scope'] as String,
        scopeId: json['scope_id'] as String,
        callerId: json['caller_id'] as String,
        calleeId: json['callee_id'] as String,
        status: CallStatus.fromValue(json['status'] as String?),
        agoraChannel: json['agora_channel'] as String,
        createdAt: DateTime.parse(json['created_at'] as String),
        answeredAt: json['answered_at'] == null
            ? null
            : DateTime.parse(json['answered_at'] as String),
        endedAt: json['ended_at'] == null
            ? null
            : DateTime.parse(json['ended_at'] as String),
      );

  final String id;

  /// `friend` | `match`.
  final String scope;

  /// friendshipId ou matchId selon [scope].
  final String scopeId;
  final String callerId;
  final String calleeId;
  final CallStatus status;

  /// Canal Agora RTC — `call_<scope>_<scopeId>`.
  final String agoraChannel;
  final DateTime createdAt;
  final DateTime? answeredAt;
  final DateTime? endedAt;

  bool get isRinging => status == CallStatus.ringing;
  bool get isAccepted => status == CallStatus.accepted;

  /// `true` tant que l'appel n'est pas clos (ringing ou accepted).
  bool get isLive =>
      status == CallStatus.ringing || status == CallStatus.accepted;
}
