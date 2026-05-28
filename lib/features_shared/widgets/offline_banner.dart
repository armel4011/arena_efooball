import 'package:arena/core/services/network_status_service.dart';
import 'package:arena/core/theme/arena_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Bandeau "Hors ligne" qui s'affiche tout en haut de l'app quand le
/// reseau est down. Discret, n'empile pas de SnackBar agressifs.
///
/// **Animation** : slide-in depuis le haut + fade. Au retour online,
/// flash bref "Reconnecte" pour rassurer le user, puis disparait.
class OfflineBanner extends ConsumerStatefulWidget {
  const OfflineBanner({super.key});

  @override
  ConsumerState<OfflineBanner> createState() => _OfflineBannerState();
}

class _OfflineBannerState extends ConsumerState<OfflineBanner> {
  bool _wasOffline = false;
  bool _showReconnected = false;

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<NetworkStatus>>(networkStatusProvider, (prev, next) {
      final now = next.valueOrNull;
      if (now == null) return;
      if (now == NetworkStatus.offline) {
        _wasOffline = true;
      } else if (now == NetworkStatus.online && _wasOffline) {
        // Flash "Reconnecte" pendant 2s puis cache.
        setState(() => _showReconnected = true);
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            setState(() {
              _showReconnected = false;
              _wasOffline = false;
            });
          }
        });
      }
    });

    final status = ref.watch(networkStatusProvider).valueOrNull;
    final showOffline = status == NetworkStatus.offline;
    final visible = showOffline || _showReconnected;
    return AnimatedSize(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      alignment: Alignment.topCenter,
      child: visible
          ? _Banner(reconnected: _showReconnected)
          : const SizedBox.shrink(),
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({required this.reconnected});
  final bool reconnected;

  @override
  Widget build(BuildContext context) {
    final (icon, label, color) = reconnected
        ? (Icons.wifi, 'RECONNECTÉ', ArenaColors.statusOk)
        : (Icons.wifi_off, 'HORS LIGNE', ArenaColors.statusWarn);
    return Material(
      color: color.withValues(alpha: 0.95),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: ArenaSpacing.md,
            vertical: 6,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: ArenaColors.void_, size: 14),
              const SizedBox(width: 6),
              Text(
                label,
                style: ArenaText.badge.copyWith(
                  color: ArenaColors.void_,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                  fontSize: 11,
                ),
              ),
              if (!reconnected) ...[
                const SizedBox(width: 8),
                Text(
                  '· Données mises en cache',
                  style: ArenaText.small.copyWith(
                    color: ArenaColors.void_.withValues(alpha: 0.85),
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
