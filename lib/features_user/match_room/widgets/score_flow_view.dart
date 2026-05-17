import 'package:arena/core/services/score_proof_uploader.dart';
import 'package:arena/core/theme/arena_theme.dart';
import 'package:arena/data/models/arena_match.dart';
import 'package:arena/data/repositories/match_repository.dart';
import 'package:arena/features_shared/widgets/arena_button.dart';
import 'package:arena/features_shared/widgets/empty_state.dart';
import 'package:arena/features_shared/widgets/error_state.dart';
import 'package:arena/features_user/auth/auth_providers.dart';
import 'package:arena/features_user/match_room/match_room_page.dart'
    show MatchRole;
import 'package:arena/features_user/match_room/match_room_providers.dart';
import 'package:arena/features_user/match_room/widgets/match_room_internals.dart';
import 'package:arena/features_user/match_room/widgets/open_chat_link.dart';
import 'package:arena/features_user/match_room/widgets/score_edit_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Step 3 — Score submission flow. Permet à chaque joueur de saisir
/// son score (avec tirs au but optionnels en KO) + une preuve photo/vidéo.
/// Quand les deux soumissions arrivent, déclenche `resolveSubmissions`
/// (compare → completed ou disputed). État optimistic survit aux remounts
/// via `pendingScoreSubmissionProvider`.
class ScoreFlowView extends ConsumerStatefulWidget {
  const ScoreFlowView({required this.match, required this.role, super.key});

  final ArenaMatch match;
  final MatchRole role;

  @override
  ConsumerState<ScoreFlowView> createState() => _ScoreFlowViewState();
}

class _ScoreFlowViewState extends ConsumerState<ScoreFlowView> {
  final _myScoreCtrl = TextEditingController();
  final _oppScoreCtrl = TextEditingController();
  final _myPenCtrl = TextEditingController();
  final _oppPenCtrl = TextEditingController();
  bool _viaPenalties = false;
  bool _submitting = false;
  String? _error;
  bool _resolutionTriggered = false;
  // Optional proof attached to this submission (screenshot or short
  // clip). The file is uploaded immediately on pick so a slow network
  // doesn't block the actual SOUMETTRE tap; the storage path is then
  // stamped on the score_submitted payload.
  PickedProof? _proof;
  String? _uploadedProofPath;
  bool _pickingProof = false;
  String? _proofError;

  @override
  void dispose() {
    _myScoreCtrl.dispose();
    _oppScoreCtrl.dispose();
    _myPenCtrl.dispose();
    _oppPenCtrl.dispose();
    super.dispose();
  }

  bool get _isPlayer1 => widget.role == MatchRole.player1;
  bool get _isKnockout => widget.match.groupId == null;

