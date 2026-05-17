import 'package:arena/core/i18n/feature_flags_service.dart';
import 'package:arena/core/i18n/i18n_service.dart';
import 'package:arena/core/i18n/supported_locale.dart';
import 'package:arena/core/theme/arena_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Lets the user switch languages. Renders nothing when the platform is
/// single-language (V1.0 default) — that way the same widget can sit in
/// Settings across all rollout versions without conditional logic.
class LanguageSwitcher extends ConsumerWidget {
  const LanguageSwitcher({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final flags = ref.watch(featureFlagsSyncProvider);
    if (!flags.isMultiLanguage) return const SizedBox.shrink();

    final current = ref.watch(currentLocaleProvider);

    return InkWell(
      borderRadius: ArenaRadius.button,
      onTap: () => _open(context, ref, flags.enabledLanguages, current),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: ArenaSpacing.md,
          vertical: ArenaSpacing.sm + 4,
        ),
        decoration: BoxDecoration(
          color: ArenaColors.surfaceLight,
          borderRadius: ArenaRadius.button,
          border: Border.all(color: ArenaColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.language,
              size: 18,
              color: ArenaColors.textMuted,
            ),
            const SizedBox(width: ArenaSpacing.sm),
            Text(current.displayName, style: ArenaTypography.labelLarge),
            const SizedBox(width: ArenaSpacing.xs),
            const Icon(
              Icons.expand_more,
              size: 18,
              color: ArenaColors.textMuted,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _open(
    BuildContext context,
    WidgetRef ref,
    List<SupportedLocale> options,
    SupportedLocale current,
  ) async {
    final picked = await showDialog<SupportedLocale>(
      context: context,
      builder: (ctx) => SimpleDialog(
        backgroundColor: ArenaColors.surface,
        title: Text('Langue', style: ArenaTypography.titleLarge),
        children: [
          for (final opt in options)
            SimpleDialogOption(
              onPressed: () => Navigator.of(ctx).pop(opt),
              child: Row(
                children: [
                  Icon(
                    opt == current
                        ? Icons.radio_button_checked
                        : Icons.radio_button_unchecked,
                    color: opt == current
                        ? Theme.of(context).colorScheme.primary
                        : ArenaColors.textMuted,
                    size: 18,
                  ),
                  const SizedBox(width: ArenaSpacing.md),
                  Text(opt.displayName, style: ArenaTypography.bodyLarge),
                ],
              ),
            ),
        ],
      ),
    );

    if (picked != null && picked != current) {
      await ref.read(currentLocaleProvider.notifier).setLocale(picked);
    }
  }
}
