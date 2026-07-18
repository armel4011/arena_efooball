part of 'dev_preview_page.dart';

class _AvatarsGallery extends StatelessWidget {
  const _AvatarsGallery();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('SIZES', style: ArenaText.inputLabel),
        const SizedBox(height: ArenaSpacing.sm),
        const Wrap(
          spacing: ArenaSpacing.md,
          runSpacing: ArenaSpacing.md,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            ArenaAvatar(initials: 'KM', size: ArenaAvatarSize.sm),
            ArenaAvatar(initials: 'KM'),
            ArenaAvatar(initials: 'KM', size: ArenaAvatarSize.lg),
            ArenaAvatar(initials: 'KM', size: ArenaAvatarSize.xl),
          ],
        ),
        const SizedBox(height: ArenaSpacing.md),
        Text('COLORS (8)', style: ArenaText.inputLabel),
        const SizedBox(height: ArenaSpacing.sm),
        Wrap(
          spacing: ArenaSpacing.sm,
          runSpacing: ArenaSpacing.sm,
          children: [
            for (final c in ArenaAvatarColor.values)
              ArenaAvatar(initials: c.name.substring(0, 2), color: c),
          ],
        ),
      ],
    );
  }
}

class _BadgesGallery extends StatelessWidget {
  const _BadgesGallery();

  @override
  Widget build(BuildContext context) {
    return const Wrap(
      spacing: ArenaSpacing.sm,
      runSpacing: ArenaSpacing.sm,
      children: [
        ArenaBadge(label: 'live', variant: ArenaBadgeVariant.live),
        ArenaBadge(label: 'success', variant: ArenaBadgeVariant.success),
        ArenaBadge(label: 'info', variant: ArenaBadgeVariant.info),
        ArenaBadge(label: 'warn', variant: ArenaBadgeVariant.warn),
        ArenaBadge(label: 'danger', variant: ArenaBadgeVariant.danger),
        ArenaBadge(label: 'bronze', variant: ArenaBadgeVariant.tierBronze),
        ArenaBadge(label: 'neutre'),
      ],
    );
  }
}

class _AppBarGallery extends StatelessWidget {
  const _AppBarGallery();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        ArenaAppBar(
          title: 'Compétitions',
          showBack: false,
          actions: [
            Icon(Icons.search, color: ArenaColors.silver, size: 20),
            SizedBox(width: ArenaSpacing.sm),
            Icon(Icons.tune, color: ArenaColors.silver, size: 20),
          ],
        ),
        SizedBox(height: ArenaSpacing.sm),
        ArenaAppBar(title: 'Détail compétition', bordered: true),
      ],
    );
  }
}

class _BottomNavGallery extends StatefulWidget {
  const _BottomNavGallery();

  @override
  State<_BottomNavGallery> createState() => _BottomNavGalleryState();
}

class _BottomNavGalleryState extends State<_BottomNavGallery> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return ArenaBottomNav(
      currentIndex: _index,
      onTap: (i) => setState(() => _index = i),
      items: const [
        ArenaBottomNavItem(icon: Icons.home_outlined, label: 'Home'),
        ArenaBottomNavItem(icon: Icons.emoji_events_outlined, label: 'Comp'),
        ArenaBottomNavItem(icon: Icons.chat_bubble_outline, label: 'Chat'),
        ArenaBottomNavItem(icon: Icons.person_outline, label: 'Profil'),
      ],
    );
  }
}

class _StepperGallery extends StatelessWidget {
  const _StepperGallery();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Step 1/4', style: ArenaText.inputLabel),
        const SizedBox(height: ArenaSpacing.xs),
        const ArenaStepper(totalSteps: 4, currentStep: 0),
        const SizedBox(height: ArenaSpacing.md),
        Text('Step 3/4', style: ArenaText.inputLabel),
        const SizedBox(height: ArenaSpacing.xs),
        const ArenaStepper(totalSteps: 4, currentStep: 2),
        const SizedBox(height: ArenaSpacing.md),
        Text('Step 5/5 (final)', style: ArenaText.inputLabel),
        const SizedBox(height: ArenaSpacing.xs),
        const ArenaStepper(totalSteps: 5, currentStep: 4),
      ],
    );
  }
}

class _BannerGallery extends StatelessWidget {
  const _BannerGallery();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        ArenaBanner(
          game: ArenaBannerGame.efoot,
          title: 'Cameroon eFootball Cup',
          subtitle: '12 / 16 joueurs · Récompense 25 000 XAF',
        ),
        SizedBox(height: ArenaSpacing.sm),
        ArenaBanner(
          game: ArenaBannerGame.draughts,
          title: 'Jeu de Dames Africa',
          subtitle: '8 / 32 joueurs · Récompense 50 000 XAF',
        ),
        SizedBox(height: ArenaSpacing.sm),
        ArenaBanner(
          game: ArenaBannerGame.fc,
          title: 'Mobile FC',
          subtitle: 'Bientôt · 64 places',
        ),
      ],
    );
  }
}

class _FloatingBtnGallery extends StatelessWidget {
  const _FloatingBtnGallery();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ArenaFloatingButton(
        onTap: () {},
        timer: '04:32',
      ),
    );
  }
}

class _DividerGallery extends StatelessWidget {
  const _DividerGallery();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: ArenaSpacing.sm),
          color: ArenaColors.carbon,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: ArenaSpacing.md,
                  vertical: ArenaSpacing.sm,
                ),
                child: Text('Section A', style: ArenaText.body),
              ),
              const ArenaDivider(),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: ArenaSpacing.md,
                  vertical: ArenaSpacing.sm,
                ),
                child: Text('Section B', style: ArenaText.body),
              ),
              const ArenaDivider(hi: true, indent: 16, endIndent: 16),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: ArenaSpacing.md,
                  vertical: ArenaSpacing.sm,
                ),
                child: Text('Section C', style: ArenaText.body),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DialogGallery extends StatelessWidget {
  const _DialogGallery();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ArenaButton(
        label: 'Ouvrir le dialog',
        onPressed: () {
          ArenaDialog.show<void>(
            context,
            title: 'Long press sur le bouton',
            content: const Text(
              'Choisis une action sur ton match en cours.',
            ),
            actions: [
              ArenaButton(
                label: 'Continuer',
                onPressed: () => Navigator.maybePop(context),
                fullWidth: true,
              ),
              ArenaButton(
                label: 'Pause',
                onPressed: () => Navigator.maybePop(context),
                variant: ArenaButtonVariant.secondary,
                fullWidth: true,
              ),
              ArenaButton(
                label: 'Forfait',
                onPressed: () => Navigator.maybePop(context),
                variant: ArenaButtonVariant.danger,
                fullWidth: true,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _PhoneFrameGallery extends StatelessWidget {
  const _PhoneFrameGallery();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ArenaPhoneFrame(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            ArenaSpacing.lg,
            48,
            ArenaSpacing.lg,
            ArenaSpacing.lg,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const ArenaLogo(fontSize: 36, letterSpacing: 4),
              const SizedBox(height: ArenaSpacing.md),
              Text('PIXEL-PERFECT FRAME', style: ArenaText.h2),
              const SizedBox(height: ArenaSpacing.sm),
              Text(
                'Wraps any screen for /_dev visual reference.',
                style: ArenaText.bodyMuted,
              ),
            ],
          ),
        ),
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
