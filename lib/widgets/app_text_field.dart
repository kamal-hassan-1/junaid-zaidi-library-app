import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../theme/theme.dart';
import 'app_text.dart';

/// Text field primitive for the auth flow. Mirrors SearchInput's
/// focus-border treatment (border.tertiary color while unfocused, text
/// primary color while focused) but as a labeled block field rather than
/// a pill, since forms need labels + inline error text.
class AppTextField extends StatefulWidget {
  final String label;
  final TextEditingController controller;
  final String? placeholder;
  final String? errorText;
  final bool obscureText;
  final TextInputType keyboardType;
  final IconData? prefixIcon;
  final ValueChanged<String>? onChanged;
  final bool enabled;

  const AppTextField({
    super.key,
    required this.label,
    required this.controller,
    this.placeholder,
    this.errorText,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.prefixIcon,
    this.onChanged,
    this.enabled = true,
  });

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  final FocusNode _focusNode = FocusNode();
  bool _isFocused = false;
  bool _obscure = true;

  @override
  void initState() {
    super.initState();
    _obscure = widget.obscureText;
    _focusNode.addListener(() => setState(() => _isFocused = _focusNode.hasFocus));
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = useTheme(context);
    final hasError = widget.errorText != null && widget.errorText!.isNotEmpty;

    final Color borderColor = hasError
        ? colors.error
        : _isFocused
        ? colors.brand
        : colors.border;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText(widget.label, variant: 'bodySmall', tone: 'secondary'),
        const SizedBox(height: AppSpacing.xs),
        Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          decoration: BoxDecoration(
            color: colors.background.secondary,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: borderColor, width: _isFocused || hasError ? 1.5 : 1),
          ),
          child: Row(
            children: [
              if (widget.prefixIcon != null) ...[
                Icon(widget.prefixIcon, size: 18, color: colors.icon),
                const SizedBox(width: AppSpacing.sm),
              ],
              Expanded(
                child: TextField(
                  controller: widget.controller,
                  focusNode: _focusNode,
                  enabled: widget.enabled,
                  obscureText: widget.obscureText ? _obscure : false,
                  keyboardType: widget.keyboardType,
                  onChanged: widget.onChanged,
                  style: AppTypography.bodyBase.toTextStyle(color: colors.text.primary),
                  decoration: InputDecoration(
                    hintText: widget.placeholder,
                    hintStyle: AppTypography.bodyBase.toTextStyle(color: colors.text.tertiary),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
              if (widget.obscureText) ...[
                const SizedBox(width: AppSpacing.sm),
                GestureDetector(
                  onTap: () => setState(() => _obscure = !_obscure),
                  behavior: HitTestBehavior.opaque,
                  child: Semantics(
                    label: _obscure ? 'Show password' : 'Hide password',
                    button: true,
                    child: Icon(
                      _obscure ? LucideIcons.eye : LucideIcons.eye_off,
                      size: 18,
                      color: colors.icon,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        if (hasError) ...[
          const SizedBox(height: AppSpacing.xs),
          AppText(widget.errorText!, variant: 'bodySmall', tone: 'error'),
        ],
      ],
    );
  }
}