part of 'super_admin_broadcast.dart';

class _ModeToggle extends StatelessWidget {
  const _ModeToggle({required this.mode, required this.onChanged});

  final _BroadcastMode mode;
  final ValueChanged<_BroadcastMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: ArenaColors.carbon,
        border: Border.all(color: ArenaColors.border),
        borderRadius: BorderRadius.circular(ArenaRadius.round),
      ),
      child: Row(
        children: [
          Expanded(
            child: _segment(
              label: '📨 NOTIF PUSH',
              active: mode == _BroadcastMode.push,
              onTap: () => onChanged(_BroadcastMode.push),
            ),
          ),
          Expanded(
            child: _segment(
              label: '💬 MESSAGE CHAT',
              active: mode == _BroadcastMode.chat,
              onTap: () => onChanged(_BroadcastMode.chat),
            ),
          ),
        ],
      ),
    );
  }

  Widget _segment({
    required String label,
    required bool active,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(ArenaRadius.round),
      child: AnimatedContainer(
        duration: ArenaDurations.short,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: active
              ? ArenaColors.signalBlue.withValues(alpha: 0.18)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(ArenaRadius.round),
        ),
        child: Center(
          child: Text(
            label,
            style: ArenaText.small.copyWith(
              color: active ? ArenaColors.signalBlue : ArenaColors.silver,
              fontWeight: active ? FontWeight.w700 : FontWeight.w500,
              letterSpacing: 0.8,
            ),
          ),
        ),
      ),
    );
  }
}

class _LoadingFilterButton extends StatelessWidget {
  const _LoadingFilterButton();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: ArenaSpacing.md,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: ArenaColors.carbon,
        borderRadius: BorderRadius.circular(ArenaRadius.round),
        border: Border.all(color: ArenaColors.border),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: ArenaColors.silver,
            ),
          ),
          SizedBox(width: 6),
          Text('Chargement…'),
        ],
      ),
    );
  }
}

class _ActiveCompetitionsBadges extends StatelessWidget {
  const _ActiveCompetitionsBadges({
    required this.competitionIds,
    required this.comps,
    required this.onClearOne,
  });

  final List<String> competitionIds;
  final List<FilterableCompetition> comps;
  final ValueChanged<String> onClearOne;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: ArenaSpacing.xs,
      runSpacing: ArenaSpacing.xs,
      children: [
        for (final id in competitionIds)
          _buildChip(id, comps.where((c) => c.id == id).firstOrNull),
      ],
    );
  }

  Widget _buildChip(String id, FilterableCompetition? c) {
    final label = c == null ? '🏆 Compétition ciblée' : '🏆 ${c.name}';
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: ArenaSpacing.sm,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: ArenaColors.signalBlue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(ArenaRadius.round),
        border: Border.all(color: ArenaColors.signalBlue),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              label,
              style: ArenaText.small.copyWith(
                color: ArenaColors.signalBlue,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 4),
          InkWell(
            onTap: () => onClearOne(id),
            child: const Icon(
              Icons.close_rounded,
              size: 14,
              color: ArenaColors.signalBlue,
            ),
          ),
        ],
      ),
    );
  }
}

class _RecipientCard extends StatelessWidget {
  const _RecipientCard({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(ArenaSpacing.md),
      decoration: BoxDecoration(
        color: ArenaColors.carbon,
        border: Border.all(color: ArenaColors.border),
        borderRadius: BorderRadius.circular(ArenaRadius.md),
      ),
      child: child,
    );
  }
}

class _ImagePickerCard extends StatelessWidget {
  const _ImagePickerCard({
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
      return InkWell(
        onTap: onPick,
        borderRadius: BorderRadius.circular(ArenaRadius.md),
        child: Container(
          padding: const EdgeInsets.all(ArenaSpacing.lg),
          decoration: BoxDecoration(
            color: ArenaColors.carbon,
            border: Border.all(
              color: ArenaColors.silverDim,
              style: BorderStyle.solid,
              width: 1.5,
            ),
            borderRadius: BorderRadius.circular(ArenaRadius.md),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.add_photo_alternate_outlined,
                color: ArenaColors.silver,
              ),
              const SizedBox(width: ArenaSpacing.sm),
              Expanded(
                child: Text(
                  'Ajouter une image (PNG / JPG / WebP · 5 MB max)',
                  style: ArenaText.bodyMuted,
                ),
              ),
            ],
          ),
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.all(ArenaSpacing.sm),
      decoration: BoxDecoration(
        color: ArenaColors.carbon,
        border: Border.all(color: ArenaColors.border),
        borderRadius: BorderRadius.circular(ArenaRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(ArenaRadius.sm),
            child: Image.file(
              pickedImage!,
              height: 140,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(height: ArenaSpacing.sm),
          Row(
            children: [
              Icon(
                uploading
                    ? Icons.cloud_upload_outlined
                    : (uploadedUrl != null
                        ? Icons.check_circle
                        : Icons.error_outline),
                color: uploading
                    ? ArenaColors.silver
                    : (uploadedUrl != null
                        ? ArenaColors.statusOk
                        : ArenaColors.neonRed),
                size: 18,
              ),
              const SizedBox(width: ArenaSpacing.xs),
              Expanded(
                child: Text(
                  uploading
                      ? 'Upload en cours…'
                      : (uploadedUrl != null
                          ? 'Image prête à envoyer'
                          : "Échec d'upload"),
                  style: ArenaText.small,
                ),
              ),
              TextButton(
                onPressed: uploading ? null : onClear,
                child: Text(
                  'Retirer',
                  style: ArenaText.small.copyWith(
                    color: ArenaColors.neonRed,
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
