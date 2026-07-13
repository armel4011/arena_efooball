import 'package:arena/core/services/permissions_service.dart';
import 'package:arena/core/theme/arena_theme.dart';
import 'package:arena/features_shared/widgets/arena_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Guide « Activer le bouton flottant » pour Android 13+/15.
///
/// Sur les téléphones récents (Pixel 9 & co), le toggle « Afficher au-dessus
/// des autres apps » (SYSTEM_ALERT_WINDOW) est GRISÉ « paramètre restreint »
/// pour les apps installées HORS Play Store — ce qui est le cas d'Arena
/// (distribution APK, le RMG étant interdit sur le Play). L'utilisateur doit
/// d'abord « Autoriser les paramètres restreints » depuis les infos de l'app.
///
/// ⚠️ L'enregistrement anti-triche (MediaProjection natif, FGS dédié) tourne
/// SANS overlay : ce guide ne concerne QUE le bouton flottant de confort.
Future<void> showOverlayRestrictedGuide(BuildContext context, WidgetRef ref) {
  return showDialog<void>(
    context: context,
    builder: (_) => const _OverlayRestrictedGuideDialog(),
  );
}

class _OverlayRestrictedGuideDialog extends ConsumerWidget {
  const _OverlayRestrictedGuideDialog();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final perms = ref.read(permissionsServiceProvider);
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
                  Icons.layers_outlined,
                  color: ArenaColors.signalBlue,
                  size: 22,
                ),
                const SizedBox(width: ArenaSpacing.sm),
                Expanded(
                  child: Text(
                    'Activer le bouton flottant',
                    style: ArenaText.body.copyWith(fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
            const SizedBox(height: ArenaSpacing.md),
            Text(
              'Ton enregistrement anti-triche tourne déjà — aucune inquiétude. '
              'Sur Android récent (Pixel & co), le bouton flottant « au-dessus '
              'des autres apps » est bloqué par défaut pour les apps installées '
              'hors Play Store. Pour le réactiver, deux étapes :',
              style: ArenaText.small.copyWith(color: ArenaColors.silver),
            ),
            const SizedBox(height: ArenaSpacing.md),
            _GuideStep(
              n: '1',
              title: 'Autoriser les paramètres restreints',
              desc: "Dans les infos de l'app, ouvre le menu ⋮ (3 points en "
                  'haut à droite) → « Autoriser les paramètres restreints », '
                  'puis confirme avec ton code / ton empreinte.',
              buttonLabel: "Ouvrir les infos de l'app",
              onTap: perms.openAppSettingsPage,
            ),
            const SizedBox(height: ArenaSpacing.sm),
            _GuideStep(
              n: '2',
              title: 'Activer « Afficher au-dessus des autres apps »',
              desc: 'Reviens ici, puis active la superposition pour Arena.',
              buttonLabel: 'Ouvrir le réglage superposition',
              onTap: () async {
                await perms.requestOverlay();
                return true;
              },
            ),
            const SizedBox(height: ArenaSpacing.md),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.of(context).maybePop(),
                child: Text(
                  'Fermer',
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

class _GuideStep extends StatelessWidget {
  const _GuideStep({
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
