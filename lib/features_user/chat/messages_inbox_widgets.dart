part of 'messages_inbox_page.dart';

class _MatchThreadRow extends StatelessWidget {
  const _MatchThreadRow({
    required this.match,
    required this.opponent,
    required this.highlighted,
    this.unread = 0,
  });

  final ArenaMatch match;
  final Profile? opponent;
  final bool highlighted;
  final int unread;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final opponentName = opponent?.username ?? l10n.inboxOpponentWaiting;
    final initials = opponentName.isEmpty ? '?' : opponentName[0].toUpperCase();
    final color = _avatarFor(opponent?.avatarColor);
    final subtitle = _subtitleFor(match, l10n);
    final timeLabel = _timeLabelFor(match, l10n);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => context.push(UserRoutes.matchChatPath(match.id)),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: highlighted
                ? ArenaColors.signalBlue.withValues(alpha: 0.08)
                : ArenaColors.carbon2,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: highlighted ? ArenaColors.signalBlue : ArenaColors.border,
            ),
            boxShadow: highlighted
                ? const [
                    BoxShadow(
                      color: ArenaColors.signalBlueGlow,
                      blurRadius: 14,
                      spreadRadius: -4,
                    ),
                  ]
                : null,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar + dot statut en bas-droite : vert si le match est
              // "hot" (en cours ou imminent), sinon pas de dot. Reproduit
              // `m-dot m-dot-online` de la maquette #15.
              Stack(
                clipBehavior: Clip.none,
                children: [
                  ArenaAvatar(initials: initials, color: color),
                  if (highlighted)
                    Positioned(
                      right: -2,
                      bottom: -2,
                      child: Container(
                        width: 11,
                        height: 11,
                        decoration: BoxDecoration(
                          color: ArenaColors.statusOk,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: ArenaColors.carbon2,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: ArenaSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            opponentName,
                            style: ArenaText.small.copyWith(
                              color: ArenaColors.bone,
                              fontWeight: FontWeight.w700,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          timeLabel,
                          style: ArenaText.small.copyWith(
                            color: ArenaColors.silver,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: ArenaText.small.copyWith(
                        color:
                            highlighted ? ArenaColors.bone : ArenaColors.silver,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (unread > 0) ...[
                const SizedBox(width: 6),
                _UnreadBadge(count: unread),
              ],
            ],
          ),
        ),
      ),
    );
  }

  static ArenaAvatarColor _avatarFor(String? hex) {
    if (hex == null) return ArenaAvatarColor.blue;
    final cleaned = hex.replaceAll('#', '').toUpperCase();
    if (cleaned.startsWith('FF')) return ArenaAvatarColor.red;
    if (cleaned.startsWith('69')) return ArenaAvatarColor.green;
    if (cleaned.startsWith('3B') || cleaned.startsWith('15')) {
      return ArenaAvatarColor.cyan;
    }
    if (cleaned.startsWith('F7')) return ArenaAvatarColor.orange;
    if (cleaned.startsWith('97') || cleaned.startsWith('84')) {
      return ArenaAvatarColor.purple;
    }
    return ArenaAvatarColor.blue;
  }

  static String _subtitleFor(ArenaMatch m, AppLocalizations l10n) {
    return switch (m.status) {
      MatchStatus.pending => l10n.inboxMatchPending,
      MatchStatus.scheduled => l10n.inboxMatchScheduled,
      MatchStatus.ready => l10n.inboxMatchReady,
      MatchStatus.inProgress => l10n.inboxMatchInProgress,
      MatchStatus.scorePending => l10n.inboxMatchScorePending,
      MatchStatus.awaitingValidation => l10n.inboxMatchAwaitingValidation,
      MatchStatus.disputed => l10n.inboxMatchDisputed,
      MatchStatus.completed => l10n.inboxMatchCompleted,
      MatchStatus.cancelled => l10n.inboxMatchCancelled,
      MatchStatus.forfeited => l10n.inboxMatchForfeited,
    };
  }

  static String _timeLabelFor(ArenaMatch m, AppLocalizations l10n) {
    final t = m.finishedAt ?? m.scheduledAt ?? m.createdAt;
    if (t == null) return '—';
    final diff = DateTime.now().difference(t);
    if (diff.isNegative) {
      final upcoming = -diff.inHours;
      if (upcoming < 1) return l10n.inboxTimeSoon;
      if (upcoming < 24) return 'Dans ${upcoming}h';
      final days = -diff.inDays;
      return 'Dans ${days}j';
    }
    if (diff.inMinutes < 60) return '${diff.inMinutes}min';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}j';
    return '${(diff.inDays / 7).floor()}sem';
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// COMPÉTITIONS — list des comp où le user est inscrit
// ──────────────────────────────────────────────────────────────────────────────
class _CompetitionsTab extends ConsumerWidget {
  const _CompetitionsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final registeredAsync = ref.watch(myRegisteredCompetitionIdsProvider);
    final compsAsync = ref.watch(competitionsListProvider(null));

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(competitionsListProvider(null));
        await Future<void>.delayed(const Duration(milliseconds: 200));
      },
      child: registeredAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _ErrorList(message: '${l10n.inboxErrorPrefix}$e'),
        data: (ids) {
          if (ids.isEmpty) {
            return EmptyState(
              icon: Icons.emoji_events_outlined,
              title: l10n.inboxNoActiveCompTitle,
              description: l10n.inboxNoActiveCompDesc,
            );
          }
          return compsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => _ErrorList(message: '${l10n.inboxErrorPrefix}$e'),
            data: (all) {
              final mine = [
                for (final c in all)
                  if (ids.contains(c.id)) c,
              ];
              if (mine.isEmpty) {
                return EmptyState(
                  icon: Icons.hourglass_empty,
                  title: l10n.inboxWaitingTitle,
                  description: l10n.inboxWaitingDesc,
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(
                  ArenaSpacing.lg,
                  0,
                  ArenaSpacing.lg,
                  ArenaSpacing.lg,
                ),
                itemCount: mine.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(height: ArenaSpacing.sm),
                itemBuilder: (ctx, i) =>
                    _CompetitionThreadRow(competition: mine[i]),
              );
            },
          );
        },
      ),
    );
  }
}

