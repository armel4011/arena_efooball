import 'package:arena/core/i18n/i18n_service.dart';
import 'package:arena/core/router/user_router.dart';
import 'package:arena/core/theme/arena_theme.dart';
import 'package:arena/core/utils/supported_countries.dart';
import 'package:arena/data/repositories/auth_failure.dart';
import 'package:arena/features_shared/widgets/arena_app_bar.dart';
import 'package:arena/features_shared/widgets/arena_avatar.dart';
import 'package:arena/features_shared/widgets/arena_button.dart';
import 'package:arena/features_shared/widgets/arena_screen_background.dart';
import 'package:arena/features_shared/widgets/arena_stepper.dart';
import 'package:arena/features_shared/widgets/arena_text_field.dart';
import 'package:arena/features_shared/widgets/google_sign_in_button.dart';
import 'package:arena/features_user/auth/auth_providers.dart';
import 'package:arena/features_user/auth/widgets/auth_error_banner.dart';
import 'package:arena/features_user/auth/widgets/auth_failure_message.dart';
import 'package:arena/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

const _cguVersion = '2026-05-01';

class RegisterUserScreen extends ConsumerStatefulWidget {
  const RegisterUserScreen({super.key});

  @override
  ConsumerState<RegisterUserScreen> createState() => _RegisterUserScreenState();
}

class _RegisterUserScreenState extends ConsumerState<RegisterUserScreen> {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _passwordConfirmCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();
  final _whatsappCtrl = TextEditingController();

  String _countryCode = 'CM';
  ArenaAvatarColor _avatarColor = ArenaAvatarColor.blue;
  bool _cguAccepted = false;
  bool _privacyAccepted = false;
  bool _marketingAccepted = false;
  int _step = 0;

  // Lot D.1 — Code de parrainage optionnel (ARN-XXXX) saisi au signup.
  // Stocké en `profiles.referred_by` lors du INSERT.
  final _referralCodeCtrl = TextEditingController();

  late final List<TextEditingController> _ctrls = [
    _emailCtrl,
    _passwordCtrl,
    _passwordConfirmCtrl,
    _usernameCtrl,
    _whatsappCtrl,
    _referralCodeCtrl,
  ];

  @override
  void initState() {
    super.initState();
    for (final c in _ctrls) {
      c.addListener(_onFieldChanged);
    }
  }

