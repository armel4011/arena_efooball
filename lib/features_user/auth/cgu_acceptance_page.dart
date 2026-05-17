import 'package:arena/core/router/user_router.dart';
import 'package:arena/core/theme/arena_theme.dart';
import 'package:arena/core/utils/supported_countries.dart';
import 'package:arena/data/repositories/auth_failure.dart';
import 'package:arena/features_shared/widgets/arena_app_bar.dart';
import 'package:arena/features_shared/widgets/arena_button.dart';
import 'package:arena/features_shared/widgets/arena_text_field.dart';
import 'package:arena/features_user/auth/auth_providers.dart';
import 'package:arena/features_user/auth/widgets/auth_failure_message.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Forcée après le premier sign-in pour les comptes SSO (Google) qui
/// arrivent sans `cgu_accepted_at` ni `whatsapp_number`. C'est ici qu'on
/// collecte l'acceptation légale + le pays + le numéro WhatsApp avant
/// de laisser l'utilisateur accéder à l'app.
///
/// Hard-coded CGU version pour V1.0 — gardée en sync avec
/// `register_user_screen.dart`.
const String _kCguVersion = '2026-05-01';

class CguAcceptancePage extends ConsumerStatefulWidget {
  const CguAcceptancePage({super.key});

  @override
  ConsumerState<CguAcceptancePage> createState() => _CguAcceptancePageState();
}

class _CguAcceptancePageState extends ConsumerState<CguAcceptancePage> {
  final _whatsappCtrl = TextEditingController();
  String _countryCode = 'CM';
  bool _cguChecked = false;
  bool _marketingChecked = false;
  bool _seededFromProfile = false;

  @override
  void initState() {
    super.initState();
    _whatsappCtrl.addListener(_onChanged);
  }

