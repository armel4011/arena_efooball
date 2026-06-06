import 'package:arena/core/router/user_router.dart';
import 'package:arena/core/theme/arena_theme.dart';
import 'package:arena/features_shared/widgets/arena_avatar.dart';
import 'package:arena/features_shared/widgets/arena_badge.dart';
import 'package:arena/features_shared/widgets/arena_button.dart';
import 'package:arena/features_shared/widgets/arena_card.dart';
import 'package:arena/features_shared/widgets/arena_text_field.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Vitrine du design system Arena (charte premium).
///
/// Route `/dev/showcase` — montée uniquement en `kDebugMode` côté
/// `user_router.dart`. Permet de valider visuellement chaque composant
/// (couleurs, typographie, boutons, cartes, avatars, badges, inputs)
/// sans avoir à parcourir les 53 écrans.
class DesignShowcasePage extends StatelessWidget {
  const DesignShowcasePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ArenaColors.void_,
      appBar: AppBar(
        backgroundColor: ArenaColors.carbon,
        title: Text('Design Showcase', style: ArenaText.appBarTitle),
        iconTheme: const IconThemeData(color: ArenaColors.bone),
      ),
      body: ListView(
        padding: const EdgeInsets.all(ArenaSpacing.md),
        children: [
          // Lien vers les pages de démo additionnelles (bracket showcase
          // ajouté 2026-05-26 pour tester l'arbre arborescent jusqu'à
          // 1024 joueurs sur device).
          ArenaButton(
            label: '🏆 BRACKET SHOWCASE (16 → 1024 joueurs)',
            fullWidth: true,
            onPressed: () => context.push(UserRoutes.devBracketShowcase),
          ),
          const SizedBox(height: ArenaSpacing.lg),
          const _Section(title: 'COULEURS — Neutres', child: _NeutralSwatch()),
          const SizedBox(height: ArenaSpacing.lg),
          const _Section(
            title: 'COULEURS — Brand & Accents',
            child: _BrandSwatch(),
          ),
          const SizedBox(height: ArenaSpacing.lg),
          const _Section(title: 'COULEURS — États', child: _StatusSwatch()),
          const SizedBox(height: ArenaSpacing.lg),
          const _Section(title: 'COULEURS — Jeux', child: _GameSwatch()),
          const SizedBox(height: ArenaSpacing.lg),
          const _Section(title: 'TYPOGRAPHIE', child: _TypoSection()),
          const SizedBox(height: ArenaSpacing.lg),
          const _Section(title: 'BOUTONS', child: _ButtonsSection()),
          const SizedBox(height: ArenaSpacing.lg),
          const _Section(title: 'CARTES', child: _CardsSection()),
          const SizedBox(height: ArenaSpacing.lg),
          const _Section(title: 'AVATARS', child: _AvatarsSection()),
          const SizedBox(height: ArenaSpacing.lg),
          const _Section(title: 'BADGES', child: _BadgesSection()),
          const SizedBox(height: ArenaSpacing.lg),
          const _Section(title: 'CHAMPS DE SAISIE', child: _InputsSection()),
          const SizedBox(height: ArenaSpacing.xl),
        ],
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
        Padding(
          padding: const EdgeInsets.only(bottom: ArenaSpacing.sm),
          child: Text(
            title,
            style: ArenaText.h2.copyWith(color: ArenaColors.pearl),
          ),
        ),
        child,
      ],
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch({required this.label, required this.color, this.textOnTop});
  final String label;
  final Color color;
  final Color? textOnTop;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 92,
      height: 64,
      padding: const EdgeInsets.all(ArenaSpacing.xs),
      decoration: BoxDecoration(
        color: color,
        borderRadius: ArenaRadius.card,
        border: Border.all(color: ArenaColors.border),
      ),
      alignment: Alignment.bottomLeft,
      child: Text(
        label,
        style: ArenaText.small.copyWith(
          color: textOnTop ?? ArenaColors.bone,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _NeutralSwatch extends StatelessWidget {
  const _NeutralSwatch();
  @override
  Widget build(BuildContext context) {
    return const Wrap(
      spacing: ArenaSpacing.sm,
      runSpacing: ArenaSpacing.sm,
      children: [
        _Swatch(label: 'void_', color: ArenaColors.void_),
        _Swatch(label: 'carbon', color: ArenaColors.carbon),
        _Swatch(label: 'carbon2', color: ArenaColors.carbon2),
        _Swatch(label: 'graphite', color: ArenaColors.graphite),
        _Swatch(label: 'steel', color: ArenaColors.steel),
        _Swatch(label: 'silver', color: ArenaColors.silver),
        _Swatch(
          label: 'pearl',
          color: ArenaColors.pearl,
          textOnTop: ArenaColors.void_,
        ),
        _Swatch(
          label: 'bone',
          color: ArenaColors.bone,
          textOnTop: ArenaColors.void_,
        ),
      ],
    );
  }
}

class _BrandSwatch extends StatelessWidget {
  const _BrandSwatch();
  @override
  Widget build(BuildContext context) {
    return const Wrap(
      spacing: ArenaSpacing.sm,
      runSpacing: ArenaSpacing.sm,
      children: [
        _Swatch(label: 'signalBlue', color: ArenaColors.signalBlue),
        _Swatch(label: 'neonRed', color: ArenaColors.neonRed),
        _Swatch(
          label: 'acidGreen',
          color: ArenaColors.acidGreen,
          textOnTop: ArenaColors.void_,
        ),
        _Swatch(label: 'hotCoral', color: ArenaColors.hotCoral),
        _Swatch(
          label: 'iceCyan',
          color: ArenaColors.iceCyan,
          textOnTop: ArenaColors.void_,
        ),
        _Swatch(
          label: 'gold',
          color: ArenaColors.gold,
          textOnTop: ArenaColors.void_,
        ),
      ],
    );
  }
}

class _StatusSwatch extends StatelessWidget {
  const _StatusSwatch();
  @override
  Widget build(BuildContext context) {
    return const Wrap(
      spacing: ArenaSpacing.sm,
      runSpacing: ArenaSpacing.sm,
      children: [
        _Swatch(label: 'statusOk', color: ArenaColors.statusOk),
        _Swatch(
          label: 'statusWarn',
          color: ArenaColors.statusWarn,
          textOnTop: ArenaColors.void_,
        ),
        _Swatch(label: 'statusLive', color: ArenaColors.statusLive),
        _Swatch(label: 'statusOkDeep', color: ArenaColors.statusOkDeep),
        _Swatch(label: 'dangerDeep', color: ArenaColors.statusDangerDeep),
      ],
    );
  }
}

class _GameSwatch extends StatelessWidget {
  const _GameSwatch();
  @override
  Widget build(BuildContext context) {
    return const Wrap(
      spacing: ArenaSpacing.sm,
      runSpacing: ArenaSpacing.sm,
      children: [
        _Swatch(label: 'gameEfoot', color: ArenaColors.gameEfoot),
        _Swatch(label: 'gameDraughts', color: ArenaColors.gameDraughts),
        _Swatch(label: 'gameFc', color: ArenaColors.gameFc),
      ],
    );
  }
}

class _TypoSection extends StatelessWidget {
  const _TypoSection();
  @override
  Widget build(BuildContext context) {
    final entries = <(String, TextStyle)>[
      ('hero — Bebas Neue display', ArenaText.hero),
      ('h1 — Bebas Neue 22', ArenaText.h1),
      ('h2 — Bebas Neue 16', ArenaText.h2),
      ('h3 — Space Grotesk 15 w700', ArenaText.h3),
      ('body — Space Grotesk 13 w500', ArenaText.body),
      ('small — Space Grotesk 11', ArenaText.small),
      ('mono — JetBrains Mono', ArenaText.mono),
      ('serif — Instrument Serif italic', ArenaText.serifTagline),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final (label, style) in entries)
          Padding(
            padding: const EdgeInsets.only(bottom: ArenaSpacing.sm),
            child: Text(label, style: style),
          ),
      ],
    );
  }
}

class _ButtonsSection extends StatelessWidget {
  const _ButtonsSection();
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
          label: 'Success',
          onPressed: () {},
          variant: ArenaButtonVariant.success,
        ),
        const ArenaButton(label: 'Disabled', onPressed: null),
        ArenaButton(label: 'Loading', onPressed: () {}, isLoading: true),
      ],
    );
  }
}

