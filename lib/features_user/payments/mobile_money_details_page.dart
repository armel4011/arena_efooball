import 'dart:io';

import 'package:arena/core/router/user_router.dart';
import 'package:arena/core/theme/arena_theme.dart';
import 'package:arena/core/utils/supported_countries.dart';
import 'package:arena/data/repositories/payment_repository.dart';
import 'package:arena/data/repositories/tutorial_video_repository.dart';
import 'package:arena/features_shared/widgets/arena_app_bar.dart';
import 'package:arena/features_shared/widgets/arena_button.dart';
import 'package:arena/features_shared/widgets/arena_screen_background.dart';
import 'package:arena/features_shared/widgets/arena_text_field.dart';
import 'package:arena/features_shared/widgets/arena_youtube_player.dart';
import 'package:arena/features_user/payments/payment_method.dart';
import 'package:arena/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

/// PHASE 11bis · P2 — Mobile Money details (paiement P2P manuel).
///
/// L'utilisateur saisit le numéro depuis lequel il va payer puis voit le
/// code de transfert de l'opérateur choisi (saisi par l'admin créateur).
/// Deux actions principales :
///   • **Copier** le code dans le presse-papier
///   • **Exécuter le paiement** — lance `tel:` avec le code USSD
///
/// Une fois le paiement effectué côté Mobile Money, l'utilisateur clique
/// "J'AI PAYÉ" : on INSERT un row `payments(status=awaiting_admin)` (avec le
/// pays + l'opérateur) puis on navigue vers P3 (attente validation admin).
///
/// Maps to screen P2 of `arena_v2.html`.
class MobileMoneyDetailsPage extends ConsumerStatefulWidget {
  const MobileMoneyDetailsPage({
    required this.operator,
    required this.amountXaf,
    required this.competitionId,
    required this.competitionName,
    super.key,
  });

  /// Opérateur choisi en P1 (label libre + code de transfert + pays +
  /// indicatif).
  final PaymentOperator operator;
  final int amountXaf;
  final String competitionId;
  final String competitionName;

  @override
  ConsumerState<MobileMoneyDetailsPage> createState() =>
      _MobileMoneyDetailsPageState();
}