class _CompetitionThreadRow extends StatelessWidget {
  const _CompetitionThreadRow({required this.competition});
  final Competition competition;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = competition;
    final emoji = switch (c.game.value) {
      'efootball' => '⚽',
      'draughts' => '🔴',
      'ea_sports_fc' => '🎯',
      _ => '🏆',
    };
    final statusLabel = switch (c.status.value) {
      'registration_open' => l10n.inboxCompRegistrationOpen,
      'registration_closed' => l10n.inboxCompRegistrationClosed,
      'ongoing' => l10n.inboxCompOngoing,
      'completed' => l10n.inboxCompCompleted,
      'cancelled' => l10n.inboxCompCancelled,
      _ => l10n.inboxCompDraft,
    };
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => context.push(UserRoutes.competitionPath(c.id)),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: ArenaColors.carbon2,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: ArenaColors.border),
          ),
          child: Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 22)),
              const SizedBox(width: ArenaSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      c.name,
                      style: ArenaText.small.copyWith(
                        color: ArenaColors.bone,
                        fontWeight: FontWeight.w700,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${c.currentPlayers}/${c.maxPlayers} • $statusLabel',
                      style: ArenaText.small.copyWith(
                        color: ArenaColors.silver,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: ArenaColors.silver),
            ],
          ),
        ),
      ),
    );
  }
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

/// Helper avatar mapping kept for backward compat with `chat_page.dart`
/// (imports `inboxAvatarFor` to pick a deterministic colour).
ArenaAvatarColor inboxAvatarFor(String seed) {
  if (seed.isEmpty) return ArenaAvatarColor.blue;
  final c = seed.codeUnitAt(0) % ArenaAvatarColor.values.length;
  return ArenaAvatarColor.values[c];
}

// ─── Inbox unified item (AMIS + MATCHS) ──────────────────────────────────────

enum _InboxItemKind { arenaTeam, header, friend, match, emptyHint }

class _InboxItem {
  const _InboxItem._({
    required this.kind,
    this.headerLabel,
    this.friend,
    this.match,
    this.peer,
    this.highlighted = false,
    this.unread = 0,
  });

  const _InboxItem.arenaTeam() : this._(kind: _InboxItemKind.arenaTeam);

  const _InboxItem.emptyHint() : this._(kind: _InboxItemKind.emptyHint);

  const _InboxItem.sectionHeader(String label)
      : this._(kind: _InboxItemKind.header, headerLabel: label);

  const _InboxItem.friend(
    ({String channelId, String friendshipId, String peerId}) friend,
    Profile? peer, {
    required int unread,
  }) : this._(
          kind: _InboxItemKind.friend,
          friend: friend,
          peer: peer,
          unread: unread,
        );

  const _InboxItem.match(
    ArenaMatch match,
    Profile? peer, {
    required bool highlighted,
    required int unread,
  }) : this._(
          kind: _InboxItemKind.match,
          match: match,
          peer: peer,
          highlighted: highlighted,
          unread: unread,
        );

  final _InboxItemKind kind;
  final String? headerLabel;
  final ({String channelId, String friendshipId, String peerId})? friend;
  final ArenaMatch? match;
  final Profile? peer;
  final bool highlighted;
  final int unread;
}

