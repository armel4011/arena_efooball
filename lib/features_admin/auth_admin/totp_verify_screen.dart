import 'dart:async';

import 'package:arena/core/router/admin_router.dart';
import 'package:arena/core/theme/arena_theme.dart';
import 'package:arena/data/repositories/auth_failure.dart';
import 'package:arena/features_admin/auth_admin/admin_auth_providers.dart';
import 'package:arena/features_admin/auth_admin/login_admin_screen.dart'
    show LoginAdminScreen;
import 'package:arena/features_shared/widgets/arena_app_bar.dart';
import 'package:arena/features_shared/widgets/arena_button.dart';
import 'package:arena/features_shared/widgets/arena_screen_background.dart';
import 'package:arena/features_user/auth/widgets/auth_failure_message.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// PHASE 2bis sub-flow B.4 — TOTP verify at login.
///
/// Reached after [LoginAdminScreen] succeeds with email + password and
/// the admin has `totp_enabled = true` already. Backup-code fallback is
/// still wired but currently routes to a placeholder (PHASE 2bis backend).
class TotpVerifyScreen extends ConsumerStatefulWidget {
  const TotpVerifyScreen({super.key});

  @override
  ConsumerState<TotpVerifyScreen> createState() => _TotpVerifyScreenState();
}

class _TotpVerifyScreenState extends ConsumerState<TotpVerifyScreen> {
  final _codeCtrl = TextEditingController();
  final _codeFocus = FocusNode();
  Timer? _ticker;

  /// Seconds left in the current 30s TOTP window.
  int _secondsLeft = 30;

  /// Failed attempt count for this session (UI only — server-side lock
  /// happens in the Edge Function once it lands).
  int _attempts = 0;

  @override
  void initState() {
    super.initState();
    _codeCtrl.addListener(_onCodeChanged);
    _startTicker();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _codeFocus.requestFocus();
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _codeCtrl
      ..removeListener(_onCodeChanged)
      ..dispose();
    _codeFocus.dispose();
    super.dispose();
  }

  void _startTicker() {
    _resetWindow();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        _secondsLeft = _secondsLeft <= 1 ? 30 : _secondsLeft - 1;
      });
    });
  }

  void _resetWindow() {
    // TOTP codes typically refresh every 30s aligned on unix epoch.
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    _secondsLeft = 30 - (now % 30);
  }

  void _onCodeChanged() {
    setState(() {});
    if (_codeCtrl.text.length == 6) {
      _submit();
    }
  }

  Future<void> _submit() async {
    if (_codeCtrl.text.length != 6) return;
    FocusScope.of(context).unfocus();
    await ref
        .read(adminTotpVerifyControllerProvider.notifier)
        .verify(_codeCtrl.text);
    if (!mounted) return;
    final state = ref.read(adminTotpVerifyControllerProvider);
    if (state.value != null) {
      context.go(AdminRoutes.home);
    } else if (state.hasError) {
      setState(() {
        _attempts++;
        _codeCtrl.clear();
      });
      _codeFocus.requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminTotpVerifyControllerProvider);
    final isLoading = state.isLoading;
    final errorMessage =
        state.hasError ? authFailureToMessage(_asFailure(state.error)) : null;

    return Scaffold(
      appBar: ArenaAppBar(
        title: 'Vérification 2FA',
        onBack: () => context.go(AdminRoutes.login),
      ),
      body: ArenaScreenBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(ArenaSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: ArenaSpacing.md),
                const Center(
                  child: Text('🔐', style: TextStyle(fontSize: 60)),
                ),
                const SizedBox(height: ArenaSpacing.md),
                Center(
                  child: Text(
                    'CODE À 6 CHIFFRES',
                    style: ArenaTypography.displayMedium,
                  ),
                ),
                const SizedBox(height: ArenaSpacing.sm),
                Center(
                  child: Text(
                    "Ouvre ton app d'authentification.",
                    style: ArenaTypography.bodyMedium.copyWith(
                      color: ArenaColors.textMuted,
                    ),
                  ),
                ),
                const SizedBox(height: ArenaSpacing.xl),
                _TotpCellGrid(
                  controller: _codeCtrl,
                  focusNode: _codeFocus,
                  enabled: !isLoading,
                ),
                const SizedBox(height: ArenaSpacing.md),
                _ExpiryCard(secondsLeft: _secondsLeft),
                if (errorMessage != null) ...[
                  const SizedBox(height: ArenaSpacing.sm),
                  _ErrorBanner(message: errorMessage),
                ],
                const SizedBox(height: ArenaSpacing.lg),
                ArenaButton(
                  label: 'VÉRIFIER',
                  fullWidth: true,
                  size: ArenaButtonSize.large,
                  isLoading: isLoading,
                  onPressed: _submit,
                ),
                const SizedBox(height: ArenaSpacing.md),
                _AttemptsCard(attempts: _attempts),
                const SizedBox(height: ArenaSpacing.sm),
                Center(
                  child: TextButton(
                    onPressed: isLoading ? null : _backupCodeStub,
                    child: const Text('🔑 Utiliser un backup code'),
                  ),
                ),
                Center(
                  child: TextButton(
                    onPressed: isLoading ? null : _lostDeviceStub,
                    child: Text(
                      "😱 J'ai perdu mon device",
                      style: ArenaText.small.copyWith(
                        color: ArenaColors.silver,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _backupCodeStub() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Récupération par code backup : PHASE 2bis backend '
          '(Edge Function pending).',
        ),
      ),
    );
  }

  void _lostDeviceStub() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Contacte ton super-admin : il peut réinitialiser ta 2FA '
          'depuis la console.',
        ),
      ),
    );
  }
}

