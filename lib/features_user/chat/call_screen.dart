import 'dart:async';

import 'package:arena/core/services/agora_call_service.dart';
import 'package:arena/core/theme/arena_theme.dart';
import 'package:arena/data/models/call_record.dart';
import 'package:arena/data/repositories/call_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Écran d'appel audio 1v1 (Phase 12.5 — item 3, étendu : signalisation).
///
/// Deux entrées :
///   - APPELANT : ouvre l'écran avec `callId == null`. L'écran crée la
///     ligne `calls` (`placeCall`) → le destinataire reçoit la sonnerie.
///   - DESTINATAIRE : ouvert depuis `IncomingCallScreen` après avoir
///     décroché, avec un `callId` déjà accepté.
///
/// Dans les deux cas on rejoint ensuite le canal Agora RTC. L'audio ne
/// circule qu'une fois les 2 pairs dans le canal — donc le destinataire
/// doit avoir décroché.
class CallScreen extends ConsumerStatefulWidget {
  const CallScreen({
    required this.scope,
    required this.id,
    required this.peerName,
    required this.calleeId,
    this.callId,
    super.key,
  });

  /// `match` | `friend`.
  final String scope;

  /// matchId ou friendshipId.
  final String id;

  /// Nom affiché du correspondant.
  final String peerName;

  /// Profil appelé — requis pour créer la ligne `calls` (côté appelant).
  final String calleeId;

  /// `null` côté appelant (l'écran crée l'appel) ; renseigné côté
  /// destinataire (appel déjà accepté).
  final String? callId;

  @override
  ConsumerState<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends ConsumerState<CallScreen> {
  late final AgoraCallService _svc;
  late final CallRepository _callRepo;

  /// Id de l'appel — résolu après `placeCall` côté appelant.
  String? _callId;

  /// Message terminal forcé (refus du pair, échec de `placeCall`).
  String? _override;
  bool _closing = false;

  @override
  void initState() {
    super.initState();
    _svc = ref.read(agoraCallServiceProvider);
    _callRepo = ref.read(callRepositoryProvider);
    WidgetsBinding.instance.addPostFrameCallback((_) => _begin());
  }

  Future<void> _begin() async {
    var id = widget.callId;
    if (id == null) {
      // Côté appelant : on crée la ligne `calls` → ça sonne chez le pair.
      try {
        final call = await _callRepo.placeCall(
          scope: widget.scope,
          scopeId: widget.id,
          calleeId: widget.calleeId,
        );
        id = call.id;
      } catch (_) {
        if (mounted) {
          setState(() => _override = "Impossible de lancer l'appel.");
        }
        return;
      }
    }
    if (!mounted) return;
    setState(() => _callId = id);
    await _svc.startCall(scope: widget.scope, id: widget.id);
  }

  @override
  void dispose() {
    unawaited(_svc.hangup());
    final id = _callId;
    if (id != null) unawaited(_callRepo.end(id));
    super.dispose();
  }

  Future<void> _hangup() async {
    if (_closing) return;
    _closing = true;
    await _svc.hangup();
    final id = _callId;
    if (id != null) {
      try {
        await _callRepo.end(id);
      } catch (_) {/* swallow — signalisation best-effort */}
    }
    if (mounted) Navigator.of(context).pop();
  }

  /// Réagit au statut signalé : le pair a refusé / raccroché / annulé.
  void _onSignal(CallRecord? c) {
    if (c == null || c.isLive || _closing || _override != null) return;
    setState(
      () => _override = c.status == CallStatus.declined
          ? 'Appel refusé.'
          : 'Appel terminé.',
    );
    unawaited(_svc.hangup());
  }

  String _statusLabel(CallSnapshot s) {
    switch (s.state) {
      case CallState.idle:
      case CallState.connecting:
        return 'Connexion en cours…';
      case CallState.ringing:
        return 'Sonnerie…';
      case CallState.connected:
        return 'En appel';
      case CallState.ended:
        return 'Appel terminé';
      case CallState.failed:
        return s.errorMessage ?? "Échec de l'appel";
    }
  }

  @override
  Widget build(BuildContext context) {
    final id = _callId;
    if (id != null) {
      ref.listen<AsyncValue<CallRecord?>>(
        callByIdProvider(id),
        (_, next) => _onSignal(next.value),
      );
    }

    return Scaffold(
      backgroundColor: ArenaColors.void_,
      body: SafeArea(
        child: StreamBuilder<CallSnapshot>(
          stream: _svc.stream,
          initialData: _svc.snapshot,
          builder: (context, snap) {
            final s = snap.data ?? const CallSnapshot(state: CallState.idle);
            final override = _override;
            final isFinal = override != null ||
                s.state == CallState.ended ||
                s.state == CallState.failed;
            final label = override ?? _statusLabel(s);
            return Column(
              children: [
                const SizedBox(height: 60),
                _PeerAvatar(name: widget.peerName),
                const SizedBox(height: ArenaSpacing.lg),
                Text(
                  widget.peerName,
                  style: ArenaText.h2.copyWith(color: ArenaColors.bone),
                ),
                const SizedBox(height: ArenaSpacing.sm),
                Text(
                  label,
                  style: ArenaText.body.copyWith(
                    color: s.state == CallState.connected
                        ? ArenaColors.statusOk
                        : ArenaColors.silver,
                  ),
                ),
                const Spacer(),
                if (!isFinal) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _CallControl(
                        icon: s.micMuted ? Icons.mic_off : Icons.mic,
                        active: s.micMuted,
                        label: s.micMuted ? 'Réactiver' : 'Couper',
                        onTap: _svc.toggleMute,
                      ),
                      _HangupButton(onTap: _hangup),
                      _CallControl(
                        icon: s.speakerOn
                            ? Icons.volume_up
                            : Icons.volume_down,
                        active: s.speakerOn,
                        label: s.speakerOn ? 'Haut-parleur' : 'Écouteur',
                        onTap: _svc.toggleSpeaker,
                      ),
                    ],
                  ),
                ] else
                  _CallControl(
                    icon: Icons.close,
                    active: false,
                    label: 'Fermer',
                    onTap: () => Navigator.of(context).pop(),
                  ),
                const SizedBox(height: 40),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _PeerAvatar extends StatelessWidget {
  const _PeerAvatar({required this.name});
  final String name;

  @override
  Widget build(BuildContext context) {
    final initial = name.isEmpty ? '?' : name[0].toUpperCase();
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: ArenaColors.signalBlue.withValues(alpha: 0.2),
        border: Border.all(color: ArenaColors.signalBlue, width: 3),
      ),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: ArenaText.h1.copyWith(
          color: ArenaColors.bone,
          fontSize: 48,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _CallControl extends StatelessWidget {
  const _CallControl({
    required this.icon,
    required this.active,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final bool active;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(999),
          child: Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: active ? ArenaColors.signalBlue : ArenaColors.carbon2,
            ),
            child: Icon(
              icon,
              color: active ? ArenaColors.bone : ArenaColors.bone,
              size: 26,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: ArenaText.small.copyWith(color: ArenaColors.silver),
        ),
      ],
    );
  }
}

class _HangupButton extends StatelessWidget {
  const _HangupButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: 76,
        height: 76,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: ArenaColors.neonRed,
        ),
        child: const Icon(
          Icons.call_end,
          color: ArenaColors.bone,
          size: 30,
        ),
      ),
    );
  }
}
