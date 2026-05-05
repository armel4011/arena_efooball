import 'package:arena/core/services/onboarding_service.dart';
import 'package:arena/features_user/onboarding/onboarding_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Decides between [OnboardingPage] and the post-onboarding screen based
/// on the persisted "completed" flag.
///
/// PHASE 2 will swap [afterOnboarding] for SplashUserScreen.
class OnboardingGate extends ConsumerWidget {
  const OnboardingGate({required this.afterOnboarding, super.key});

  final Widget afterOnboarding;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final completed = ref.watch(onboardingCompletedProvider);
    if (completed) return afterOnboarding;
    return OnboardingPage(
      onFinish: ref.read(onboardingCompletedProvider.notifier).markCompleted,
    );
  }
}
