import 'package:arena/core/theme/arena_theme.dart';
import 'package:arena/features_admin_desktop/notifications/desktop_notification_service.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

/// Cloche de notifications du shell admin desktop.
///
/// Affiche un badge avec le total de non-lus ([DesktopNotificationState])
/// et ouvre un [FlyoutController] listant les derniers événements Realtime.
/// Chaque ligne est cliquable et navigue vers la route de l'événement ;
/// l'ouverture du flyout marque tout comme lu.
///
/// Le widget est autonome (lit/écrit `desktopNotificationsProvider`) et
/// destiné à être inséré dans l'`endHeader` du shell par l'orchestrateur.
class DesktopNotificationBell extends ConsumerStatefulWidget {
  const DesktopNotificationBell({super.key});

  @override
  ConsumerState<DesktopNotificationBell> createState() =>
      _DesktopNotificationBellState();
}

class _DesktopNotificationBellState
    extends ConsumerState<DesktopNotificationBell> {
  final _flyoutController = FlyoutController();

  @override
  void dispose() {
    _flyoutController.dispose();
    super.dispose();
  }

  void _openFlyout() {
    _flyoutController.showFlyout<void>(
      autoModeConfiguration: FlyoutAutoConfiguration(
        preferredMode: FlyoutPlacementMode.bottomRight,
      ),
      barrierDismissible: true,
      dismissOnPointerMoveAway: false,
      builder: (context) => _NotificationFlyout(
        onSelect: (event) {
          Flyout.of(context).close();
          context.go(event.route);
        },
        onClearAll: () {
          ref.read(desktopNotificationsProvider.notifier).markAllSeen();
          Flyout.of(context).close();
        },
      ),
    );
    // L'ouverture vaut consultation : on remet le badge à zéro.
    ref.read(desktopNotificationsProvider.notifier).markAllSeen();
  }

  @override
  Widget build(BuildContext context) {
    final total = ref.watch(
      desktopNotificationsProvider.select((s) => s.totalUnread),
    );

    return FlyoutTarget(
      controller: _flyoutController,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          IconButton(
            icon: const Icon(FluentIcons.ringer, size: 16),
            onPressed: _openFlyout,
          ),
          if (total > 0)
            Positioned(
              right: 2,
              top: 2,
              child: IgnorePointer(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  constraints: const BoxConstraints(minWidth: 16),
                  decoration: BoxDecoration(
                    color: ArenaColors.neonRed,
                    borderRadius: BorderRadius.circular(ArenaRadius.round),
                  ),
                  child: Text(
                    total > 99 ? '99+' : '$total',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.spaceGrotesk(
                      color: ArenaColors.bone,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _NotificationFlyout extends ConsumerWidget {
  const _NotificationFlyout({
    required this.onSelect,
    required this.onClearAll,
  });

  final void Function(DesktopNotificationEvent event) onSelect;
  final VoidCallback onClearAll;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final events = ref.watch(
      desktopNotificationsProvider.select((s) => s.recentEvents),
    );

    return FlyoutContent(
      constraints: const BoxConstraints(maxWidth: 360),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'NOTIFICATIONS',
                  style: GoogleFonts.bebasNeue(
                    color: ArenaColors.bone,
                    fontSize: 16,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
              if (events.isNotEmpty)
                HyperlinkButton(
                  onPressed: onClearAll,
                  child: Text(
                    'Tout effacer',
                    style: GoogleFonts.spaceGrotesk(
                      color: ArenaColors.silver,
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          if (events.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text('Aucune notification pour le moment.'),
              ),
            )
          else
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 420),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: events.length,
                separatorBuilder: (_, __) => const SizedBox(height: 4),
                itemBuilder: (context, i) => _EventTile(
                  event: events[i],
                  onTap: () => onSelect(events[i]),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _EventTile extends StatelessWidget {
  const _EventTile({required this.event, required this.onTap});

  final DesktopNotificationEvent event;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final visual = _visualFor(event.category);
    return HoverButton(
      onPressed: onTap,
      builder: (context, states) {
        final hovered = states.isHovered;
        return Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: hovered ? ArenaColors.carbon2 : ArenaColors.carbon,
            borderRadius: BorderRadius.circular(ArenaRadius.sm),
            border: Border.all(color: ArenaColors.border),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(visual.icon, size: 16, color: visual.color),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.title,
                      style: GoogleFonts.spaceGrotesk(
                        color: ArenaColors.bone,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      event.subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.spaceGrotesk(
                        color: ArenaColors.silver,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                DateFormat('HH:mm').format(event.at),
                style: GoogleFonts.spaceGrotesk(
                  color: ArenaColors.silverDim,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CategoryVisual {
  const _CategoryVisual({required this.icon, required this.color});
  final IconData icon;
  final Color color;
}

_CategoryVisual _visualFor(DesktopNotificationCategory category) {
  return switch (category) {
    DesktopNotificationCategory.payment => const _CategoryVisual(
        icon: FluentIcons.money,
        color: ArenaColors.statusOk,
      ),
    DesktopNotificationCategory.dispute => const _CategoryVisual(
        icon: FluentIcons.warning,
        color: ArenaColors.statusWarn,
      ),
    DesktopNotificationCategory.message => const _CategoryVisual(
        icon: FluentIcons.chat,
        color: ArenaColors.signalBlue,
      ),
    DesktopNotificationCategory.reintegration => const _CategoryVisual(
        icon: FluentIcons.follow_user,
        color: ArenaColors.neonRed,
      ),
  };
}