class _MobileMoneyDetailsPageState
    extends ConsumerState<MobileMoneyDetailsPage> {
  final _phoneCtrl = TextEditingController();
  final _countryCtrl = TextEditingController();
  bool _submitting = false;

  /// Indicatif E.164 : celui saisi par l'admin, sinon dérivé du pays.
  String get _dialCode =>
      widget.operator.dialCode ?? dialCodeFor(widget.operator.countryCode);

  /// Code de transfert de l'opérateur (peut être vide si non configuré).
  String get _transferCode => widget.operator.transferCode ?? '';

  /// Flux « transfert vers un numéro destinataire » : numéro copiable + étapes
  /// + tuto. Réservé aux pays CEMAC HORS Cameroun, où payer ARENA est un
  /// transfert transfrontalier. Depuis le Cameroun le paiement est domestique →
  /// le code marchand suffit, comme en UEMOA.
  bool get _needsRecipientNumber =>
      needsRecipientNumberFlow(widget.operator.countryCode);

  /// Numéro destinataire à copier, vide si non configuré.
  String get _paymentNumber => widget.operator.paymentNumber ?? '';

  /// Nom du pays affiché (drapeau + nom) — repli sur le code brut.
  String get _countryDisplay {
    final match = kSupportedCountries
        .where((c) => c.code == widget.operator.countryCode)
        .toList();
    if (match.isEmpty) return widget.operator.countryCode;
    return '${match.first.flag} ${match.first.name}';
  }

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _countryCtrl.dispose();
    super.dispose();
  }

  bool get _phoneValid => isLocalPhoneValid(_phoneCtrl.text);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final operator = widget.operator;
    final hasCode = _transferCode.trim().isNotEmpty;
    // Disabled, read-only field — nom du pays de l'opérateur.
    _countryCtrl.text = _countryDisplay;
    // Tuto vidéo de paiement IN-APP, propre au pays ET à l'opérateur : l'admin
    // publie une vidéo par opérateur (repli sur la vidéo par défaut du pays si
    // aucune vidéo propre à l'opérateur). Absent → rien ne s'affiche.
    final tutorialVideo = ref
        .watch(
          paymentTutorialVideoProvider(
            (country: operator.countryCode, operatorCode: operator.code),
          ),
        )
        .valueOrNull;
    final tutorialPlayer = tutorialVideo == null
        ? null
        : ArenaYoutubePlayer.maybe(tutorialVideo.videoUrl);
    return Scaffold(
      appBar: ArenaAppBar(title: operator.label.toUpperCase()),
      body: ArenaScreenBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(ArenaSpacing.lg),
            children: [
              _Hero(operator: operator, amountXaf: widget.amountXaf)
                  .animate()
                  .fadeIn(duration: ArenaDurations.medium),
              const SizedBox(height: ArenaSpacing.lg),
              // Transfert transfrontalier : le numéro destinataire vient AVANT
              // le code à exécuter — l'utilisateur le copie pour le saisir dans
              // le menu de l'opérateur.
              if (_needsRecipientNumber && _paymentNumber.isNotEmpty) ...[
                _PaymentNumberCard(
                  number: _paymentNumber,
                  onCopy: () => _copyNumber(context),
                ),
                const SizedBox(height: ArenaSpacing.lg),
              ],
              if (!hasCode) ...[
                const _MissingCodeBanner(),
                const SizedBox(height: ArenaSpacing.md),
              ] else
                _MerchantCodeCard(
                  operator: operator,
                  code: _transferCode,
                  onCopy: () => _copyCode(context),
                  onDial: () => _dialPayment(context),
                ),
              // Transfert transfrontalier : le code n'est qu'une étape — on
              // guide la suite (choix du pays destinataire + saisie du numéro
              // copié) + un tuto vidéo.
              if (_needsRecipientNumber) ...[
                const SizedBox(height: ArenaSpacing.lg),
                _CrossBorderStepsCard(hasNumber: _paymentNumber.isNotEmpty),
              ],
              const SizedBox(height: ArenaSpacing.lg),
              Text(
                l10n.mobileMoneyCountryLabel,
                style: ArenaText.monoSmall.copyWith(
                  color: ArenaColors.silver,
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: ArenaSpacing.xs),
              ArenaTextField(
                controller: _countryCtrl,
                enabled: false,
              ),
              const SizedBox(height: ArenaSpacing.md),
              Text(
                '${l10n.mobileMoneyNumberLabel}${operator.label.toUpperCase()}',
                style: ArenaText.monoSmall.copyWith(
                  color: ArenaColors.silver,
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: ArenaSpacing.xs),
              Text(
                l10n.mobileMoneyNumberHelp,
                style: ArenaText.small,
              ),
              const SizedBox(height: ArenaSpacing.xs),
              Row(
                children: [
                  _DialBox(label: _dialCode),
                  const SizedBox(width: ArenaSpacing.xs),
                  Expanded(
                    child: ArenaTextField(
                      controller: _phoneCtrl,
                      hint: '6 78 45 12 42',
                      keyboardType: TextInputType.phone,
                      onChanged: (_) => setState(() {}),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp('[0-9 ]')),
                        LengthLimitingTextInputFormatter(15),
                      ],
                    ),
                  ),
                ],
              ),
              if (_phoneValid) ...[
                const SizedBox(height: ArenaSpacing.xs),
                Text(
                  '${l10n.mobileMoneyPhoneValid}${operator.label}',
                  style:
                      ArenaText.bodyMuted.copyWith(color: ArenaColors.statusOk),
                ),
              ],
              // Tuto vidéo — placé JUSTE SOUS le champ de saisie du numéro de
              // téléphone. Affiché si l'admin a publié une vidéo pour ce pays
              // (et cet opérateur, sinon repli pays).
              if (tutorialPlayer != null) ...[
                const SizedBox(height: ArenaSpacing.lg),
                _PaymentTutorialCard(player: tutorialPlayer),
              ],
              const SizedBox(height: ArenaSpacing.lg),
              const _Disclaimer().animate(delay: 100.ms).fadeIn(
                    duration: ArenaDurations.medium,
                  ),
              const SizedBox(height: ArenaSpacing.xl),
              ArenaButton(
                label: _submitting
                    ? l10n.mobileMoneySubmitSending
                    : '${l10n.mobileMoneySubmitPaid}${_formatXaf(widget.amountXaf)} XAF',
                fullWidth: true,
                size: ArenaButtonSize.large,
                isLoading: _submitting,
                onPressed:
                    (_phoneValid && hasCode && !_submitting) ? _submit : null,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _copyCode(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: _transferCode));
    if (!context.mounted) return;
    final l10n = AppLocalizations.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.mobileMoneyCodeCopied)),
    );
  }

  Future<void> _copyNumber(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: _paymentNumber));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Numéro copié.')),
    );
  }

  Future<void> _dialPayment(BuildContext context) async {
    // Codes USSD MoMo / Orange : `*` doit rester littéral (USSD séparateur),
    // mais `#` doit être encodé `%23` pour ne pas être interprété comme
    // fragment URI par Android — sinon le code arrive coupé dans le
    // composeur (et `%23` apparaît en `23` dans certains dialers).
    final ussd = _transferCode.replaceAll('#', '%23');
    final uri = Uri.parse('tel:$ussd');
    final ok = await launchUrl(uri);
    if (!ok && context.mounted) {
      final l10n = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.mobileMoneyDialerError),
        ),
      );
    }
  }

  Future<void> _submit() async {
    setState(() => _submitting = true);
    try {
      final repo = ref.read(paymentRepositoryProvider);
      final id = await repo.submitManualPayment(
        competitionId: widget.competitionId,
        amountLocal: widget.amountXaf.toDouble(),
        currency: 'XAF',
        payerMethodCode: widget.operator.code,
        payerPhone: '$_dialCode ${_phoneCtrl.text.trim()}',
        countryCode: widget.operator.countryCode,
        operatorLabel: widget.operator.label,
      );
      if (!mounted) return;
      context.go(
        UserRoutes.paymentProcessing,
        extra: PaymentProcessingArgs(
          paymentId: id,
          operator: widget.operator,
          amountXaf: widget.amountXaf,
          competitionName: widget.competitionName,
          maskedPhone: _maskPhone(_phoneCtrl.text.trim(), _dialCode),
        ),
      );
    } on PostgrestException catch (e, st) {
      await Sentry.captureException(e, stackTrace: st);
      if (!mounted) return;
      final l10n = AppLocalizations.of(context);
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${l10n.mobileMoneySubmitError}${e.message}')),
      );
    } on SocketException catch (e) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context);
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${l10n.mobileMoneyNoConnection}$e')),
      );
    } catch (e, st) {
      await Sentry.captureException(e, stackTrace: st);
      if (!mounted) return;
      final l10n = AppLocalizations.of(context);
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${l10n.mobileMoneySubmitError}$e')),
      );
    }
  }
}

