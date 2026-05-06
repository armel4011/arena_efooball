import 'package:arena/core/theme/arena_colors.dart';
import 'package:arena/core/theme/arena_theme.dart';
import 'package:arena/core/theme/arena_typography.dart';
import 'package:arena/data/models/profile.dart';
import 'package:arena/features_shared/widgets/arena_card.dart';
import 'package:arena/features_user/auth/auth_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// User dashboard.
///
/// Phase 3 ships the layout, the header and the stats card with real
/// data from `profile.stats`. Sections that depend on later phases
/// (competitions: 4 / matches: 5 / streams: 8) render compact "coming
/// soon" panels until those phases land.
class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(currentProfileProvider).value;

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(currentProfileProvider);
        await ref.read(currentProfileProvider.future);
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(ArenaSpacing.lg),
        children: [
          _Header(profile: profile),
          const SizedBox(height: ArenaSpacing.xl),
          const _SectionTitle('Compétitions actives'),
          const SizedBox(height: ArenaSpacing.sm),
          const _ComingSoonPanel(
            phase: 'PHASE 4',
            description: 'Liste des tournois en cours sur eFootball, FIFA'
                ' Mobile et EA SPORTS FC Mobile.',
            icon: Icons.sports_esports_outlined,
          ),
          const SizedBox(height: ArenaSpacing.xl),
          const _SectionTitle('Prochains matchs'),
          const SizedBox(height: ArenaSpacing.sm),
          const _ComingSoonPanel(
            phase: 'PHASE 5',
            description: 'Tes matchs à jouer (code room, adversaire,'
                ' deadline) apparaîtront ici.',
            icon: Icons.calendar_today_outlined,
          ),
          const SizedBox(height: ArenaSpacing.xl),
          const _SectionTitle('Lives en cours'),
          const SizedBox(height: ArenaSpacing.sm),
          const _ComingSoonPanel(
            phase: 'PHASE 8',
            description: 'Streaming Agora des finales — bientôt diffusé en'
                ' direct.',
            icon: Icons.live_tv_outlined,
          ),
          const SizedBox(height: ArenaSpacing.xl),
          const _SectionTitle('Tes stats'),
          const SizedBox(height: ArenaSpacing.sm),
          _StatsBlock(profile: profile),
          const SizedBox(height: ArenaSpacing.xl),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.profile});

  final Profile? profile;

  @override
  Widget build(BuildContext context) {
    final username = profile?.username ?? 'Joueur';
    final initial = username.isEmpty ? '?' : username[0].toUpperCase();
    final avatarColor = _parseHexColor(profile?.avatarColor) ??
        Theme.of(context).colorScheme.primary;

    return Row(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: avatarColor,
          ),
          alignment: Alignment.center,
          child: Text(
            initial,
            style: ArenaTypography.displayMedium.copyWith(
              color: Colors.white,
              fontSize: 22,
            ),
          ),
        ),
        const SizedBox(width: ArenaSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Salut,',
                style: ArenaTypography.bodyMedium.copyWith(
                  color: ArenaColors.textMuted,
                ),
              ),
              Text(
                username.toUpperCase(),
                style: ArenaTypography.headlineMedium,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.notifications_outlined),
          tooltip: 'Notifications',
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Notifications push : PHASE 10 (FCM).'),
              ),
            );
          },
        ),
      ],
    );
  }

  static Color? _parseHexColor(String? hex) {
    if (hex == null || hex.isEmpty) return null;
    var cleaned = hex.replaceAll('#', '').trim();
    if (cleaned.length == 6) cleaned = 'FF$cleaned';
    final value = int.tryParse(cleaned, radix: 16);
    return value == null ? null : Color(value);
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(text.toUpperCase(), style: ArenaTypography.headlineMedium);
  }
}

class _ComingSoonPanel extends StatelessWidget {
  const _ComingSoonPanel({
    required this.phase,
    required this.description,
    required this.icon,
  });

  final String phase;
  final String description;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return ArenaCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: ArenaColors.textMuted, size: 32),
          const SizedBox(width: ArenaSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  phase,
                  style: ArenaTypography.labelLarge.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: ArenaSpacing.xs),
                Text(
                  description,
                  style: ArenaTypography.bodyMedium.copyWith(
                    color: ArenaColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsBlock extends StatelessWidget {
  const _StatsBlock({required this.profile});

  final Profile? profile;

  @override
  Widget build(BuildContext context) {
    final stats = profile?.stats ?? const <String, dynamic>{};
    final wins = _asInt(stats['wins']);
    final losses = _asInt(stats['losses']);
    final goalsScored = _asInt(stats['goals_scored']);
    final goalsConceded = _asInt(stats['goals_conceded']);
    final played = wins + losses;
    final winRate = played == 0 ? 0 : ((wins / played) * 100).round();

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _StatCard(
                label: 'Victoires',
                value: '$wins',
                icon: Icons.emoji_events_outlined,
                accent: ArenaColors.success,
              ),
            ),
            const SizedBox(width: ArenaSpacing.sm),
            Expanded(
              child: _StatCard(
                label: 'Défaites',
                value: '$losses',
                icon: Icons.do_disturb_alt_outlined,
                accent: ArenaColors.danger,
              ),
            ),
          ],
        ),
        const SizedBox(height: ArenaSpacing.sm),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                label: 'Buts marqués',
                value: '$goalsScored',
                icon: Icons.sports_soccer_outlined,
              ),
            ),
            const SizedBox(width: ArenaSpacing.sm),
            Expanded(
              child: _StatCard(
                label: 'Buts encaissés',
                value: '$goalsConceded',
                icon: Icons.shield_outlined,
              ),
            ),
          ],
        ),
        const SizedBox(height: ArenaSpacing.sm),
        _StatCard(
          label: played == 0 ? 'Aucun match joué' : 'Ratio victoires',
          value: played == 0 ? '—' : '$winRate %',
          icon: Icons.bar_chart_outlined,
          accent: Theme.of(context).colorScheme.primary,
          fullWidth: true,
        ),
      ],
    );
  }

  static int _asInt(Object? v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    this.accent,
    this.fullWidth = false,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color? accent;
  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    final tone = accent ?? ArenaColors.textMuted;
    return ArenaCard(
      child: Row(
        children: [
          Icon(icon, color: tone, size: fullWidth ? 28 : 22),
          const SizedBox(width: ArenaSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: ArenaTypography.bodyMedium.copyWith(
                    color: ArenaColors.textMuted,
                    fontSize: 12,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  value,
                  style: ArenaTypography.displayMedium.copyWith(
                    color: tone,
                    fontSize: fullWidth ? 24 : 20,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
