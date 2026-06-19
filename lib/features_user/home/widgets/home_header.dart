import 'package:arena/core/router/user_router.dart';
import 'package:arena/core/theme/arena_theme.dart';
import 'package:arena/data/models/profile.dart';
import 'package:arena/data/repositories/notification_repository.dart';
import 'package:arena/features_shared/widgets/arena_avatar.dart';
import 'package:arena/features_shared/widgets/arena_badge.dart';
import 'package:arena/l10n/generated/app_localizations.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Top header de la home : avatar + username + tier badge +
/// search icon + notif bell avec badge unread.
class HomeHeader extends ConsumerWidget {
  const HomeHeader({required this.profile, super.key});

  final Profile? profile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final username = profile?.username ?? l10n.homeHeaderDefaultUsername;
    final initial = username.isEmpty ? '?' : username[0].toUpperCase();
    final color = _avatarColorFor(profile?.avatarColor);
    final unread = profile == null
        ? 0
        : ref.watch(unreadNotificationCountProvider(profile!.id));

    return Container(
      padding: const EdgeInsets.fromLTRB(
        ArenaSpacing.lg,
        ArenaSpacing.md,
        ArenaSpacing.lg,
        ArenaSpacing.md,
      ),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: ArenaColors.border),
        ),
      ),
      child: Row(
        children: [
          // Long-press sur l'avatar = raccourci debug vers le design
          // showcase (qui contient l'accès au bracket showcase). Seul
          // un appui long en kDebugMode déclenche la nav — l'avatar
          // garde son comportement standard en release.
          GestureDetector(
            onLongPress:
                kDebugMode ? () => context.push(UserRoutes.devShowcase) : null,
            child: ArenaAvatar(
              initials: initial,
              color: color,
              imageUrl: profile?.avatarUrl,
            ),
          ),
          const SizedBox(width: ArenaSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  username,
                  style: ArenaText.body.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                ArenaBadge(
                  label: l10n.homeHeaderTierBronze,
                  variant: ArenaBadgeVariant.tierBronze,
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(
              Icons.search,
              color: ArenaColors.silver,
              size: 20,
            ),
            tooltip: l10n.homeHeaderSearchTooltip,
            onPressed: () => context.push(UserRoutes.friendsSearch),
          ),
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                icon: const Icon(
                  Icons.notifications_outlined,
                  color: ArenaColors.silver,
                  size: 20,
                ),
                onPressed: () => context.push(UserRoutes.notifications),
              ),
              if (unread > 0)
                Positioned(
                  top: 6,
                  right: 4,
                  child: Container(
                    width: 13,
                    height: 13,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      color: ArenaColors.neonRed,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      unread > 9 ? '9+' : '$unread',
                      style: ArenaText.badge.copyWith(
                        color: ArenaColors.bone,
                        fontSize: 9,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  static ArenaAvatarColor _avatarColorFor(String? hex) {
    if (hex == null) return ArenaAvatarColor.blue;
    final cleaned = hex.replaceAll('#', '').trim().toUpperCase();
    return switch (cleaned) {
      'FF6B6B' ||
      'E03131' ||
      _ when cleaned.startsWith('FF') && cleaned.endsWith('5F5') =>
        ArenaAvatarColor.red,
      _ => ArenaAvatarColor.blue,
    };
  }
}
