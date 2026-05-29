import 'package:arena/core/services/network_status_service.dart';
import 'package:arena/core/services/sync_queue_service.dart';
import 'package:arena/core/theme/arena_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Bandeau d'etat reseau / synchronisation affiche tout en haut de l'app.
/// Discret, n'empile pas de SnackBar agressifs et ne prend de la place
/// que quand il a quelque chose a dire.
///
/// **Etats** (par priorite) :
///   1. HORS LIGNE         — reseau down (+ compteur d'actions en file)
///   2. SYNCHRONISATION…   — flush de la sync queue en cours (spinner)
///   3. CONNEXION LENTE    — interface up mais latence elevee
///   4. RECONNECTÉ         — flash bref de 2s au retour online
///   5. masque             — online + rien a synchroniser
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
    // Etat reactif de la sync queue (peut etre absent au tout debut du
    // boot avant que le FutureProvider ne resolve).
    final syncNotifier = ref.watch(syncQueueServiceProvider).valueOrNull?.state;

    return ValueListenableBuilder<SyncState>(
      valueListenable: syncNotifier ?? _idleSync,
      builder: (context, sync, _) {
        final variant = _resolve(status, sync);
        return AnimatedSize(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          alignment: Alignment.topCenter,
          child: variant == null
              ? const SizedBox.shrink()
              : _Banner(variant: variant),
        );
      },
    );
  }

  /// Notifier inerte utilise tant que la vraie queue n'est pas prete —
  /// evite un `ValueListenableBuilder` conditionnel.
  static final _idleSync = ValueNotifier<SyncState>(SyncState.idle);

  _BannerVariant? _resolve(NetworkStatus? status, SyncState sync) {
    if (status == NetworkStatus.offline) {
      return _BannerVariant.offline(sync.pending);
    }
    // En ligne / lent : la sync prime sur le badge "lent".
    if (sync.flushing && sync.pending > 0) {
      return _BannerVariant.syncing(sync.pending);
    }
    if (status == NetworkStatus.slow) {
      return const _BannerVariant.slow();
    }
    if (_showReconnected) {
      return const _BannerVariant.reconnected();
    }
    return null;
  }
}

/// Description visuelle figee du bandeau a un instant donne.
class _BannerVariant {
  const _BannerVariant._({
    required this.icon,
    required this.label,
    required this.color,
    this.detail,
    this.spinner = false,
  });

  const _BannerVariant.offline(int pending)
      : this._(
          icon: Icons.wifi_off,
          label: 'HORS LIGNE',
          color: ArenaColors.statusWarn,
          detail: pending > 0
              ? '$pending action${pending > 1 ? 's' : ''} en attente'
              : 'Données mises en cache',
        );

  const _BannerVariant.syncing(int pending)
      : this._(
          icon: Icons.sync,
          label: 'SYNCHRONISATION…',
          color: ArenaColors.signalBlue,
          detail: '$pending restante${pending > 1 ? 's' : ''}',
          spinner: true,
        );

  const _BannerVariant.slow()
      : this._(
          icon: Icons.signal_cellular_alt_2_bar,
          label: 'CONNEXION LENTE',
          color: ArenaColors.statusWarn,
        );

  const _BannerVariant.reconnected()
      : this._(
          icon: Icons.wifi,
          label: 'RECONNECTÉ',
          color: ArenaColors.statusOk,
        );

  final IconData icon;
  final String label;
  final Color color;
  final String? detail;
  final bool spinner;
}

class _Banner extends StatelessWidget {
  const _Banner({required this.variant});
  final _BannerVariant variant;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: variant.color.withValues(alpha: 0.95),
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
              if (variant.spinner)
                const SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(ArenaColors.void_),
                  ),
                )
              else
                Icon(variant.icon, color: ArenaColors.void_, size: 14),
              const SizedBox(width: 6),
              Text(
                variant.label,
                style: ArenaText.badge.copyWith(
                  color: ArenaColors.void_,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                  fontSize: 11,
                ),
              ),
              if (variant.detail != null) ...[
                const SizedBox(width: 8),
                Text(
                  '· ${variant.detail}',
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
