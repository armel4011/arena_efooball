import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingService {
  const OnboardingService(this._prefs);

  static const _keyCompleted = 'onboarding_completed';

  final SharedPreferences _prefs;

  bool isCompleted() => _prefs.getBool(_keyCompleted) ?? false;

  Future<void> markCompleted() => _prefs.setBool(_keyCompleted, true);

  /// Useful for the future "Replay onboarding" toggle in Settings (PHASE 9).
  Future<void> reset() => _prefs.remove(_keyCompleted);
}

/// SharedPreferences instance, loaded once in `bootstrap()` and injected
/// via `ProviderScope.overrides`. Reading without an override throws —
/// the override is mandatory.
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError(
    'sharedPreferencesProvider must be overridden in ProviderScope. '
    'See bootstrap.dart.',
  );
});

final onboardingServiceProvider = Provider<OnboardingService>((ref) {
  return OnboardingService(ref.watch(sharedPreferencesProvider));
});

/// Synchronous "onboarding completed?" controller. Notify with
/// `markCompleted()` after the user finishes the flow.
class OnboardingFlagController extends Notifier<bool> {
  @override
  bool build() => ref.watch(onboardingServiceProvider).isCompleted();

  Future<void> markCompleted() async {
    await ref.read(onboardingServiceProvider).markCompleted();
    state = true;
  }

  Future<void> reset() async {
    await ref.read(onboardingServiceProvider).reset();
    state = false;
  }
}

final onboardingCompletedProvider =
    NotifierProvider<OnboardingFlagController, bool>(
  OnboardingFlagController.new,
);
