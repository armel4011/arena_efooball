part of 'player_profile_page.dart';

/// Header centré façon maquette #24 — avatar XL avec glow couleur du
/// profil + username display Bebas 26px uppercase + sous-titre
/// "🇨🇲 ${country} · Inscrit en ${month year}" + tier badge gradient.
/// Le bouton "modifier" est posé en overlay top-right pour rester
/// visible même sans AppBar (la page est embeddée dans MainLayout).
class _Header extends StatelessWidget {
  const _Header({required this.profile, required this.wins});

  final Profile profile;
  final int wins;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final color = AvatarPalette.colorFromHex(profile.avatarColor);
    final tier = tierFor(wins);
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
            _TierBadge(
              label: _tierLabel(l10n, tier),
              gradient: tier.gradient,
            ),
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

/// Traduit un [PlayerTier] en libellé localisé pour le badge.
String _tierLabel(AppLocalizations l10n, PlayerTier tier) => switch (tier) {
      PlayerTier.bronze => l10n.playerProfileTierBronze,
      PlayerTier.silver => l10n.playerProfileTierSilver,
      PlayerTier.gold => l10n.playerProfileTierGold,
      PlayerTier.elite => l10n.playerProfileTierElite,
    };

/// Tier badge — couleur dérivée du palier réel du joueur ([gradient]),
/// libellé localisé. Le palier est calculé via `tierFor(wins)`.
class _TierBadge extends StatelessWidget {
  const _TierBadge({required this.label, required this.gradient});

  final String label;
  final List<Color> gradient;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradient,
        ),
        borderRadius: BorderRadius.circular(ArenaRadius.round),
        boxShadow: [
          BoxShadow(
            color: gradient.first.withValues(alpha: 0.35),
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
