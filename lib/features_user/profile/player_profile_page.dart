import 'package:arena/core/router/user_router.dart';
import 'package:arena/core/theme/arena_theme.dart';
import 'package:arena/data/models/arena_match.dart';
import 'package:arena/data/models/player_stats.dart';
import 'package:arena/data/models/profile.dart';
import 'package:arena/data/repositories/friends_repository.dart';
import 'package:arena/data/repositories/match_stats_repository.dart';
import 'package:arena/data/repositories/referral_repository.dart';
import 'package:arena/features_shared/widgets/arena_button.dart';
import 'package:arena/features_shared/widgets/arena_card.dart';
import 'package:arena/features_shared/widgets/arena_screen_background.dart';
import 'package:arena/features_user/auth/auth_providers.dart';
import 'package:arena/features_user/profile/avatar_palette.dart';
import 'package:arena/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Tab "Profil" of the user app (PHASE 9.1).
///
/// Mounted by `MainLayout` under tab index 3, so it has no AppBar of its
/// own — the parent scaffold supplies it. Pulls the authenticated
/// profile from [currentProfileProvider] and the W/L stats from
/// [playerStatsProvider]; both providers refresh on pull-to-refresh.
class PlayerProfilePage extends ConsumerWidget {
  const PlayerProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(currentProfileProvider);

    return ArenaScreenBackground(
      child: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(ArenaSpacing.lg),
            child: Text(
              AppLocalizations.of(context).playerProfileError(e),
              textAlign: TextAlign.center,
              style: ArenaText.body.copyWith(color: ArenaColors.danger),
            ),
          ),
        ),
        data: (profile) {
          if (profile == null) {
            return Center(
              child: Text(
                AppLocalizations.of(context).playerProfileUnavailable,
                style: ArenaText.bodyMuted,
              ),
            );
          }
          return _ProfileBody(profile: profile);
        },
      ),
    );
  }
}

class _ProfileBody extends ConsumerWidget {
  const _ProfileBody({required this.profile});

  final Profile profile;

