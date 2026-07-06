import 'package:arena/core/router/user_router.dart';
import 'package:arena/core/services/sync_queue_service.dart';
import 'package:arena/core/theme/arena_theme.dart';
import 'package:arena/data/models/competition_payment_option.dart';
import 'package:arena/data/repositories/competition_repository.dart';
import 'package:arena/data/repositories/referral_repository.dart';
import 'package:arena/features_shared/prize_ranks.dart';
import 'package:arena/features_shared/widgets/arena_app_bar.dart';
import 'package:arena/features_shared/widgets/arena_button.dart';
import 'package:arena/features_shared/widgets/arena_divider.dart';
import 'package:arena/features_shared/widgets/arena_screen_background.dart';
import 'package:arena/features_user/auth/auth_providers.dart';
import 'package:arena/features_user/competitions/widgets/country_pick_dialog.dart';
import 'package:arena/features_user/competitions/widgets/referral_progress_card.dart';
import 'package:arena/features_user/payments/payment_method.dart';
import 'package:arena/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

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
    this.androidStoreUrl,
    this.iosStoreUrl,
    super.key,
  });

  final String competitionId;
  final String competitionName;
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
        context.go(
          UserRoutes.paymentMomoDetails,
          extra: PaymentMomoArgs(
            operator: operator,
            amountXaf: widget.entryFeeXaf,
            competitionId: widget.competitionId,
            competitionName: widget.competitionName,
          ),
        );
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

/// Titre display tout en haut du checkout — reproduit le `m-text-display`
/// de la maquette avec un accent italic ice-cyan sur la fin de phrase
/// ("Confirme ton inscription.") pour donner du caractère.
class _DisplayTitle extends StatelessWidget {
  const _DisplayTitle();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return RichText(
      text: TextSpan(
        style: ArenaText.h1.copyWith(
          color: ArenaColors.bone,
          fontSize: 28,
          letterSpacing: 1,
          height: 1,
        ),
        children: [
          TextSpan(text: l10n.regConfirmDisplayTitleStart),
          TextSpan(
            text: l10n.regConfirmDisplayTitleAccent,
            style: ArenaText.serifAccent.copyWith(
              color: ArenaColors.iceCyan,
              fontSize: 22,
            ),
          ),
        ],
      ),
    );
  }
}

/// Banner premium pour la compétition — reproduit `.m-banner` de la
/// maquette (~70 px). Gradient `signalBlueDark → signalBlue` (sans
/// couleur game-themed pour rester neutre — la page checkout n'a pas
/// accès au `GameType` enum, seulement au label string). Affiche un
/// pill `GRATUIT` ou `PAYANTE` en haut à droite.
class _CompetitionBanner extends StatelessWidget {
  const _CompetitionBanner({
    required this.name,
    required this.gameLabel,
    required this.gameEmoji,
    required this.dateLabel,
    required this.formatLabel,
    required this.isFree,
  });

  final String name;
  final String gameLabel;
  final String gameEmoji;
  final String dateLabel;
  final String formatLabel;
  final bool isFree;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(ArenaSpacing.lg),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [ArenaColors.signalBlue, ArenaColors.signalBlueDark],
        ),
        borderRadius: BorderRadius.circular(ArenaRadius.lg),
        boxShadow: const [
          BoxShadow(
            color: ArenaColors.signalBlueGlow,
            blurRadius: 18,
            spreadRadius: -4,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  name.toUpperCase(),
                  style: ArenaText.h2.copyWith(
                    color: ArenaColors.bone,
                    fontSize: 18,
                    letterSpacing: 1.5,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: ArenaSpacing.xs),
              _Pill(
                label: isFree ? l10n.regConfirmPillFree : l10n.regConfirmPillPaid,
                accent:
                    isFree ? ArenaColors.statusOk : ArenaColors.tierGoldWarm,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '$gameEmoji  $gameLabel  ·  $formatLabel',
            style: ArenaText.small.copyWith(
              color: ArenaColors.bone.withValues(alpha: 0.85),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '🗓  $dateLabel',
            style: ArenaText.small.copyWith(
              color: ArenaColors.bone.withValues(alpha: 0.85),
            ),
          ),
        ],
      ),
    );
  }
}

