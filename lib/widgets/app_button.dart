import 'package:flutter/material.dart';

import '../theme/theme.dart';
import 'app_text.dart';

/// Button primitive for the auth flow. Follows the same string-variant
/// convention as [AppText]/[Heading] rather than an enum, so it composes
/// the same way the rest of the design system does.
///
/// Variants:
/// - 'primary'   — filled brand background, white label (main CTA)
/// - 'secondary' — brand-colored outline, brand label (secondary action)
/// - 'text'      — no background/border, brand label (tertiary/link action)
class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final String variant;
  final bool isLoading;
  final bool fullWidth;
  final IconData? icon;

  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = 'primary',
    this.isLoading = false,
    this.fullWidth = true,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final colors = useTheme(context);
    final isDisabled = onPressed == null || isLoading;

    final Color background;
    final Color foreground;
    final BoxBorder? border;

    switch (variant) {
      case 'secondary':
        background = Colors.transparent;
        foreground = isDisabled ? colors.text.tertiary : colors.brand;
        border = Border.all(
          color: isDisabled ? colors.border : colors.brand,
          width: 1.5,
        );
        break;
      case 'text':
        background = Colors.transparent;
        foreground = isDisabled ? colors.text.tertiary : colors.brand;
        border = null;
        break;
      case 'primary':
      default:
        background = isDisabled ? colors.border : colors.brand;
        foreground = colors.text.onBrand;
        border = null;
    }

    final child = isLoading
        ? SizedBox(
      width: 20,
      height: 20,
      child: CircularProgressIndicator(strokeWidth: 2.2, color: foreground),
    )
        : Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 18, color: foreground),
          const SizedBox(width: AppSpacing.sm),
        ],
        AppText(
          label,
          variant: 'bodyBase',
          style: TextStyle(color: foreground, fontWeight: FontWeight.w600),
        ),
      ],
    );

    return SizedBox(
      width: fullWidth ? double.infinity : null,
      height: 52,
      child: Material(
        color: background,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: InkWell(
          onTap: isDisabled ? null : onPressed,
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: border,
            ),
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: child,
          ),
        ),
      ),
    );
  }
}