import 'package:arena/core/theme/arena_theme.dart';
import 'package:arena/data/repositories/app_update_repository.dart';
import 'package:arena/features_shared/widgets/arena_button.dart';
import 'package:arena/l10n/generated/app_localizations.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';

/// Dialog « Mise à jour disponible » (distribution APK hors Play Store).
///
/// Action « Mettre à jour » : tente un téléchargement + installation
/// in-app (permission REQUEST_INSTALL_PACKAGES → dio → open_filex qui
/// lance l'installateur système). En cas de refus de permission ou
/// d'échec, repli automatique sur l'ouverture de l'URL de l'APK dans le
/// navigateur. Non bloquant par défaut (bouton « Plus tard ») ; bloquant
/// si `status.mandatory`.
class UpdateAvailableDialog extends StatefulWidget {
  const UpdateAvailableDialog({required this.status, super.key});

  final UpdateStatus status;

  static Future<void> show(BuildContext context, UpdateStatus status) {
    return showDialog<void>(
      context: context,
      barrierDismissible: !status.mandatory,
      builder: (_) => UpdateAvailableDialog(status: status),
    );
  }

  @override
  State<UpdateAvailableDialog> createState() => _UpdateAvailableDialogState();
}

class _UpdateAvailableDialogState extends State<UpdateAvailableDialog> {
  bool _busy = false;
  double? _progress;

  Future<void> _update() async {
    if (_busy) return;
    setState(() => _busy = true);
    final apkUrl = widget.status.config.apkUrl;
    try {
      // 1. Permission « installer des applis inconnues » (Android 8+).
      final status = await Permission.requestInstallPackages.request();
      if (!status.isGranted) {
        await _openInBrowser(apkUrl);
        return;
      }
      // 2. Téléchargement de l'APK dans le dossier temporaire.
      final dir = await getTemporaryDirectory();
      final path = '${dir.path}/arena-update.apk';
      await Dio().download(
        apkUrl,
        path,
        onReceiveProgress: (received, total) {
          if (total > 0 && mounted) {
            setState(() => _progress = received / total);
          }
        },
      );
      // 3. Lance l'installateur système.
      final result = await OpenFilex.open(path);
      if (result.type != ResultType.done) {
        await _openInBrowser(apkUrl);
      } else if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (_) {
      await _openInBrowser(apkUrl);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Repli : ouvre l'URL de l'APK dans le navigateur (download manager).
  Future<void> _openInBrowser(String apkUrl) async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context);
    final ok = await launchUrl(
      Uri.parse(apkUrl),
      mode: LaunchMode.externalApplication,
    );
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop();
    } else {
      messenger.showSnackBar(SnackBar(content: Text(l10n.updateFailed)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cfg = widget.status.config;
    final changelog = cfg.changelog?.trim();

    return AlertDialog(
      backgroundColor: ArenaColors.carbon,
      title: Text(l10n.updateTitle, style: ArenaText.h3),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.updateMessage(cfg.latestVersion), style: ArenaText.body),
          if (changelog != null && changelog.isNotEmpty) ...[
            const SizedBox(height: ArenaSpacing.md),
            Text(
              l10n.updateChangelogLabel,
              style: ArenaText.small.copyWith(
                color: ArenaColors.silver,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(changelog, style: ArenaText.bodyMuted),
          ],
          if (_busy) ...[
            const SizedBox(height: ArenaSpacing.lg),
            LinearProgressIndicator(
              value: _progress,
              backgroundColor: ArenaColors.void_,
              color: ArenaColors.signalBlue,
            ),
            const SizedBox(height: 6),
            Text(
              _progress == null
                  ? l10n.updateDownloading
                  : '${l10n.updateDownloading} ${(_progress! * 100).round()}%',
              style: ArenaText.small.copyWith(color: ArenaColors.silver),
            ),
          ],
        ],
      ),
      actions: [
        if (!widget.status.mandatory)
          TextButton(
            onPressed: _busy ? null : () => Navigator.of(context).pop(),
            child: Text(
              l10n.updateLater,
              style: ArenaText.body.copyWith(color: ArenaColors.silver),
            ),
          ),
        ArenaButton(
          label: l10n.updateNow,
          onPressed: _busy ? null : _update,
          isLoading: _busy,
        ),
      ],
    );
  }
}
