import 'package:arena/core/theme/arena_colors.dart';
import 'package:arena/core/theme/arena_theme.dart';
import 'package:arena/core/theme/arena_typography.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Branded text input.
///
/// Wraps [TextField] with the project's typography and decoration. Forms
/// in PHASE 2+ will plug `reactive_forms` controllers in via [controller].
class ArenaTextField extends StatelessWidget {
  const ArenaTextField({
    this.label,
    this.hint,
    this.helper,
    this.errorText,
    this.controller,
    this.initialValue,
    this.onChanged,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.prefixIcon,
    this.suffixIcon,
    this.enabled = true,
    this.maxLength,
    this.inputFormatters,
    this.autofocus = false,
    this.validator,
    super.key,
  }) : assert(
          controller == null || initialValue == null,
          'Pass either a controller or initialValue, not both.',
        );

  final String? label;
  final String? hint;
  final String? helper;
  final String? errorText;
  final TextEditingController? controller;
  final String? initialValue;
  final ValueChanged<String>? onChanged;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final bool enabled;
  final int? maxLength;
  final List<TextInputFormatter>? inputFormatters;
  final bool autofocus;
  final FormFieldValidator<String>? validator;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(label!, style: ArenaTypography.labelMedium),
          const SizedBox(height: ArenaSpacing.sm),
        ],
        TextFormField(
          controller: controller,
          initialValue: initialValue,
          onChanged: onChanged,
          obscureText: obscureText,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          enabled: enabled,
          maxLength: maxLength,
          inputFormatters: inputFormatters,
          autofocus: autofocus,
          validator: validator,
          style: ArenaTypography.bodyLarge,
          cursorColor: Theme.of(context).colorScheme.primary,
          decoration: InputDecoration(
            hintText: hint,
            errorText: errorText,
            helperText: helper,
            counterText: '',
            prefixIcon: prefixIcon == null
                ? null
                : Icon(prefixIcon, color: ArenaColors.textMuted, size: 20),
            suffixIcon: suffixIcon,
          ),
        ),
      ],
    );
  }
}
