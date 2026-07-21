import 'package:arena/core/router/user_router.dart';
import 'package:arena/core/services/sync_queue_service.dart';
import 'package:arena/core/theme/arena_theme.dart';
import 'package:arena/data/models/competition_enums.dart';
import 'package:arena/data/models/competition_payment_option.dart';
import 'package:arena/data/repositories/competition_repository.dart';
import 'package:arena/data/repositories/referral_repository.dart';
import 'package:arena/features_shared/prize_ranks.dart';
import 'package:arena/features_shared/widgets/arena_app_bar.dart';
import 'package:arena/features_shared/widgets/arena_button.dart';
import 'package:arena/features_shared/widgets/arena_divider.dart';
import 'package:arena/features_shared/widgets/arena_screen_background.dart';
import 'package:arena/features_user/auth/auth_providers.dart';
import 'package:arena/features_user/competitions/app_check_dialog.dart';
import 'package:arena/features_user/competitions/widgets/country_pick_dialog.dart';
import 'package:arena/features_user/competitions/widgets/referral_progress_card.dart';
import 'package:arena/features_user/payments/payment_method.dart';
import 'package:arena/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

part 'registration_confirm_widgets.dart';

/// Page #12 — `RegistrationConfirmPage` (`/competitions/:id/register/confirm`).
///
/// Recree from scratch en suivant `arena_premium_reference.html` (ecran
/// #12 CHECKOUT) tout en preservant les 2 flows existants :
/// * Compétition **gratuite** (`entryFeeXaf == 0`) → INSERT direct dans
///   `competition_registrations` via RLS self-insert + retour HOME.
/// * Compétition **payante** → routing P1 PaymentMethodPicker puis P2
///   PaymentMomoDetails avec le code marchand correspondant.
///
/// Layout premium (top → bottom) :
/// 1. Display "Confirme ton inscription" + accent italic "ta place." en
///    ice-cyan (reproduit `m-text-display` + `m-serif` de la maquette).
/// 2. Banner premium signalBlue (gradient + Bebas) avec le nom de la
///    compétition + jeu/date.
/// 3. Bloc paiement (visible uniquement si payante) : 3 rows entry fee
///    / service / total.
/// 4. Caption "RÉPARTITION DES GAINS" + row de cards rangs (🥇/🥈/🥉/4️⃣)
///    avec couleur dédiée gold/silver/hotCoral/pearl.
/// 5. `ReferralProgressCard` si quota parrainage actif.
/// 6. Boutons stores du jeu (si URLs configurées).
/// 7. `_AckTile` checkbox d'acceptation des règles.
/// 8. CTA primary "PROCÉDER AU PAIEMENT · X XAF" / "M'INSCRIRE
///    GRATUITEMENT" + ghost Annuler.
class RegistrationConfirmPage extends ConsumerStatefulWidget {
  const RegistrationConfirmPage({
    required this.competitionId,
    required this.competitionName,
    required this.gameLabel,
    required this.gameEmoji,
    required this.dateLabel,
    required this.formatLabel,
    required this.entryFeeXaf,
    required this.totalPrizeXaf,
    required this.prizeDistribution,
    this.game,
    this.androidStoreUrl,
    this.iosStoreUrl,
    super.key,
  });

  final String competitionId;
  final String competitionName;

  /// Jeu de la compétition — pour le dialogue de contrôle d'installation
  /// (jeux externes) affiché AU-DESSUS de ce checkout. `null` = pas de contrôle.
  final GameType? game;
  final String gameLabel;
  final String gameEmoji;
  final String dateLabel;
  final String formatLabel;
  final int entryFeeXaf;
  final int totalPrizeXaf;

  /// Pourcentages de gains par rang, fournis par la compétition.
  final List<int> prizeDistribution;

  /// Item 1 prompt 2026-05-19 — liens stores du jeu (null = pas affiché).
  final String? androidStoreUrl;
  final String? iosStoreUrl;

  @override
  ConsumerState<RegistrationConfirmPage> createState() =>
      _RegistrationConfirmPageState();
}