  void _onFieldChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    for (final c in _ctrls) {
      c
        ..removeListener(_onFieldChanged)
        ..dispose();
    }
    super.dispose();
  }

  String _initialFromUsername() {
    final v = _usernameCtrl.text.trim();
    return v.isEmpty ? '?' : v[0].toUpperCase();
  }

  void _next() => setState(() => _step += 1);
  void _back() {
    if (_step == 0) {
      context.goNamed('user.login');
    } else {
      setState(() => _step -= 1);
    }
  }

  Future<void> _submit() async {
    final now = DateTime.now().toUtc();
    final locale = ref.read(currentLocaleProvider);
    final referral = _referralCodeCtrl.text.trim().toUpperCase();
    await ref.read(signUpControllerProvider.notifier).signUp(
          email: _emailCtrl.text,
          password: _passwordCtrl.text,
          username: _usernameCtrl.text.trim(),
          countryCode: _countryCode,
          preferredLanguage: locale.locale.languageCode,
          preferredCurrency: 'XAF', // can be adjusted later by feature flags
          whatsappNumber: buildE164Phone(
            countryCode: _countryCode,
            local: _whatsappCtrl.text,
          ),
          cguAcceptedAt: now,
          cguVersionAccepted: _cguVersion,
          privacyPolicyAcceptedAt: now,
          marketingConsent: _marketingAccepted,
          referredBy: referral.isEmpty ? null : referral,
        );
    if (mounted &&
        ref.read(signUpControllerProvider).hasValue &&
        ref.read(signUpControllerProvider).value != null) {
      setState(() => _step = 2);
    }
  }

  Future<void> _submitGoogle() async {
    FocusScope.of(context).unfocus();
    await ref.read(googleSsoControllerProvider.notifier).signIn();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(signUpControllerProvider);
    final googleState = ref.watch(googleSsoControllerProvider);
    final isLoading = state.isLoading || googleState.isLoading;
    final errorMessage = state.hasError
        ? authFailureToMessage(_asFailure(state.error))
        : googleState.hasError
            ? authFailureToMessage(_asFailure(googleState.error))
            : null;

    return Scaffold(
      appBar: ArenaAppBar(
        title: 'Étape ${_step + 1} / 3',
        showBack: _step < 2 && !isLoading,
        onBack: _back,
      ),
      body: ArenaScreenBackground(
        child: SafeArea(
          child: Column(
            children: [
              // Visual stepper above the form so the user can read progress
              // without parsing the AppBar copy. Locked to 3 steps per the
              // master prompt; success page also rides on the last bar.
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  ArenaSpacing.lg,
                  ArenaSpacing.sm,
                  ArenaSpacing.lg,
                  0,
                ),
                child: ArenaStepper(totalSteps: 3, currentStep: _step),
              ),
              Expanded(
                child: switch (_step) {
                  0 => _AccountStep(
                      emailCtrl: _emailCtrl,
                      passwordCtrl: _passwordCtrl,
                      passwordConfirmCtrl: _passwordConfirmCtrl,
                      onNext: _next,
                      onGoogle: _submitGoogle,
                      googleLoading: googleState.isLoading,
                      isLoading: isLoading,
                    ),
                  1 => _ProfileStep(
                      referralCodeCtrl: _referralCodeCtrl,
                      usernameCtrl: _usernameCtrl,
                      whatsappCtrl: _whatsappCtrl,
                      countryCode: _countryCode,
                      onCountry: (c) => setState(() => _countryCode = c),
                      avatarColor: _avatarColor,
                      onAvatarColor: (c) => setState(() => _avatarColor = c),
                      initial: _initialFromUsername(),
                      cgu: _cguAccepted,
                      privacy: _privacyAccepted,
                      marketing: _marketingAccepted,
                      onCgu: (v) => setState(() => _cguAccepted = v),
                      onPrivacy: (v) => setState(() => _privacyAccepted = v),
                      onMarketing: (v) =>
                          setState(() => _marketingAccepted = v),
                      errorMessage: errorMessage,
                      onSubmit: _submit,
                      isLoading: isLoading,
                    ),
                  _ => const _SuccessStep(),
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

AuthFailure _asFailure(Object? error) {
  if (error is AuthFailure) return error;
  return UnknownAuthFailure(error);
}

// ─── Step 1 ─────────────────────────────────────────────────────────────

class _AccountStep extends StatelessWidget {
  const _AccountStep({
    required this.emailCtrl,
    required this.passwordCtrl,
    required this.passwordConfirmCtrl,
    required this.onNext,
    required this.onGoogle,
    required this.googleLoading,
    required this.isLoading,
  });

  final TextEditingController emailCtrl;
  final TextEditingController passwordCtrl;
  final TextEditingController passwordConfirmCtrl;
  final VoidCallback onNext;
  final Future<void> Function() onGoogle;
  final bool googleLoading;
  final bool isLoading;

  String? _emailError(String value, AppLocalizations l10n) {
    if (value.isEmpty) return l10n.registerEmailRequired;
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value)) {
      return l10n.registerEmailInvalid;
    }
    return null;
  }

  String? _passwordError(String value, AppLocalizations l10n) {
    if (value.length < 8) return l10n.registerPasswordTooShort;
    return null;
  }

  String? _confirmError(AppLocalizations l10n) {
    if (passwordConfirmCtrl.text != passwordCtrl.text) {
      return l10n.registerPasswordMismatch;
    }
    return null;
  }

  bool _canSubmit(AppLocalizations l10n) =>
      _emailError(emailCtrl.text, l10n) == null &&
      _passwordError(passwordCtrl.text, l10n) == null &&
      _confirmError(l10n) == null;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return _StepShell(
      title: l10n.registerAccountStepTitle,
      subtitle: l10n.registerAccountStepSubtitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GoogleSignInButton(
            label: l10n.registerGoogleSignUp,
            fullWidth: true,
            isLoading: googleLoading,
            onPressed: isLoading ? null : onGoogle,
          ),
          const SizedBox(height: ArenaSpacing.md),
          const _OrDivider(),
          const SizedBox(height: ArenaSpacing.md),
          ArenaTextField(
            label: l10n.registerEmailLabel,
            hint: 'joueur@arena.app',
            controller: emailCtrl,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            prefixIcon: Icons.email_outlined,
            enabled: !isLoading,
            errorText: emailCtrl.text.isEmpty
                ? null
                : _emailError(emailCtrl.text, l10n),
          ),
          const SizedBox(height: ArenaSpacing.md),
          ArenaTextField(
            label: l10n.registerPasswordLabel,
            controller: passwordCtrl,
            obscureText: true,
            textInputAction: TextInputAction.next,
            prefixIcon: Icons.lock_outline,
            enabled: !isLoading,
            errorText: passwordCtrl.text.isEmpty
                ? null
                : _passwordError(passwordCtrl.text, l10n),
          ),
          const SizedBox(height: ArenaSpacing.md),
          ArenaTextField(
            label: l10n.registerPasswordConfirmLabel,
            controller: passwordConfirmCtrl,
            obscureText: true,
            textInputAction: TextInputAction.done,
            prefixIcon: Icons.lock_outline,
            enabled: !isLoading,
            errorText: passwordConfirmCtrl.text.isEmpty
                ? null
                : _confirmError(l10n),
          ),
          const SizedBox(height: ArenaSpacing.xl),
          ArenaButton(
            label: l10n.registerAccountContinueButton,
            fullWidth: true,
            size: ArenaButtonSize.large,
            onPressed: _canSubmit(l10n) ? onNext : null,
          ),
        ],
      ),
    );
  }
}

// ─── Step 2 ─────────────────────────────────────────────────────────────

class _ProfileStep extends StatelessWidget {
  const _ProfileStep({
    required this.usernameCtrl,
    required this.whatsappCtrl,
    required this.referralCodeCtrl,
    required this.countryCode,
    required this.onCountry,
    required this.avatarColor,
    required this.onAvatarColor,
    required this.initial,
    required this.cgu,
    required this.privacy,
    required this.marketing,
    required this.onCgu,
    required this.onPrivacy,
    required this.onMarketing,
    required this.errorMessage,
    required this.onSubmit,
    required this.isLoading,
  });

  final TextEditingController usernameCtrl;
  final TextEditingController whatsappCtrl;
  final TextEditingController referralCodeCtrl;
  final String countryCode;
  final ValueChanged<String> onCountry;
  final ArenaAvatarColor avatarColor;
  final ValueChanged<ArenaAvatarColor> onAvatarColor;
  final String initial;
  final bool cgu;
  final bool privacy;
  final bool marketing;
  final ValueChanged<bool> onCgu;
  final ValueChanged<bool> onPrivacy;
  final ValueChanged<bool> onMarketing;
  final String? errorMessage;
  final VoidCallback onSubmit;
  final bool isLoading;

  String get _dialCode => dialCodeFor(countryCode);

  bool get _isWhatsappValid => isLocalPhoneValid(whatsappCtrl.text);

  bool get _canSubmit =>
      cgu &&
      privacy &&
      usernameCtrl.text.trim().length >= 3 &&
      usernameCtrl.text.trim().length <= 20 &&
      _isWhatsappValid;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return _StepShell(
      title: l10n.registerProfileStepTitle,
      subtitle: l10n.registerProfileStepSubtitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ArenaTextField(
            label: l10n.registerUsernameLabel,
            hint: l10n.registerUsernameHint,
            controller: usernameCtrl,
            textInputAction: TextInputAction.next,
            prefixIcon: Icons.person_outline,
            enabled: !isLoading,
            maxLength: 20,
          ),
          const SizedBox(height: ArenaSpacing.md),
          _CountryPicker(
            selected: countryCode,
            onSelect: onCountry,
            options: kSupportedCountries,
            isLoading: isLoading,
          ),
          const SizedBox(height: ArenaSpacing.md),
          ArenaTextField(
            label: 'WHATSAPP ($_dialCode)',
            hint: l10n.registerWhatsappHint,
            helper: 'Le code pays $_dialCode est ajouté automatiquement.',
            controller: whatsappCtrl,
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.done,
            prefixIcon: Icons.chat_outlined,
            enabled: !isLoading,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[\d\s]')),
            ],
            errorText: whatsappCtrl.text.isEmpty || _isWhatsappValid
                ? null
                : l10n.registerWhatsappInvalid,
          ),
          const SizedBox(height: ArenaSpacing.md),
          Text(l10n.registerAvatarColorLabel, style: ArenaText.inputLabel),
          const SizedBox(height: ArenaSpacing.sm),
          _AvatarColorPicker(
            initial: initial,
            selected: avatarColor,
            onSelect: onAvatarColor,
            disabled: isLoading,
          ),
          const SizedBox(height: ArenaSpacing.md),
          ArenaTextField(
            label: l10n.registerReferralCodeLabel,
            hint: l10n.registerReferralCodeHint,
            helper: l10n.registerReferralCodeHelper,
            controller: referralCodeCtrl,
            prefixIcon: Icons.group_outlined,
            enabled: !isLoading,
            maxLength: 12,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9\-]')),
            ],
          ),
          const SizedBox(height: ArenaSpacing.md),
          _ConsentTile(
            title: l10n.registerCguConsent,
            value: cgu,
            onChanged: isLoading ? null : onCgu,
            mandatory: true,
          ),
          _ConsentTile(
            title: l10n.registerPrivacyConsent,
            value: privacy,
            onChanged: isLoading ? null : onPrivacy,
            mandatory: true,
          ),
          _ConsentTile(
            title: l10n.registerMarketingConsent,
            value: marketing,
            onChanged: isLoading ? null : onMarketing,
          ),
          if (errorMessage != null) ...[
            const SizedBox(height: ArenaSpacing.sm),
            AuthErrorBanner(message: errorMessage!),
          ],
          const SizedBox(height: ArenaSpacing.xl),
          ArenaButton(
            label: l10n.registerCreateAccountButton,
            fullWidth: true,
            size: ArenaButtonSize.large,
            isLoading: isLoading,
            onPressed: _canSubmit ? onSubmit : null,
          ),
        ],
      ),
    );
  }
}