String _maskPhone(String raw, String dialCode) {
  final digits = raw.replaceAll(' ', '');
  if (digits.length < 4) return '$dialCode ••';
  final tail = digits.substring(digits.length - 2);
  return '$dialCode ••• •• •• $tail';
}

class _Hero extends StatelessWidget {
  const _Hero({required this.operator, required this.amountXaf});

  final PaymentOperator operator;
  final int amountXaf;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Column(
        children: [
          PaymentOperatorLogo(operator: operator, size: 70),
          const SizedBox(height: ArenaSpacing.sm),
          Text(
            '${l10n.mobileMoneyHeroPayment}${operator.label}',
            style: ArenaText.h3,
          ),
          const SizedBox(height: 2),
          Text(
            '${l10n.mobileMoneyHeroForAmount}${_formatXaf(amountXaf)} XAF',
            style: ArenaText.bodyMuted,
          ),
        ],
      ),
    );
  }
}

class _MerchantCodeCard extends StatelessWidget {
  const _MerchantCodeCard({
    required this.operator,
    required this.code,
    required this.onCopy,
    required this.onDial,
  });

  final PaymentOperator operator;
  final String code;
  final VoidCallback onCopy;
  final VoidCallback onDial;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(ArenaSpacing.lg),
      decoration: BoxDecoration(
        color: operator.brandColor.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(ArenaRadius.lg),
        border: Border.all(
          color: operator.brandColor.withValues(alpha: 0.35),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('📱', style: ArenaText.h3),
              const SizedBox(width: 6),
              Text(l10n.mobileMoneyMerchantCodeTitle, style: ArenaText.h3),
            ],
          ),
          const SizedBox(height: ArenaSpacing.sm),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: ArenaSpacing.md,
              vertical: ArenaSpacing.md,
            ),
            decoration: BoxDecoration(
              color: ArenaColors.carbon,
              borderRadius: BorderRadius.circular(ArenaRadius.md),
              border: Border.all(color: ArenaColors.borderHi),
            ),
            child: SelectableText(
              code,
              textAlign: TextAlign.center,
              style: ArenaText.mono.copyWith(
                fontSize: 22,
                color: operator.brandColor,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
              ),
            ),
          ),
          const SizedBox(height: ArenaSpacing.sm),
          Row(
            children: [
              Expanded(
                child: ArenaButton(
                  label: l10n.mobileMoneyCopyButton,
                  variant: ArenaButtonVariant.secondary,
                  onPressed: onCopy,
                ),
              ),
              const SizedBox(width: ArenaSpacing.sm),
              Expanded(
                child: ArenaButton(
                  label: l10n.mobileMoneyExecuteButton,
                  onPressed: onDial,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            l10n.mobileMoneyDialHelp(operator.label),
            style: ArenaText.small,
          ),
        ],
      ),
    );
  }
}

