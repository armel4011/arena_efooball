import 'package:arena/core/i18n/currency.dart';
import 'package:arena/core/i18n/currency_service.dart';
import 'package:arena/core/i18n/feature_flags_service.dart';
import 'package:arena/core/i18n/i18n_service.dart';
import 'package:arena/core/theme/arena_colors.dart';
import 'package:arena/core/theme/arena_theme.dart';
import 'package:arena/core/theme/arena_typography.dart';
import 'package:arena/features_shared/widgets/arena_app_bar.dart';
import 'package:arena/features_shared/widgets/arena_avatar.dart';
import 'package:arena/features_shared/widgets/arena_badge.dart';
import 'package:arena/features_shared/widgets/arena_banner.dart';
import 'package:arena/features_shared/widgets/arena_bottom_nav.dart';
import 'package:arena/features_shared/widgets/arena_button.dart';
import 'package:arena/features_shared/widgets/arena_card.dart';
import 'package:arena/features_shared/widgets/arena_dialog.dart';
import 'package:arena/features_shared/widgets/arena_divider.dart';
import 'package:arena/features_shared/widgets/arena_floating_button.dart';
import 'package:arena/features_shared/widgets/arena_loading_indicator.dart';
import 'package:arena/features_shared/widgets/arena_phone_frame.dart';
import 'package:arena/features_shared/widgets/arena_stepper.dart';
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
          SizedBox(height: ArenaSpacing.xl),
          _Section(title: 'AVATARS', child: _AvatarsGallery()),
          SizedBox(height: ArenaSpacing.xl),
          _Section(title: 'BADGES', child: _BadgesGallery()),
          SizedBox(height: ArenaSpacing.xl),
          _Section(title: 'APP BAR', child: _AppBarGallery()),
          SizedBox(height: ArenaSpacing.xl),
          _Section(title: 'BOTTOM NAV', child: _BottomNavGallery()),
          SizedBox(height: ArenaSpacing.xl),
          _Section(title: 'STEPPER', child: _StepperGallery()),
          SizedBox(height: ArenaSpacing.xl),
          _Section(title: 'BANNERS GAME', child: _BannerGallery()),
          SizedBox(height: ArenaSpacing.xl),
          _Section(title: 'FLOATING BTN (#17)', child: _FloatingBtnGallery()),
          SizedBox(height: ArenaSpacing.xl),
          _Section(title: 'DIVIDER', child: _DividerGallery()),
          SizedBox(height: ArenaSpacing.xl),
          _Section(title: 'DIALOG', child: _DialogGallery()),
          SizedBox(height: ArenaSpacing.xl),
          _Section(title: 'PHONE FRAME', child: _PhoneFrameGallery()),
          SizedBox(height: ArenaSpacing.xxl),
        ],
      ),
    );
  }
}

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
          subtitle: '12 / 16 joueurs · Cagnotte 25 000 XAF',
        ),
        SizedBox(height: ArenaSpacing.sm),
        ArenaBanner(
          game: ArenaBannerGame.fifa,
          title: 'FIFA Mobile Africa',
          subtitle: '8 / 32 joueurs · Cagnotte 50 000 XAF',
        ),
        SizedBox(height: ArenaSpacing.sm),
        ArenaBanner(
          game: ArenaBannerGame.fc,
          title: 'EA SPORTS FC Mobile',
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
