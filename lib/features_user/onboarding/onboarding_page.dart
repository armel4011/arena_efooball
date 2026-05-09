import 'package:arena/core/theme/arena_theme.dart';
import 'package:arena/features_shared/widgets/arena_button.dart';
import 'package:arena/features_user/onboarding/onboarding_slide.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// First-launch onboarding — 4 swipeable slides.
///
/// Native [PageView] (was `flutter_onboarding_slider` until wave 1 polish)
/// because the package's stepper / button look did not match the v2 design.
/// Layout follows `.onb` in `arena_v2.html`: column space-between, emoji +
/// h1 + p centered in the middle, custom dots + SUIVANT/Passer fixed at the
/// bottom.
///
/// Stateless from a data POV: [onFinish] is called when the user taps
/// PASSER on any slide or COMMENCER on the last one. Persistence and
/// navigation are the parent's responsibility (`OnboardingGate`).
class OnboardingPage extends StatefulWidget {
  const OnboardingPage({required this.onFinish, super.key});

  final VoidCallback onFinish;

  static const _slides = <OnboardingSlideData>[
    OnboardingSlideData(
      emoji: '⚽',
      title: 'TOURNOIS E-SPORT PANAFRICAINS',
      description: 'Bienvenue sur ARENA, la plateforme #1 de tournois '
          'eFootball, FIFA Mobile et FC Mobile en Afrique.',
    ),
    OnboardingSlideData(
      emoji: '🏆',
      title: 'DES BRACKETS, DE VRAIS DUELS',
      description: "Élimination directe ou phase de groupes : grimpe l'arbre"
          ' du tournoi et bats tous tes adversaires pour la récompense.',
    ),
    OnboardingSlideData(
      emoji: '📱',
      title: 'CODE DE ROOM PARTAGÉ',
      description: "Tu partages ton code de room dans le jeu, vous vous"
          ' affrontez, puis vous validez le score à deux dans ARENA.',
    ),
    OnboardingSlideData(
      emoji: '💰',
      title: 'RÉCOMPENSES VERSÉES DIRECT',
      description: 'Obtenez des récompenses même dans des compétitions à'
          ' inscription gratuite et divertissez-vous.',
    ),
  ];

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final _controller = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _isLast => _currentPage == OnboardingPage._slides.length - 1;

  void _next() {
    if (_isLast) {
      widget.onFinish();
    } else {
      _controller.nextPage(
        duration: ArenaDurations.medium,
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Solid void scaffold so the radial blue wash below has somewhere to
      // sit. The wash mirrors the same trick used on the splash screen:
      // a soft signal-blue glow centred slightly above the middle of the
      // viewport (where the emoji hero lives), fading to void at 70 %.
      backgroundColor: ArenaColors.void_,
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(0, -0.25),
            radius: 0.6,
            colors: [
              ArenaColors.signalBlue.withValues(alpha: 0.10),
              ArenaColors.void_,
            ],
            stops: const [0, 0.5],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: PageView(
                  controller: _controller,
                  onPageChanged: (i) => setState(() => _currentPage = i),
                  children: [
                    for (final s in OnboardingPage._slides)
                      OnboardingSlide(data: s)
                          .animate(key: ValueKey(s.title))
                          .fadeIn(duration: ArenaDurations.medium)
                          .slideY(
                            begin: 0.05,
                            end: 0,
                            curve: Curves.easeOutCubic,
                          ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 14, 22, 28),
                child: Column(
                  children: [
                    _OnboardingDots(
                      total: OnboardingPage._slides.length,
                      current: _currentPage,
                    ),
                    const SizedBox(height: ArenaSpacing.lg),
                    ArenaButton(
                      label: _isLast ? 'COMMENCER' : 'SUIVANT',
                      fullWidth: true,
                      size: ArenaButtonSize.large,
                      onPressed: _next,
                    ),
                    const SizedBox(height: ArenaSpacing.xs),
                    ArenaButton(
                      label: 'Ignorer',
                      fullWidth: true,
                      variant: ArenaButtonVariant.ghost,
                      onPressed: widget.onFinish,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Custom 4-dot indicator matching `.onb-dots` / `.onb-dot` in
/// `arena_v2.html` — inactive dots are 6×6 silverDim circles, the active
/// dot stretches to a 22×6 pill in signalBlue with a soft glow.
class _OnboardingDots extends StatelessWidget {
  const _OnboardingDots({required this.total, required this.current});

  final int total;
  final int current;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < total; i++) ...[
          if (i > 0) const SizedBox(width: 5),
          AnimatedContainer(
            duration: ArenaDurations.short,
            curve: Curves.easeOutCubic,
            width: i == current ? 22 : 6,
            height: 6,
            decoration: BoxDecoration(
              color: i == current
                  ? ArenaColors.signalBlue
                  : ArenaColors.silverDim,
              borderRadius: BorderRadius.circular(3),
              boxShadow: i == current
                  ? [
                      BoxShadow(
                        color: ArenaColors.signalBlue.withValues(alpha: 0.4),
                        blurRadius: 8,
                      ),
                    ]
                  : null,
            ),
          ),
        ],
      ],
    );
  }
}
