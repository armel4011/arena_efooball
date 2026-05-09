import 'package:arena/core/theme/arena_theme.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// THE iconic 72 dp anti-cheat overlay button (#17 MatchInProgressOverlay).
///
/// Round, neon-red, with a continuous pulsing glow ring (1500 ms). When
/// [timer] is provided it renders below the "ARENA" label in JetBrains Mono
/// 11 px — typical use is the elapsed match time.
///
/// Maps to `.floating-btn` in `arena_v2.html`.
class ArenaFloatingButton extends StatefulWidget {
  const ArenaFloatingButton({
    required this.onTap,
    this.onLongPress,
    this.timer,
    this.diameter = 72,
    super.key,
  });

  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final String? timer;
  final double diameter;

  @override
  State<ArenaFloatingButton> createState() => _ArenaFloatingButtonState();
}

class _ArenaFloatingButtonState extends State<ArenaFloatingButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: ArenaDurations.pulse)
      ..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        final t = _ctrl.value;
        final ringSize = widget.diameter + (t * 16);
        return SizedBox(
          width: widget.diameter + 16,
          height: widget.diameter + 16,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: ringSize,
                height: ringSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: ArenaColors.neonRed.withValues(alpha: (1 - t) * 0.4),
                ),
              ),
              GestureDetector(
                onTap: widget.onTap,
                onLongPress: widget.onLongPress,
                child: Container(
                  width: widget.diameter,
                  height: widget.diameter,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: ArenaColors.neonRed,
                    boxShadow: [
                      BoxShadow(
                        color: ArenaColors.neonRed.withValues(alpha: 0.4),
                        blurRadius: 20,
                      ),
                      const BoxShadow(
                        color: Color(0x66000000),
                        blurRadius: 16,
                        offset: Offset(0, 6),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'ARENA',
                        style: GoogleFonts.bebasNeue(
                          color: Colors.white,
                          fontSize: 14,
                          letterSpacing: 1.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (widget.timer != null)
                        Text(
                          widget.timer!,
                          style: GoogleFonts.jetBrainsMono(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
