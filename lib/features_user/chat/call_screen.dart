import 'package:arena/core/services/agora_call_service.dart';
import 'package:arena/core/theme/arena_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Écran d'appel audio 1v1 (Phase 12.5 — item 3 B1).
///
/// Modes :
///   - `connecting` : on demande le token + on join le channel
///   - `ringing` : on est dans le channel, on attend que le peer rejoigne
///   - `connected` : peer connecté, audio bidirectionnel
///   - `ended` : un des deux a hangup OU le peer s'est déconnecté
///   - `failed` : échec (permission micro refusée, token rejeté, etc.)
///
/// V1 limitations:
///   - Pas de FCM ringing — le peer doit ouvrir le chat pour voir l'appel
///   - Pas de vidéo (audio seulement)
///   - Pas de signaling RTM (pas de "call_invite" qui sonne côté peer)
class CallScreen extends ConsumerStatefulWidget {
  const CallScreen({
    required this.scope,
    required this.id,
    required this.peerName,
    super.key,
  });

  /// `match` | `friend`
  final String scope;

  /// matchId ou friendshipId
  final String id;

  /// Nom affiché du peer pendant l'appel
  final String peerName;

  @override
  ConsumerState<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends ConsumerState<CallScreen> {
  late final AgoraCallService _svc;

  @override
  void initState() {
    super.initState();
    _svc = ref.read(agoraCallServiceProvider);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _svc.startCall(scope: widget.scope, id: widget.id);
    });
  }

  @override
  void dispose() {
    // Hangup auto si l'utilisateur ferme l'écran sans tap hangup.
    unawaited(_svc.hangup());
    super.dispose();
  }

  String _statusLabel(CallSnapshot s) {
    switch (s.state) {
      case CallState.idle:
      case CallState.connecting:
        return 'Connexion en cours…';
      case CallState.ringing:
        return 'En attente de réponse…';
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
    return Scaffold(
      backgroundColor: ArenaColors.void_,
      body: SafeArea(
        child: StreamBuilder<CallSnapshot>(
          stream: _svc.stream,
          initialData: _svc.snapshot,
          builder: (context, snap) {
            final s = snap.data ?? const CallSnapshot(state: CallState.idle);
            final isFinal =
                s.state == CallState.ended || s.state == CallState.failed;
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
                  _statusLabel(s),
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
                      _HangupButton(
                        onTap: () async {
                          await _svc.hangup();
                          if (!context.mounted) return;
                          Navigator.of(context).pop();
                        },
                      ),
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
              color: active
                  ? ArenaColors.signalBlue
                  : ArenaColors.carbon2,
            ),
            child: Icon(
              icon,
              color: active ? Colors.white : ArenaColors.bone,
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
          color: Colors.white,
          size: 30,
        ),
      ),
    );
  }
}

// `unawaited` helper local au file pour éviter dépendre de pub:meta.
void unawaited(Future<void> _) {}
