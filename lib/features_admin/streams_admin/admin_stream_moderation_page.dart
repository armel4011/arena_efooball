import 'package:arena/core/theme/arena_theme.dart';
import 'package:arena/data/models/match_stream.dart';
import 'package:arena/data/repositories/admin/admin_audit_log_repository.dart';
import 'package:arena/data/repositories/match_stream_repository.dart';
import 'package:arena/features_shared/widgets/arena_app_bar.dart';
import 'package:arena/features_shared/widgets/arena_badge.dart';
import 'package:arena/features_shared/auth_common/shared_auth_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// PHASE 11 · A12 — multi-stream moderation grid.
///
/// Reads live public streams via [activePublicStreamsProvider]
/// (realtime). The cap is informational (V1.0 won't enforce a hard
/// max); the kill switch flips `streams.is_public = false` so the
/// stream drops out of the user-facing `LiveStreamsPage` immediately.
/// Every cut is appended to the audit log.
///
/// Maps to screen A12 of `arena_v2.html`.
class AdminStreamModerationPage extends ConsumerWidget {
  const AdminStreamModerationPage({super.key});

  static const _capacity = 6;
  static const _gradients = <LinearGradient>[
    LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF1A3A6C), Color(0xFF2C0A1F)],
    ),
    LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF1A3A1A), Color(0xFF0A1A0A)],
    ),
    LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF3A2200), Color(0xFF1A0A00)],
    ),
    LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF3A0A6C), Color(0xFF1A0A30)],
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final streams = ref.watch(activePublicStreamsProvider);

    return Scaffold(
      appBar: const ArenaAppBar(title: 'Modération streams'),
      body: SafeArea(
        child: streams.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Padding(
            padding: const EdgeInsets.all(ArenaSpacing.lg),
            child: Text(
              'Erreur de chargement : $e',
              style: ArenaText.bodyMuted,
            ),
          ),
          data: (list) => ListView(
            padding: const EdgeInsets.all(ArenaSpacing.lg),
            children: [
              _SummaryCard(streams: list),
              const SizedBox(height: ArenaSpacing.md),
              if (list.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(ArenaSpacing.lg),
                  child: Text(
                    'Aucun stream public actif.',
                    style: ArenaText.bodyMuted,
                    textAlign: TextAlign.center,
                  ),
                )
              else
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  childAspectRatio: 0.95,
                  crossAxisSpacing: ArenaSpacing.xs,
                  mainAxisSpacing: ArenaSpacing.xs,
                  children: [
                    for (var i = 0; i < list.length; i++)
                      _StreamTile(
                        stream: list[i],
                        gradient: _gradients[i % _gradients.length],
                      ),
                    if (list.length < _capacity)
                      _EmptySlot(
                        used: list.length,
                        total: _capacity,
                      ),
                  ],
                ),
              const SizedBox(height: ArenaSpacing.lg),
              Container(
                padding: const EdgeInsets.all(ArenaSpacing.md),
                decoration: arenaWarningCardDecoration(),
                child: Text(
                  '⚠ Couper un stream est journalisé dans admin_audit_log '
                  'avec ton ID admin.',
                  style: ArenaText.body,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.streams});
  final List<MatchStream> streams;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(ArenaSpacing.md),
      decoration: arenaGlowCardDecoration(),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${streams.length} stream${streams.length > 1 ? 's' : ''} actif${streams.length > 1 ? 's' : ''}',
                  style: ArenaText.h3,
                ),
                const SizedBox(height: 2),
                Text(
                  'Sur ${AdminStreamModerationPage._capacity} max simultanés',
                  style: ArenaText.bodyMuted,
                ),
              ],
            ),
          ),
          if (streams.isNotEmpty)
            const ArenaBadge(label: 'LIVE', variant: ArenaBadgeVariant.live),
        ],
      ),
    );
  }
}

class _StreamTile extends ConsumerWidget {
  const _StreamTile({required this.stream, required this.gradient});

  final MatchStream stream;
  final LinearGradient gradient;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
        color: ArenaColors.carbon,
        borderRadius: BorderRadius.circular(ArenaRadius.lg),
        border: Border.all(color: ArenaColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Stack(
            children: [
              Container(
                height: 80,
                decoration: BoxDecoration(gradient: gradient),
              ),
              const Positioned(
                top: 4,
                left: 4,
                child: ArenaBadge(
                  label: 'LIVE',
                  variant: ArenaBadgeVariant.live,
                ),
              ),
              Positioned(
                bottom: 4,
                left: 4,
                child: Text(
                  'M-${stream.matchId.substring(0, 6)}',
                  style: ArenaText.body.copyWith(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Streamer ${stream.playerId.substring(0, 6)}',
                  style: ArenaText.body.copyWith(fontSize: 9),
                ),
                const SizedBox(height: 4),
                _MiniButton(
                  label: '🔇 COUPER',
                  danger: true,
                  onTap: () => _cut(context, ref),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _cut(BuildContext context, WidgetRef ref) async {
    final adminId = ref.read(currentSessionProvider)?.user.id;
    if (adminId == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: ArenaColors.carbon,
        title: Text('Couper ce stream ?', style: ArenaText.h3),
        content: Text(
          'Le stream sera retiré de la liste publique et les viewers '
          'seront déconnectés.',
          style: ArenaText.bodyMuted,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(c).pop(false),
            child: const Text('ANNULER'),
          ),
          TextButton(
            onPressed: () => Navigator.of(c).pop(true),
            style: TextButton.styleFrom(foregroundColor: ArenaColors.neonRed),
            child: const Text('COUPER'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    try {
      await ref.read(matchStreamRepositoryProvider).setStreamingPublic(
            streamId: stream.id,
            isPublic: false,
          );
      await ref.read(adminAuditLogRepositoryProvider).record(
        adminId: adminId,
        action: 'stream_cut',
        targetType: 'stream',
        targetId: stream.id,
        afterState: {'match_id': stream.matchId},
      );
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Stream coupé.')),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Échec : $e')),
      );
    }
  }
}

class _EmptySlot extends StatelessWidget {
  const _EmptySlot({required this.used, required this.total});

  final int used;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(ArenaSpacing.md),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(ArenaRadius.lg),
        border: Border.all(
          color: ArenaColors.silverDim,
          width: 1.5,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '+',
              style: ArenaText.bigNumber.copyWith(
                color: ArenaColors.silverDim,
                fontSize: 24,
              ),
            ),
            const SizedBox(height: 4),
            Text('Slot libre', style: ArenaText.bodyMuted),
            const SizedBox(height: 2),
            Text(
              '$used/$total utilisés',
              style: ArenaText.small,
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniButton extends StatelessWidget {
  const _MiniButton({
    required this.label,
    required this.onTap,
    this.danger = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(ArenaRadius.sm),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        decoration: BoxDecoration(
          color: danger ? ArenaColors.neonRed : ArenaColors.carbon2,
          borderRadius: BorderRadius.circular(ArenaRadius.sm),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: ArenaText.badge.copyWith(
            color: Colors.white,
            fontSize: 9,
          ),
        ),
      ),
    );
  }
}
