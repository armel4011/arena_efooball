import 'package:arena/core/router/user_router.dart';
import 'package:arena/core/theme/arena_theme.dart';
import 'package:arena/data/models/arena_match.dart';
import 'package:arena/data/models/profile.dart';
import 'package:arena/features_shared/widgets/arena_avatar.dart';
import 'package:arena/features_user/match_room/match_room_page.dart'
    show MatchRole;
import 'package:arena/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Header HOME/AWAY de la match room : deux PlayerSeat encadrant un VS
/// central. Tap sur un seat ouvre le profil public (sauf "TOI").
class PlayersHeader extends StatelessWidget {
  const PlayersHeader({
    required this.match,
    required this.role,
    required this.p1,
    required this.p2,
    super.key,
  });

  final ArenaMatch match;
  final MatchRole role;
  final Profile? p1;
  final Profile? p2;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final p1IsHome = match.homePlayerId != null &&
        match.homePlayerId == match.player1Id;
    final p2IsHome = match.homePlayerId != null &&
        match.homePlayerId == match.player2Id;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _PlayerSeat(
            profile: p1,
            seatLabel: l10n.matchHeaderPlayer1,
            isSelf: role == MatchRole.player1,
            isHome: p1IsHome,
            fallbackColor: ArenaAvatarColor.blue,
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 14),
          child: Text(
            'VS',
            style: ArenaText.h2.copyWith(color: ArenaColors.silverDim),
          ),
        ),
        Expanded(
          child: _PlayerSeat(
            profile: p2,
            seatLabel: l10n.matchHeaderPlayer2,
            isSelf: role == MatchRole.player2,
            isHome: p2IsHome,
            fallbackColor: ArenaAvatarColor.green,
          ),
        ),
      ],
    );
  }
}

class _PlayerSeat extends StatelessWidget {
  const _PlayerSeat({
    required this.profile,
    required this.seatLabel,
    required this.isSelf,
    required this.isHome,
    required this.fallbackColor,
  });

  final Profile? profile;
  final String seatLabel;
  final bool isSelf;
  final bool isHome;
  final ArenaAvatarColor fallbackColor;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final username = profile?.username ?? seatLabel;
    final initial =
        username.isEmpty ? '?' : username.characters.first.toUpperCase();
    final color = profile == null
        ? fallbackColor
        : _avatarColorFromHex(profile!.avatarColor) ?? fallbackColor;

    // Phase 13 — tap sur le seat ouvre /profile/u/:username (sauf "TOI",
    // qui re-route déjà vers son propre profil via le bottom tab).
    final canOpenProfile = profile != null && !isSelf;

    final seat = Column(
      children: [
        ArenaAvatar(
          initials: initial,
          color: color,
          size: ArenaAvatarSize.lg,
          selected: isSelf,
        ),
        const SizedBox(height: ArenaSpacing.sm),
        Text(
          isSelf ? '$username · TOI' : username,
          style: ArenaText.body.copyWith(
            color: ArenaColors.bone,
            fontWeight: FontWeight.w700,
          ),
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 6),
        if (isHome)
          _SeatBadge(label: l10n.matchHeaderBadgeHome, color: ArenaColors.signalBlue)
        else if (profile != null)
          _SeatBadge(label: l10n.matchHeaderBadgeAway, color: ArenaColors.statusWarn),
      ],
    );

    if (!canOpenProfile) return seat;
    return InkWell(
      onTap: () =>
          context.push(UserRoutes.publicProfilePath(profile!.username)),
      borderRadius: BorderRadius.circular(12),
      child: seat,
    );
  }
}

class _SeatBadge extends StatelessWidget {
  const _SeatBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: ArenaRadius.pill,
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: ArenaText.badge.copyWith(color: color, fontSize: 9),
      ),
    );
  }
}

ArenaAvatarColor? _avatarColorFromHex(String hex) {
  final cleaned = hex.replaceAll('#', '').trim().toUpperCase();
  return switch (cleaned) {
    '4C7AFF' => ArenaAvatarColor.blue,
    'FF2D55' => ArenaAvatarColor.red,
    '00C896' => ArenaAvatarColor.green,
    'F77F00' => ArenaAvatarColor.orange,
    '00B4D8' => ArenaAvatarColor.cyan,
    '9D4EDD' => ArenaAvatarColor.purple,
    'FF6B9D' => ArenaAvatarColor.pink,
    'FFD700' => ArenaAvatarColor.yellow,
    _ => null,
  };
}
