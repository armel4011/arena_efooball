import 'package:arena/core/theme/arena_theme.dart';
import 'package:arena/data/models/arena_match.dart';
import 'package:arena/data/repositories/match_repository.dart';
import 'package:arena/features_shared/widgets/arena_button.dart';
import 'package:arena/features_shared/widgets/arena_text_field.dart';
import 'package:arena/features_user/match_room/match_room_page.dart'
    show MatchRole;
import 'package:arena/features_user/match_room/widgets/cyan_dashed_container.dart';
import 'package:arena/features_user/match_room/widgets/forfeit_timer_card.dart';
import 'package:arena/features_user/match_room/widgets/open_chat_link.dart';
import 'package:arena/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Step 2 — Code shared, opponent joining. Affiche le code à copier +
/// CTA "JE SUIS DANS LA ROOM" pour les joueurs, ou un hint d'attente
/// pour les observers.
class RoomReadyView extends ConsumerStatefulWidget {
  const RoomReadyView({required this.match, required this.role, super.key});

  final ArenaMatch match;
  final MatchRole role;

  @override
  ConsumerState<RoomReadyView> createState() => _RoomReadyViewState();
}

class _RoomReadyViewState extends ConsumerState<RoomReadyView> {
  bool _submitting = false;
  late final TextEditingController _teamCtrl;

  bool get _isPlayer1 => widget.role == MatchRole.player1;

  bool get _isHome =>
      widget.match.homePlayerId != null &&
      switch (widget.role) {
        MatchRole.player1 => widget.match.player1Id == widget.match.homePlayerId,
        MatchRole.player2 => widget.match.player2Id == widget.match.homePlayerId,
        MatchRole.observer => false,
      };

  @override
  void initState() {
    super.initState();
    final existing =
        _isPlayer1 ? widget.match.player1TeamName : widget.match.player2TeamName;
    _teamCtrl = TextEditingController(text: existing ?? '');
  }

  @override
  void dispose() {
    _teamCtrl.dispose();
    super.dispose();
  }

  Future<void> _markStarted() async {
    final teamName = _teamCtrl.text.trim();
    // Garde-fou : le bouton est déjà désactivé tant que le nom est vide.
    if (teamName.isEmpty) return;
    setState(() => _submitting = true);
    try {
      final repo = ref.read(matchRepositoryProvider);
      // Le nom d'équipe est obligatoire avant de démarrer — on le persiste
      // d'abord (aide à l'arbitrage anti-triche) puis on flippe in_progress.
      await repo.setTeamName(
        matchId: widget.match.id,
        isPlayer1: _isPlayer1,
        teamName: teamName,
      );
      await repo.markInProgress(widget.match.id);
    } catch (e) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context);
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${l10n.roomReadyMarkStartedError}$e')),
      );
    }
  }

  Future<void> _copyCode(String code) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    await Clipboard.setData(ClipboardData(text: code));
    if (!mounted) return;
    messenger.showSnackBar(
      SnackBar(
        content: Text(l10n.roomReadyCodeCopied),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final code = widget.match.roomCode;
    final isPlayer = widget.role != MatchRole.observer;
    final hint = switch (widget.role) {
      MatchRole.observer => l10n.roomReadyHintObserver,
      _ when _isHome => l10n.roomReadyHintHome,
      _ => l10n.roomReadyHintAway,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.roomReadyCodeLabel,
          style: ArenaText.inputLabel,
        ),
        const SizedBox(height: ArenaSpacing.sm),
        CyanDashedContainer(
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: SelectableText(
                      code ?? '—',
                      textAlign: TextAlign.center,
                      style: ArenaText.roomCode.copyWith(fontSize: 28),
                    ),
                  ),
                  if (code != null)
                    IconButton(
                      icon: const Icon(Icons.copy_outlined, size: 18),
                      tooltip: l10n.roomReadyCopyTooltip,
                      color: ArenaColors.silver,
                      onPressed: () => _copyCode(code),
                    ),
                ],
              ),
              const SizedBox(height: ArenaSpacing.sm),
              Text(
                hint,
                textAlign: TextAlign.center,
                style: ArenaText.small.copyWith(color: ArenaColors.silver),
              ),
            ],
          ),
        ),
        if (widget.match.scheduledAt != null) ...[
          const SizedBox(height: ArenaSpacing.lg),
          ForfeitTimerCard(scheduledAt: widget.match.scheduledAt!),
        ],
        if (isPlayer) ...[
          const SizedBox(height: ArenaSpacing.lg),
          Text(l10n.roomReadyTeamNameLabel, style: ArenaText.inputLabel),
          const SizedBox(height: ArenaSpacing.sm),
          ArenaTextField(
            controller: _teamCtrl,
            hint: l10n.roomReadyTeamNameHint,
            maxLength: 40,
            helper: l10n.roomReadyTeamNameHelper,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: ArenaSpacing.md),
          ArenaButton(
            label: l10n.roomReadyInRoomButton,
            icon: Icons.play_arrow_rounded,
            fullWidth: true,
            isLoading: _submitting,
            onPressed: _teamCtrl.text.trim().isEmpty ? null : _markStarted,
          ),
          const SizedBox(height: ArenaSpacing.sm),
          OpenChatLink(matchId: widget.match.id),
        ],
      ],
    );
  }
}

/// Interstitial affiché immédiatement après que le HOME ait envoyé son
/// code, le temps que la sync DB arrive (et déclenche
/// `MatchStatus.ready`). Affiche le code + un spinner.
class CodeSharedInterstitial extends StatelessWidget {
  const CodeSharedInterstitial({
    required this.code,
    required this.matchId,
    super.key,
  });

  final String code;
  final String matchId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l10n.roomReadyCodeLabel, style: ArenaText.inputLabel),
        const SizedBox(height: ArenaSpacing.sm),
        CyanDashedContainer(
          child: Column(
            children: [
              const Icon(
                Icons.check_circle,
                color: ArenaColors.statusOk,
                size: 28,
              ),
              const SizedBox(height: ArenaSpacing.xs),
              Text(
                l10n.roomReadyCodeSharedBadge,
                style: ArenaText.inputLabel.copyWith(
                  color: ArenaColors.statusOk,
                ),
              ),
              const SizedBox(height: ArenaSpacing.sm),
              Text(
                code,
                textAlign: TextAlign.center,
                style: ArenaText.roomCode.copyWith(fontSize: 28),
              ),
              const SizedBox(height: ArenaSpacing.sm),
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(height: ArenaSpacing.xs),
              Text(
                l10n.roomReadySyncingHint,
                textAlign: TextAlign.center,
                style: ArenaText.small.copyWith(color: ArenaColors.silver),
              ),
            ],
          ),
        ),
        const SizedBox(height: ArenaSpacing.lg),
        OpenChatLink(matchId: matchId),
      ],
    );
  }
}
