import 'dart:async';

import 'package:arena/core/services/agora_call_service.dart';
import 'package:arena/core/theme/arena_theme.dart';
import 'package:arena/data/models/call_record.dart';
import 'package:arena/data/repositories/call_repository.dart';
import 'package:arena/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Écran d'appel audio 1v1 (Phase 12.5 — item 3, étendu : signalisation).
///
/// Deux entrées :
///   - APPELANT : ouvre l'écran avec `callId == null`. L'écran crée la
///     ligne `calls` (`placeCall`) → le destinataire reçoit la sonnerie.
///   - DESTINATAIRE : ouvert depuis l'UI d'appel native (CallKit) après
///     avoir décroché, avec un `callId` déjà accepté.
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

  /// Côté appelant : coupe l'appel si le pair ne décroche pas à temps —
  /// évite une « Sonnerie… » infinie quand l'app du pair est tuée et
  /// n'envoie jamais de statut `declined`/`cancelled`.
  Timer? _ringTimeout;
  static const _kRingTimeout = Duration(seconds: 45);

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
          final l10n = AppLocalizations.of(context);
          setState(() => _override = l10n.callPlaceCallFailed);
        }
        return;
      }
    }
    if (!mounted) return;
    setState(() => _callId = id);
    // Appelant uniquement : arme le garde-fou « pas de réponse ». Côté
    // destinataire (`callId` déjà fourni) l'appel est déjà accepté.
    if (widget.callId == null) {
      _ringTimeout = Timer(_kRingTimeout, _onRingTimeout);
    }
    await _svc.startCall(scope: widget.scope, id: widget.id);
  }

  @override
  void dispose() {
    _ringTimeout?.cancel();
    unawaited(_svc.hangup());
    final id = _callId;
    // Ne clôt la ligne `calls` que si l'appel était encore vivant au
    // moment où l'écran est quitté (retour arrière). Si `_override` est
    // défini ou `_closing`, un statut terminal (declined/missed/ended) a
    // déjà été posé — ne pas l'écraser avec `ended`.
    if (id != null && !_closing && _override == null) {
      unawaited(_callRepo.end(id));
    }
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

  /// Le pair n'a pas décroché dans le délai imparti : on clôt l'appel en
  /// `missed` plutôt que de laisser sonner indéfiniment.
  void _onRingTimeout() {
    final id = _callId;
    if (_closing || _override != null || id == null) return;
    final l10n = AppLocalizations.of(context);
    setState(() => _override = l10n.callNoAnswer);
    unawaited(_svc.hangup());
    unawaited(_callRepo.markMissed(id));
  }

  /// Réagit au statut signalé : le pair a décroché / refusé / raccroché.
  void _onSignal(CallRecord? c) {
    if (c == null) return;
    // L'appel a quitté l'état sonnerie : le garde-fou n'a plus lieu d'être.
    if (!c.isRinging) _ringTimeout?.cancel();
    if (c.isLive || _closing || _override != null) return;
    final l10n = AppLocalizations.of(context);
    setState(
      () => _override = switch (c.status) {
        CallStatus.declined => l10n.callDeclined,
        CallStatus.missed => l10n.callNoAnswer,
        _ => l10n.callEnded,
      },
    );
    unawaited(_svc.hangup());
  }

  String _statusLabel(CallSnapshot s) {
    final l10n = AppLocalizations.of(context);
    switch (s.state) {
      case CallState.idle:
      case CallState.connecting:
        return l10n.callStatusConnecting;
      case CallState.ringing:
        return l10n.callStatusRinging;
      case CallState.connected:
        return l10n.callStatusConnected;
      case CallState.ended:
        return l10n.callStatusEnded;
      case CallState.failed:
        return s.errorMessage ?? l10n.callStatusFailed;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
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
                        label: s.micMuted
                            ? l10n.callControlUnmute
                            : l10n.callControlMute,
                        onTap: _svc.toggleMute,
                      ),
                      _HangupButton(onTap: _hangup),
                      _CallControl(
                        icon: s.speakerOn
                            ? Icons.volume_up
                            : Icons.volume_down,
                        active: s.speakerOn,
                        label: s.speakerOn
                            ? l10n.callControlSpeaker
                            : l10n.callControlEarpiece,
                        onTap: _svc.toggleSpeaker,
                      ),
                    ],
                  ),
                ] else
                  _CallControl(
                    icon: Icons.close,
                    active: false,
                    label: l10n.callControlClose,
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
              color: ArenaColors.bone,
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
