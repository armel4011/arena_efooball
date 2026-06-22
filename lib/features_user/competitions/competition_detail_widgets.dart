part of 'competition_detail_page.dart';

/// Banner premium — reproduit `.m-banner` 100 px de la maquette : un
/// gradient game-themed (eFoot bleu / Dames rouge / FC orange), caption
/// mono `{JEU} · {dates}` semi-transparent en haut, titre Bebas Neue 28
/// px sur l'image en bas. Le titre est uppercase, peut wrap sur 2
/// lignes (`maxLines: 2`).
class _PremiumBanner extends StatelessWidget {
  const _PremiumBanner({required this.competition});

  final Competition competition;

  @override
  Widget build(BuildContext context) {
    final c = competition;
    final dates = _formatDateRange(c.startDate, c.endDate);
    final caption = '${c.game.label.toUpperCase()} · $dates';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        ArenaSpacing.lg,
        ArenaSpacing.md,
        ArenaSpacing.lg,
        ArenaSpacing.md,
      ),
      decoration: BoxDecoration(gradient: _gradientFor(c.game)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            caption,
            style: ArenaText.monoSmall.copyWith(
              color: ArenaColors.bone.withValues(alpha: 0.75),
              letterSpacing: 1.2,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            c.name.toUpperCase(),
            style: ArenaText.h1.copyWith(
              color: ArenaColors.bone,
              fontSize: 28,
              letterSpacing: 1.5,
              height: 1,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  static LinearGradient _gradientFor(GameType g) => switch (g) {
        GameType.efootball => ArenaColors.bannerEfoot,
        GameType.draughts => ArenaColors.bannerDraughts,
        GameType.eaSportsFc => ArenaColors.bannerFc,
      };

  static String _formatDateRange(DateTime start, DateTime? end) {
    final s = DateFormat('d MMM y', 'fr').format(start.toLocal());
    if (end == null) return s;
    final e = DateFormat('d MMM y', 'fr').format(end.toLocal());
    return '$s — $e';
  }
}

/// Ligne de 2 badges sous le banner : statut (OUVERT/EN COURS/COMPLET…)
/// et capacité (`12/16`). Reproduit `.m-row gap:6px` de la maquette,
/// rendu hors banner pour rester lisible sur fond ArenaScreenBackground.
class _BannerBadges extends StatelessWidget {
  const _BannerBadges({required this.competition});

  final Competition competition;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final (statusLabel, statusColor) = _statusFor(competition.status, l10n);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        ArenaSpacing.lg,
        ArenaSpacing.md,
        ArenaSpacing.lg,
        0,
      ),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: [
          _Pill(label: statusLabel, accent: statusColor),
          _Pill(
            label: '${competition.currentPlayers}/${competition.maxPlayers}',
            accent: ArenaColors.signalBlue,
          ),
        ],
      ),
    );
  }

  // Statut unifié (À VENIR / EN COURS / TERMINÉ + À REPROGRAMMER) — même source
  // que la liste et le badge de card, pour un vocabulaire cohérent partout.
  static (String, Color) _statusFor(
    CompetitionStatus s,
    AppLocalizations l10n,
  ) =>
      (
        competitionStatusLabel(s, l10n),
        competitionStatusColor(s),
      );
}