  Future<void> _refresh(WidgetRef ref) async {
    ref
      ..invalidate(currentProfileProvider)
      ..invalidate(playerStatsProvider(profile.id))
      ..invalidate(playerRecentMatchesProvider(profile.id))
      // Le compteur d'invités est un FutureProvider (pas de Realtime sur
      // `profiles`) : sans cette invalidation il reste figé au pull-to-refresh.
      ..invalidate(myReferralCountProvider);
    await ref.read(currentProfileProvider.future);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final statsAsync = ref.watch(playerStatsProvider(profile.id));
    final recentAsync = ref.watch(playerRecentMatchesProvider(profile.id));

    return RefreshIndicator(
      onRefresh: () => _refresh(ref),
      child: ListView(
        padding: const EdgeInsets.all(ArenaSpacing.lg),
        children: [
          _Header(profile: profile),
          const SizedBox(height: ArenaSpacing.lg),
          _StatsRow(stats: statsAsync),
          const SizedBox(height: ArenaSpacing.lg),
          Text(
            l10n.playerProfileSuccessHeader,
            style: ArenaText.monoSmall.copyWith(
              color: ArenaColors.silver,
              letterSpacing: 1.5,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: ArenaSpacing.sm),
          _AchievementsRow(stats: statsAsync),
          const SizedBox(height: ArenaSpacing.lg),
          const _FriendsSection(),
          const SizedBox(height: ArenaSpacing.lg),
          const _ReferralBadgeCard(),
          const SizedBox(height: ArenaSpacing.lg),
          Text(
            l10n.playerProfileRecentMatchesHeader,
            style: ArenaText.monoSmall.copyWith(
              color: ArenaColors.silver,
              letterSpacing: 1.5,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: ArenaSpacing.sm),
          _RecentMatches(playerId: profile.id, asyncMatches: recentAsync),
          const SizedBox(height: ArenaSpacing.xl),
          ArenaButton(
            label: l10n.playerProfileSettingsButton,
            icon: Icons.settings_outlined,
            variant: ArenaButtonVariant.secondary,
            fullWidth: true,
            onPressed: () => context.push(UserRoutes.settings),
          ),
          const SizedBox(height: ArenaSpacing.sm),
          ArenaButton(
            label: l10n.playerProfileSignOutButton,
            icon: Icons.logout,
            variant: ArenaButtonVariant.ghost,
            fullWidth: true,
            onPressed: () => ref.read(signOutProvider)(),
          ),
        ],
      ),
    );
  }
}

/// Header centré façon maquette #24 — avatar XL avec glow couleur du
/// profil + username display Bebas 26px uppercase + sous-titre
/// "🇨🇲 ${country} · Inscrit en ${month year}" + tier badge gradient.
/// Le bouton "modifier" est posé en overlay top-right pour rester
/// visible même sans AppBar (la page est embeddée dans MainLayout).
class _Header extends StatelessWidget {
  const _Header({required this.profile});

  final Profile profile;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final color = AvatarPalette.colorFromHex(profile.avatarColor);
    final initial =
        profile.username.isEmpty ? '?' : profile.username[0].toUpperCase();
    final country = _countryLabel(profile.countryCode);
    final joinedAt = _joinedLabel(profile.createdAt);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Column(
          children: [
            Container(
              width: 86,
              height: 86,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.6),
                    blurRadius: 36,
                    spreadRadius: -2,
                  ),
                ],
                border: Border.all(
                  color: ArenaColors.bone.withValues(alpha: 0.18),
                  width: 1.5,
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                initial,
                style: ArenaText.h1.copyWith(
                  color: ArenaColors.bone,
                  fontSize: 38,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(height: ArenaSpacing.sm),
            Text(
              profile.username.toUpperCase(),
              style: ArenaText.h1.copyWith(
                color: ArenaColors.bone,
                fontSize: 26,
                letterSpacing: 2,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              '$country · ${l10n.playerProfileJoinedPrefix} $joinedAt',
              style: ArenaText.small.copyWith(color: ArenaColors.silver),
            ),
            const SizedBox(height: 8),
            _TierBadge(label: l10n.playerProfileTierBronze),
          ],
        ),
        Positioned(
          top: 0,
          right: 0,
          child: IconButton(
            icon: const Icon(
              Icons.edit_outlined,
              color: ArenaColors.silver,
              size: 20,
            ),
            tooltip: l10n.playerProfileEditTooltip,
            onPressed: () => context.push(UserRoutes.profileEdit),
          ),
        ),
      ],
    );
  }

  static String _countryLabel(String code) {
    // L'API stocke un ISO 2 ; on prefixe d'un emoji drapeau pour matcher
    // la maquette `🇨🇲 Cameroon`. Le label long n'est pas mappé en V1
    // (l'utilisateur le voit dans EditProfilePage de toute façon).
    if (code.length < 2) return '🌍 $code';
    final flag = String.fromCharCodes(
      code.toUpperCase().codeUnits.map((c) => 0x1F1E6 + (c - 0x41)),
    );
    return '$flag $code';
  }

  static String _joinedLabel(DateTime? at) {
    if (at == null) return '—';
    const months = [
      'janv.',
      'févr.',
      'mars',
      'avril',
      'mai',
      'juin',
      'juil.',
      'août',
      'sept.',
      'oct.',
      'nov.',
      'déc.',
    ];
    return '${months[at.month - 1]} ${at.year}';
  }
}

