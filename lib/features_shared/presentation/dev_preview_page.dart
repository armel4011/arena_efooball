import 'package:arena/core/i18n/currency.dart';
import 'package:arena/core/i18n/currency_service.dart';
import 'package:arena/core/i18n/feature_flags_service.dart';
import 'package:arena/core/i18n/i18n_service.dart';
import 'package:arena/core/theme/arena_theme.dart';
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

part 'dev_preview_galleries.dart';
part 'dev_preview_theme.dart';

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
