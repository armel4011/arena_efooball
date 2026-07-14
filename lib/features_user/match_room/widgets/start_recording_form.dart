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
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Étape 1 (nouveau flux HOME) — le joueur à domicile saisit son nom
/// d'équipe puis **démarre son enregistrement** (bouton flottant rouge).
/// Il n'y a PAS encore de code : le HOME créera sa room dans eFootball et
/// enverra le code depuis le bouton flottant. Poser le team name avant
/// `markInProgress` fait que `MatchRecordingLifecycle` démarre le recording
/// pour lui (garde `_selfJoined`).
class StartRecordingForm extends ConsumerStatefulWidget {
  const StartRecordingForm({
    required this.match,
    required this.role,
    super.key,
  });

  final ArenaMatch match;
  final MatchRole role;

  @override
  ConsumerState<StartRecordingForm> createState() => _StartRecordingFormState();
}

class _StartRecordingFormState extends ConsumerState<StartRecordingForm> {
  bool _submitting = false;
  late final TextEditingController _teamCtrl;

  bool get _isPlayer1 => widget.role == MatchRole.player1;

  @override
  void initState() {
    super.initState();
    final existing = _isPlayer1
        ? widget.match.player1TeamName
        : widget.match.player2TeamName;
    _teamCtrl = TextEditingController(text: existing ?? '');
  }

  @override
  void dispose() {
    _teamCtrl.dispose();
    super.dispose();
  }

  /// Vrai quand le nom d'équipe du joueur est DÉJÀ posé en base → on passe à
  /// l'étape 2 (« Activer l'enregistrement »).
  bool get _hasTeamName {
    final n = _isPlayer1
        ? widget.match.player1TeamName
        : widget.match.player2TeamName;
    return n != null && n.trim().isNotEmpty;
  }

  /// ÉTAPE 1 — persiste UNIQUEMENT le nom d'équipe (pas de `markInProgress`,
  /// donc pas d'enregistrement ici). Le rebuild realtime fait passer à l'étape 2.
  Future<void> _saveTeamName() async {
    final teamName = _teamCtrl.text.trim();
    if (teamName.isEmpty) return;
    setState(() => _submitting = true);
    try {
      await ref.read(matchRepositoryProvider).setTeamName(
            matchId: widget.match.id,
            isPlayer1: _isPlayer1,
            teamName: teamName,
          );
    } catch (e) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${l10n.roomReadyMarkStartedError}$e')),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  /// ÉTAPE 2 — bascule le match en `in_progress`. C'est CE moment (nouvelle
  /// étape, APRÈS le nom d'équipe) qui déclenche la demande d'enregistrement
  /// (via MatchRecordingLifecycle : isLive + team name posé).
  Future<void> _startRecording() async {
    setState(() => _submitting = true);
    try {
      await ref.read(matchRepositoryProvider).markInProgress(widget.match.id);
    } catch (e) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context);
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${l10n.roomReadyMarkStartedError}$e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return _hasTeamName ? _activateStep(l10n) : _teamNameStep(l10n);
  }

  /// Étape 1 : saisie du nom d'équipe (aucun enregistrement déclenché ici).
  Widget _teamNameStep(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l10n.startRecordingTeamStepTitle, style: ArenaText.inputLabel),
        const SizedBox(height: ArenaSpacing.sm),
        CyanDashedContainer(
          child: Text(
            l10n.startRecordingTeamStepDesc,
            textAlign: TextAlign.center,
            style: ArenaText.small.copyWith(color: ArenaColors.silver),
          ),
        ),
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
        if (widget.match.scheduledAt != null) ...[
          const SizedBox(height: ArenaSpacing.lg),
          ForfeitTimerCard(scheduledAt: widget.match.scheduledAt!),
        ],
        const SizedBox(height: ArenaSpacing.lg),
        ArenaButton(
          label: l10n.commonContinue,
          icon: Icons.arrow_forward_rounded,
          fullWidth: true,
          isLoading: _submitting,
          onPressed: _teamCtrl.text.trim().isEmpty ? null : _saveTeamName,
        ),
        const SizedBox(height: ArenaSpacing.sm),
        OpenChatLink(matchId: widget.match.id),
      ],
    );
  }

  /// Étape 2 : activation de l'enregistrement (APRÈS le nom d'équipe). C'est ici
  /// que la permission de capture d'écran est demandée.
  Widget _activateStep(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l10n.startRecordingActivateTitle, style: ArenaText.inputLabel),
        const SizedBox(height: ArenaSpacing.sm),
        CyanDashedContainer(
          child: Text(
            l10n.startRecordingActivateDesc,
            textAlign: TextAlign.center,
            style: ArenaText.small.copyWith(color: ArenaColors.silver),
          ),
        ),
        if (widget.match.scheduledAt != null) ...[
          const SizedBox(height: ArenaSpacing.lg),
          ForfeitTimerCard(scheduledAt: widget.match.scheduledAt!),
        ],
        const SizedBox(height: ArenaSpacing.lg),
        ArenaButton(
          label: l10n.startRecordingButton,
          icon: Icons.fiber_manual_record,
          fullWidth: true,
          isLoading: _submitting,
          onPressed: _startRecording,
        ),
        const SizedBox(height: ArenaSpacing.sm),
        OpenChatLink(matchId: widget.match.id),
      ],
    );
  }
}
