import 'package:arena/core/theme/arena_theme.dart';
import 'package:arena/data/models/profile.dart';
import 'package:arena/features_shared/admin_sections.dart';
import 'package:arena/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';

/// VOLET 3 — bandeau « Périmètre : {pays} » affiché sur les écrans de
/// versements/paiements quand l'admin courant a un scope pays restreint.
///
/// Clarifie pourquoi la liste est réduite (le filtrage pays est déjà fait
/// par la RLS `payouts_select` côté serveur). À n'afficher que si
/// [adminHasCountryScope] est vrai.
class AdminScopeBanner extends StatelessWidget {
  const AdminScopeBanner({required this.profile, super.key});

  final Profile? profile;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final label = adminCountriesLabel(profile?.adminAllowedCountries);
    if (label.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: ArenaSpacing.md,
        vertical: ArenaSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: ArenaColors.signalBlue.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(ArenaRadius.md),
        border: Border.all(
          color: ArenaColors.signalBlue.withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.public,
            size: 16,
            color: ArenaColors.signalBlue,
          ),
          const SizedBox(width: ArenaSpacing.sm),
          Expanded(
            child: Text(
              l10n.adminScopePerimeterBanner(label),
              style: ArenaText.small.copyWith(color: ArenaColors.silver),
            ),
          ),
        ],
      ),
    );
  }
}