class _AvatarColorPicker extends StatelessWidget {
  const _AvatarColorPicker({
    required this.initial,
    required this.selected,
    required this.onSelect,
    required this.disabled,
  });

  final String initial;
  final ArenaAvatarColor selected;
  final ValueChanged<ArenaAvatarColor> onSelect;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: ArenaSpacing.sm,
      runSpacing: ArenaSpacing.sm,
      children: [
        for (final c in ArenaAvatarColor.values)
          GestureDetector(
            onTap: disabled ? null : () => onSelect(c),
            child: ArenaAvatar(
              initials: c == selected ? initial : '',
              color: c,
              selected: c == selected,
            ),
          ),
      ],
    );
  }
}

class _CountryPicker extends StatelessWidget {
  const _CountryPicker({
    required this.selected,
    required this.onSelect,
    required this.options,
    required this.isLoading,
  });

  final String selected;
  final ValueChanged<String> onSelect;
  final List<SupportedCountry> options;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.registerCountryLabel, style: ArenaTypography.labelMedium),
        const SizedBox(height: ArenaSpacing.sm),
        DropdownButtonFormField<String>(
          initialValue: selected,
          isExpanded: true,
          dropdownColor: ArenaColors.surfaceLight,
          onChanged: isLoading ? null : (v) => v == null ? null : onSelect(v),
          items: [
            for (final c in options)
              DropdownMenuItem(
                value: c.code,
                child: Row(
                  children: [
                    Text(
                      c.flag,
                      style: ArenaTypography.bodyLarge.copyWith(fontSize: 20),
                    ),
                    const SizedBox(width: ArenaSpacing.sm),
                    Text(c.name, style: ArenaTypography.bodyLarge),
                  ],
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _ConsentTile extends StatelessWidget {
  const _ConsentTile({
    required this.title,
    required this.value,
    required this.onChanged,
    this.mandatory = false,
  });

  final String title;
  final bool value;
  final ValueChanged<bool>? onChanged;
  final bool mandatory;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: ArenaSpacing.xs),
      child: Row(
        children: [
          Checkbox(
            value: value,
            onChanged: onChanged == null ? null : (v) => onChanged!(v ?? false),
            activeColor: Theme.of(context).colorScheme.primary,
            visualDensity: VisualDensity.compact,
          ),
          Expanded(
            child: GestureDetector(
              onTap: onChanged == null ? null : () => onChanged!(!value),
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(text: title),
                    if (mandatory)
                      TextSpan(
                        text: ' *',
                        style: ArenaTypography.bodySmall.copyWith(
                          color: ArenaColors.danger,
                        ),
                      ),
                  ],
                ),
                style: ArenaTypography.bodySmall.copyWith(
                  color: ArenaColors.text,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Step 3 ─────────────────────────────────────────────────────────────

class _SuccessStep extends StatelessWidget {
  const _SuccessStep();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return _StepShell(
      title: l10n.registerSuccessTitle,
      subtitle: l10n.registerSuccessSubtitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: ArenaSpacing.xxl),
          const Center(
            child: Icon(
              Icons.check_circle_outline,
              size: 96,
              color: ArenaColors.success,
            ),
          ),
          const SizedBox(height: ArenaSpacing.xxl),
          ArenaButton(
            label: l10n.registerSuccessContinueButton,
            fullWidth: true,
            size: ArenaButtonSize.large,
            onPressed: () => context.go(UserRoutes.home),
          ),
        ],
      ),
    );
  }
}

// ─── Shared step layout ─────────────────────────────────────────────────

class _StepShell extends StatelessWidget {
  const _StepShell({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(ArenaSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: ArenaTypography.displayMedium),
          const SizedBox(height: ArenaSpacing.sm),
          Text(
            subtitle,
            style: ArenaTypography.bodyMedium.copyWith(
              color: ArenaColors.textMuted,
            ),
          ),
          const SizedBox(height: ArenaSpacing.xl),
          child,
        ],
      ),
    );
  }
}

class _OrDivider extends StatelessWidget {
  const _OrDivider();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Expanded(child: Divider(color: ArenaColors.border, height: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: ArenaSpacing.md),
          child: Text(l10n.registerOrDivider, style: ArenaText.small),
        ),
        const Expanded(child: Divider(color: ArenaColors.border, height: 1)),
      ],
    );
  }
}
