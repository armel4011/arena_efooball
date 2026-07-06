import 'package:arena/core/theme/arena_theme.dart';
import 'package:arena/core/utils/supported_countries.dart';
import 'package:arena/features_shared/widgets/arena_button.dart';
import 'package:arena/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';

/// Dialog « Choisis ton pays » — affiché à l'inscription d'une compétition
/// payante quand elle propose plusieurs pays de paiement. Liste chaque pays
/// activé (drapeau + nom depuis [kSupportedCountries], repli = code brut si
/// inconnu). Retourne le `countryCode` choisi, ou `null` si annulé.
Future<String?> showCountryPickDialog(
  BuildContext context, {
  required List<String> countryCodes,
  required String selected,
}) {
  return showDialog<String>(
    context: context,
    builder: (_) => _CountryPickDialog(
      countryCodes: countryCodes,
      initial: selected,
    ),
  );
}

class _CountryPickDialog extends StatefulWidget {
  const _CountryPickDialog({
    required this.countryCodes,
    required this.initial,
  });

  final List<String> countryCodes;
  final String initial;

  @override
  State<_CountryPickDialog> createState() => _CountryPickDialogState();
}

class _CountryPickDialogState extends State<_CountryPickDialog> {
  late String _selected = widget.initial;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      backgroundColor: ArenaColors.carbon,
      title: Text(l10n.countryPickTitle, style: ArenaText.h3),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.countryPickSubtitle, style: ArenaText.bodyMuted),
          const SizedBox(height: ArenaSpacing.md),
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final code in widget.countryCodes)
                    _CountryTile(
                      code: code,
                      selected: _selected == code,
                      onTap: () => setState(() => _selected = code),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
      actions: [
        ArenaButton(
          label: l10n.countryPickCancel,
          variant: ArenaButtonVariant.ghost,
          onPressed: () => Navigator.pop(context),
        ),
        ArenaButton(
          label: l10n.countryPickConfirm,
          onPressed: () => Navigator.pop(context, _selected),
        ),
      ],
    );
  }
}

class _CountryTile extends StatelessWidget {
  const _CountryTile({
    required this.code,
    required this.selected,
    required this.onTap,
  });

  final String code;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // Repli : code brut si le pays n'est pas dans kSupportedCountries.
    final match = kSupportedCountries.where((c) => c.code == code).toList();
    final flag = match.isEmpty ? '🏳' : match.first.flag;
    final name = match.isEmpty ? code : match.first.name;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(ArenaRadius.md),
      child: Container(
        margin: const EdgeInsets.only(bottom: ArenaSpacing.xs),
        padding: const EdgeInsets.symmetric(
          horizontal: ArenaSpacing.md,
          vertical: ArenaSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: selected
              ? ArenaColors.signalBlue.withValues(alpha: 0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(ArenaRadius.md),
          border: Border.all(
            color: selected ? ArenaColors.signalBlue : ArenaColors.border,
          ),
        ),
        child: Row(
          children: [
            Text(flag, style: const TextStyle(fontSize: 22)),
            const SizedBox(width: ArenaSpacing.sm),
            Expanded(
              child: Text(
                name,
                style: ArenaText.body.copyWith(
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                ),
              ),
            ),
            if (selected)
              const Icon(
                Icons.check_circle,
                size: 20,
                color: ArenaColors.signalBlue,
              ),
          ],
        ),
      ),
    );
  }
}
