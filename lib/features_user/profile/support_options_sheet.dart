import 'package:arena/core/router/user_router.dart';
import 'package:arena/core/theme/arena_theme.dart';
import 'package:arena/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

/// Adresse e-mail de support (repli hors-app / clients qui préfèrent l'e-mail).
const supportEmail = 'support@arena.gg';

/// Bottom-sheet « Contacter le support » offrant les deux canaux :
///   1. Discuter avec l'équipe → fil de support in-app (`/support-chat`).
///   2. Écrire un e-mail → `mailto:support@arena.gg`.
///
/// Mutualisé entre la page « À propos » (lien Support) et les Réglages
/// (section Aide) pour rester cohérent.
Future<void> showSupportOptionsSheet(BuildContext context) {
  final l10n = AppLocalizations.of(context);
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: ArenaColors.carbon,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (sheetCtx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.only(top: ArenaSpacing.sm),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: ArenaColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              ArenaSpacing.lg,
              ArenaSpacing.lg,
              ArenaSpacing.lg,
              ArenaSpacing.sm,
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(l10n.supportOptionsTitle, style: ArenaText.h3),
            ),
          ),
          ListTile(
            leading: const Icon(
              Icons.forum_outlined,
              color: ArenaColors.signalBlue,
            ),
            title: Text(l10n.supportOptionChat),
            subtitle: Text(
              l10n.supportOptionChatSubtitle,
              style: ArenaText.small.copyWith(color: ArenaColors.textMuted),
            ),
            onTap: () {
              Navigator.of(sheetCtx).pop();
              context.push(UserRoutes.supportChat);
            },
          ),
          ListTile(
            leading: const Icon(
              Icons.mail_outline,
              color: ArenaColors.silver,
            ),
            title: Text(l10n.supportOptionEmail),
            subtitle: Text(
              supportEmail,
              style: ArenaText.small.copyWith(color: ArenaColors.textMuted),
            ),
            onTap: () async {
              Navigator.of(sheetCtx).pop();
              final messenger = ScaffoldMessenger.of(context);
              final uri = Uri(scheme: 'mailto', path: supportEmail);
              final ok = await launchUrl(uri);
              if (!ok) {
                messenger.showSnackBar(
                  const SnackBar(content: Text(supportEmail)),
                );
              }
            },
          ),
          const SizedBox(height: ArenaSpacing.sm),
        ],
      ),
    ),
  );
}
