import 'package:arena/core/router/user_router.dart';
import 'package:arena/core/theme/arena_theme.dart';
import 'package:arena/data/models/friendship.dart';
import 'package:arena/data/models/profile.dart';
import 'package:arena/data/repositories/friends_repository.dart';
import 'package:arena/features_shared/avatar_palette.dart';
import 'package:arena/features_shared/widgets/arena_app_bar.dart';
import 'package:arena/features_shared/widgets/arena_button.dart';
import 'package:arena/features_shared/widgets/arena_card.dart';
import 'package:arena/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Phase 13 — Hub social `/friends`.
///
/// Trois onglets :
///   1. Amis        — liste accepted, action retirer/voir profil
///   2. Demandes    — pending entrantes (accept/refuse) + sortantes
///   3. Bloqués     — utilisateurs que `me` a bloqués, action débloquer
///
/// Bouton "rechercher" dans l'app bar → /friends/search.
class FriendsPage extends ConsumerStatefulWidget {
  const FriendsPage({super.key});

  @override
  ConsumerState<FriendsPage> createState() => _FriendsPageState();
}

class _FriendsPageState extends ConsumerState<FriendsPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 3, vsync: this);

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  void _invalidate() {
    ref
      ..invalidate(acceptedFriendsProvider)
      ..invalidate(incomingFriendRequestsProvider)
      ..invalidate(outgoingFriendRequestsProvider)
      ..invalidate(blockedByMeProvider);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: ArenaColors.void_,
      appBar: ArenaAppBar(
        title: l10n.friendsAppBarTitle,
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: ArenaColors.bone),
            tooltip: l10n.friendsSearchTooltip,
            onPressed: () => context.push(UserRoutes.friendsSearch),
          ),
        ],
      ),
      body: Column(
        children: [
          TabBar(
            controller: _tabs,
            labelColor: ArenaColors.bone,
            unselectedLabelColor: ArenaColors.textMuted,
            indicatorColor: ArenaColors.primary,
            tabs: [
              Tab(text: l10n.friendsTabFriends),
              Tab(text: l10n.friendsTabRequests),
              Tab(text: l10n.friendsTabBlocked),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabs,
              children: [
                _FriendsTab(onChanged: _invalidate),
                _RequestsTab(onChanged: _invalidate),
                _BlockedTab(onChanged: _invalidate),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab 1 — Amis acceptés
// ─────────────────────────────────────────────────────────────────────────────
class _FriendsTab extends ConsumerWidget {
  const _FriendsTab({required this.onChanged});
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final async = ref.watch(acceptedFriendsProvider);
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(acceptedFriendsProvider);
        await ref.read(acceptedFriendsProvider.future);
      },
      child: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _ErrorList(message: l10n.friendsErrorMessage(e)),
        data: (rows) {
          if (rows.isEmpty) {
            return _EmptyState(
              icon: Icons.group_outlined,
              label: l10n.friendsEmptyLabel,
              hint: l10n.friendsEmptyHint,
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(ArenaSpacing.lg),
            itemCount: rows.length,
            itemBuilder: (ctx, i) {
              final (f, peer) = rows[i];
              return _PeerRow(
                profile: peer,
                onTap: () => context.push(UserRoutes.friendChatPath(f.id)),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _MiniButton(
                      icon: Icons.chat_bubble_outline,
                      color: ArenaColors.signalBlue,
                      onPressed: () => context.push(
                        UserRoutes.friendChatPath(f.id),
                      ),
                    ),
                    const SizedBox(width: 6),
                    _MiniButton(
                      icon: Icons.person_remove_outlined,
                      color: ArenaColors.danger,
                      onPressed: () =>
                          _confirmRemove(context, ref, f, peer).then((ok) {
                        if (ok) onChanged();
                      }),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<bool> _confirmRemove(
    BuildContext context,
    WidgetRef ref,
    Friendship f,
    Profile peer,
  ) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ArenaColors.surface,
        title: Text(l10n.friendsRemoveDialogTitle(peer.username)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.friendsRemoveCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.friendsRemoveConfirm),
          ),
        ],
      ),
    );
    if (confirmed != true) return false;
    try {
      await ref.read(friendsRepositoryProvider).remove(peer.id);
      return true;
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.friendsErrorMessage(e)),
            backgroundColor: ArenaColors.danger,
          ),
        );
      }
      return false;
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab 2 — Demandes (entrantes + sortantes)
// ─────────────────────────────────────────────────────────────────────────────
class _RequestsTab extends ConsumerWidget {
  const _RequestsTab({required this.onChanged});
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final incomingAsync = ref.watch(incomingFriendRequestsProvider);
    final outgoingAsync = ref.watch(outgoingFriendRequestsProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref
          ..invalidate(incomingFriendRequestsProvider)
          ..invalidate(outgoingFriendRequestsProvider);
        await Future.wait([
          ref.read(incomingFriendRequestsProvider.future),
          ref.read(outgoingFriendRequestsProvider.future),
        ]);
      },
      child: ListView(
        padding: const EdgeInsets.all(ArenaSpacing.lg),
        children: [
          _SectionLabel(text: l10n.friendsSectionReceived),
          const SizedBox(height: ArenaSpacing.sm),
          incomingAsync.when(
            loading: () => const _LoadingRow(),
            error: (e, _) => _ErrorList(message: l10n.friendsErrorMessage(e)),
            data: (rows) {
              if (rows.isEmpty) {
                return _SmallEmpty(l10n.friendsNoRequests);
              }
              return Column(
                children: [
                  for (final (f, peer) in rows)
                    Padding(
                      padding: const EdgeInsets.only(bottom: ArenaSpacing.sm),
                      child: _PeerRow(
                        profile: peer,
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _MiniButton(
                              icon: Icons.check,
                              color: ArenaColors.success,
                              onPressed: () =>
                                  _accept(context, ref, f, peer.username)
                                      .then((ok) {
                                if (ok) onChanged();
                              }),
                            ),
                            const SizedBox(width: 6),
                            _MiniButton(
                              icon: Icons.close,
                              color: ArenaColors.danger,
                              onPressed: () =>
                                  _decline(context, ref, f).then((ok) {
                                if (ok) onChanged();
                              }),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: ArenaSpacing.xl),
          _SectionLabel(text: l10n.friendsSectionSent),
          const SizedBox(height: ArenaSpacing.sm),
          outgoingAsync.when(
            loading: () => const _LoadingRow(),
            error: (e, _) => _ErrorList(message: l10n.friendsErrorMessage(e)),
            data: (rows) {
              if (rows.isEmpty) {
                return _SmallEmpty(l10n.friendsNoPendingRequests);
              }
              return Column(
                children: [
                  for (final (f, peer) in rows)
                    Padding(
                      padding: const EdgeInsets.only(bottom: ArenaSpacing.sm),
                      child: _PeerRow(
                        profile: peer,
                        trailing: _RowAction(
                          label: l10n.friendsCancelRequest,
                          icon: Icons.undo,
                          variant: ArenaButtonVariant.ghost,
                          onPressed: () =>
                              _decline(context, ref, f).then((ok) {
                            if (ok) onChanged();
                          }),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Future<bool> _accept(
    BuildContext context,
    WidgetRef ref,
    Friendship f,
    String peerUsername,
  ) async {
    final l10n = AppLocalizations.of(context);
    try {
      await ref.read(friendsRepositoryProvider).accept(f.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.friendsAcceptedSnack(peerUsername))),
        );
      }
      return true;
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.friendsErrorMessage(e)),
            backgroundColor: ArenaColors.danger,
          ),
        );
      }
      return false;
    }
  }

  Future<bool> _decline(
    BuildContext context,
    WidgetRef ref,
    Friendship f,
  ) async {
    try {
      await ref.read(friendsRepositoryProvider).decline(f.id);
      return true;
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).friendsErrorMessage(e)),
            backgroundColor: ArenaColors.danger,
          ),
        );
      }
      return false;
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab 3 — Bloqués
// ─────────────────────────────────────────────────────────────────────────────
class _BlockedTab extends ConsumerWidget {
  const _BlockedTab({required this.onChanged});
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final async = ref.watch(blockedByMeProvider);
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(blockedByMeProvider);
        await ref.read(blockedByMeProvider.future);
      },
      child: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _ErrorList(message: l10n.friendsErrorMessage(e)),
        data: (rows) {
          if (rows.isEmpty) {
            return _EmptyState(
              icon: Icons.block_outlined,
              label: l10n.friendsBlockedEmptyLabel,
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(ArenaSpacing.lg),
            itemCount: rows.length,
            itemBuilder: (ctx, i) {
              final (_, peer) = rows[i];
              return _PeerRow(
                profile: peer,
                trailing: _RowAction(
                  label: l10n.friendsUnblockAction,
                  icon: Icons.lock_open,
                  variant: ArenaButtonVariant.secondary,
                  onPressed: () => _unblock(ctx, ref, peer).then((ok) {
                    if (ok) onChanged();
                  }),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<bool> _unblock(
    BuildContext context,
    WidgetRef ref,
    Profile peer,
  ) async {
    final l10n = AppLocalizations.of(context);
    try {
      await ref.read(friendsRepositoryProvider).unblock(peer.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.friendsUnblockedSnack(peer.username))),
        );
      }
      return true;
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.friendsErrorMessage(e)),
            backgroundColor: ArenaColors.danger,
          ),
        );
      }
      return false;
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Building blocks
// ─────────────────────────────────────────────────────────────────────────────
class _PeerRow extends StatelessWidget {
  const _PeerRow({
    required this.profile,
    required this.trailing,
    this.onTap,
  });

  final Profile profile;
  final Widget trailing;

  /// Override du tap sur la row. Par défaut, ouvre le profil public.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = AvatarPalette.colorFromHex(profile.avatarColor);
    final initial =
        profile.username.isEmpty ? '?' : profile.username[0].toUpperCase();
    final photoUrl = profile.avatarUrl;
    final hasPhoto = photoUrl != null && photoUrl.isNotEmpty;
    return ArenaCard(
      onTap: onTap ??
          () => context.push(UserRoutes.publicProfilePath(profile.username)),
      padding: const EdgeInsets.symmetric(
        vertical: ArenaSpacing.sm,
        horizontal: ArenaSpacing.md,
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: hasPhoto ? null : color,
              shape: BoxShape.circle,
              image: hasPhoto
                  ? DecorationImage(
                      image: NetworkImage(photoUrl),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            alignment: Alignment.center,
            child: hasPhoto
                ? null
                : Text(
                    initial,
                    style: ArenaTypography.headlineMedium.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
          ),
          const SizedBox(width: ArenaSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(profile.username, style: ArenaTypography.bodyMedium),
                Text(
                  profile.countryCode,
                  style: ArenaTypography.bodySmall.copyWith(
                    color: ArenaColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          trailing,
        ],
      ),
    );
  }
}

class _RowAction extends StatelessWidget {
  const _RowAction({
    required this.label,
    required this.icon,
    required this.variant,
    required this.onPressed,
  });
  final String label;
  final IconData icon;
  final ArenaButtonVariant variant;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return ArenaButton(
      label: label,
      icon: icon,
      variant: variant,
      onPressed: onPressed,
    );
  }
}

class _MiniButton extends StatelessWidget {
  const _MiniButton({
    required this.icon,
    required this.color,
    required this.onPressed,
  });
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(ArenaRadius.round),
      onTap: onPressed,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.16),
          shape: BoxShape.circle,
          border: Border.all(color: color.withValues(alpha: 0.55)),
        ),
        child: Icon(icon, size: 18, color: color),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.text});
  final String text;
  @override
  Widget build(BuildContext context) =>
      Text(text, style: ArenaTypography.labelMedium);
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.icon, required this.label, this.hint});
  final IconData icon;
  final String label;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(ArenaSpacing.xxl),
      children: [
        const SizedBox(height: 80),
        Icon(icon, size: 56, color: ArenaColors.textMuted),
        const SizedBox(height: ArenaSpacing.md),
        Text(
          label,
          textAlign: TextAlign.center,
          style: ArenaTypography.bodyMedium,
        ),
        if (hint != null) ...[
          const SizedBox(height: 4),
          Text(
            hint!,
            textAlign: TextAlign.center,
            style: ArenaTypography.bodySmall.copyWith(
              color: ArenaColors.textMuted,
            ),
          ),
        ],
      ],
    );
  }
}

class _SmallEmpty extends StatelessWidget {
  const _SmallEmpty(this.text);
  final String text;
  @override
  Widget build(BuildContext context) {
    return ArenaCard(
      child: Text(
        text,
        style: ArenaTypography.bodySmall.copyWith(
          color: ArenaColors.textMuted,
        ),
      ),
    );
  }
}

class _LoadingRow extends StatelessWidget {
  const _LoadingRow();
  @override
  Widget build(BuildContext context) => const ArenaCard(
        child: SizedBox(
          height: 48,
          child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
        ),
      );
}

class _ErrorList extends StatelessWidget {
  const _ErrorList({required this.message});
  final String message;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(ArenaSpacing.lg),
      child: Text(
        message,
        style: ArenaText.body.copyWith(color: ArenaColors.danger),
      ),
    );
  }
}
