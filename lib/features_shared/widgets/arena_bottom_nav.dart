import 'package:arena/core/theme/arena_theme.dart';
import 'package:flutter/material.dart';

/// 4-tab bottom navigation (Home / Compétitions / Chat / Profil).
///
/// Maps to `.bottom-nav` / `.nav-item` in `arena_v2.html`. Selected tab uses
/// `signalBlue` for both icon and label, with a 6 px drop-shadow glow on the
/// icon. Unselected uses `silver` (icon) and `silverDim` (label).
class ArenaBottomNavItem {
  const ArenaBottomNavItem({required this.icon, required this.label});
  final IconData icon;
  final String label;
}

class ArenaBottomNav extends StatelessWidget {
  const ArenaBottomNav({
    required this.items,
    required this.currentIndex,
    required this.onTap,
    super.key,
  }) : assert(items.length == 4, 'ARENA bottom nav uses exactly 4 tabs');

  final List<ArenaBottomNavItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      decoration: const BoxDecoration(
        color: ArenaColors.carbon,
        border: Border(top: BorderSide(color: ArenaColors.border)),
      ),
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          for (var i = 0; i < items.length; i++)
            Expanded(
              child: _NavCell(
                item: items[i],
                active: i == currentIndex,
                onTap: () => onTap(i),
              ),
            ),
        ],
      ),
    );
  }
}

class _NavCell extends StatelessWidget {
  const _NavCell({
    required this.item,
    required this.active,
    required this.onTap,
  });

  final ArenaBottomNavItem item;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final iconColor = active ? ArenaColors.signalBlue : ArenaColors.silver;
    final labelColor = active ? ArenaColors.signalBlue : ArenaColors.silverDim;

    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            item.icon,
            size: 18,
            color: iconColor,
            shadows: active
                ? [
                    Shadow(
                      color: ArenaColors.signalBlue.withValues(alpha: 0.7),
                      blurRadius: 6,
                    ),
                  ]
                : null,
          ),
          const SizedBox(height: 2),
          Text(
            item.label,
            style: ArenaText.navLabel.copyWith(color: labelColor),
          ),
        ],
      ),
    );
  }
}