class _TotpCellGrid extends StatelessWidget {
  const _TotpCellGrid({
    required this.controller,
    required this.focusNode,
    required this.enabled,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final value = controller.text;
    return GestureDetector(
      onTap: focusNode.requestFocus,
      child: Stack(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(6, (i) {
              final filled = i < value.length;
              final isCurrent = i == value.length && enabled;
              return _TotpCell(
                digit: filled ? value[i] : '',
                isCurrent: isCurrent,
              );
            }),
          ),
          // Invisible TextField captures focus + input.
          Opacity(
            opacity: 0,
            child: SizedBox(
              height: 56,
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                enabled: enabled,
                autofocus: true,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(6),
                ],
                style: const TextStyle(color: Colors.transparent),
                cursorColor: Colors.transparent,
                showCursor: false,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TotpCell extends StatelessWidget {
  const _TotpCell({required this.digit, required this.isCurrent});
  final String digit;
  final bool isCurrent;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 56,
      decoration: BoxDecoration(
        color: ArenaColors.carbon,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isCurrent
              ? ArenaColors.signalBlue
              : digit.isNotEmpty
                  ? ArenaColors.bone.withValues(alpha: 0.4)
                  : ArenaColors.border,
          width: isCurrent ? 2 : 1,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        digit,
        style: ArenaText.bigNumber.copyWith(fontSize: 24),
      ),
    );
  }
}

class _ExpiryCard extends StatelessWidget {
  const _ExpiryCard({required this.secondsLeft});
  final int secondsLeft;

  @override
  Widget build(BuildContext context) {
    final mm = (secondsLeft ~/ 60).toString().padLeft(2, '0');
    final ss = (secondsLeft % 60).toString().padLeft(2, '0');
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: ArenaSpacing.md,
        vertical: ArenaSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: ArenaColors.carbon,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: ArenaColors.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('⏱ Code expire dans', style: ArenaText.small),
          Text(
            '$mm:$ss',
            style: ArenaText.mono.copyWith(
              color: ArenaColors.neonRed,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _AttemptsCard extends StatelessWidget {
  const _AttemptsCard({required this.attempts});
  final int attempts;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: ArenaColors.carbon,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: ArenaColors.border),
      ),
      alignment: Alignment.center,
      child: Text(
        'Tentatives ${attempts.clamp(0, 3)}/3 · Lock 5 min après 3 échecs',
        style: ArenaText.small.copyWith(color: ArenaColors.bone),
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
