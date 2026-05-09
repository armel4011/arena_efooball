import 'package:arena/core/theme/arena_theme.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Circle avatar with gradient fill and centered initials.
///
/// Maps to `.avatar` in `arena_v2.html` (sizes `av-sm`/`av-md`/`av-lg`/`av-xl`).
/// 8 brand gradients are provided via [ArenaAvatarColor] — the user picks one
/// at signup and it is stored on `profiles.avatar_color`.
enum ArenaAvatarSize { sm, md, lg, xl }

enum ArenaAvatarColor { blue, red, green, orange, cyan, purple, pink, yellow }

class ArenaAvatar extends StatelessWidget {
  const ArenaAvatar({
    required this.initials,
    this.color = ArenaAvatarColor.blue,
    this.size = ArenaAvatarSize.md,
    this.selected = false,
    super.key,
  });

  final String initials;
  final ArenaAvatarColor color;
  final ArenaAvatarSize size;
  final bool selected;

  double get _diameter => switch (size) {
        ArenaAvatarSize.sm => 26,
        ArenaAvatarSize.md => 38,
        ArenaAvatarSize.lg => 52,
        ArenaAvatarSize.xl => 76,
      };

  double get _fontSize => switch (size) {
        ArenaAvatarSize.sm => 10,
        ArenaAvatarSize.md => 13,
        ArenaAvatarSize.lg => 17,
        ArenaAvatarSize.xl => 26,
      };

  LinearGradient get _gradient => switch (color) {
        ArenaAvatarColor.blue => ArenaColors.avBlue,
        ArenaAvatarColor.red => ArenaColors.avRed,
        ArenaAvatarColor.green => ArenaColors.avGreen,
        ArenaAvatarColor.orange => ArenaColors.avOrange,
        ArenaAvatarColor.cyan => ArenaColors.avCyan,
        ArenaAvatarColor.purple => ArenaColors.avPurple,
        ArenaAvatarColor.pink => ArenaColors.avPink,
        ArenaAvatarColor.yellow => ArenaColors.avYellow,
      };

  Color get _textColor =>
      color == ArenaAvatarColor.yellow ? Colors.black : ArenaColors.bone;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: _diameter,
      height: _diameter,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: _gradient,
        border: selected
            ? Border.all(color: ArenaColors.bone, width: 2)
            : null,
      ),
      alignment: Alignment.center,
      child: Text(
        initials.toUpperCase(),
        style: GoogleFonts.bebasNeue(
          fontSize: _fontSize,
          fontWeight: FontWeight.w700,
          color: _textColor,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