  Future<void> _submit() async {
    final my = int.tryParse(_myScoreCtrl.text.trim());
    final opp = int.tryParse(_oppScoreCtrl.text.trim());
    if (my == null || opp == null || my < 0 || my > 99 || opp < 0 || opp > 99) {
      setState(() => _error = 'Scores attendus entre 0 et 99.');
      return;
    }

    int? myPen;
    int? oppPen;
    if (_viaPenalties) {
      if (my != opp) {
        setState(() {
          _error = 'Le score réglementaire doit être à égalité avant'
              ' les tirs au but.';
        });
        return;
      }
      myPen = int.tryParse(_myPenCtrl.text.trim());
      oppPen = int.tryParse(_oppPenCtrl.text.trim());
      if (myPen == null ||
          oppPen == null ||
          myPen < 0 ||
          oppPen < 0 ||
          myPen > 30 ||
          oppPen > 30) {
        setState(() => _error = 'Tirs au but attendus entre 0 et 30.');
        return;
      }
      if (myPen == oppPen) {
        setState(() {
          _error = 'Les tirs au but ne peuvent pas finir à égalité.';
        });
        return;
      }
    }

    final selfId = ref.read(currentSessionProvider)?.user.id;
    if (selfId == null) return;

    final s1 = _isPlayer1 ? my : opp;
    final s2 = _isPlayer1 ? opp : my;
    final pen1 = _viaPenalties ? (_isPlayer1 ? myPen : oppPen) : null;
    final pen2 = _viaPenalties ? (_isPlayer1 ? oppPen : myPen) : null;

    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      await ref.read(matchRepositoryProvider).submitScore(
            matchId: widget.match.id,
            byProfileId: selfId,
            scoreP1: s1,
            scoreP2: s2,
            decidedByPenalties: _viaPenalties,
            penaltyP1: pen1,
            penaltyP2: pen2,
            proofPath: _uploadedProofPath,
            proofMimeType: _proof?.mimeType,
          );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = 'Impossible de soumettre : $e';
      });
      return;
    }
    if (!mounted) return;
    ref
        .read(pendingScoreSubmissionProvider(widget.match.id).notifier)
        .state = {
      'created_by': selfId,
      'payload': {
        'score1': s1,
        'score2': s2,
        if (_viaPenalties) ...{
          'via_penalties': true,
          'penalty1': pen1,
          'penalty2': pen2,
        },
        if (_uploadedProofPath != null) 'proof_path': _uploadedProofPath,
        if (_proof?.mimeType != null) 'proof_mime': _proof!.mimeType,
      },
    };
    setState(() => _submitting = false);
  }

  Future<void> _pickAndUploadProof() async {
    if (_pickingProof || _submitting) return;
    final selfId = ref.read(currentSessionProvider)?.user.id;
    if (selfId == null) return;

    setState(() {
      _pickingProof = true;
      _proofError = null;
    });
    try {
      final picked = await ref.read(scoreProofUploaderProvider).pick();
      if (picked == null) {
        if (!mounted) return;
        setState(() => _pickingProof = false);
        return;
      }
      final storagePath = await ref.read(scoreProofUploaderProvider).upload(
            matchId: widget.match.id,
            userId: selfId,
            proof: picked,
          );
      if (!mounted) return;
      setState(() {
        _proof = picked;
        _uploadedProofPath = storagePath;
        _pickingProof = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _pickingProof = false;
        _proofError = e is FormatException ? e.message : 'Upload impossible : $e';
      });
    }
  }

  void _clearProof() {
    if (_submitting) return;
    setState(() {
      _proof = null;
      _uploadedProofPath = null;
      _proofError = null;
    });
  }

  Future<void> _resolve(
    Map<String, dynamic> p1Submission,
    Map<String, dynamic> p2Submission,
  ) async {
    await resolveSubmissions(
      match: widget.match,
      p1Submission: p1Submission,
      p2Submission: p2Submission,
      repo: ref.read(matchRepositoryProvider),
      onError: (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur de résolution : $e')),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final selfId = ref.watch(currentSessionProvider)?.user.id;
    if (selfId == null) {
      return const EmptyState(
        icon: Icons.lock_outline,
        title: 'Session expirée',
        description: 'Reconnecte-toi pour saisir un score.',
      );
    }

    final submissionsAsync =
        ref.watch(matchScoreSubmissionsProvider(widget.match.id));

    return submissionsAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: ArenaSpacing.xxl),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => ErrorState(
        description: e.toString(),
        onRetry: () => ref.invalidate(
          matchScoreSubmissionsProvider(widget.match.id),
        ),
      ),
      data: (submissions) {
        final byPlayer = latestSubmissionPerPlayer(submissions);
        final optimistic =
            ref.watch(pendingScoreSubmissionProvider(widget.match.id));
        if (optimistic != null && !byPlayer.containsKey(selfId)) {
          byPlayer[selfId] = optimistic;
        }
        final mine = byPlayer[selfId];
        final p1Sub = widget.match.player1Id == null
            ? null
            : byPlayer[widget.match.player1Id];
        final p2Sub = widget.match.player2Id == null
            ? null
            : byPlayer[widget.match.player2Id];
        final bothSubmitted = p1Sub != null && p2Sub != null;

        if (bothSubmitted && !_resolutionTriggered) {
          _resolutionTriggered = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _resolve(p1Sub, p2Sub);
          });
        }

        if (mine == null) {
          return _buildForm();
        }
        return _buildAfterSubmit(mine, bothSubmitted);
      },
    );
  }

  Widget _buildForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'SAISIS LE SCORE FINAL',
          style: ArenaText.inputLabel,
        ),
        const SizedBox(height: ArenaSpacing.sm),
        Text(
          'Entre les buts de chaque côté. Si vos deux saisies'
          ' concordent, le match est validé automatiquement.',
          style: ArenaText.bodyMuted,
        ),
        const SizedBox(height: ArenaSpacing.lg),
        Row(
          children: [
            Expanded(
              child: ScoreField(
                label: 'Mon score',
                controller: _myScoreCtrl,
                enabled: !_submitting,
                action: TextInputAction.next,
              ),
            ),
            const SizedBox(width: ArenaSpacing.md),
            Expanded(
              child: ScoreField(
                label: 'Score adversaire',
                controller: _oppScoreCtrl,
                enabled: !_submitting,
                action: _isKnockout
                    ? TextInputAction.next
                    : TextInputAction.done,
              ),
            ),
          ],
        ),
        if (_isKnockout) ...[
          const SizedBox(height: ArenaSpacing.md),
          SwitchListTile.adaptive(
            title: Text(
              'Match décidé aux tirs au but',
              style: ArenaText.body,
            ),
            subtitle: Text(
              'À cocher uniquement si le score réglementaire est à égalité.',
              style: ArenaText.small.copyWith(color: ArenaColors.silver),
            ),
            value: _viaPenalties,
            contentPadding: EdgeInsets.zero,
            onChanged: _submitting
                ? null
                : (v) => setState(() {
                      _viaPenalties = v;
                      if (!v) {
                        _myPenCtrl.clear();
                        _oppPenCtrl.clear();
                      }
                    }),
          ),
          if (_viaPenalties) ...[
            const SizedBox(height: ArenaSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: ScoreField(
                    label: 'Mes tirs au but',
                    controller: _myPenCtrl,
                    enabled: !_submitting,
                    action: TextInputAction.next,
                  ),
                ),
                const SizedBox(width: ArenaSpacing.md),
                Expanded(
                  child: ScoreField(
                    label: 'Tirs adversaire',
                    controller: _oppPenCtrl,
                    enabled: !_submitting,
                    action: TextInputAction.done,
                  ),
                ),
              ],
            ),
          ],
        ],
        const SizedBox(height: ArenaSpacing.lg),
        _ProofAttachmentBlock(
          proof: _proof,
          uploading: _pickingProof,
          submitting: _submitting,
          error: _proofError,
          onPick: _pickAndUploadProof,
          onClear: _clearProof,
        ),
        if (_error != null) ...[
          const SizedBox(height: ArenaSpacing.sm),
          Text(
            _error!,
            style: ArenaText.bodyMuted.copyWith(color: ArenaColors.neonRed),
          ),
        ],
        const SizedBox(height: ArenaSpacing.lg),
        ArenaButton(
          label: 'SOUMETTRE LE SCORE',
          icon: Icons.check_circle_outline,
          fullWidth: true,
          isLoading: _submitting,
          onPressed: _submit,
        ),
        const SizedBox(height: ArenaSpacing.sm),
        OpenChatLink(matchId: widget.match.id),
      ],
    );
  }

  Widget _buildAfterSubmit(Map<String, dynamic> mine, bool bothSubmitted) {
    final pl = (mine['payload'] as Map?)?.cast<String, dynamic>() ?? {};
    final s1 = pl['score1'] as int? ?? 0;
    final s2 = pl['score2'] as int? ?? 0;
    final myGoals = _isPlayer1 ? s1 : s2;
    final oppGoals = _isPlayer1 ? s2 : s1;
    final viaPen = pl['via_penalties'] == true;
    final myPen = viaPen
        ? (_isPlayer1 ? pl['penalty1'] as int? : pl['penalty2'] as int?)
        : null;
    final oppPen = viaPen
        ? (_isPlayer1 ? pl['penalty2'] as int? : pl['penalty1'] as int?)
        : null;

    return Container(
      padding: const EdgeInsets.all(ArenaSpacing.lg),
      decoration: arenaWarningCardDecoration(),
      child: Column(
        children: [
          Icon(
            bothSubmitted ? Icons.hourglass_top : Icons.hourglass_bottom,
            color: ArenaColors.statusWarn,
            size: 32,
          ),
          const SizedBox(height: ArenaSpacing.sm),
          Text(
            bothSubmitted
                ? 'VALIDATION EN COURS'
                : 'EN ATTENTE DE TON ADVERSAIRE',
            style: ArenaText.inputLabel.copyWith(
              color: ArenaColors.statusWarn,
            ),
          ),
          const SizedBox(height: ArenaSpacing.sm),
          Text(
            'Tu as soumis : $myGoals — $oppGoals',
            style: ArenaText.h2,
          ),
          if (viaPen && myPen != null && oppPen != null) ...[
            const SizedBox(height: 4),
            Text(
              'Aux tirs au but : $myPen — $oppPen',
              style: ArenaText.small.copyWith(color: ArenaColors.silver),
            ),
          ],
          const SizedBox(height: ArenaSpacing.sm),
          Text(
            bothSubmitted
                ? 'On compare les scores des deux joueurs…'
                : "Ton adversaire n'a pas encore saisi son score.",
            textAlign: TextAlign.center,
            style: ArenaText.small.copyWith(color: ArenaColors.silver),
          ),
          if (bothSubmitted) ...[
            const SizedBox(height: ArenaSpacing.md),
            const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ],
        ],
      ),
    );
  }
}

