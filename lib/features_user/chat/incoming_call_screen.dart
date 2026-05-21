import 'dart:async';

import 'package:arena/core/services/notification_service.dart';
import 'package:arena/core/theme/arena_theme.dart';
import 'package:arena/data/models/call_record.dart';
import 'package:arena/data/repositories/call_repository.dart';
import 'package:arena/features_user/chat/call_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Nom de l'appelant — pour l'écran d'appel entrant.
final _callerNameProvider =
    FutureProvider.autoDispose.family<String, String>((ref, callerId) {
  return ref.watch(callRepositoryProvider).usernameOf(callerId);
});

/// Écran d'appel ENTRANT — surgit (sonnerie + vibration) quand un appel
/// `ringing` arrive pour l'utilisateur courant. Poussé par l'écoute
/// globale de `main_user.dart`.
///
/// Décrocher → marque l'appel `accepted` puis ouvre [CallScreen].
/// Refuser   → marque l'appel `declined` et ferme l'écran.
class IncomingCallScreen extends ConsumerStatefulWidget {
  const IncomingCallScreen({required this.call, super.key});

  final CallRecord call;

  @override
  ConsumerState<IncomingCallScreen> createState() =>
      _IncomingCallScreenState();
}

class _IncomingCallScreenState extends ConsumerState<IncomingCallScreen> {
  Timer? _ringTimer;
  Timer? _timeoutTimer;
  bool _handled = false;

  /// Au-delà de ce délai sans réponse, l'appel entrant est abandonné
  /// (`missed`) — évite une sonnerie infinie si l'appelant ne raccroche
  /// jamais (app tuée, donc aucun statut `cancelled`).
  static const _kIncomingTimeout = Duration(seconds: 45);

  @override
  void initState() {
    super.initState();
    // Sonnerie « app ouverte » : vibration + bip d'alerte en boucle.
    // Le son système plein écran arrive via la notif FCM (Lot 3).
    HapticFeedback.heavyImpact();
    _ringTimer = Timer.periodic(const Duration(milliseconds: 1800), (_) {
      HapticFeedback.heavyImpact();
      SystemSound.play(SystemSoundType.alert);
    });
    _timeoutTimer = Timer(_kIncomingTimeout, _onTimeout);
    // L'écran in-app prend le relais : la notif FCM plein écran (Lot 3)
    // ferait double emploi et resterait sinon coincée dans le tray.
    unawaited(dismissIncomingCallRing());
  }

  @override
  void dispose() {
    _ringTimer?.cancel();
    _timeoutTimer?.cancel();
    super.dispose();
  }

  void _stopRing() {
    _ringTimer?.cancel();
    _timeoutTimer?.cancel();
  }

  Future<void> _accept() async {
    if (_handled) return;
    _handled = true;
    _stopRing();
    final nav = Navigator.of(context);
    final peerName =
        ref.read(_callerNameProvider(widget.call.callerId)).value ?? 'Joueur';
    try {
      await ref.read(callRepositoryProvider).accept(widget.call.id);
    } catch (_) {/* on tente la jonction Agora même si l'update échoue */}
    if (!mounted) return;
    await nav.pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => CallScreen(
          callId: widget.call.id,
          scope: widget.call.scope,
          id: widget.call.scopeId,
          calleeId: widget.call.callerId,
          peerName: peerName,
        ),
        fullscreenDialog: true,
      ),
    );
  }

  Future<void> _decline() async {
    if (_handled) return;
    _handled = true;
    _stopRing();
    final nav = Navigator.of(context);
    try {
      await ref.read(callRepositoryProvider).decline(widget.call.id);
    } catch (_) {/* swallow */}
    if (mounted) nav.pop();
  }

  /// Sonnerie trop longue sans réponse : on marque l'appel `missed` et
  /// on ferme l'écran.
  Future<void> _onTimeout() async {
    if (_handled) return;
    _handled = true;
    _stopRing();
    final nav = Navigator.of(context);
    try {
      await ref.read(callRepositoryProvider).markMissed(widget.call.id);
    } catch (_) {/* swallow */}
    if (mounted) nav.pop();
  }

  @override
  Widget build(BuildContext context) {
    // Auto-fermeture si l'appelant annule avant qu'on réponde.
    ref.listen<AsyncValue<CallRecord?>>(callByIdProvider(widget.call.id),
        (_, next) {
      final c = next.value;
      if (c != null && !c.isRinging && !_handled) {
        _handled = true;
        _stopRing();
        if (mounted) Navigator.of(context).pop();
      }
    });

    final name = ref.watch(_callerNameProvider(widget.call.callerId)).value;
    final display = name ?? 'Appel entrant';
    final initial = (name == null || name.isEmpty)
        ? '?'
        : name[0].toUpperCase();

    return Scaffold(
      backgroundColor: ArenaColors.void_,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 72),
            Container(
              width: 128,
              height: 128,
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
                  fontSize: 52,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(height: ArenaSpacing.lg),
            Text(
              display,
              style: ArenaText.h2.copyWith(color: ArenaColors.bone),
            ),
            const SizedBox(height: ArenaSpacing.sm),
            Text(
              'Appel entrant…',
              style: ArenaText.body.copyWith(color: ArenaColors.silver),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: ArenaSpacing.xxxl,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _CallAction(
                    color: ArenaColors.neonRed,
                    icon: Icons.call_end,
                    label: 'Refuser',
                    onTap: _decline,
                  ),
                  _CallAction(
                    color: ArenaColors.statusOk,
                    icon: Icons.call,
                    label: 'Décrocher',
                    onTap: _accept,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 56),
          ],
        ),
      ),
    );
  }
}

class _CallAction extends StatelessWidget {
  const _CallAction({
    required this.color,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final Color color;
  final IconData icon;
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
            width: 76,
            height: 76,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color),
            child: Icon(icon, color: ArenaColors.bone, size: 32),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: ArenaText.small.copyWith(color: ArenaColors.silver),
        ),
      ],
    );
  }
}