  @override
  void dispose() {
    _whatsappCtrl
      ..removeListener(_onChanged)
      ..dispose();
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  bool get _isWhatsappValid => isLocalPhoneValid(_whatsappCtrl.text);

  bool get _canSubmit => _cguChecked && _isWhatsappValid;

  Future<void> _submit() async {
    if (!_canSubmit) return;
    FocusScope.of(context).unfocus();
    await ref.read(acceptCguControllerProvider.notifier).accept(
          cguVersion: _kCguVersion,
          marketingConsent: _marketingChecked,
          countryCode: _countryCode,
          whatsappNumber: buildE164Phone(
            countryCode: _countryCode,
            local: _whatsappCtrl.text,
          ),
        );
    if (!mounted) return;
    final state = ref.read(acceptCguControllerProvider);
    if (state.value ?? false) {
      context.go(UserRoutes.home);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(acceptCguControllerProvider);
    final isLoading = state.isLoading;
    final errorMessage = state.hasError
        ? authFailureToMessage(_asFailure(state.error))
        : null;

    // Pré-remplir le pays avec celui déjà présent sur le profil SSO
    // (Google sign-in pose 'CI' par défaut, mais un compte legacy peut
    // avoir autre chose).
    final profile = ref.watch(currentProfileProvider).valueOrNull;
    if (profile != null && !_seededFromProfile) {
      final inList = kSupportedCountries.any((c) => c.code == profile.countryCode);
      _countryCode = inList ? profile.countryCode : 'CM';
      _seededFromProfile = true;
    }

    return Scaffold(
      // Pas de back — l'acceptation est obligatoire pour continuer.
      appBar: const ArenaAppBar(title: '', showBack: false),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(ArenaSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('COMPLÈTE TON\nPROFIL', style: ArenaTypography.displayMedium),
              const SizedBox(height: ArenaSpacing.sm),
              Text(
                'Quelques infos manquantes avant de pouvoir jouer.',
                style: ArenaTypography.bodyMedium.copyWith(
                  color: ArenaColors.textMuted,
                ),
              ),
              const SizedBox(height: ArenaSpacing.xl),
              _CountryPicker(
                selected: _countryCode,
                onSelect: (v) => setState(() => _countryCode = v),
                isLoading: isLoading,
              ),
              const SizedBox(height: ArenaSpacing.md),
              ArenaTextField(
                label: 'WHATSAPP (${dialCodeFor(_countryCode)})',
                hint: 'Ex. 07 07 07 07 07',
                helper:
                    'Le code pays ${dialCodeFor(_countryCode)} est ajouté'
                    ' automatiquement.',
                controller: _whatsappCtrl,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.done,
                prefixIcon: Icons.chat_outlined,
                enabled: !isLoading,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[\d\s]')),
                ],
                errorText: _whatsappCtrl.text.isEmpty || _isWhatsappValid
                    ? null
                    : 'Numéro WhatsApp invalide.',
              ),
              const SizedBox(height: ArenaSpacing.lg),
              _DocLink(
                label: "Lire les Conditions Générales d'Utilisation",
                onTap: () => _showDocPlaceholder(context, 'CGU'),
              ),
              const SizedBox(height: ArenaSpacing.sm),
              _DocLink(
                label: 'Lire la politique de confidentialité',
                onTap: () => _showDocPlaceholder(context, 'Confidentialité'),
              ),
              const SizedBox(height: ArenaSpacing.lg),
              _ConsentTile(
                value: _cguChecked,
                onChanged: isLoading
                    ? null
                    : (v) => setState(() => _cguChecked = v ?? false),
                title: "J'accepte les CGU et la politique de confidentialité",
                required: true,
              ),
              const SizedBox(height: ArenaSpacing.sm),
              _ConsentTile(
                value: _marketingChecked,
                onChanged: isLoading
                    ? null
                    : (v) => setState(() => _marketingChecked = v ?? false),
                title:
                    "J'accepte de recevoir des informations sur les nouveaux"
                    ' tournois (optionnel)',
              ),
              if (errorMessage != null) ...[
                const SizedBox(height: ArenaSpacing.md),
                _ErrorBanner(message: errorMessage),
              ],
              const SizedBox(height: ArenaSpacing.xl),
              ArenaButton(
                label: 'CONTINUER',
                fullWidth: true,
                size: ArenaButtonSize.large,
                isLoading: isLoading,
                onPressed: _canSubmit ? _submit : null,
              ),
              const SizedBox(height: ArenaSpacing.md),
              TextButton(
                onPressed: isLoading
                    ? null
                    : () async {
                        await ref.read(signOutProvider)();
                      },
                child: const Text('Refuser et se déconnecter'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDocPlaceholder(BuildContext context, String docName) {
    // PHASE 9 — replace with WebView pointing to the hosted docs URL
    // (linked from app_config.cgu_url / app_config.privacy_url).
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(docName),
        content: const Text(
          'La version complète sera affichée ici (PHASE 9 — '
          'AboutPage + WebView vers les docs hébergés).',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

class _CountryPicker extends StatelessWidget {
  const _CountryPicker({
    required this.selected,
    required this.onSelect,
    required this.isLoading,
  });

  final String selected;
  final ValueChanged<String> onSelect;
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
            for (final c in kSupportedCountries)
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
    required this.value,
    required this.onChanged,
    required this.title,
    this.required = false,
  });

  final bool value;
  final ValueChanged<bool?>? onChanged;
  final String title;
  final bool required;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onChanged == null ? null : () => onChanged!(!value),
      borderRadius: ArenaRadius.button,
      child: Container(
        padding: const EdgeInsets.all(ArenaSpacing.md),
        decoration: BoxDecoration(
          color: ArenaColors.surface,
          borderRadius: ArenaRadius.button,
          border: Border.all(
            color: value
                ? Theme.of(context).colorScheme.primary
                : ArenaColors.border,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Checkbox(value: value, onChanged: onChanged),
            const SizedBox(width: ArenaSpacing.sm),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  required ? '$title *' : title,
                  style: ArenaTypography.bodyMedium,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DocLink extends StatelessWidget {
  const _DocLink({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: ArenaSpacing.sm),
        child: Row(
          children: [
            const Icon(
              Icons.description_outlined,
              size: 18,
              color: ArenaColors.textMuted,
            ),
            const SizedBox(width: ArenaSpacing.sm),
            Expanded(
              child: Text(
                label,
                style: ArenaTypography.bodyMedium.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
            const Icon(
              Icons.open_in_new,
              size: 16,
              color: ArenaColors.textMuted,
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
          const Icon(
            Icons.error_outline,
            color: ArenaColors.danger,
            size: 20,
          ),
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