class _MissingCodeBanner extends StatelessWidget {
  const _MissingCodeBanner();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(ArenaSpacing.md),
      decoration: arenaDangerCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.mobileMoneyMissingCodeTitle, style: ArenaText.h3),
          const SizedBox(height: ArenaSpacing.xs),
          Text(
            l10n.mobileMoneyMissingCodeBody,
            style: ArenaText.body,
          ),
        ],
      ),
    );
  }
}

class _DialBox extends StatelessWidget {
  const _DialBox({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64,
      height: 44,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: ArenaColors.carbon,
        borderRadius: BorderRadius.circular(ArenaRadius.md),
        border: Border.all(color: ArenaColors.borderHi),
      ),
      child: Text(label, style: ArenaText.body),
    );
  }
}

class _Disclaimer extends StatelessWidget {
  const _Disclaimer();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final items = <String>[
      l10n.mobileMoneyDisclaimerExactAmount,
      l10n.mobileMoneyDisclaimerKeepSms,
      l10n.mobileMoneyDisclaimerManualValidation,
    ];
    return Container(
      padding: const EdgeInsets.all(ArenaSpacing.lg),
      decoration: arenaWarningCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.mobileMoneyDisclaimerTitle, style: ArenaText.h3),
          const SizedBox(height: ArenaSpacing.sm),
          for (final i in items)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '•  ',
                    style: ArenaText.bodyMuted.copyWith(
                      color: ArenaColors.statusWarn,
                    ),
                  ),
                  Expanded(child: Text(i, style: ArenaText.body)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

String _formatXaf(int amount) {
  final s = amount.toString();
  final buf = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write(' ');
    buf.write(s[i]);
  }
  return buf.toString();
}

/// CEMAC — carte du NUMÉRO destinataire à copier (présentée AVANT le code).
/// L'utilisateur le colle dans le menu Mobile Money après avoir exécuté le code.
class _PaymentNumberCard extends StatelessWidget {
  const _PaymentNumberCard({required this.number, required this.onCopy});