/// Pill colorée (status / capacity) — fond `accent @ 15 %`, border
/// `accent @ 50 %`, texte `accent` bold mono.
class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.accent});

  final String label;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.15),
        border: Border.all(color: accent.withValues(alpha: 0.5)),
        borderRadius: BorderRadius.circular(ArenaRadius.round),
      ),
      child: Text(
        label,
        style: ArenaText.badge.copyWith(
          color: accent,
          letterSpacing: 1,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// Vue affichée quand le joueur n'est pas inscrit. Reproduit la maquette
/// #11 jusqu'au CTA bottom : banner premium + badges + récap prize/
/// gratuit + bloc parrainage si quota + bouton `S'INSCRIRE` collé en
/// bas (mode payant : montant + devise ; mode gratuit : "gratuitement").
class _GatedDetailView extends ConsumerWidget {
  const _GatedDetailView({required this.competition});

  final Competition competition;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final c = competition;
    final isFree = c.isFree;
    final accent = isFree ? ArenaColors.statusOk : ArenaColors.tierGoldWarm;
    final canRegister = c.canRegister;
    final ctaLabel = isFree
        ? l10n.compDetailCtaRegisterFree
        : '${l10n.compDetailCtaRegisterPaidPrefix}'
            '${_money(c.registrationFee)} ${c.registrationCurrency}';

    return SafeArea(
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _PremiumBanner(competition: c),
                _BannerBadges(competition: c),
                const SizedBox(height: ArenaSpacing.lg),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: ArenaSpacing.lg,
                  ),
                  child: _GatedPrizeCard(competition: c, accent: accent),
                ),
                if (c.referralQuota > 0) ...[
                  const SizedBox(height: ArenaSpacing.md),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: ArenaSpacing.lg,
                    ),
                    child: ReferralProgressCard(
                      competitionId: c.id,
                      referralQuota: c.referralQuota,
                    ),
                  ),
                ],
                const SizedBox(height: ArenaSpacing.lg),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: ArenaSpacing.lg,
                  ),
                  child: Text(
                    l10n.compDetailGatedLockNotice,
                    style: ArenaText.small.copyWith(
                      color: ArenaColors.silver,
                    ),
                  ),
                ),
                const SizedBox(height: ArenaSpacing.xl),
              ],
            ),
          ),
          // CTA collé en bas, comme la maquette `m-btn m-btn-primary
          // margin-top: auto`.
          Padding(
            padding: const EdgeInsets.fromLTRB(
              ArenaSpacing.lg,
              ArenaSpacing.sm,
              ArenaSpacing.lg,
              ArenaSpacing.md,
            ),
            child: ArenaButton(
              label: canRegister ? ctaLabel : l10n.compDetailRegistrationsClosed,
              variant: canRegister
                  ? ArenaButtonVariant.primary
                  : ArenaButtonVariant.secondary,
              fullWidth: true,
              onPressed: canRegister
                  ? () => context.push(
                        UserRoutes.registrationConfirmPath(c.id),
                        extra: _confirmArgsFor(c, l10n),
                      )
                  : null,
            ),
          ),
        ],
      ),
    );
  }

  static RegistrationConfirmArgs _confirmArgsFor(
    Competition c,
    AppLocalizations l10n,
  ) {
    final dateLabel =
        DateFormat('d MMM yyyy · HH:mm', 'fr').format(c.startDate.toLocal());
    return RegistrationConfirmArgs(
      competitionName: c.name,
      gameLabel: c.game.label,
      gameEmoji: _gameEmoji(c.game),
      dateLabel: dateLabel,
      formatLabel: _formatLabel(c.format, l10n),
      entryFeeXaf: c.registrationFee.round(),
      totalPrizeXaf: c.prizePoolLocal.round(),
      prizeDistribution: c.prizeDistribution,
      androidStoreUrl: c.androidStoreUrl,
      iosStoreUrl: c.iosStoreUrl,
    );
  }

  static String _money(double v) =>
      NumberFormat.decimalPattern('fr').format(v).replaceAll(',', ' ');
}

/// Card "À gagner" / "Inscription libre" affichée dans la vue gated.
/// Mode payant : ShaderMask gold sur le montant en bigNumber. Mode
/// gratuit : "GRATUIT" en vert (statusOk).
class _GatedPrizeCard extends StatelessWidget {
  const _GatedPrizeCard({required this.competition, required this.accent});

  final Competition competition;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = competition;
    final isFree = c.isFree;
    final prize = isFree
        ? l10n.compDetailPrizeFree
        : '${_money(c.prizePoolLocal)} '
            '${c.prizePoolCurrency ?? c.registrationCurrency}';

    return Container(
      padding: const EdgeInsets.all(ArenaSpacing.lg),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(ArenaRadius.lg),
        border: Border.all(color: accent.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            isFree ? l10n.compDetailPrizeFreeLabel : l10n.compDetailPrizeToWinLabel,
            style: ArenaText.monoSmall.copyWith(
              color: accent,
              fontWeight: FontWeight.w700,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            prize,
            style: ArenaText.bigNumber.copyWith(
              color: accent,
              fontSize: isFree ? 36 : 32,
              letterSpacing: 2,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  static String _money(double v) =>
      NumberFormat.decimalPattern('fr').format(v).replaceAll(',', ' ');
}
