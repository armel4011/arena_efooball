import 'package:arena/core/i18n/i18n_service.dart';
import 'package:arena/core/router/user_router.dart';
import 'package:arena/core/theme/arena_theme.dart';
import 'package:arena/data/repositories/auth_failure.dart';
import 'package:arena/features_shared/widgets/arena_app_bar.dart';
import 'package:arena/features_shared/widgets/arena_avatar.dart';
import 'package:arena/features_shared/widgets/arena_button.dart';
import 'package:arena/features_shared/widgets/arena_stepper.dart';
import 'package:arena/features_shared/widgets/arena_text_field.dart';
import 'package:arena/features_shared/widgets/google_sign_in_button.dart';
import 'package:arena/features_user/auth/auth_providers.dart';
import 'package:arena/features_user/auth/widgets/auth_failure_message.dart';
import 'package:flutter/material.dart';
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

  String _countryCode = 'CM';
  ArenaAvatarColor _avatarColor = ArenaAvatarColor.blue;
  bool _cguAccepted = false;
  bool _privacyAccepted = false;
  bool _marketingAccepted = false;
  int _step = 0;

  late final List<TextEditingController> _ctrls = [
    _emailCtrl,
    _passwordCtrl,
    _passwordConfirmCtrl,
    _usernameCtrl,
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
      c.removeListener(_onFieldChanged);
      c.dispose();
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
    await ref.read(signUpControllerProvider.notifier).signUp(
          email: _emailCtrl.text,
          password: _passwordCtrl.text,
          username: _usernameCtrl.text.trim(),
          countryCode: _countryCode,
          preferredLanguage: locale.locale.languageCode,
          preferredCurrency: 'XAF', // can be adjusted later by feature flags
          cguAcceptedAt: now,
          cguVersionAccepted: _cguVersion,
          privacyPolicyAcceptedAt: now,
          marketingConsent: _marketingAccepted,
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
      body: SafeArea(
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
                    usernameCtrl: _usernameCtrl,
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
                    onMarketing: (v) => setState(() => _marketingAccepted = v),
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

  String? _emailError(String value) {
    if (value.isEmpty) return 'Email requis.';
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value)) {
      return 'Format email invalide.';
    }
    return null;
  }

  String? _passwordError(String value) {
    if (value.length < 8) return '8 caractères minimum.';
    return null;
  }

  String? _confirmError() {
    if (passwordConfirmCtrl.text != passwordCtrl.text) {
      return 'Les mots de passe ne correspondent pas.';
    }
    return null;
  }

  bool get _canSubmit =>
      _emailError(emailCtrl.text) == null &&
      _passwordError(passwordCtrl.text) == null &&
      _confirmError() == null;

  @override
  Widget build(BuildContext context) {
    return _StepShell(
      title: 'CRÉE\nTON COMPTE',
      subtitle: 'Email + mot de passe (8 caractères minimum).',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GoogleSignInButton(
            label: "S'inscrire avec Google",
            fullWidth: true,
            isLoading: googleLoading,
            onPressed: isLoading ? null : onGoogle,
          ),
          const SizedBox(height: ArenaSpacing.md),
          const _OrDivider(),
          const SizedBox(height: ArenaSpacing.md),
          ArenaTextField(
            label: 'EMAIL',
            hint: 'joueur@arena.app',
            controller: emailCtrl,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            prefixIcon: Icons.email_outlined,
            enabled: !isLoading,
            errorText: emailCtrl.text.isEmpty
                ? null
                : _emailError(emailCtrl.text),
          ),
          const SizedBox(height: ArenaSpacing.md),
          ArenaTextField(
            label: 'MOT DE PASSE',
            controller: passwordCtrl,
            obscureText: true,
            textInputAction: TextInputAction.next,
            prefixIcon: Icons.lock_outline,
            enabled: !isLoading,
            errorText: passwordCtrl.text.isEmpty
                ? null
                : _passwordError(passwordCtrl.text),
          ),
          const SizedBox(height: ArenaSpacing.md),
          ArenaTextField(
            label: 'CONFIRMER LE MOT DE PASSE',
            controller: passwordConfirmCtrl,
            obscureText: true,
            textInputAction: TextInputAction.done,
            prefixIcon: Icons.lock_outline,
            enabled: !isLoading,
            errorText: passwordConfirmCtrl.text.isEmpty ? null : _confirmError(),
          ),
          const SizedBox(height: ArenaSpacing.xl),
          ArenaButton(
            label: 'CONTINUER',
            fullWidth: true,
            size: ArenaButtonSize.large,
            onPressed: _canSubmit ? onNext : null,
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

  static const _countries = <_Country>[
    _Country('CM', 'Cameroun', '🇨🇲'),
    _Country('SN', 'Sénégal', '🇸🇳'),
    _Country('CI', "Côte d'Ivoire", '🇨🇮'),
    _Country('GA', 'Gabon', '🇬🇦'),
    _Country('BJ', 'Bénin', '🇧🇯'),
    _Country('TG', 'Togo', '🇹🇬'),
    _Country('BF', 'Burkina Faso', '🇧🇫'),
    _Country('ML', 'Mali', '🇲🇱'),
    _Country('NE', 'Niger', '🇳🇪'),
    _Country('TD', 'Tchad', '🇹🇩'),
    _Country('GN', 'Guinée', '🇬🇳'),
    _Country('CD', 'RD Congo', '🇨🇩'),
    _Country('MG', 'Madagascar', '🇲🇬'),
  ];

  bool get _canSubmit =>
      cgu &&
      privacy &&
      usernameCtrl.text.trim().length >= 3 &&
      usernameCtrl.text.trim().length <= 20;

  @override
  Widget build(BuildContext context) {
    return _StepShell(
      title: 'TON\nPROFIL',
      subtitle: 'Pseudo + pays + acceptation des CGU.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ArenaTextField(
            label: 'PSEUDO',
            hint: '3 à 20 caractères',
            controller: usernameCtrl,
            textInputAction: TextInputAction.done,
            prefixIcon: Icons.person_outline,
            enabled: !isLoading,
            maxLength: 20,
          ),
          const SizedBox(height: ArenaSpacing.md),
          _CountryPicker(
            selected: countryCode,
            onSelect: onCountry,
            options: _countries,
            isLoading: isLoading,
          ),
          const SizedBox(height: ArenaSpacing.md),
          Text("COULEUR D'AVATAR", style: ArenaText.inputLabel),
          const SizedBox(height: ArenaSpacing.sm),
          _AvatarColorPicker(
            initial: initial,
            selected: avatarColor,
            onSelect: onAvatarColor,
            disabled: isLoading,
          ),
          const SizedBox(height: ArenaSpacing.md),
          _ConsentTile(
            title: "J'accepte les Conditions Générales d'Utilisation",
            value: cgu,
            onChanged: isLoading ? null : onCgu,
            mandatory: true,
          ),
          _ConsentTile(
            title: "J'accepte la Politique de Confidentialité",
            value: privacy,
            onChanged: isLoading ? null : onPrivacy,
            mandatory: true,
          ),
          _ConsentTile(
            title: "J'accepte de recevoir les communications marketing (optionnel)",
            value: marketing,
            onChanged: isLoading ? null : onMarketing,
          ),
          if (errorMessage != null) ...[
            const SizedBox(height: ArenaSpacing.sm),
            _ErrorBanner(message: errorMessage!),
          ],
          const SizedBox(height: ArenaSpacing.xl),
          ArenaButton(
            label: 'CRÉER MON COMPTE',
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

class _Country {
  const _Country(this.code, this.name, this.flag);
  final String code;
  final String name;
  final String flag;
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
  final List<_Country> options;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('PAYS', style: ArenaTypography.labelMedium),
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
    return _StepShell(
      title: 'COMPTE\nCRÉÉ',
      subtitle: 'Bienvenue sur ARENA. Tu es prêt à rejoindre les tournois.',
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
            label: 'CONTINUER',
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
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Expanded(child: Divider(color: ArenaColors.border, height: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: ArenaSpacing.md),
          child: Text('OU', style: ArenaText.small),
        ),
        const Expanded(child: Divider(color: ArenaColors.border, height: 1)),
      ],
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(ArenaSpacing.md),
      decoration: BoxDecoration(
        color: ArenaColors.danger.withValues(alpha: 0.12),
        borderRadius: ArenaRadius.button,
        border: Border.all(color: ArenaColors.danger.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: ArenaColors.danger, size: 20),
          const SizedBox(width: ArenaSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: ArenaTypography.bodySmall.copyWith(
                color: ArenaColors.danger,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
