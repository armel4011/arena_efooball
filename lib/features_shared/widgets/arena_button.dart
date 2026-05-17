import 'package:arena/core/theme/arena_theme.dart';
import 'package:flutter/material.dart';

enum ArenaButtonVariant { primary, secondary, danger, ghost }

enum ArenaButtonSize { regular, large }

/// ARENA's primary call-to-action.
///
/// Variants map to brand intents (see [ArenaButtonVariant]):
/// - primary   → main CTA (bleu user / rouge admin via theme)
/// - secondary → outlined neutral
/// - danger    → destructive action (delete account, ban, etc.)
/// - ghost     → tertiary, no background
class ArenaButton extends StatelessWidget {
  const ArenaButton({
    required this.label,
    required this.onPressed,
    this.variant = ArenaButtonVariant.primary,
    this.size = ArenaButtonSize.regular,
    this.icon,
    this.isLoading = false,
    this.fullWidth = false,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final ArenaButtonVariant variant;
  final ArenaButtonSize size;
  final IconData? icon;
  final bool isLoading;
  final bool fullWidth;

  bool get _disabled => isLoading || onPressed == null;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bg = _backgroundColor(scheme);
    final fg = _foregroundColor(scheme);
    final borderSide = _borderSide(scheme);

    final padding = EdgeInsets.symmetric(
      horizontal: size == ArenaButtonSize.large
          ? ArenaSpacing.xl
          : ArenaSpacing.lg,
      vertical:
          size == ArenaButtonSize.large ? ArenaSpacing.md : ArenaSpacing.sm + 4,
    );

    final child = isLoading
        ? SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation(fg),
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18, color: fg),
                const SizedBox(width: ArenaSpacing.sm),
              ],
              Text(
                label,
                style: ArenaTypography.labelLarge.copyWith(color: fg),
              ),
            ],
          );

    final button = Material(
      color: bg,
      borderRadius: ArenaRadius.button,
      child: InkWell(
        onTap: _disabled ? null : onPressed,
        borderRadius: ArenaRadius.button,
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: ArenaRadius.button,
            border: borderSide == null ? null : Border.fromBorderSide(borderSide),
          ),
          child: Center(child: child),
        ),
      ),
    );

    final glow = _glowColor(scheme);
    final wrapped = glow == null
        ? button
        : DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: ArenaRadius.button,
              boxShadow: [
                BoxShadow(
                  color: glow.withValues(alpha: 0.65),
                  blurRadius: 30,
                  spreadRadius: 0,
                  offset: const Offset(0, 6),
                ),
                BoxShadow(
                  color: glow.withValues(alpha: 0.35),
                  blurRadius: 12,
                  spreadRadius: -2,
                ),
              ],
            ),
            child: button,
          );

    if (fullWidth) {
      return SizedBox(width: double.infinity, child: wrapped);
    }
    return wrapped;
  }

  Color? _glowColor(ColorScheme scheme) {
    if (_disabled) return null;
    return switch (variant) {
      ArenaButtonVariant.primary => scheme.primary,
      ArenaButtonVariant.danger => ArenaColors.danger,
      ArenaButtonVariant.secondary || ArenaButtonVariant.ghost => null,
    };
  }

  Color _backgroundColor(ColorScheme scheme) {
    if (_disabled) {
      return switch (variant) {
        ArenaButtonVariant.primary || ArenaButtonVariant.danger =>
          ArenaColors.surfaceLight,
        ArenaButtonVariant.secondary || ArenaButtonVariant.ghost =>
          Colors.transparent,
      };
    }
    return switch (variant) {
      ArenaButtonVariant.primary => scheme.primary,
      ArenaButtonVariant.danger => ArenaColors.danger,
      ArenaButtonVariant.secondary || ArenaButtonVariant.ghost =>
        Colors.transparent,
    };
  }

  Color _foregroundColor(ColorScheme scheme) {
    if (_disabled) return ArenaColors.textFaint;
    return switch (variant) {
      ArenaButtonVariant.primary || ArenaButtonVariant.danger => Colors.white,
      ArenaButtonVariant.secondary => ArenaColors.text,
      ArenaButtonVariant.ghost => scheme.primary,
    };
  }

  BorderSide? _borderSide(ColorScheme scheme) {
    return switch (variant) {
      ArenaButtonVariant.secondary => const BorderSide(
          color: ArenaColors.border,
        ),
      ArenaButtonVariant.primary ||
      ArenaButtonVariant.danger ||
      ArenaButtonVariant.ghost =>
        null,
    };
  }
}
