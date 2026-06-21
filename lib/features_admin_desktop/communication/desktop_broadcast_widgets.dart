part of 'desktop_broadcast_page.dart';

// ─────────────────────────────────────────────────────────────────────────
// Widgets privés
// ─────────────────────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.bebasNeue(
        color: ArenaColors.silver,
        fontSize: 16,
        letterSpacing: 1.5,
      ),
    );
  }
}

class _ModeToggle extends StatelessWidget {
  const _ModeToggle({required this.mode, required this.onChanged});

  final _BroadcastMode mode;
  final ValueChanged<_BroadcastMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ToggleButton(
            checked: mode == _BroadcastMode.push,
            onChanged: (_) => onChanged(_BroadcastMode.push),
            child: const SizedBox(
              width: double.infinity,
              child: Center(child: Text('NOTIFICATION PUSH')),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ToggleButton(
            checked: mode == _BroadcastMode.chat,
            onChanged: (_) => onChanged(_BroadcastMode.chat),
            child: const SizedBox(
              width: double.infinity,
              child: Center(child: Text('MESSAGE CHAT')),
            ),
          ),
        ),
      ],
    );
  }
}

class _RecipientsBar extends StatelessWidget {
  const _RecipientsBar({required this.usersAsync});

  final AsyncValue<List<dynamic>> usersAsync;

  @override
  Widget build(BuildContext context) {
    return usersAsync.when(
      loading: () => const _RecipientCard(
        icon: FluentIcons.people,
        color: ArenaColors.silver,
        text: 'Calcul du nombre de destinataires…',
        showRing: true,
      ),
      error: (e, _) => _RecipientCard(
        icon: FluentIcons.error_badge,
        color: ArenaColors.neonRed,
        text: 'Erreur de filtre : $e',
      ),
      data: (list) => _RecipientCard(
        icon: list.isEmpty ? FluentIcons.warning : FluentIcons.group,
        color: list.isEmpty ? ArenaColors.statusWarn : ArenaColors.signalBlue,
        text: list.isEmpty
            ? 'Aucun destinataire — ajustez les filtres.'
            : '${list.length} destinataire(s) ciblé(s)',
      ),
    );
  }
}

class _RecipientCard extends StatelessWidget {
  const _RecipientCard({
    required this.icon,
    required this.color,
    required this.text,
    this.showRing = false,
  });

  final IconData icon;
  final Color color;
  final String text;
  final bool showRing;

  @override
  Widget build(BuildContext context) {
    return Card(
      backgroundColor: ArenaColors.carbon,
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          if (showRing)
            const SizedBox(
              height: 16,
              width: 16,
              child: ProgressRing(strokeWidth: 2),
            )
          else
            Icon(icon, color: color, size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.spaceGrotesk(
                color: ArenaColors.bone,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ImagePicker extends StatelessWidget {
  const _ImagePicker({
    required this.pickedImage,
    required this.uploadedUrl,
    required this.uploading,
    required this.onPick,
    required this.onClear,
  });

  final File? pickedImage;
  final String? uploadedUrl;
  final bool uploading;
  final VoidCallback onPick;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    if (pickedImage == null) {
      return Button(
        onPressed: onPick,
        child: const Padding(
          padding: EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(FluentIcons.photo2_add, size: 16),
              SizedBox(width: 8),
              Text('Ajouter une image (PNG / JPG / WebP)'),
            ],
          ),
        ),
      );
    }
    return Card(
      backgroundColor: ArenaColors.carbon,
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(ArenaRadius.sm),
            child: Image.file(
              pickedImage!,
              height: 160,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              if (uploading)
                const SizedBox(
                  height: 14,
                  width: 14,
                  child: ProgressRing(strokeWidth: 2),
                )
              else
                Icon(
                  uploadedUrl != null
                      ? FluentIcons.completed_solid
                      : FluentIcons.error_badge,
                  size: 16,
                  color: uploadedUrl != null
                      ? ArenaColors.statusOk
                      : ArenaColors.neonRed,
                ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  uploading
                      ? 'Upload en cours…'
                      : (uploadedUrl != null
                          ? 'Image prête à envoyer'
                          : 'Échec de l’upload'),
                  style: GoogleFonts.spaceGrotesk(
                    color: ArenaColors.silver,
                    fontSize: 12,
                  ),
                ),
              ),
              HyperlinkButton(
                onPressed: uploading ? null : onClear,
                child: Text(
                  'Retirer',
                  style: GoogleFonts.spaceGrotesk(
                    color: ArenaColors.neonRed,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