class _CardsSection extends StatelessWidget {
  const _CardsSection();
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ArenaCard(
          child: Text('Carte neutre par défaut', style: ArenaText.body),
        ),
        const SizedBox(height: ArenaSpacing.sm),
        ArenaCard(
          color: ArenaColors.signalBlue.withValues(alpha: 0.12),
          borderColor: ArenaColors.signalBlue.withValues(alpha: 0.4),
          child: Text(
            'Carte glow — accent bleu',
            style: ArenaText.body.copyWith(color: ArenaColors.signalBlue),
          ),
        ),
        const SizedBox(height: ArenaSpacing.sm),
        ArenaCard(
          color: ArenaColors.statusOk.withValues(alpha: 0.10),
          borderColor: ArenaColors.statusOk.withValues(alpha: 0.35),
          child: Text(
            'Carte success — paiement validé',
            style: ArenaText.body.copyWith(color: ArenaColors.statusOk),
          ),
        ),
        const SizedBox(height: ArenaSpacing.sm),
        ArenaCard(
          elevated: true,
          child: Text(
            'Carte elevated (carbon2)',
            style: ArenaText.body,
          ),
        ),
      ],
    );
  }
}

class _AvatarsSection extends StatelessWidget {
  const _AvatarsSection();
  @override
  Widget build(BuildContext context) {
    return const Wrap(
      spacing: ArenaSpacing.md,
      runSpacing: ArenaSpacing.md,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        ArenaAvatar(initials: 'AR', size: ArenaAvatarSize.sm),
        ArenaAvatar(initials: 'EN'),
        ArenaAvatar(
          initials: 'CY',
          color: ArenaAvatarColor.cyan,
          size: ArenaAvatarSize.lg,
        ),
        ArenaAvatar(
          initials: 'PR',
          color: ArenaAvatarColor.purple,
          size: ArenaAvatarSize.xl,
        ),
      ],
    );
  }
}

