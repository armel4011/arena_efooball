import 'dart:async';

import 'package:arena/core/theme/arena_theme.dart';
import 'package:arena/data/repositories/match_repository.dart';
import 'package:arena/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

/// Écran de verrouillage de la salle de match : l'accès n'ouvre qu'à T-5 min
/// avant le coup d'envoi planifié (`scheduledAt`). Affiche un compte-à-rebours
/// vers l'ouverture et déverrouille automatiquement (invalide
/// [matchByIdProvider]) une fois l'heure atteinte, sans que le joueur ait à
/// quitter puis revenir.
///
/// Deux cas :
///  * [opensAt] non-null → match planifié : compte-à-rebours + heure du match.
///  * [opensAt] null → match pas encore programmé : message d'attente, sans
///    rebours (l'horaire sera fixé quand le round précédent se termine).
class MatchLockedView extends ConsumerStatefulWidget {
  const MatchLockedView({
    required this.matchId,
    required this.scheduledAt,
    required this.opensAt,
    super.key,
  });

  final String matchId;
  final DateTime? scheduledAt;
  final DateTime? opensAt;

  @override
  ConsumerState<MatchLockedView> createState() => _MatchLockedViewState();
}

class _MatchLockedViewState extends ConsumerState<MatchLockedView> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    if (widget.opensAt != null) {
      _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) return;
        if (!DateTime.now().isBefore(widget.opensAt!)) {
          // L'accès vient d'ouvrir : on invalide le match → la page parente
          // re-évalue le verrou et laisse entrer dans la room.
          _ticker?.cancel();
          ref.invalidate(matchByIdProvider(widget.matchId));
        } else {
          setState(() {});
        }
      });
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toString();
    final scheduledAt = widget.scheduledAt;
    final opensAt = widget.opensAt;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(ArenaSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              opensAt == null ? Icons.schedule_outlined : Icons.lock_clock,
              size: 56,
              color: ArenaColors.signalBlue,
            ),
            const SizedBox(height: ArenaSpacing.lg),
            Text(
              opensAt == null
                  ? l10n.matchLockedNoScheduleTitle
                  : l10n.matchLockedTitle,
              style: ArenaText.h2,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: ArenaSpacing.sm),
            if (opensAt == null) ...[
              Text(
                l10n.matchLockedNoScheduleBody,
                style: ArenaText.body.copyWith(color: ArenaColors.silver),
                textAlign: TextAlign.center,
              ),
            ] else ...[
              Text(
                l10n.matchLockedBody,
                style: ArenaText.body.copyWith(color: ArenaColors.silver),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: ArenaSpacing.lg),
              Text(
                _formatCountdown(opensAt.difference(DateTime.now())),
                style: ArenaText.monoLg.copyWith(
                  color: ArenaColors.signalBlue,
                  fontSize: 32,
                ),
              ),
              if (scheduledAt != null) ...[
                const SizedBox(height: ArenaSpacing.sm),
                Text(
                  l10n.matchLockedScheduled(
                    DateFormat('EEE d MMM · HH:mm', locale)
                        .format(scheduledAt.toLocal()),
                  ),
                  style: ArenaText.small.copyWith(color: ArenaColors.silver),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  /// hh:mm:ss si ≥ 1h, sinon mm:ss. Borné à 0.
  String _formatCountdown(Duration raw) {
    final d = raw.isNegative ? Duration.zero : raw;
    final h = d.inHours;
    final mm = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final ss = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (h > 0) return '${h.toString().padLeft(2, '0')}:$mm:$ss';
    return '$mm:$ss';
  }
}
