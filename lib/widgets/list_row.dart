import 'package:flutter/widgets.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../theme/theme.dart';
import 'app_text.dart';

/// List Row — used for search results, "My Books", the More-tab menu and
/// About sub-section list.
///
/// Rendered as a plain (non-tappable) row when `onTap` is omitted, so items
/// that are intentionally inert (e.g. "Coming soon") read as inert rather
/// than fake-interactive.
///
/// `accent`, if provided, renders the icon inside a tinted rounded-square
/// chip (iOS-Settings-style) instead of a bare icon, for screens that want
/// per-item color categorization.
class ListRow extends StatelessWidget {
  final IconData? icon;
  final String label;
  final String? secondaryLabel;
  final VoidCallback? onTap;
  final bool showChevron;
  final Widget? badge;
  final bool showDivider;
  final AppAccent? accent;

  const ListRow({
    super.key,
    this.icon,
    required this.label,
    this.secondaryLabel,
    this.onTap,
    this.showChevron = true,
    this.badge,
    this.showDivider = true,
    this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final colors = useTheme(context);
    final accentColor = accent != null ? resolveAccent(colors, accent) : null;

    final content = Container(
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.ms,
        horizontal: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        border: showDivider
            ? Border(bottom: BorderSide(color: colors.border))
            : null,
      ),
      child: Row(
        children: [
          if (icon != null) ...[
            if (accentColor != null)
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  color: withOpacity(accentColor, 0.12),
                ),
                alignment: Alignment.center,
                child: Icon(icon, size: 18, color: accentColor),
              )
            else
              SizedBox(
                width: AppSpacing.lg,
                child: Icon(icon, size: 20, color: colors.icon),
              ),
            const SizedBox(width: AppSpacing.ms),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                AppText(label, variant: 'bodyBase', tone: 'primary'),
                if (secondaryLabel != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  AppText(secondaryLabel!, variant: 'bodySmall', tone: 'secondary'),
                ],
              ],
            ),
          ),
          if (badge != null) ...[
            const SizedBox(width: AppSpacing.ms),
            badge!,
          ],
          if (onTap != null && showChevron) ...[
            const SizedBox(width: AppSpacing.ms),
            Icon(LucideIcons.chevron_right, size: 18, color: colors.icon),
          ],
        ],
      ),
    );

    if (onTap == null) {
      return content;
    }

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: content,
    );
  }
}
