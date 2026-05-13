import 'package:arena/core/router/admin_router.dart';
import 'package:arena/core/theme/arena_theme.dart';
import 'package:arena/data/repositories/auth_failure.dart';
import 'package:arena/features_admin/auth_admin/admin_auth_providers.dart';
import 'package:arena/features_shared/widgets/arena_app_bar.dart';
import 'package:arena/features_shared/widgets/arena_button.dart';
import 'package:arena/features_shared/widgets/arena_text_field.dart';
import 'package:arena/features_user/auth/widgets/auth_failure_message.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Single-screen invitation redeem flow.
///
/// In V1.0 the visual breakdown of "step 1: code → step 2: account →
/// step 3: TOTP → step 4: success" lives in PHASE 2bis sub-flows; here
/// we ship a compact form because TOTP setup is its own dedicated route
/// ([TotpSetupScreen]). Once redeem succeeds, we send the user there.
const String _kAdminCguVersion = '2026-05-01';

class InvitationRedeemScreen extends ConsumerStatefulWidget {
  const InvitationRedeemScreen({super.key});

  @override
  ConsumerState<InvitationRedeemScreen> createState() =>
      _InvitationRedeemScreenState();
}

class _InvitationRedeemScreenState
    extends ConsumerState<InvitationRedeemScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codeCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _obscure1 = true;
  bool _obscure2 = true;
  bool _cguChecked = false;

  @override
  void dispose() {
    _codeCtrl.dispose();
    _emailCtrl.dispose();
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  String? _validateCode(String? v) {
    if (v == null || v.isEmpty) return "Code d'invitation requis";
    // Format ARENA-XXXX-XXXX-XXXX (admin invite codes).
    final cleaned = v.toUpperCase().replaceAll(RegExp(r'\s+'), '');
    if (!RegExp(r'^ARENA(-[A-Z0-9]{4}){3}$').hasMatch(cleaned)) {
      return 'Format attendu : ARENA-XXXX-XXXX-XXXX';
    }
    return null;
  }

  String? _validateEmail(String? v) {
    if (v == null || v.isEmpty) return 'Email requis';
    if (!v.contains('@')) return 'Email invalide';
    return null;
  }

  String? _validatePassword(String? v) {
    if (v == null || v.isEmpty) return 'Mot de passe requis';
    // Admin password rules : 12 chars + at least 1 upper + 1 lower +
    // 1 digit + 1 symbol (PHASE 2bis spec).
    if (v.length < 12) return 'Minimum 12 caractères';
    if (!RegExp(r'[A-Z]').hasMatch(v)) return 'Au moins une majuscule';
    if (!RegExp(r'[a-z]').hasMatch(v)) return 'Au moins une minuscule';
    if (!RegExp(r'\d').hasMatch(v)) return 'Au moins un chiffre';
    if (!RegExp(r'[!@#$%^&*(),.?":{}|<>_\-]').hasMatch(v)) {
      return 'Au moins un caractère spécial';
    }
    return null;
  }

  String? _validateConfirm(String? v) {
    if (v != _passwordCtrl.text) return 'Les mots de passe ne correspondent pas';
    return null;
  }

  String? _validateUsername(String? v) {
    if (v == null || v.length < 3) return 'Au moins 3 caractères';
    return null;
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (!_cguChecked) return;
    FocusScope.of(context).unfocus();

    await ref.read(invitationRedeemControllerProvider.notifier).redeem(
          code: _codeCtrl.text.trim().toUpperCase(),
          email: _emailCtrl.text.trim().toLowerCase(),
          password: _passwordCtrl.text,
          username: _usernameCtrl.text.trim(),
          cguAcceptedAt: DateTime.now().toUtc(),
          cguVersionAccepted: _kAdminCguVersion,
        );
    if (!mounted) return;
    final state = ref.read(invitationRedeemControllerProvider);
    if (state.value != null) {
      // Admin account created — force TOTP setup before any other action.
      context.go(AdminRoutes.totpSetup);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(invitationRedeemControllerProvider);
    final isLoading = state.isLoading;
    final errorMessage = state.hasError
        ? authFailureToMessage(_asFailure(state.error))
        : null;

    return Scaffold(
      appBar: ArenaAppBar(
        title: 'Code invitation',
        onBack: () => context.go(AdminRoutes.splash),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(ArenaSpacing.lg),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: ArenaSpacing.sm),
                const Center(
                  child: Text('🎟️', style: TextStyle(fontSize: 54)),
                ),
                const SizedBox(height: ArenaSpacing.md),
                Center(
                  child: Text(
                    'DEVENIR ADMIN',
                    style: ArenaTypography.displayMedium,
                  ),
                ),
                const SizedBox(height: ArenaSpacing.sm),
                Center(
                  child: Text(
                    "Saisis le code d'invitation reçu par email.",
                    style: ArenaTypography.bodyMedium.copyWith(
                      color: ArenaColors.textMuted,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: ArenaSpacing.xl),
                ArenaTextField(
                  label: 'CODE INVITATION',
                  hint: 'ARENA-XXXX-XXXX-XXXX',
                  controller: _codeCtrl,
                  textInputAction: TextInputAction.next,
                  prefixIcon: Icons.confirmation_number_outlined,
                  enabled: !isLoading,
                  validator: _validateCode,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                      RegExp(r'[A-Za-z0-9\-]'),
                    ),
                    LengthLimitingTextInputFormatter(19),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Format : ARENA-XXXX-XXXX-XXXX (auto-formaté)',
                  style: ArenaText.small,
                ),
                const SizedBox(height: ArenaSpacing.md),
                const _InvitationPreviewCard(
                  role: 'Modérateur',
                  sender: 'super@arena.app',
                  expiresOn: '16/05/2026',
                ),
                const SizedBox(height: ArenaSpacing.md),
                ArenaTextField(
                  label: 'EMAIL',
                  hint: 'admin@arena.app',
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  prefixIcon: Icons.email_outlined,
                  enabled: !isLoading,
                  validator: _validateEmail,
                ),
                const SizedBox(height: ArenaSpacing.md),
                ArenaTextField(
                  label: 'NOM AFFICHÉ',
                  hint: 'Jean Admin',
                  controller: _usernameCtrl,
                  textInputAction: TextInputAction.next,
                  prefixIcon: Icons.person_outline,
                  enabled: !isLoading,
                  validator: _validateUsername,
                ),
                const SizedBox(height: ArenaSpacing.md),
                ArenaTextField(
                  label: 'MOT DE PASSE',
                  hint: 'Au moins 12 caractères',
                  controller: _passwordCtrl,
                  obscureText: _obscure1,
                  textInputAction: TextInputAction.next,
                  prefixIcon: Icons.lock_outline,
                  enabled: !isLoading,
                  validator: _validatePassword,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscure1 ? Icons.visibility : Icons.visibility_off,
                      color: ArenaColors.textMuted,
                      size: 20,
                    ),
                    onPressed: () => setState(() => _obscure1 = !_obscure1),
                  ),
                ),
                const SizedBox(height: ArenaSpacing.md),
                ArenaTextField(
                  label: 'CONFIRMER',
                  hint: 'Retape ton mot de passe',
                  controller: _confirmCtrl,
                  obscureText: _obscure2,
                  textInputAction: TextInputAction.done,
                  prefixIcon: Icons.lock_outline,
                  enabled: !isLoading,
                  validator: _validateConfirm,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscure2 ? Icons.visibility : Icons.visibility_off,
                      color: ArenaColors.textMuted,
                      size: 20,
                    ),
                    onPressed: () => setState(() => _obscure2 = !_obscure2),
                  ),
                ),
                const SizedBox(height: ArenaSpacing.md),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  value: _cguChecked,
                  onChanged: isLoading
                      ? null
                      : (v) => setState(() => _cguChecked = v ?? false),
                  title: const Text(
                    "J'accepte les CGU admin (responsabilité accrue,"
                    ' audit, accès données joueurs).',
                  ),
                ),
                if (errorMessage != null) ...[
                  const SizedBox(height: ArenaSpacing.sm),
                  _ErrorBanner(message: errorMessage),
                ],
                const SizedBox(height: ArenaSpacing.lg),
                ArenaButton(
                  label: 'VALIDER LE CODE',
                  fullWidth: true,
                  size: ArenaButtonSize.large,
                  isLoading: isLoading,
                  onPressed: _cguChecked ? _submit : null,
                ),
                const SizedBox(height: ArenaSpacing.md),
                Center(
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        'Pas reçu de code ? ',
                        style: ArenaText.bodyMuted,
                      ),
                      GestureDetector(
                        onTap: () => _showContactHint(context),
                        child: Text(
                          'Contacter le super-admin',
                          style: ArenaText.bodyMuted.copyWith(
                            color: ArenaColors.neonRed,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showContactHint(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Demande à ton super-admin de renvoyer une invitation depuis '
          'la console.',
        ),
      ),
    );
  }
}

AuthFailure _asFailure(Object? error) {
  if (error is AuthFailure) return error;
  return UnknownAuthFailure(error);
}

class _InvitationPreviewCard extends StatelessWidget {
  const _InvitationPreviewCard({
    required this.role,
    required this.sender,
    required this.expiresOn,
  });

  final String role;
  final String sender;
  final String expiresOn;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(ArenaSpacing.md),
      decoration: BoxDecoration(
        color: ArenaColors.neonRed.withValues(alpha: 0.08),
        borderRadius: ArenaRadius.button,
        border: Border.all(
          color: ArenaColors.neonRed.withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('📧 Tu as reçu', style: ArenaText.h3),
          const SizedBox(height: 4),
          Text(
            'Invitation $role',
            style: ArenaText.body.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            'De : $sender · Expire le $expiresOn',
            style: ArenaText.small,
          ),
        ],
      ),
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