  final String number;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(ArenaSpacing.lg),
      decoration: BoxDecoration(
        color: ArenaColors.iceCyan.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(ArenaRadius.lg),
        border: Border.all(
          color: ArenaColors.iceCyan.withValues(alpha: 0.35),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('💳', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 6),
              Text('Numéro à payer', style: ArenaText.h3),
            ],
          ),
          const SizedBox(height: ArenaSpacing.xs),
          Text(
            'Copiez ce numéro : vous devrez le saisir dans le menu de '
            "l'opérateur après avoir exécuté le code ci-dessous.",
            style: ArenaText.small.copyWith(color: ArenaColors.silver),
          ),
          const SizedBox(height: ArenaSpacing.sm),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: ArenaSpacing.md,
              vertical: ArenaSpacing.md,
            ),
            decoration: BoxDecoration(
              color: ArenaColors.carbon,
              borderRadius: BorderRadius.circular(ArenaRadius.md),
              border: Border.all(color: ArenaColors.borderHi),
            ),
            child: SelectableText(
              number,
              textAlign: TextAlign.center,
              style: ArenaText.mono.copyWith(
                fontSize: 22,
                color: ArenaColors.iceCyan,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
              ),
            ),
          ),
          const SizedBox(height: ArenaSpacing.sm),
          ArenaButton(
            label: 'COPIER LE NUMÉRO',
            variant: ArenaButtonVariant.secondary,
            fullWidth: true,
            onPressed: onCopy,
          ),
        ],
      ),
    );
  }
}

/// Transfert transfrontalier (CEMAC hors Cameroun) — étapes textuelles guidant
/// la suite du paiement : le code n'ouvre que le menu de l'opérateur, le choix
/// du pays de destination et la saisie du numéro s'y font.
class _CrossBorderStepsCard extends StatelessWidget {
  const _CrossBorderStepsCard({required this.hasNumber});

  final bool hasNumber;

  @override
  Widget build(BuildContext context) {
    final steps = <String>[
      'Exécutez le code ci-dessus (il ouvre le menu Mobile Money).',
      'Sélectionnez le pays de destination : Cameroun.',
      if (hasNumber)
        'Saisissez le numéro copié plus haut comme destinataire.'
      else
        "Saisissez le numéro destinataire communiqué par l'organisateur.",
      'Confirmez le montant, puis validez avec votre code secret.',
    ];
    return Container(
      padding: const EdgeInsets.all(ArenaSpacing.lg),
      decoration: BoxDecoration(
        color: ArenaColors.carbon,
        borderRadius: BorderRadius.circular(ArenaRadius.lg),
        border: Border.all(color: ArenaColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Étapes du paiement', style: ArenaText.h3),
          const SizedBox(height: ArenaSpacing.sm),
          for (var i = 0; i < steps.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: ArenaSpacing.xs),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: ArenaColors.iceCyan.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${i + 1}',
                      style: ArenaText.small.copyWith(
                        color: ArenaColors.iceCyan,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: ArenaSpacing.sm),
                  Expanded(child: Text(steps[i], style: ArenaText.body)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Tuto vidéo de paiement joué IN-APP, propre au pays. L'admin renseigne le
/// lien YouTube par pays ; le [player] est déjà construit par la page (absent
/// si aucune vidéo n'est publiée, auquel cas la carte n'apparaît pas).
class _PaymentTutorialCard extends StatelessWidget {
  const _PaymentTutorialCard({required this.player});

  final Widget player;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(ArenaSpacing.md),
      decoration: BoxDecoration(
        color: ArenaColors.carbon,
        borderRadius: BorderRadius.circular(ArenaRadius.lg),
        border: Border.all(color: ArenaColors.neonRed.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: ArenaColors.neonRed,
                  borderRadius: BorderRadius.circular(ArenaRadius.sm),
                ),
                child: const Icon(
                  Icons.play_arrow_rounded,
                  color: ArenaColors.bone,
                ),
              ),
              const SizedBox(width: ArenaSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tutoriel de paiement',
                      style:
                          ArenaText.body.copyWith(fontWeight: FontWeight.w700),
                    ),
                    Text(
                      'Comment payer étape par étape',
                      style: ArenaText.small.copyWith(color: ArenaColors.silver),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: ArenaSpacing.sm),
          player,
        ],
      ),
    );
  }
}
