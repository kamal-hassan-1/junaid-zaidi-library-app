import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import 'app_text.dart';
import '../theme/theme.dart';

/// Dropdown/select field primitive for the auth flow. Same visual shell
/// as AppTextField (label above, bordered box, inline error text below)
/// but backed by a fixed set of options instead of free text â€” used for
/// Campus on the signup forms.
class AppDropdownField extends StatelessWidget {
  final String label;
  final String? value;
  final List<String> options;
  final String? placeholder;
  final String? errorText;
  final IconData? prefixIcon;
  final ValueChanged<String?> onChanged;
  final bool enabled;

  const AppDropdownField({
    super.key,
    required this.label,
    required this.options,
    required this.onChanged,
    this.value,
    this.placeholder,
    this.errorText,
    this.prefixIcon,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final colors = useTheme(context);
    final hasError = errorText != null && errorText!.isNotEmpty;

    final Color borderColor = hasError ? colors.error : colors.border;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText(label, variant: 'bodySmall', tone: 'secondary'),
        const SizedBox(height: AppSpacing.xs),
        Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          decoration: BoxDecoration(
            color: colors.background.secondary,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: borderColor, width: hasError ? 1.5 : 1),
          ),
          child: Row(
            children: [
              if (prefixIcon != null) ...[
                Icon(prefixIcon, size: 18, color: colors.icon),
                const SizedBox(width: AppSpacing.sm),
              ],
              Expanded(
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: value,
                    isExpanded: true,
                    isDense: true,
                    icon: Icon(LucideIcons.chevron_down, size: 18, color: colors.icon),
                    hint: placeholder != null
                        ? AppText(placeholder!, variant: 'bodyBase', tone: 'tertiary')
                        : null,
                    style: AppTypography.bodyBase.toTextStyle(color: colors.text.primary),
                    dropdownColor: colors.background.secondary,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    items: options
                        .map(
                          (option) => DropdownMenuItem<String>(
                            value: option,
                            child: Text(option),
                          ),
                        )
                        .toList(),
                    onChanged: enabled ? onChanged : null,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (hasError) ...[
          const SizedBox(height: AppSpacing.xs),
          AppText(errorText!, variant: 'bodySmall', tone: 'error'),
        ],
      ],
    );
  }
}
