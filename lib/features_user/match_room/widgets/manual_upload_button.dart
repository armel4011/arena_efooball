import 'package:arena/core/services/manual_video_upload_service.dart';
import 'package:arena/core/services/recording_uploader.dart';
import 'package:arena/features_shared/widgets/arena_button.dart';
import 'package:arena/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// CTA "Envoyer une vidéo de preuve" — used after a match completes
/// or when a dispute is opened, so the player can upload an
/// independent recording (gallery / external app) for admin review.
///
/// Reuses the same `streams` + Storage pipeline as the auto-recording
/// flow, so the dispute admin only ever has to inspect one place.
class ManualUploadButton extends ConsumerStatefulWidget {
  const ManualUploadButton({
    required this.matchId,
    required this.playerId,
    this.label,
    super.key,
  });

  final String matchId;
  final String playerId;

  /// Falls back to [AppLocalizations.manualUploadButtonLabel] when null.
  final String? label;

  @override
  ConsumerState<ManualUploadButton> createState() => _ManualUploadButtonState();
}

class _ManualUploadButtonState extends ConsumerState<ManualUploadButton> {
  bool _busy = false;

  Future<void> _onTap() async {
    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context);
    try {
      final outcome =
          await ref.read(manualVideoUploadServiceProvider).pickAndUpload(
                matchId: widget.matchId,
                playerId: widget.playerId,
              );
      if (!mounted) return;
      if (outcome.cancelled) {
        // Quiet on cancel — the user already knows they tapped Cancel.
        return;
      }
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.manualUploadSuccess)),
      );
    } on RecordingUploadException catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.manualUploadFailure(e.message))),
      );
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.manualUploadError(e))),
      );
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ArenaButton(
      label: widget.label ?? l10n.manualUploadButtonLabel,
      icon: Icons.upload_file,
      variant: ArenaButtonVariant.secondary,
      isLoading: _busy,
      onPressed: _onTap,
      fullWidth: true,
    );
  }
}