/// Row inbox pour un friend chat (Item 3 wave C — 2026-05-19).
/// Tap → /chat/friend/:friendshipId. Layout cohérent avec _MatchThreadRow.
class _FriendThreadRow extends StatelessWidget {
  const _FriendThreadRow({
    required this.friendshipId,
    required this.peer,
    this.unread = 0,
  });

  final String friendshipId;
  final Profile? peer;
  final int unread;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final username = peer?.username ?? l10n.inboxFriendDefaultName;
    final initials = username.isEmpty ? '?' : username[0].toUpperCase();
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => context.push(UserRoutes.friendChatPath(friendshipId)),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: ArenaColors.carbon2,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: ArenaColors.border),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ArenaAvatar(
                initials: initials,
                color: inboxAvatarFor(username),
              ),
              const SizedBox(width: ArenaSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      username,
                      style: ArenaText.small.copyWith(
                        color: ArenaColors.bone,
                        fontWeight: FontWeight.w700,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      l10n.inboxChatWithFriend,
                      style: ArenaText.small.copyWith(
                        color: ArenaColors.silver,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (unread > 0)
                _UnreadBadge(count: unread)
              else
                const Icon(
                  Icons.chevron_right,
                  color: ArenaColors.silverDim,
                  size: 20,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Conversation "Équipe ARENA" : pinned en tête de l'inbox DIRECT.
/// Stream realtime via `adminChatRepository.watchInbox` — preview du
/// dernier message + badge unread. Tap -> /admin-messages.
class _ArenaTeamRow extends ConsumerWidget {
  const _ArenaTeamRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final me = ref.watch(currentSessionProvider)?.user.id;
    final repo = ref.read(adminChatRepositoryProvider);
    return StreamBuilder<List<AdminChatMessage>>(
      stream: me == null ? const Stream.empty() : repo.watchInbox(me),
      builder: (context, snap) {
        final msgs = snap.data ?? const <AdminChatMessage>[];
        final last = msgs.isNotEmpty ? msgs.first : null;
        final unread = msgs.where((m) => m.isUnread).length;
        final preview = _previewOf(last, l10n);
        final timeLabel = last == null ? '' : _relativeTime(last.sentAt, l10n);
        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => context.push(UserRoutes.adminMessages),
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: ArenaColors.neonRed.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: ArenaColors.neonRed),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: ArenaColors.neonRed.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: ArenaColors.neonRed),
                    ),
                    child: const Icon(
                      Icons.shield_outlined,
                      color: ArenaColors.neonRed,
                      size: 22,
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
                              l10n.inboxArenaTeam,
                              style: ArenaText.small.copyWith(
                                color: ArenaColors.bone,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: ArenaColors.neonRed,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                l10n.inboxArenaOfficialBadge,
                                style: ArenaText.small.copyWith(
                                  color: ArenaColors.bone,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 9,
                                  letterSpacing: 0.6,
                                ),
                              ),
                            ),
                            const Spacer(),
                            if (timeLabel.isNotEmpty)
                              Text(
                                timeLabel,
                                style: ArenaText.small.copyWith(
                                  color: ArenaColors.silver,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          preview,
                          style: ArenaText.small.copyWith(
                            color: ArenaColors.silver,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  if (unread > 0) ...[
                    const SizedBox(width: 6),
                    _UnreadBadge(count: unread),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  static String _previewOf(AdminChatMessage? m, AppLocalizations l10n) {
    if (m == null) return l10n.inboxArenaPreviewDefault;
    if (m.caption != null && m.caption!.isNotEmpty) return m.caption!;
    if (m.text != null && m.text!.isNotEmpty) return m.text!;
    if (m.hasImage) return l10n.inboxArenaPreviewImage;
    return '';
  }

  static String _relativeTime(DateTime t, AppLocalizations l10n) {
    final diff = DateTime.now().difference(t);
    if (diff.inMinutes < 1) return l10n.inboxTimeJustNow;
    if (diff.inMinutes < 60) return '${diff.inMinutes}min';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}j';
    return '${(diff.inDays / 7).floor()}sem';
  }
}

/// Badge "messages non-lus" style WhatsApp — bulle bleue avec compteur.
/// Affiche "99+" pour count >= 100.
class _UnreadBadge extends StatelessWidget {
  const _UnreadBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final label = count >= 100 ? '99+' : '$count';
    return Container(
      constraints: const BoxConstraints(minWidth: 22, minHeight: 22),
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: const BoxDecoration(
        color: ArenaColors.signalBlue,
        shape: BoxShape.rectangle,
        borderRadius: BorderRadius.all(Radius.circular(999)),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: ArenaText.small.copyWith(
          color: ArenaColors.bone,
          fontWeight: FontWeight.w700,
          fontSize: 11,
        ),
      ),
    );
  }
}
