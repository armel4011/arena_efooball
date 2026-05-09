import 'package:arena/core/theme/arena_theme.dart';
import 'package:flutter/material.dart';

/// Subtle 1 px divider using `ArenaColors.border` (6 % white).
///
/// [hi] = true switches to `borderHi` (12 % white) for higher contrast.
/// Maps to the `--border` / `--border-hi` CSS vars in `arena_v2.html`.
class ArenaDivider extends StatelessWidget {
  const ArenaDivider({this.indent = 0, this.endIndent = 0, this.hi = false, super.key});

  final double indent;
  final double endIndent;
  final bool hi;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: indent, right: endIndent),
      child: Container(
        height: 1,
        color: hi ? ArenaColors.borderHi : ArenaColors.border,
      ),
    );
  }
}
