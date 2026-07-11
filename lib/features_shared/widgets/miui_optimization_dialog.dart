import 'package:arena/core/services/miui_optimization_service.dart';
import 'package:arena/core/services/onboarding_service.dart'
    show sharedPreferencesProvider;
import 'package:arena/core/theme/arena_theme.dart';
import 'package:arena/features_shared/widgets/arena_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Nom de préférence (pas un secret) : flag « guide MIUI déjà montré ».
const _miuiPromptedPref = 'arena_miui_prompted';

/// Affiche UNE seule fois (persisté) le guide d'optimisation MIUI sur les
/// appareils Xiaomi. À appeler après login, depuis un endroit stable (home).
/// No-op hors Xiaomi ou si déjà montré. Idempotent.
Future<void> maybePromptMiuiOptimization(
  BuildContext context,
  WidgetRef ref,
) async {
  final prefs = ref.read(sharedPreferencesProvider);
  if (prefs.getBool(_miuiPromptedPref) == true) return;
  final isMiui = await ref.read(miuiOptimizationServiceProvider).isMiui();
  if (!isMiui) return;
  await prefs.setBool(_miuiPromptedPref, true);
  if (!context.mounted) return;
  await showMiuiOptimizationDialog(context, ref);
}

/// Ouvre le guide MIUI à la demande (ex. depuis les réglages). Toujours affiché.
Future<void> showMiuiOptimizationDialog(
  BuildContext context,
  WidgetRef ref,
) {
  return showDialog<void>(
    context: context,
    builder: (_) => const _MiuiOptimizationDialog(),
  );
}

class _MiuiOptimizationDialog extends ConsumerWidget {
  const _MiuiOptimizationDialog();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final svc = ref.read(miuiOptimizationServiceProvider);
    return Dialog(
      backgroundColor: ArenaColors.carbon,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(ArenaRadius.lg),
      ),
      child: Padding(
        padding: const EdgeInsets.all(ArenaSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.battery_saver,
                  color: ArenaColors.signalBlue,
                  size: 22,
                ),
                const SizedBox(width: ArenaSpacing.sm),
                Expanded(
                  child: Text(
                    'Autorise Arena sur ton Xiaomi',
                    style:
                        ArenaText.body.copyWith(fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
            const SizedBox(height: ArenaSpacing.md),
            Text(
              'MIUI met les applis en veille quand elles sont fermées. Pour que '
              'ta preuve de match parte automatiquement (et que tu reçoives tes '
              'gains sans souci), active deux réglages pour Arena :',
              style: ArenaText.small.copyWith(color: ArenaColors.silver),
            ),
            const SizedBox(height: ArenaSpacing.md),
            _Step(
              n: '1',
              title: 'Démarrage auto',
              desc: 'Autorise Arena à démarrer en arrière-plan.',
              buttonLabel: 'Ouvrir « Démarrage auto »',
              onTap: svc.openAutostart,
            ),
            const SizedBox(height: ArenaSpacing.sm),
            _Step(
              n: '2',
              title: 'Batterie « Sans restriction »',
              desc: 'Économiseur de batterie → choisis « Sans restriction ».',
              buttonLabel: 'Ouvrir les réglages batterie',
              onTap: svc.openBatterySaver,
            ),
            const SizedBox(height: ArenaSpacing.md),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.of(context).maybePop(),
                child: Text(
                  'Plus tard',
                  style: ArenaText.small.copyWith(color: ArenaColors.silver),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({
    required this.n,
    required this.title,
    required this.desc,
    required this.buttonLabel,
    required this.onTap,
  });

  final String n;
  final String title;
  final String desc;
  final String buttonLabel;
  final Future<bool> Function() onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(ArenaSpacing.md),
      decoration: BoxDecoration(
        color: ArenaColors.void_,
        borderRadius: BorderRadius.circular(ArenaRadius.md),
        border: Border.all(color: ArenaColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '$n. ',
                style: ArenaText.small.copyWith(
                  color: ArenaColors.signalBlue,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Expanded(
                child: Text(
                  title,
                  style: ArenaText.small.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            desc,
            style: ArenaText.small.copyWith(color: ArenaColors.silver),
          ),
          const SizedBox(height: ArenaSpacing.sm),
          ArenaButton(
            label: buttonLabel,
            variant: ArenaButtonVariant.secondary,
            fullWidth: true,
            onPressed: onTap,
          ),
        ],
      ),
    );
  }
}
