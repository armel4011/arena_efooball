import 'package:arena/core/theme/arena_theme.dart';
import 'package:flutter/material.dart';

/// iPhone bezel mockup used by `/_dev/widgets`.
///
/// 300×620 dp, 6 px black bezel, 38 px corner radius, plus a centered notch
/// (90×22, top 12). Inner screen renders [child] on the void background with
/// a 30 px corner radius. Maps to `.phone` / `.phone::before` in
/// `arena_v2.html`.
class ArenaPhoneFrame extends StatelessWidget {
  const ArenaPhoneFrame({required this.child, super.key});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 300,
      height: 620,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(38),
        border: Border.all(color: const Color(0xFF1A1A22), width: 6),
        boxShadow: const [
          BoxShadow(
            color: Color(0x99000000),
            blurRadius: 50,
            offset: Offset(0, 20),
          ),
        ],
      ),
      padding: const EdgeInsets.all(2),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(30),
            child: ColoredBox(color: ArenaColors.void_, child: child),
          ),
          Positioned(
            top: 12,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                width: 90,
                height: 22,
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(ArenaRadius.round),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
