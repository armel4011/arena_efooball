import 'package:arena/core/i18n/currency.dart';
import 'package:arena/core/i18n/currency_service.dart';
import 'package:arena/core/i18n/feature_flags_service.dart';
import 'package:arena/core/i18n/i18n_service.dart';
import 'package:arena/core/theme/arena_colors.dart';
import 'package:arena/core/theme/arena_theme.dart';
import 'package:arena/core/theme/arena_typography.dart';
import 'package:arena/features_shared/widgets/arena_button.dart';
import 'package:arena/features_shared/widgets/arena_card.dart';
import 'package:arena/features_shared/widgets/arena_loading_indicator.dart';
import 'package:arena/features_shared/widgets/arena_text_field.dart';
import 'package:arena/features_shared/widgets/empty_state.dart';
import 'package:arena/features_shared/widgets/error_state.dart';
import 'package:arena/features_shared/widgets/language_switcher.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Visual catalogue for ARENA's design system.
///
/// Temporary — kept around through phases 1 → 11 as a sanity check, then
/// removed in PHASE 13 polish.
class DevPreviewPage extends StatelessWidget {
  const DevPreviewPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Design system')),
      body: ListView(
        padding: const EdgeInsets.all(ArenaSpacing.md),
        children: const [
          _Section(
            title: 'I18N + CURRENCY',
            child: _I18nGallery(),
          ),
          SizedBox(height: ArenaSpacing.xl),
          _Section(
            title: 'COULEURS',
            child: _ColorPalette(),
          ),
          SizedBox(height: ArenaSpacing.xl),
          _Section(
            title: 'TYPOGRAPHIE',
            child: _TypographySamples(),
          ),
          SizedBox(height: ArenaSpacing.xl),
          _Section(
            title: 'BOUTONS',
            child: _ButtonsGallery(),
          ),
          SizedBox(height: ArenaSpacing.xl),
          _Section(
            title: 'CARTES',
            child: _CardsGallery(),
          ),
          SizedBox(height: ArenaSpacing.xl),
          _Section(
            title: 'CHAMPS DE TEXTE',
            child: _TextFieldGallery(),
          ),
          SizedBox(height: ArenaSpacing.xl),
          _Section(
            title: 'LOADING',
            child: _LoadingGallery(),
          ),
          SizedBox(height: ArenaSpacing.xl),
          _Section(
            title: 'ÉTATS VIDES / ERREUR',
            child: _StatesGallery(),
          ),
          SizedBox(height: ArenaSpacing.xxl),
        ],
      ),
    );
  }
}

class _I18nGallery extends ConsumerWidget {
  const _I18nGallery();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final flags = ref.watch(featureFlagsSyncProvider);
    final locale = ref.watch(currentLocaleProvider);
    final currency = ref.watch(currentCurrencyProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const LanguageSwitcher(),
            const SizedBox(width: ArenaSpacing.md),
            Expanded(
              child: Text(
                'Active: ${locale.displayName} • '
                '${flags.enabledLanguages.length} langue(s) activée(s)',
                style: ArenaTypography.bodySmall,
              ),
            ),
          ],
        ),
        const SizedBox(height: ArenaSpacing.md),
        Text('DEVISES (V1.0 actives)', style: ArenaTypography.labelMedium),
        const SizedBox(height: ArenaSpacing.sm),
        Wrap(
          spacing: ArenaSpacing.sm,
          runSpacing: ArenaSpacing.sm,
          children: [
            for (final c in flags.enabledCurrencies)
              _CurrencyChip(
                currency: c,
                isActive: c == currency,
                onTap: () => ref
                    .read(currentCurrencyProvider.notifier)
                    .setCurrency(c),
              ),
          ],
        ),
        const SizedBox(height: ArenaSpacing.md),
        ArenaCard(
          elevated: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Format actuel (${currency.code} en ${locale.displayName})',
                style: ArenaTypography.labelMedium,
              ),
              const SizedBox(height: ArenaSpacing.sm),
              for (final amount in const [5000, 1234567, 12.5])
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Text(
                    formatAmount(ref, amount),
                    style: ArenaTypography.codeMedium,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CurrencyChip extends StatelessWidget {
  const _CurrencyChip({
    required this.currency,
    required this.isActive,
    required this.onTap,
  });

  final Currency currency;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return InkWell(
      borderRadius: ArenaRadius.button,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: ArenaSpacing.md,
          vertical: ArenaSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: isActive
              ? primary.withValues(alpha: 0.18)
              : ArenaColors.surfaceLight,
          borderRadius: ArenaRadius.button,
          border: Border.all(
            color: isActive ? primary : ArenaColors.border,
          ),
        ),
        child: Text(
          '${currency.code} ${currency.symbol}',
          style: ArenaTypography.labelMedium.copyWith(
            color: isActive ? primary : ArenaColors.text,
          ),
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: ArenaTypography.headlineMedium),
        const SizedBox(height: ArenaSpacing.md),
        child,
      ],
    );
  }
}

class _ColorPalette extends StatelessWidget {
  const _ColorPalette();

  static const _swatches = <_Swatch>[
    _Swatch('bg', ArenaColors.bg),
    _Swatch('surface', ArenaColors.surface),
    _Swatch('surfaceLight', ArenaColors.surfaceLight),
    _Swatch('primary', ArenaColors.primary),
    _Swatch('secondary', ArenaColors.secondary),
    _Swatch('efootball', ArenaColors.efootball),
    _Swatch('fifa', ArenaColors.fifa),
    _Swatch('fcMobile', ArenaColors.fcMobile),
    _Swatch('success', ArenaColors.success),
    _Swatch('warning', ArenaColors.warning),
    _Swatch('danger', ArenaColors.danger),
    _Swatch('text', ArenaColors.text),
    _Swatch('textMuted', ArenaColors.textMuted),
    _Swatch('textFaint', ArenaColors.textFaint),
  ];

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: ArenaSpacing.sm,
      runSpacing: ArenaSpacing.sm,
      children: [
        for (final s in _swatches) _ColorChip(swatch: s),
      ],
    );
  }
}

