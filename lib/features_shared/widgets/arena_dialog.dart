import 'dart:ui';

import 'package:arena/core/theme/arena_theme.dart';
import 'package:flutter/material.dart';

/// Modal with a frosted-blur backdrop, void-tinted surface and 16 dp radius.
///
/// Use [show] to push a barrier-dimmed [ArenaDialog] onto the navigator with
/// the right blur + slide-up animation. Maps to the bottom modal pattern in
/// `arena_v2.html` (lines ~1077-1082).
class ArenaDialog extends StatelessWidget {
  const ArenaDialog({
    this.title,
    this.content,
    this.actions = const [],
    super.key,
  });

  final String? title;
  final Widget? content;
  final List<Widget> actions;

  static Future<T?> show<T>(
    BuildContext context, {
    String? title,
    Widget? content,
    List<Widget> actions = const [],
  }) {
    return showGeneralDialog<T>(
      context: context,
      barrierDismissible: true,
      barrierLabel: title ?? 'dialog',
      barrierColor: Colors.black.withValues(alpha: 0.5),
      transitionDuration: ArenaDurations.medium,
      pageBuilder: (_, __, ___) => Center(
        child: ArenaDialog(title: title, content: content, actions: actions),
      ),
      transitionBuilder: (_, anim, __, child) {
        final curve = CurvedAnimation(parent: anim, curve: Curves.easeOutCubic);
        return FadeTransition(
          opacity: curve,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.06),
              end: Offset.zero,
            ).animate(curve),
            child: child,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: ArenaSpacing.xxl),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(ArenaRadius.lg),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: ArenaColors.void_.withValues(alpha: 0.95),
              borderRadius: BorderRadius.circular(ArenaRadius.lg),
              border: Border.all(color: ArenaColors.border),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (title != null) ...[
                  Text(title!.toUpperCase(), style: ArenaText.h3),
                  const SizedBox(height: ArenaSpacing.md),
                ],
                if (content != null) ...[
                  DefaultTextStyle.merge(
                    style: ArenaText.bodyMuted,
                    child: content!,
                  ),
                  const SizedBox(height: ArenaSpacing.lg),
                ],
                if (actions.isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (var i = 0; i < actions.length; i++) ...[
                        if (i > 0) const SizedBox(height: 6),
                        actions[i],
                      ],
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