class _BadgesSection extends StatelessWidget {
  const _BadgesSection();
  @override
  Widget build(BuildContext context) {
    return const Wrap(
      spacing: ArenaSpacing.sm,
      runSpacing: ArenaSpacing.sm,
      children: [
        ArenaBadge(label: 'SUCCESS', variant: ArenaBadgeVariant.success),
        ArenaBadge(label: 'INFO', variant: ArenaBadgeVariant.info),
        ArenaBadge(label: 'WARNING', variant: ArenaBadgeVariant.warn),
        ArenaBadge(label: 'DANGER', variant: ArenaBadgeVariant.danger),
        ArenaBadge(label: 'LIVE', variant: ArenaBadgeVariant.live),
        ArenaBadge(label: 'BRONZE', variant: ArenaBadgeVariant.tierBronze),
      ],
    );
  }
}

class _InputsSection extends StatelessWidget {
  const _InputsSection();
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ArenaTextField(
          label: 'Email',
          hint: 'joueur@example.com',
          controller: TextEditingController(),
        ),
        const SizedBox(height: ArenaSpacing.sm),
        ArenaTextField(
          label: 'Code room',
          hint: 'AB12-CD34',
          controller: TextEditingController(text: 'XY99-ZK01'),
        ),
      ],
    );
  }
}