class _Swatch {
  const _Swatch(this.name, this.color);
  final String name;
  final Color color;
}

class _ColorChip extends StatelessWidget {
  const _ColorChip({required this.swatch});

  final _Swatch swatch;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 110,
      padding: const EdgeInsets.all(ArenaSpacing.sm),
      decoration: BoxDecoration(
        color: ArenaColors.surface,
        borderRadius: ArenaRadius.button,
        border: Border.all(color: ArenaColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 40,
            decoration: BoxDecoration(
              color: swatch.color,
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          const SizedBox(height: ArenaSpacing.xs),
          Text(swatch.name, style: ArenaTypography.labelMedium),
        ],
      ),
    );
  }
}

class _TypographySamples extends StatelessWidget {
  const _TypographySamples();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _TypoRow('displayMedium', ArenaTypography.displayMedium, 'ARENA'),
        _TypoRow('headlineLarge', ArenaTypography.headlineLarge, 'Compétitions'),
        _TypoRow('titleLarge', ArenaTypography.titleLarge, 'Cameroon Cup 2026'),
        _TypoRow(
          'bodyLarge',
          ArenaTypography.bodyLarge,
          'Le tournoi commence dans 5 minutes.',
        ),
        _TypoRow('bodySmall', ArenaTypography.bodySmall, 'Frais 5 000 XAF'),
        _TypoRow('labelLarge', ArenaTypography.labelLarge, "S'INSCRIRE"),
        _TypoRow('codeLarge', ArenaTypography.codeLarge, 'AB12-34CD'),
      ],
    );
  }
}

class _TypoRow extends StatelessWidget {
  const _TypoRow(this.name, this.style, this.sample);

  final String name;
  final TextStyle style;
  final String sample;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: ArenaSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(name, style: ArenaTypography.labelMedium),
          const SizedBox(height: ArenaSpacing.xs),
          Text(sample, style: style),
        ],
      ),
    );
  }
}

class _ButtonsGallery extends StatelessWidget {
  const _ButtonsGallery();

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: ArenaSpacing.sm,
      runSpacing: ArenaSpacing.sm,
      children: [
        ArenaButton(label: 'Primary', onPressed: () {}),
        ArenaButton(
          label: 'Secondary',
          onPressed: () {},
          variant: ArenaButtonVariant.secondary,
        ),
        ArenaButton(
          label: 'Danger',
          onPressed: () {},
          variant: ArenaButtonVariant.danger,
        ),
        ArenaButton(
          label: 'Ghost',
          onPressed: () {},
          variant: ArenaButtonVariant.ghost,
        ),
        ArenaButton(
          label: 'Avec icône',
          onPressed: () {},
          icon: Icons.bolt,
        ),
        const ArenaButton(label: 'Disabled', onPressed: null),
        ArenaButton(label: 'Loading…', onPressed: () {}, isLoading: true),
        ArenaButton(
          label: 'Large',
          onPressed: () {},
          size: ArenaButtonSize.large,
        ),
      ],
    );
  }
}

class _CardsGallery extends StatelessWidget {
  const _CardsGallery();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ArenaCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Surface card', style: ArenaTypography.titleMedium),
              const SizedBox(height: ArenaSpacing.xs),
              Text(
                'Conteneur basique avec padding standard.',
                style: ArenaTypography.bodyMedium,
              ),
            ],
          ),
        ),
        const SizedBox(height: ArenaSpacing.sm),
        ArenaCard(
          elevated: true,
          onTap: () {},
          child: Row(
            children: [
              const Icon(Icons.flash_on, color: ArenaColors.fifa),
              const SizedBox(width: ArenaSpacing.md),
              Expanded(
                child: Text(
                  'Tappable elevated card',
                  style: ArenaTypography.titleMedium,
                ),
              ),
              const Icon(Icons.chevron_right, color: ArenaColors.textMuted),
            ],
          ),
        ),
      ],
    );
  }
}

class _TextFieldGallery extends StatelessWidget {
  const _TextFieldGallery();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        ArenaTextField(
          label: 'Email',
          hint: 'joueur@arena.app',
          prefixIcon: Icons.email_outlined,
        ),
        SizedBox(height: ArenaSpacing.md),
        ArenaTextField(
          label: 'Mot de passe',
          hint: '••••••••',
          obscureText: true,
          prefixIcon: Icons.lock_outline,
        ),
        SizedBox(height: ArenaSpacing.md),
        ArenaTextField(
          label: 'Avec erreur',
          initialValue: 'invalide',
          errorText: 'Format incorrect',
        ),
      ],
    );
  }
}

class _LoadingGallery extends StatelessWidget {
  const _LoadingGallery();

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        ArenaLoadingIndicator(),
        ArenaLoadingIndicator(label: 'Chargement…'),
      ],
    );
  }
}

class _StatesGallery extends StatelessWidget {
  const _StatesGallery();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 240,
          child: EmptyState(
            title: 'Aucune compétition',
            description: 'Aucune compétition ouverte pour le moment.',
            icon: Icons.emoji_events_outlined,
            actionLabel: 'Actualiser',
            onAction: () {},
          ),
        ),
        const SizedBox(height: ArenaSpacing.lg),
        SizedBox(
          height: 240,
          child: ErrorState(
            description: 'Impossible de charger les données. Vérifie ta connexion.',
            onRetry: () {},
          ),
        ),
      ],
    );
  }
}
