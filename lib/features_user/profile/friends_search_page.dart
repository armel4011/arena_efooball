import 'dart:async';

import 'package:arena/core/router/user_router.dart';
import 'package:arena/core/theme/arena_theme.dart';
import 'package:arena/data/models/profile.dart';
import 'package:arena/data/repositories/friends_repository.dart';
import 'package:arena/features_shared/auth_common/shared_auth_providers.dart';
import 'package:arena/features_shared/widgets/arena_app_bar.dart';
import 'package:arena/features_shared/widgets/arena_card.dart';
import 'package:arena/features_user/profile/avatar_palette.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Phase 13 — `/friends/search`. Recherche par username avec debounce.
///
/// `searchByUsername` côté repo filtre déjà `is_active=true`,
/// `permanent_ban=false`, `deleted_at IS NULL` et exclut `me`. Tap sur un
/// résultat → ouvre `/profile/u/<username>` où l'utilisateur peut envoyer
/// une demande d'ami.
class FriendsSearchPage extends ConsumerStatefulWidget {
  const FriendsSearchPage({super.key});

  @override
  ConsumerState<FriendsSearchPage> createState() => _FriendsSearchPageState();
}

class _FriendsSearchPageState extends ConsumerState<FriendsSearchPage> {
  final _controller = TextEditingController();
  Timer? _debounce;
  AsyncValue<List<Profile>> _results = const AsyncValue.data([]);

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    final trimmed = value.trim();
    if (trimmed.length < 2) {
      setState(() => _results = const AsyncValue.data([]));
      return;
    }
    setState(() => _results = const AsyncValue.loading());
    _debounce = Timer(const Duration(milliseconds: 350), () => _run(trimmed));
  }

  Future<void> _run(String query) async {
    final me = ref.read(currentSessionProvider)?.user.id;
    if (me == null) {
      setState(() => _results = const AsyncValue.data([]));
      return;
    }
    try {
      final profiles = await ref
          .read(friendsRepositoryProvider)
          .searchByUsername(query: query, me: me);
      if (!mounted) return;
      setState(() => _results = AsyncValue.data(profiles));
    } catch (e, st) {
      if (!mounted) return;
      setState(() => _results = AsyncValue.error(e, st));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ArenaColors.void_,
      appBar: const ArenaAppBar(title: 'Rechercher'),
      body: Padding(
        padding: const EdgeInsets.all(ArenaSpacing.lg),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              autofocus: true,
              onChanged: _onChanged,
              style: const TextStyle(color: ArenaColors.bone),
              decoration: InputDecoration(
                hintText: "Nom d'utilisateur",
                hintStyle: ArenaTypography.bodyMedium.copyWith(
                  color: ArenaColors.textMuted,
                ),
                prefixIcon:
                    const Icon(Icons.search, color: ArenaColors.textMuted),
                filled: true,
                fillColor: ArenaColors.surface,
                border: const OutlineInputBorder(
                  borderRadius: ArenaRadius.card,
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: ArenaSpacing.lg),
            Expanded(child: _ResultList(results: _results)),
          ],
        ),
      ),
    );
  }
}

class _ResultList extends StatelessWidget {
  const _ResultList({required this.results});
  final AsyncValue<List<Profile>> results;

  @override
  Widget build(BuildContext context) {
    return results.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Padding(
        padding: const EdgeInsets.all(ArenaSpacing.lg),
        child: Text(
          'Erreur : $e',
          style: const TextStyle(color: ArenaColors.danger),
        ),
      ),
      data: (profiles) {
        if (profiles.isEmpty) {
          return Center(
            child: Text(
              'Tape au moins 2 caractères pour chercher.',
              textAlign: TextAlign.center,
              style: ArenaTypography.bodyMedium.copyWith(
                color: ArenaColors.textMuted,
              ),
            ),
          );
        }
        return ListView.builder(
          itemCount: profiles.length,
          itemBuilder: (ctx, i) {
            final p = profiles[i];
            return Padding(
              padding: const EdgeInsets.only(bottom: ArenaSpacing.sm),
              child: _SearchRow(profile: p),
            );
          },
        );
      },
    );
  }
}

class _SearchRow extends StatelessWidget {
  const _SearchRow({required this.profile});
  final Profile profile;

  @override
  Widget build(BuildContext context) {
    final color = AvatarPalette.colorFromHex(profile.avatarColor);
    final initial =
        profile.username.isEmpty ? '?' : profile.username[0].toUpperCase();
    return ArenaCard(
      onTap: () => context.push(UserRoutes.publicProfilePath(profile.username)),
      padding: const EdgeInsets.symmetric(
        vertical: ArenaSpacing.sm,
        horizontal: ArenaSpacing.md,
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            alignment: Alignment.center,
            child: Text(
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
          const Icon(Icons.chevron_right, color: ArenaColors.textMuted),
        ],
      ),
    );
  }
}