/// Tier badge gradient gold→hotCoral — placeholder visuel pour V1 (le
/// vrai tier sera dérivé de `profile.stats.elo` ou similaire en V1.5).
class _TierBadge extends StatelessWidget {
  const _TierBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [ArenaColors.tierGoldWarm, ArenaColors.hotCoral],
        ),
        borderRadius: BorderRadius.circular(ArenaRadius.round),
        boxShadow: [
          BoxShadow(
            color: ArenaColors.tierGoldWarm.withValues(alpha: 0.35),
            blurRadius: 14,
            spreadRadius: -2,
          ),
        ],
      ),
      child: Text(
        label,
        style: ArenaText.badge.copyWith(
          color: ArenaColors.bone,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

/// Ligne de 3 stats compactes (Victoires / Défaites / Taux victoires) —
/// reproduit `.m-row gap:6px` + 3 `m-card` de la maquette. La 3e card
/// (winrate) est en glow signalBlue pour la mettre en valeur.
class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.stats});

  final AsyncValue<PlayerStats> stats;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return stats.when(
      loading: () => const SizedBox(
        height: 80,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Text(
        l10n.playerProfileStatsError(e),
        style: ArenaText.body.copyWith(color: ArenaColors.danger),
      ),
      data: (s) {
        final pct =
            s.totalMatches == 0 ? '—' : '${(s.winRatio * 100).round()}%';
        return Row(
          children: [
            Expanded(
              child: _MiniStatCard(
                value: '${s.wins}',
                label: l10n.playerProfileStatWins,
                color: ArenaColors.statusOk,
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: _MiniStatCard(
                value: '${s.losses}',
                label: l10n.playerProfileStatLosses,
                color: ArenaColors.neonRed,
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: _MiniStatCard(
                value: pct,
                label: l10n.playerProfileStatWinRate,
                color: ArenaColors.signalBlue,
                glow: true,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _MiniStatCard extends StatelessWidget {
  const _MiniStatCard({
    required this.value,
    required this.label,
    required this.color,
    this.glow = false,
  });

  final String value;
  final String label;
  final Color color;
  final bool glow;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: ArenaColors.carbon,
        borderRadius: BorderRadius.circular(ArenaRadius.lg),
        border: Border.all(
          color: glow ? color : ArenaColors.border,
        ),
        boxShadow: glow
            ? [
                BoxShadow(
                  color: color.withValues(alpha: 0.25),
                  blurRadius: 18,
                  spreadRadius: -4,
                ),
              ]
            : null,
      ),
      child: Column(
        children: [
          Text(
            value,
            style: ArenaText.mono.copyWith(
              color: color,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: ArenaText.small.copyWith(color: ArenaColors.silver),
          ),
        ],
      ),
    );
  }
}

/// Row de squares 36×36 — reproduit `🏆 ACHIEVEMENTS` de la maquette.
/// V1 : les badges sont dérivés des stats du joueur (1 match terminé →
/// 🎮, 1ère victoire → 🥇, série de 3 victoires → 🔥, 10+ matches → ⚡),
/// les slots restants sont des placeholders gris.
class _AchievementsRow extends StatelessWidget {
  const _AchievementsRow({required this.stats});

  final AsyncValue<PlayerStats> stats;

  @override
  Widget build(BuildContext context) {
    final s = stats.valueOrNull;
    final played = s?.totalMatches ?? 0;
    final wins = s?.wins ?? 0;
    final unlocked = <(String, List<Color>)>[
      if (played >= 1) ('🎮', [ArenaColors.signalBlue, ArenaColors.iceCyan]),
      if (wins >= 1)
        ('🥇', [ArenaColors.tierGoldWarm, ArenaColors.tierGoldDeep]),
      if (wins >= 3) ('🔥', [ArenaColors.statusOk, ArenaColors.gameDraughts]),
      if (played >= 10) ('⚡', [ArenaColors.neonRed, ArenaColors.hotCoral]),
    ];
    final slots = List<(String, List<Color>)?>.filled(5, null);
    for (var i = 0; i < unlocked.length && i < 5; i++) {
      slots[i] = unlocked[i];
    }

    return Row(
      children: [
        for (var i = 0; i < slots.length; i++) ...[
          _AchievementBadge(badge: slots[i]),
          if (i < slots.length - 1) const SizedBox(width: 6),
        ],
      ],
    );
  }
}

class _AchievementBadge extends StatelessWidget {
  const _AchievementBadge({required this.badge});

  final (String, List<Color>)? badge;

  @override
  Widget build(BuildContext context) {
    if (badge == null) {
      return Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: ArenaColors.bone.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(10),
        ),
      );
    }
    final (emoji, colors) = badge!;
    return Container(
      width: 36,
      height: 36,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: colors.first.withValues(alpha: 0.3),
            blurRadius: 12,
            spreadRadius: -2,
          ),
        ],
      ),
      child: Text(emoji, style: const TextStyle(fontSize: 18)),
    );
  }
}

class _RecentMatches extends StatelessWidget {
  const _RecentMatches({
    required this.playerId,
    required this.asyncMatches,
  });

  final String playerId;
  final AsyncValue<List<ArenaMatch>> asyncMatches;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return asyncMatches.when(
      loading: () => const ArenaCard(
        child: SizedBox(
          height: 64,
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (e, _) => ArenaCard(
        child: Text(
          l10n.playerProfileMatchRowError(e),
          style: ArenaText.body.copyWith(color: ArenaColors.danger),
        ),
      ),
      data: (matches) {
        if (matches.isEmpty) {
          return ArenaCard(
            child: Text(
              l10n.playerProfileNoCompletedMatches,
              style: ArenaTypography.bodyMedium.copyWith(
                color: ArenaColors.textMuted,
              ),
            ),
          );
        }
        return Column(
          children: [
            for (final m in matches)
              Padding(
                padding: const EdgeInsets.only(bottom: ArenaSpacing.sm),
                child: _MatchRow(playerId: playerId, match: m),
              ),
          ],
        );
      },
    );
  }
}

class _MatchRow extends StatelessWidget {
  const _MatchRow({required this.playerId, required this.match});

  final String playerId;
  final ArenaMatch match;

  @override
  Widget build(BuildContext context) {
    final isP1 = match.player1Id == playerId;
    final myScore = isP1 ? match.score1 : match.score2;
    final theirScore = isP1 ? match.score2 : match.score1;

    final result = match.winnerId == null
        ? _Outcome.draw
        : match.winnerId == playerId
            ? _Outcome.win
            : _Outcome.loss;

    return ArenaCard(
      onTap: () => context.push(UserRoutes.matchPath(match.id)),
      padding: const EdgeInsets.symmetric(
        vertical: ArenaSpacing.sm,
        horizontal: ArenaSpacing.md,
      ),
      child: Row(
        children: [
          _ResultBadge(result: result),
          const SizedBox(width: ArenaSpacing.md),
          Expanded(
            child: Text(
              'Match #${match.id.substring(0, 8)}',
              style: ArenaTypography.bodyMedium,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            '${myScore ?? '-'} : ${theirScore ?? '-'}',
            style: ArenaTypography.labelLarge,
          ),
        ],
      ),
    );
  }
}

/// Phase 13 — Section "Mes amis" dans le tab profil. Affiche un compteur
/// total d'amis acceptés + un badge si demandes pending entrantes ;
/// tap → /friends. Le badge utilise un stream realtime de la table
/// `friendships` pour se mettre à jour sans navigation.
class _FriendsSection extends ConsumerWidget {
  const _FriendsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final pendingAsync = ref.watch(incomingFriendRequestsCountProvider);
    final friendsAsync = ref.watch(acceptedFriendsProvider);

    final pending = pendingAsync.maybeWhen(data: (v) => v, orElse: () => 0);
    final friendsCount =
        friendsAsync.maybeWhen(data: (v) => v.length, orElse: () => 0);

    return ArenaCard(
      onTap: () => context.push(UserRoutes.friends),
      padding: const EdgeInsets.symmetric(
        vertical: ArenaSpacing.md,
        horizontal: ArenaSpacing.md,
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: ArenaColors.primary.withValues(alpha: 0.16),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.people_outline,
              color: ArenaColors.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: ArenaSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      l10n.playerProfileFriendsTitle,
                      style: ArenaTypography.bodyMedium,
                    ),
                    if (pending > 0) ...[
                      const SizedBox(width: ArenaSpacing.sm),
                      _PendingBadge(count: pending),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  friendsCount == 0
                      ? l10n.playerProfileNoFriends
                      : friendsCount > 1
                          ? l10n.playerProfileFriendsCountPlural(friendsCount)
                          : l10n.playerProfileFriendsCountSingular(
                              friendsCount,
                            ),
                  style: ArenaTypography.bodySmall.copyWith(
                    color: ArenaColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: ArenaColors.textMuted),
        ],
      ),
    );
  }
}

class _PendingBadge extends StatelessWidget {
  const _PendingBadge({required this.count});
  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: ArenaColors.danger,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        count > 99 ? '99+' : '$count',
        style: ArenaTypography.labelSmall.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

enum _Outcome { win, loss, draw }

class _ResultBadge extends StatelessWidget {
  const _ResultBadge({required this.result});

  final _Outcome result;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final (label, color) = switch (result) {
      _Outcome.win => (l10n.playerProfileResultWin, ArenaColors.success),
      _Outcome.loss => (l10n.playerProfileResultLoss, ArenaColors.danger),
      _Outcome.draw => (l10n.playerProfileResultDraw, ArenaColors.textMuted),
    };
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
        boxShadow: result == _Outcome.draw
            ? null
            : [
                BoxShadow(
                  color: color.withValues(alpha: 0.55),
                  blurRadius: 14,
                  spreadRadius: -2,
                ),
              ],
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: ArenaTypography.labelLarge.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

/// Item 2 prompt 2026-05-19 — Badge parrainage sur la page Profil.
///
/// Montre : code parrainage (tap to copy) + nombre de filleuls actifs +
/// rappel du perk "accès auto aux compétitions gratuites à récompense
/// conditionnée" pour les users qui atteignent le quota requis par la
/// compétition. La logique de gating elle-même vit côté DB (trigger
/// `enforce_referral_quota_on_registration`) ; ce badge n'est qu'un
/// indicateur informatif.
class _ReferralBadgeCard extends ConsumerWidget {
  const _ReferralBadgeCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final codeAsync = ref.watch(myReferralCodeProvider);
    final countAsync = ref.watch(myReferralCountProvider);

    final code = codeAsync.valueOrNull;
    final count = countAsync.valueOrNull ?? 0;

    return ArenaCard(
      padding: const EdgeInsets.all(ArenaSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(
                Icons.group_add_outlined,
                color: ArenaColors.tierGoldWarm,
                size: 22,
              ),
              const SizedBox(width: ArenaSpacing.sm),
              Expanded(
                child: Text(
                  l10n.playerProfileReferralTitle,
                  style: ArenaTypography.titleMedium,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: ArenaColors.tierGoldWarm.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: ArenaColors.tierGoldWarm.withValues(alpha: 0.5),
                  ),
                ),
                child: Text(
                  count > 1
                      ? l10n.playerProfileReferralCountPlural(count)
                      : l10n.playerProfileReferralCountSingular(count),
                  style: ArenaTypography.labelMedium.copyWith(
                    color: ArenaColors.tierGoldWarm,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: ArenaSpacing.sm),
          if (code != null && code.isNotEmpty)
            InkWell(
              onTap: () async {
                await Clipboard.setData(ClipboardData(text: code));
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(l10n.playerProfileReferralCodeCopied),
                    duration: const Duration(seconds: 1),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(ArenaRadius.md),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: ArenaSpacing.md,
                  vertical: ArenaSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: ArenaColors.void_,
                  borderRadius: BorderRadius.circular(ArenaRadius.md),
                  border: Border.all(color: ArenaColors.tierGoldWarm),
                ),
                child: Row(
                  children: [
                    Text(
                      code,
                      style: ArenaTypography.titleMedium.copyWith(
                        color: ArenaColors.bone,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2,
                      ),
                    ),
                    const Spacer(),
                    const Icon(
                      Icons.copy_outlined,
                      size: 18,
                      color: ArenaColors.tierGoldWarm,
                    ),
                  ],
                ),
              ),
            )
          else
            Text(
              l10n.playerProfileReferralCodeGenerating,
              style: ArenaText.bodyMuted,
            ),
          const SizedBox(height: ArenaSpacing.sm),
          Text(
            l10n.playerProfileReferralExplainer,
            style: ArenaText.small.copyWith(color: ArenaColors.silver),
          ),
        ],
      ),
    );
  }
}
