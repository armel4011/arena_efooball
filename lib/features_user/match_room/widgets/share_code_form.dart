import 'package:arena/core/theme/arena_theme.dart';
import 'package:arena/data/models/arena_match.dart';
import 'package:arena/data/repositories/match_repository.dart';
import 'package:arena/features_shared/widgets/arena_button.dart';
import 'package:arena/features_user/auth/auth_providers.dart';
import 'package:arena/features_user/match_room/match_room_providers.dart';
import 'package:arena/features_user/match_room/widgets/cyan_dashed_container.dart';
import 'package:arena/features_user/match_room/widgets/forfeit_timer_card.dart';
import 'package:arena/features_user/match_room/widgets/open_chat_link.dart';
import 'package:arena/features_user/match_room/widgets/room_ready_view.dart'
    show CodeSharedInterstitial;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Step 1 — Share the room code (cyan dashed input + forfeit timer).
/// Le HOME saisit son code eFootball, l'envoie au repo, puis l'écran
/// passe sur `CodeSharedInterstitial` en optimistic via
/// `pendingRoomCodeProvider`.
class ShareCodeForm extends ConsumerStatefulWidget {
  const ShareCodeForm({required this.match, super.key});

  final ArenaMatch match;

  @override
  ConsumerState<ShareCodeForm> createState() => _ShareCodeFormState();
}

class _ShareCodeFormState extends ConsumerState<ShareCodeForm> {
  final _controller = TextEditingController();
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final raw = _controller.text.trim().toUpperCase();
    if (raw.length < 4 || raw.length > 12) {
      setState(() => _error = 'Le code doit faire entre 4 et 12 caractères.');
      return;
    }
    final selfId = ref.read(currentSessionProvider)?.user.id;
    if (selfId == null) return;

    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      await ref.read(matchRepositoryProvider).setRoomCode(
            matchId: widget.match.id,
            hostProfileId: selfId,
            code: raw,
          );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = 'Impossible de partager le code : $e';
      });
      return;
    }
    if (!mounted) return;
    ref.read(pendingRoomCodeProvider(widget.match.id).notifier).state = raw;
    setState(() => _submitting = false);
  }

  @override
  Widget build(BuildContext context) {
    final optimisticCode =
        ref.watch(pendingRoomCodeProvider(widget.match.id));
    if (optimisticCode != null) {
      return CodeSharedInterstitial(
        code: optimisticCode,
        matchId: widget.match.id,
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'CODE ROOM (HOME CRÉE)',
          style: ArenaText.inputLabel,
        ),
        const SizedBox(height: ArenaSpacing.sm),
        CyanDashedContainer(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Saisis ton code eFootball :',
                textAlign: TextAlign.center,
                style: ArenaText.bodyMuted.copyWith(
                  color: ArenaColors.silver,
                ),
              ),
              const SizedBox(height: ArenaSpacing.sm),
              _CodeInput(
                controller: _controller,
                enabled: !_submitting,
              ),
              const SizedBox(height: ArenaSpacing.sm),
              Text(
                widget.match.player2Id == null
                    ? 'Ton adversaire recevra ce code au chat dès envoi.'
                    : 'Ton adversaire reçoit ce code au chat dès envoi.',
                textAlign: TextAlign.center,
                style: ArenaText.small.copyWith(color: ArenaColors.silver),
              ),
            ],
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: ArenaSpacing.sm),
          Text(
            _error!,
            style: ArenaText.bodyMuted.copyWith(color: ArenaColors.neonRed),
          ),
        ],
        if (widget.match.scheduledAt != null) ...[
          const SizedBox(height: ArenaSpacing.lg),
          ForfeitTimerCard(scheduledAt: widget.match.scheduledAt!),
        ],
        const SizedBox(height: ArenaSpacing.lg),
        ArenaButton(
          label: 'ENVOYER LE CODE',
          icon: Icons.send_outlined,
          fullWidth: true,
          isLoading: _submitting,
          onPressed: _submit,
        ),
        const SizedBox(height: ArenaSpacing.sm),
        OpenChatLink(matchId: widget.match.id),
      ],
    );
  }
}

class _CodeInput extends StatelessWidget {
  const _CodeInput({required this.controller, required this.enabled});

  final TextEditingController controller;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      enabled: enabled,
      autofocus: true,
      maxLength: 12,
      textAlign: TextAlign.center,
      textCapitalization: TextCapitalization.characters,
      textInputAction: TextInputAction.done,
      style: ArenaText.roomCode.copyWith(
        color: ArenaColors.bone,
        fontSize: 22,
        letterSpacing: 4,
      ),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp('[A-Za-z0-9-]')),
        _UpperCaseFormatter(),
      ],
      decoration: InputDecoration(
        hintText: 'Ex: 8K3-TZ9',
        hintStyle: ArenaText.body.copyWith(
          color: ArenaColors.silverDim,
          letterSpacing: 4,
        ),
        counterText: '',
        filled: true,
        fillColor: ArenaColors.void_,
        contentPadding: const EdgeInsets.symmetric(
          vertical: ArenaSpacing.md,
          horizontal: ArenaSpacing.lg,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ArenaRadius.md),
          borderSide: const BorderSide(color: ArenaColors.gameEfoot, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ArenaRadius.md),
          borderSide: const BorderSide(color: ArenaColors.gameEfoot, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ArenaRadius.md),
          borderSide: const BorderSide(color: ArenaColors.gameEfoot, width: 2),
        ),
      ),
    );
  }
}

class _UpperCaseFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return newValue.copyWith(text: newValue.text.toUpperCase());
  }
}