class _RegistrationConfirmPageState
    extends ConsumerState<RegistrationConfirmPage> {
  bool _ack = false;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    // Le dialogue de contrôle d'installation (jeux externes) s'affiche
    // AU-DESSUS du checkout : on l'ouvre au premier frame. Annuler → on quitte
    // le checkout (retour arrière) ; Continuer → il se referme, on reste.
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeShowAppCheck());
  }

  Future<void> _maybeShowAppCheck() async {
    final game = widget.game;
    if (game == null || !game.isExternal || !mounted) return;
    final ok = await showAppCheckDialog(context, game: game);
    if (!ok && mounted) await Navigator.of(context).maybePop();
  }

  bool get _isFree => widget.entryFeeXaf == 0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    // Lot D — Récupère l'éligibilité parrainage en parallèle. Si la
    // compétition n'a pas de quota, on a `target=0` et `eligible=true`,
    // le widget n'est pas affiché et le bouton inscription reste actif.
    final eligibilityAsync = ref.watch(
      referralEligibilityProvider(widget.competitionId),
    );
    final eligibility = eligibilityAsync.valueOrNull;
    final hasGating = eligibility != null && eligibility.target > 0;
    final isEligible = eligibility?.eligible ?? !hasGating;
    final canSubmit = _ack && !_submitting && isEligible;

    return Scaffold(
      appBar: ArenaAppBar(title: l10n.regConfirmAppBarTitle),
      body: ArenaScreenBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(ArenaSpacing.lg),
            children: [
              const _DisplayTitle()
                  .animate()
                  .fadeIn(duration: ArenaDurations.medium),
              const SizedBox(height: ArenaSpacing.md),
              _CompetitionBanner(
                name: widget.competitionName,
                gameLabel: widget.gameLabel,
                gameEmoji: widget.gameEmoji,
                dateLabel: widget.dateLabel,
                formatLabel: widget.formatLabel,
                isFree: _isFree,
              ).animate(delay: 80.ms).fadeIn(duration: ArenaDurations.medium),
              const SizedBox(height: ArenaSpacing.lg),
              if (!_isFree) ...[
                _PaymentBreakdown(entryFeeXaf: widget.entryFeeXaf)
                    .animate(delay: 140.ms)
                    .fadeIn(duration: ArenaDurations.medium),
                const SizedBox(height: ArenaSpacing.lg),
              ],
              Text(
                l10n.regConfirmPrizeDistribution,
                style: ArenaText.monoSmall.copyWith(
                  color: ArenaColors.silver,
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: ArenaSpacing.sm),
              _PrizeDistribution(
                totalXaf: widget.totalPrizeXaf,
                distribution: widget.prizeDistribution,
              ).animate(delay: 200.ms).fadeIn(duration: ArenaDurations.medium),
              if (hasGating) ...[
                const SizedBox(height: ArenaSpacing.lg),
                ReferralProgressCard(
                  competitionId: widget.competitionId,
                  referralQuota: eligibility.target,
                ),
              ],
              if (widget.androidStoreUrl != null ||
                  widget.iosStoreUrl != null) ...[
                const SizedBox(height: ArenaSpacing.lg),
                Text(
                  l10n.regConfirmDownloadGame,
                  style: ArenaText.monoSmall.copyWith(
                    color: ArenaColors.silver,
                    letterSpacing: 1.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: ArenaSpacing.sm),
                _StoreButtons(
                  androidUrl: widget.androidStoreUrl,
                  iosUrl: widget.iosStoreUrl,
                ),
              ],
              const SizedBox(height: ArenaSpacing.lg),
              _AckTile(
                checked: _ack,
                onChanged: (v) => setState(() => _ack = v),
              ),
              const SizedBox(height: ArenaSpacing.xl),
              ArenaButton(
                label: hasGating && !isEligible
                    ? l10n.regConfirmCtaReferralsInsufficient
                    : _isFree
                        ? l10n.regConfirmCtaRegisterFree
                        : '${l10n.regConfirmCtaProceedPaymentPrefix}'
                            '${_formatXaf(widget.entryFeeXaf)}'
                            '${l10n.regConfirmCtaXafSuffix}',
                fullWidth: true,
                size: ArenaButtonSize.large,
                isLoading: _submitting,
                onPressed: canSubmit ? _onSubmit : null,
              ),
              const SizedBox(height: ArenaSpacing.sm),
              ArenaButton(
                label: l10n.regConfirmCancel,
                fullWidth: true,
                variant: ArenaButtonVariant.ghost,
                onPressed: () => Navigator.maybePop(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _onSubmit() async {
    final l10n = AppLocalizations.of(context);
    setState(() => _submitting = true);
    try {
      if (_isFree) {
        final playerId = ref.read(currentSessionProvider)?.user.id;
        if (playerId == null) {
          throw StateError(l10n.regConfirmNoSession);
        }
        final queued =
            await ref.read(offlineAwareActionsProvider).registerFreeCompetition(
                  competitionId: widget.competitionId,
                  playerId: playerId,
                );
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              queued
                  ? l10n.regConfirmOfflineQueued
                  : '${l10n.regConfirmConfirmedPrefix}'
                      '${widget.competitionName}.',
            ),
            backgroundColor:
                queued ? ArenaColors.statusWarn : ArenaColors.statusOk,
          ),
        );
        context.go(UserRoutes.home);
      } else {
        // Récupère les options de paiement (pays × opérateur × code)
        // configurées par l'admin pour cette compétition.
        final options = await ref
            .read(competitionRepositoryProvider)
            .fetchPaymentOptions(widget.competitionId);
        if (!mounted) return;
        if (options.isEmpty) {
          setState(() => _submitting = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.paymentOptionsMissing)),
          );
          return;
        }

        // Pays distincts activés (ordre = tri country_code déjà appliqué
        // côté repo). 1 seul pays → auto-sélection sans dialog.
        final countries = <String>[];
        for (final o in options) {
          if (!countries.contains(o.countryCode)) countries.add(o.countryCode);
        }
        String countryCode;
        if (countries.length == 1) {
          countryCode = countries.first;
        } else {
          // Pré-sélectionne le pays du profil joueur s'il fait partie de la
          // liste, sinon le 1er pays disponible.
          final profileCountry =
              ref.read(currentProfileProvider).valueOrNull?.countryCode;
          final preselect =
              (profileCountry != null && countries.contains(profileCountry))
                  ? profileCountry
                  : countries.first;
          final picked = await showCountryPickDialog(
            context,
            countryCodes: countries,
            selected: preselect,
          );
          if (picked == null || !mounted) {
            setState(() => _submitting = false);
            return;
          }
          countryCode = picked;
        }

        // P1 picker sur les options du pays choisi → option retenue.
        final countryOptions =
            options.where((o) => o.countryCode == countryCode).toList();
        if (!mounted) return;
        final selected = await context.push<CompetitionPaymentOption>(
          UserRoutes.paymentMethodPicker,
          extra: PaymentPickerArgs(
            amountXaf: widget.entryFeeXaf,
            contextLabel: widget.competitionName,
            options: countryOptions,
          ),
        );
        if (selected == null || !mounted) {
          setState(() => _submitting = false);
          return;
        }
        final operator = PaymentOperator.fromOption(selected);
        if (!mounted) return;
        // `push` et NON `go` : `go` remplace toute la pile, il ne reste alors
        // rien sous la page de paiement et le bouton Retour système QUITTE
        // l'app. `push` garde cet écran dessous — Retour ramène au récap
        // d'inscription, ce qu'attend le joueur qui se ravise.
        // (La page de paiement fait elle-même `go` vers le suivi une fois payé :
        // là, remplacer la pile est voulu — on ne revient pas payer deux fois.)
        await context.push(
          UserRoutes.paymentMomoDetails,
          extra: PaymentMomoArgs(
            operator: operator,
            amountXaf: widget.entryFeeXaf,
            competitionId: widget.competitionId,
            competitionName: widget.competitionName,
          ),
        );
        // Cet écran SURVIT sous la page de paiement (c'est tout l'objet du
        // `push`) : au retour, il faut relâcher `_submitting`, sinon le joueur
        // qui se ravise retrouve son bouton bloqué en chargement. Avec `go` la
        // page était détruite, la question ne se posait pas.
        if (!mounted) return;
        setState(() => _submitting = false);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${l10n.regConfirmErrorPrefix}$e')),
      );
    }
  }
}
