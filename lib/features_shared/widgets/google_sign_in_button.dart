import 'package:arena/core/theme/arena_theme.dart';
import 'package:flutter/material.dart';

/// Bouton « Continuer avec Google » conforme aux Google Sign-In Brand
/// Guidelines (variante Light) : fond blanc, logo G quadricolore, texte
/// `#1F1F1F`. Les couleurs sont hardcodées intentionnellement — la
/// reconnaissance instantanée du bouton repose sur ces valeurs précises
/// de la charte Google, pas sur le design system ARENA.
///
/// Exposé en plein-écran via `fullWidth: true`. `isLoading` swap le
/// contenu pour un spinner gris foncé sur fond blanc.
class GoogleSignInButton extends StatelessWidget {
  const GoogleSignInButton({
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.fullWidth = false,
    super.key,
  });

  final String label;
  final Future<void> Function()? onPressed;
  final bool isLoading;
  final bool fullWidth;

  static const _googleTextColor = Color(0xFF1F1F1F);
  static const _googleBackground = Color(0xFFFFFFFF);
  static const _googleSplash = Color(0xFFE8E8E8);

  bool get _disabled => isLoading || onPressed == null;

  @override
  Widget build(BuildContext context) {
    final button = Material(
      color: _googleBackground,
      borderRadius: ArenaRadius.button,
      child: InkWell(
        onTap: _disabled ? null : () => onPressed!.call(),
        borderRadius: ArenaRadius.button,
        splashColor: _googleSplash,
        highlightColor: _googleSplash,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: ArenaSpacing.lg,
            vertical: ArenaSpacing.md,
          ),
          decoration: BoxDecoration(
            borderRadius: ArenaRadius.button,
            border: Border.all(color: const Color(0xFFDADCE0)),
          ),
          child: Center(
            child: isLoading
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(_googleTextColor),
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const _GoogleGLogo(),
                      const SizedBox(width: ArenaSpacing.md),
                      Text(
                        label,
                        style: ArenaTypography.labelLarge.copyWith(
                          color: _googleTextColor,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );

    return fullWidth ? SizedBox(width: double.infinity, child: button) : button;
  }
}

/// Pastille « G » Google : cercle bleu brand `#4285F4` + lettre `G` blanche.
/// Choix pragmatique vs un vrai logo 4-couleurs (qui exigerait un asset
/// SVG ou un Path complexe) — reste universellement reconnaissable
/// associé au fond blanc du bouton et au libellé « Google ».
class _GoogleGLogo extends StatelessWidget {
  const _GoogleGLogo();

  static const _googleBlue = Color(0xFF4285F4);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: _googleBlue,
      ),
      child: const Text(
        'G',
        style: TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w800,
          height: 1,
        ),
      ),
    );
  }
}
