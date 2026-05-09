import 'package:arena/core/theme/arena_theme.dart';
import 'package:flutter/material.dart';

/// Branded top bar (height 56, transparent void background, optional 1px
/// bottom border). Maps to `.app-bar` in `arena_v2.html`.
///
/// Title renders in Bebas Neue (`ArenaText.appBarTitle`). Leading defaults to
/// a circular back chevron when `Navigator.canPop` and [showBack] is true.
class ArenaAppBar extends StatelessWidget implements PreferredSizeWidget {
  const ArenaAppBar({
    required this.title,
    this.showBack = true,
    this.actions = const [],
    this.bordered = false,
    super.key,
  });

  final String title;
  final bool showBack;
  final List<Widget> actions;
  final bool bordered;

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.canPop(context);
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: ArenaSpacing.lg),
      decoration: BoxDecoration(
        color: ArenaColors.void_,
        border: bordered
            ? const Border(bottom: BorderSide(color: ArenaColors.border))
            : null,
      ),
      child: Row(
        children: [
          if (showBack && canPop) ...[
            _CircleIconButton(
              icon: Icons.arrow_back,
              onTap: () => Navigator.maybePop(context),
            ),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: Text(
              title.toUpperCase(),
              style: ArenaText.appBarTitle,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          ...actions,
        ],
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(ArenaRadius.round),
      child: Container(
        width: 30,
        height: 30,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: ArenaColors.carbon,
        ),
        child: Icon(icon, size: 16, color: ArenaColors.bone),
      ),
    );
  }
}
