part of 'dev_preview_page.dart';

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
    _Swatch('draughts', ArenaColors.draughts),
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
              const Icon(Icons.flash_on, color: ArenaColors.draughts),
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
