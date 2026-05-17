import 'package:arena/core/router/user_router.dart';
import 'package:arena/features_shared/widgets/arena_button.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Ghost button "OUVRIR LE CHAT" affiché en bas de chaque step du
/// match room.
class OpenChatLink extends StatelessWidget {
  const OpenChatLink({required this.matchId, super.key});

  final String matchId;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ArenaButton(
        label: 'OUVRIR LE CHAT',
        icon: Icons.chat_bubble_outline,
        variant: ArenaButtonVariant.ghost,
        onPressed: () => context.push(UserRoutes.matchChatPath(matchId)),
      ),
    );
  }
}
