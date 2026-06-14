part of 'desktop_create_competition_page.dart';

// ─────────────────────────────────────────────────────────────────────
// Widgets privés
// ─────────────────────────────────────────────────────────────────────

class _StepsRail extends StatelessWidget {
  const _StepsRail({
    required this.steps,
    required this.current,
    required this.onTap,
  });

  final List<String> steps;
  final int current;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      backgroundColor: ArenaColors.carbon,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < steps.length; i++)
            _StepTile(
              index: i,
              label: steps[i],
              active: i == current,
              done: i < current,
              onTap: () => onTap(i),
            ),
        ],
      ),
    );
  }
}

class _StepTile extends StatelessWidget {
  const _StepTile({
    required this.index,
    required this.label,
    required this.active,
    required this.done,
    required this.onTap,
  });

  final int index;
  final String label;
  final bool active;
  final bool done;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = active ? ArenaColors.neonRed : ArenaColors.silver;
    return HoverButton(
      onPressed: onTap,
      builder: (context, states) {
        final hovered = states.isHovered;
        return Container(
          color: active
              ? ArenaColors.neonRed.withValues(alpha: 0.10)
              : hovered
                  ? ArenaColors.carbon2
                  : ArenaColors.carbon,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 24,
                height: 24,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: done
                      ? ArenaColors.statusOk
                      : (active
                          ? ArenaColors.neonRed
                          : ArenaColors.carbon2),
                ),
                child: done
                    ? const Icon(
                        FluentIcons.accept,
                        size: 12,
                        color: ArenaColors.bone,
                      )
                    : Text(
                        '${index + 1}',
                        style: GoogleFonts.spaceGrotesk(
                          color: ArenaColors.bone,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
              const SizedBox(width: 12),
              Text(
                label,
                style: GoogleFonts.spaceGrotesk(
                  color: active ? ArenaColors.bone : accent,
                  fontSize: 14,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        text.toUpperCase(),
        style: GoogleFonts.bebasNeue(
          color: ArenaColors.bone,
          fontSize: 20,
          letterSpacing: 1,
        ),
      ),
    );
  }
}

class _ReviewRow extends StatelessWidget {
  const _ReviewRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: ArenaColors.border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.spaceGrotesk(
                color: ArenaColors.silver,
                fontSize: 13,
              ),
            ),
          ),
          Text(
            value,
            style: GoogleFonts.spaceGrotesk(
              color: ArenaColors.bone,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