/// Pill `GRATUIT` / `PAYANTE` — fond `bone @ 25 %` translucide, texte
/// `accent` bold mono.
class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.accent});

  final String label;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: ArenaColors.bone.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(ArenaRadius.round),
      ),
      child: Text(
        label,
        style: ArenaText.badge.copyWith(
          color: ArenaColors.bone,
          letterSpacing: 1,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _PaymentBreakdown extends StatelessWidget {
  const _PaymentBreakdown({required this.entryFeeXaf});

  final int entryFeeXaf;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      decoration: BoxDecoration(
        color: ArenaColors.carbon,
        borderRadius: BorderRadius.circular(ArenaRadius.lg),
        border: Border.all(color: ArenaColors.border),
      ),
      child: Column(
        children: [
          _Row(
            label: l10n.regConfirmBreakdownFee,
            value: '${_formatXaf(entryFeeXaf)} XAF',
          ),
          const ArenaDivider(),
          _Row(
            label: l10n.regConfirmBreakdownService,
            value: l10n.regConfirmBreakdownServiceIncluded,
          ),
          const ArenaDivider(),
          _Row(
            label: l10n.regConfirmBreakdownTotal,
            value: '${_formatXaf(entryFeeXaf)} XAF',
            emphasis: true,
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.label,
    required this.value,
    this.emphasis = false,
  });
  final String label;
  final String value;
  final bool emphasis;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: ArenaSpacing.md,
        vertical: 10,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: emphasis ? ArenaText.h3 : ArenaText.bodyMuted,
            ),
          ),
          Text(
            value,
            style: emphasis
                ? ArenaText.monoLg.copyWith(color: ArenaColors.signalBlue)
                : ArenaText.mono,
          ),
        ],
      ),
    );
  }
}

/// Répartition des gains — total en `bigNumber` vert au centre, puis
/// **tous** les rangs récompensés affichés dans une grille de cards
/// (4 colonnes, multi-lignes si > 4). Reproduit la maquette `m-row gap:
/// 6px` + `m-card flex:1 align-items:center` mais wrap automatiquement
/// pour supporter les compétitions à 8 / 16 / 32 / 64 rangs (max
/// `kMaxRewardedRanks` configurable côté admin).
///
/// Palette : podium (tierGoldWarm / silver / hotCoral) sur les 3
/// premiers, puis pearl pour le reste — distingue visuellement le
/// podium sans saturer les rangs de fond de classement.
class _PrizeDistribution extends StatelessWidget {
  const _PrizeDistribution({
    required this.totalXaf,
    required this.distribution,
  });

  final int totalXaf;

  /// Montants de gain par rang (en monnaie locale), fournis par la
  /// compétition. Toutes les places configurées par l'admin sont
  /// affichées, y compris celles à 0.
  final List<int> distribution;

  /// Couleur dédiée par rang. Les 3 premiers ont leur métal dédié,
  /// les suivants utilisent `pearl` (texte secondaire premium).
  static Color _colorForRank(int position) {
    switch (position) {
      case 0:
        return ArenaColors.tierGoldWarm;
      case 1:
        return ArenaColors.silver;
      case 2:
        return ArenaColors.hotCoral;
      default:
        return ArenaColors.pearl;
    }
  }

