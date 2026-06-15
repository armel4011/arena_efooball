part of 'player_profile_page.dart';

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