class _ProofAttachmentBlock extends StatelessWidget {
  const _ProofAttachmentBlock({
    required this.proof,
    required this.uploading,
    required this.submitting,
    required this.error,
    required this.onPick,
    required this.onClear,
  });

  final PickedProof? proof;
  final bool uploading;
  final bool submitting;
  final String? error;
  final VoidCallback onPick;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final attached = proof != null;
    return Container(
      padding: const EdgeInsets.all(ArenaSpacing.md),
      decoration: BoxDecoration(
        color: attached
            ? ArenaColors.success.withValues(alpha: 0.10)
            : ArenaColors.carbon,
        borderRadius: BorderRadius.circular(ArenaRadius.md),
        border: Border.all(
          color: attached
              ? ArenaColors.success.withValues(alpha: 0.5)
              : ArenaColors.borderHi,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                attached
                    ? Icons.check_circle
                    : Icons.add_photo_alternate_outlined,
                color: attached ? ArenaColors.success : ArenaColors.silver,
                size: 18,
              ),
              const SizedBox(width: ArenaSpacing.sm),
              Expanded(
                child: Text(
                  attached
                      ? 'Preuve attachée'
                      : 'Joins une photo ou vidéo (recommandé)',
                  style: ArenaText.inputLabel.copyWith(
                    color: attached ? ArenaColors.success : ArenaColors.bone,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            attached
                ? '${proof!.displayName} · ${_humanSize(proof!.bytes)}'
                : "Capture d'écran de l'écran de fin du match ou clip de "
                    'la dernière action — utile en cas de litige.',
            style: ArenaText.small.copyWith(color: ArenaColors.silver),
          ),
          if (error != null) ...[
            const SizedBox(height: 6),
            Text(
              error!,
              style: ArenaText.small.copyWith(color: ArenaColors.neonRed),
            ),
          ],
          const SizedBox(height: ArenaSpacing.sm),
          if (uploading)
            Row(
              children: [
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: ArenaSpacing.sm),
                Text('Upload en cours…', style: ArenaText.bodyMuted),
              ],
            )
          else if (attached)
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.swap_horiz, size: 16),
                    label: const Text('Remplacer'),
                    onPressed: submitting ? null : onPick,
                  ),
                ),
                const SizedBox(width: ArenaSpacing.sm),
                IconButton(
                  icon: const Icon(Icons.close, color: ArenaColors.silver),
                  tooltip: 'Retirer la preuve',
                  onPressed: submitting ? null : onClear,
                ),
              ],
            )
          else
            OutlinedButton.icon(
              icon: const Icon(Icons.attach_file, size: 16),
              label: const Text('Choisir un fichier'),
              onPressed: submitting ? null : onPick,
            ),
        ],
      ),
    );
  }

  static String _humanSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(0)} Ko';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} Mo';
  }
}