  // Layout : 4 colonnes fixes, peu importe le nombre de rangs. Le
  // LayoutBuilder calcule la largeur exacte de chaque card pour
  // respecter le spacing 6 px entre colonnes — évite le débordement
  // horizontal qu'aurait un Row avec >4 enfants.
  static const _columns = 4;
  static const _gap = 6.0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final ranks = distribution.length > kMaxRewardedRanks
        ? kMaxRewardedRanks
        : distribution.length;
    return Container(
      padding: const EdgeInsets.all(ArenaSpacing.lg),
      decoration: BoxDecoration(
        color: ArenaColors.carbon,
        borderRadius: BorderRadius.circular(ArenaRadius.lg),
        border: Border.all(color: ArenaColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Text(
              '${_formatXaf(totalXaf)} XAF',
              style: ArenaText.bigNumber.copyWith(
                color: ArenaColors.statusOk,
                fontSize: 28,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Center(
            child: Text(
              ranks <= 1
                  ? l10n.regConfirmRanksRewardedSingle
                  : '$ranks${l10n.regConfirmRanksRewardedPluralSuffix}',
              style: ArenaText.small.copyWith(color: ArenaColors.silver),
            ),
          ),
          const SizedBox(height: ArenaSpacing.md),
          LayoutBuilder(
            builder: (context, constraints) {
              final cardWidth =
                  (constraints.maxWidth - _gap * (_columns - 1)) / _columns;
              return Wrap(
                spacing: _gap,
                runSpacing: _gap,
                children: [
                  for (var i = 0; i < ranks; i++)
                    SizedBox(
                      width: cardWidth,
                      child: _RankCard(
                        emoji: prizeRankEmoji(i),
                        rankNumber: i + 1,
                        amount: distribution[i],
                        color: _colorForRank(i),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

/// Mini card par rang — emoji 🥇/🥈/🥉/🏅 + indicateur `Nᵉ` (à partir
/// du 4ᵉ, l'emoji 🏅 ne discrimine plus le rang exact) + montant en
/// mono. Fond et border colorés selon `color` (gold/silver/hotCoral/
/// pearl).
class _RankCard extends StatelessWidget {
  const _RankCard({
    required this.emoji,
    required this.rankNumber,
    required this.amount,
    required this.color,
  });

  final String emoji;
  final int rankNumber;
  final int amount;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final showRankNumber = rankNumber > 3;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(ArenaRadius.md),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          if (showRankNumber) ...[
            const SizedBox(height: 2),
            Text(
              prizeRankLabel(rankNumber - 1),
              style: ArenaText.mono.copyWith(
                color: color,
                fontSize: 9,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          const SizedBox(height: 4),
          Text(
            _formatXaf(amount),
            style: ArenaText.mono.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: 11,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _AckTile extends StatelessWidget {
  const _AckTile({required this.checked, required this.onChanged});
  final bool checked;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return InkWell(
      onTap: () => onChanged(!checked),
      borderRadius: BorderRadius.circular(ArenaRadius.lg),
      child: Container(
        padding: const EdgeInsets.all(ArenaSpacing.md),
        decoration: BoxDecoration(
          color: ArenaColors.carbon,
          borderRadius: BorderRadius.circular(ArenaRadius.lg),
          border: Border.all(
            color: checked ? ArenaColors.signalBlue : ArenaColors.border,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Checkbox(value: checked, onChanged: (v) => onChanged(v ?? false)),
            const SizedBox(width: ArenaSpacing.sm),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  l10n.regConfirmAckLabel,
                  style: ArenaText.body,
                ),
              ),
            ),
          ],
        ),
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

/// 2 boutons stores (Item 1 prompt 2026-05-19). Affichés en Row quand
/// les 2 sont présents, l'un en dessous de l'autre sinon.
class _StoreButtons extends StatelessWidget {
  const _StoreButtons({this.androidUrl, this.iosUrl});

  final String? androidUrl;
  final String? iosUrl;

  Future<void> _open(BuildContext context, String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      final l10n = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.regConfirmStoreLinkError)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final hasAndroid = androidUrl != null && androidUrl!.isNotEmpty;
    final hasIos = iosUrl != null && iosUrl!.isNotEmpty;
    if (!hasAndroid && !hasIos) return const SizedBox.shrink();

    final androidBtn = hasAndroid
        ? ArenaButton(
            label: l10n.regConfirmPlayStore,
            icon: Icons.android,
            fullWidth: true,
            variant: ArenaButtonVariant.secondary,
            onPressed: () => _open(context, androidUrl!),
          )
        : null;
    final iosBtn = hasIos
        ? ArenaButton(
            label: l10n.regConfirmAppStore,
            icon: Icons.apple,
            fullWidth: true,
            variant: ArenaButtonVariant.secondary,
            onPressed: () => _open(context, iosUrl!),
          )
        : null;

    if (hasAndroid && hasIos) {
      return Row(
        children: [
          Expanded(child: androidBtn!),
          const SizedBox(width: ArenaSpacing.sm),
          Expanded(child: iosBtn!),
        ],
      );
    }
    return androidBtn ?? iosBtn!;
  }
}
