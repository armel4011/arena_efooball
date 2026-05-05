import 'package:arena/core/theme/arena_colors.dart';
import 'package:arena/features_user/onboarding/onboarding_slide.dart';
import 'package:flutter/material.dart';
import 'package:flutter_onboarding_slider/flutter_onboarding_slider.dart';
import 'package:google_fonts/google_fonts.dart';

/// First-launch onboarding — 4 illustrated slides.
///
/// Stateless from a data POV: the parent (OnboardingGate) owns the
/// "completed" flag and reacts to [onFinish].
class OnboardingPage extends StatelessWidget {
  const OnboardingPage({required this.onFinish, super.key});

  /// Fired when the user taps PASSER on any slide or COMMENCER on the last.
  /// Persistence and navigation are the parent's responsibility.
  final VoidCallback onFinish;

  static const _slides = <_SlideContent>[
    _SlideContent(
      title: 'BIENVENUE\nSUR ARENA',
      description: 'La plateforme africaine de tournois e-sport mobile sur '
          'eFootball, FIFA Mobile et EA SPORTS FC Mobile.',
      icon: Icons.sports_esports,
      accent: ArenaColors.primary,
    ),
    _SlideContent(
      title: 'BRACKETS\nAUTOMATIQUES',
      description: 'Single élimination, phase de groupes, round robin — '
          'l’app gère le tirage et les avancées.',
      icon: Icons.account_tree,
      accent: ArenaColors.efootball,
    ),
    _SlideContent(
      title: 'CODE DE\nROOM PARTAGÉ',
      description: 'Tu partages ton code eFootball, vous jouez le match, '
          'puis vous validez le score à deux.',
      icon: Icons.qr_code_2,
      accent: ArenaColors.fifa,
    ),
    _SlideContent(
      title: 'GAINS DU\nTOP 4',
      description: 'Versement direct vers ton MTN MoMo, Orange Money ou Wave '
          'dès la fin du tournoi.',
      icon: Icons.emoji_events,
      accent: ArenaColors.success,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return OnBoardingSlider(
      totalPage: _slides.length,
      headerBackgroundColor: ArenaColors.bg,
      pageBackgroundColor: ArenaColors.bg,
      speed: 1.8,
      background: List<Widget>.filled(_slides.length, const SizedBox.shrink()),
      pageBodies: [
        for (final slide in _slides)
          OnboardingSlide(
            title: slide.title,
            description: slide.description,
            icon: slide.icon,
            accentColor: slide.accent,
          ),
      ],
      controllerColor: ArenaColors.primary,
      skipTextButton: Text(
        'PASSER',
        style: GoogleFonts.nunito(
          color: ArenaColors.textMuted,
          fontSize: 14,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.5,
        ),
      ),
      skipFunctionOverride: onFinish,
      finishButtonText: 'COMMENCER',
      finishButtonStyle: const FinishButtonStyle(
        backgroundColor: ArenaColors.primary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(28)),
        ),
      ),
      finishButtonTextStyle: GoogleFonts.orbitron(
        fontSize: 14,
        fontWeight: FontWeight.w800,
        letterSpacing: 2,
        color: Colors.white,
      ),
      onFinish: onFinish,
    );
  }
}

class _SlideContent {
  const _SlideContent({
    required this.title,
    required this.description,
    required this.icon,
    required this.accent,
  });

  final String title;
  final String description;
  final IconData icon;
  final Color accent;
}
