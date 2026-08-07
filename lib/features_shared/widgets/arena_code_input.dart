import 'package:arena/core/theme/arena_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Champ de saisie de code segmenté (une case par chiffre).
///
/// Design pro : cases individuelles, la case « suivante » est mise en
/// évidence, coller un code entier fonctionne, et le remplissage/effacement
/// se fait au clavier natif. Un `TextField` transparent superposé capture la
/// frappe (coller + autofill OTP inclus) tandis que les cases ne font que
/// refléter [controller]`.text`.
class ArenaCodeInput extends StatefulWidget {
  const ArenaCodeInput({
    required this.controller,
    this.length = 6,
    this.enabled = true,
    this.hasError = false,
    this.autofocus = true,
    this.onCompleted,
    super.key,
  });

  final TextEditingController controller;
  final int length;
  final bool enabled;
  final bool hasError;
  final bool autofocus;

  /// Appelé une fois que les [length] chiffres sont saisis.
  final VoidCallback? onCompleted;

  @override
  State<ArenaCodeInput> createState() => _ArenaCodeInputState();
}

class _ArenaCodeInputState extends State<ArenaCodeInput> {
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode()..addListener(_onFocus);
    widget.controller.addListener(_onChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onChanged);
    _focusNode
      ..removeListener(_onFocus)
      ..dispose();
    super.dispose();
  }

  void _onFocus() {
    if (mounted) setState(() {});
  }

  void _onChanged() {
    if (mounted) setState(() {});
    if (widget.controller.text.length == widget.length) {
      widget.onCompleted?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = widget.controller.text;
    final focused = _focusNode.hasFocus;
    return Stack(
      children: [
        Row(
          children: [
            for (var i = 0; i < widget.length; i++)
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    left: i == 0 ? 0 : ArenaSpacing.xs,
                    right: i == widget.length - 1 ? 0 : ArenaSpacing.xs,
                  ),
                  child: _Cell(
                    char: i < text.length ? text[i] : '',
                    // Case active = la prochaine à remplir (curseur logique).
                    active: focused && i == text.length,
                    hasError: widget.hasError,
                  ),
                ),
              ),
          ],
        ),
        // TextField transparent superposé : capture frappe, coller et autofill.
        Positioned.fill(
          child: Opacity(
            opacity: 0,
            child: TextField(
              controller: widget.controller,
              focusNode: _focusNode,
              enabled: widget.enabled,
              autofocus: widget.autofocus,
              showCursor: false,
              enableInteractiveSelection: false,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.oneTimeCode],
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(widget.length),
              ],
              decoration: const InputDecoration(
                border: InputBorder.none,
                counterText: '',
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Cell extends StatelessWidget {
  const _Cell({
    required this.char,
    required this.active,
    required this.hasError,
  });

  final String char;
  final bool active;
  final bool hasError;

  @override
  Widget build(BuildContext context) {
    final filled = char.isNotEmpty;
    final Color borderColor;
    final double borderWidth;
    if (hasError) {
      borderColor = ArenaColors.neonRed;
      borderWidth = 1.5;
    } else if (active) {
      borderColor = ArenaColors.primary;
      borderWidth = 2;
    } else if (filled) {
      borderColor = ArenaColors.borderHi;
      borderWidth = 1;
    } else {
      borderColor = ArenaColors.border;
      borderWidth = 1;
    }
    return AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      height: 60,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: ArenaColors.surfaceLight,
        borderRadius: BorderRadius.circular(ArenaRadius.md),
        border: Border.all(color: borderColor, width: borderWidth),
      ),
      child: Text(
        char,
        style: ArenaTypography.codeLarge.copyWith(
          fontSize: 26,
          letterSpacing: 0,
        ),
      ),
    );
  }
}
