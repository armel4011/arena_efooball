import 'package:arena/core/services/miui_optimization_service.dart';
import 'package:arena/core/services/onboarding_service.dart'
    show sharedPreferencesProvider;
import 'package:arena/core/theme/arena_theme.dart';
import 'package:arena/features_shared/widgets/arena_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Nom de préférence (pas un secret) : flag « guide arrière-plan déjà montré ».
// NB : nouvelle clé (≠ ancien `arena_miui_prompted`) pour que le guide amélioré
// — avec l'exemption batterie universelle — soit revu une fois par TOUS, y
// compris ceux qui n'avaient eu que l'ancien guide MIUI.
const _bgReliabilityPromptedPref = 'arena_bg_reliability_prompted';

/// Affiche UNE seule fois (persisté) le guide « garder Arena actif en
/// arrière-plan ». À appeler après login, depuis un endroit stable (home).
///
/// Se déclenche si l'app n'est PAS exemptée de l'optimisation batterie (tous
/// OEM — Samsung inclus) OU sur Xiaomi (réglages MIUI supplémentaires). No-op si
/// déjà exemptée et hors Xiaomi, ou si déjà montré. Idempotent.
Future<void> maybePromptBackgroundReliability(
  BuildContext context,
  WidgetRef ref,
) async {
  final prefs = ref.read(sharedPreferencesProvider);
  if (prefs.getBool(_bgReliabilityPromptedPref) == true) return;
  final svc = ref.read(miuiOptimizationServiceProvider);
  final isMiui = await svc.isMiui();
  final ignoring = await svc.isIgnoringBatteryOptimizations();
  // Rien à faire : déjà exemptée ET pas de réglages MIUI spécifiques à activer.
  if (ignoring && !isMiui) return;
  await prefs.setBool(_bgReliabilityPromptedPref, true);
  if (!context.mounted) return;
  await showBackgroundReliabilityDialog(context, ref, isMiui: isMiui);
}

/// Ouvre le guide à la demande (ex. depuis les réglages). Toujours affiché.
Future<void> showBackgroundReliabilityDialog(
  BuildContext context,
  WidgetRef ref, {
  bool? isMiui,
}) async {
  final resolvedMiui =
      isMiui ?? await ref.read(miuiOptimizationServiceProvider).isMiui();
  if (!context.mounted) return;
  await showDialog<void>(
    context: context,
    builder: (_) => _BackgroundReliabilityDialog(isMiui: resolvedMiui),
  );
}

class _BackgroundReliabilityDialog extends ConsumerWidget {
  const _BackgroundReliabilityDialog({required this.isMiui});

  final bool isMiui;

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
                    'Garde Arena actif en arrière-plan',
                    style:
                        ArenaText.body.copyWith(fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
            const SizedBox(height: ArenaSpacing.md),
            Text(
              'Ton téléphone met les applis en veille au bout de quelques '
              "minutes. Pendant un match, ça coupe l'enregistrement et ta preuve "
              'est perdue. Active ce réglage pour Arena :',
              style: ArenaText.small.copyWith(color: ArenaColors.silver),
            ),
            const SizedBox(height: ArenaSpacing.md),
            // Étape UNIVERSELLE (tous OEM) : exemption batterie en une tape.
            _Step(
              n: '1',
              title: "Autoriser l'exécution en arrière-plan",
              desc: 'Le plus important : whiteliste Arena de l’économiseur '
                  'de batterie (empêche Android de la fermer).',
              buttonLabel: 'Autoriser (recommandé)',
              onTap: svc.requestBatteryExemption,
            ),
            if (isMiui) ...[
              const SizedBox(height: ArenaSpacing.sm),
              _Step(
                n: '2',
                title: 'Démarrage auto (Xiaomi)',
                desc: 'Autorise Arena à démarrer en arrière-plan.',
                buttonLabel: 'Ouvrir « Démarrage auto »',
                onTap: svc.openAutostart,
              ),
              const SizedBox(height: ArenaSpacing.sm),
              _Step(
                n: '3',
                title: 'Batterie « Sans restriction » (Xiaomi)',
                desc: 'Économiseur de batterie → choisis « Sans restriction ».',
                buttonLabel: 'Ouvrir les réglages batterie',
                onTap: svc.openBatterySaver,
              ),
            ],
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
