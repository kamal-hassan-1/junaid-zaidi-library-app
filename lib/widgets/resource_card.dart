import 'package:flutter/widgets.dart';

import '../theme/theme.dart';
import 'app_text.dart';
import 'card.dart';

/// Home screen's icon-shortcut card, two per row, ~48% width. Extension of
/// the Book Card anatomy applied to the Home screen's resource-shortcut
/// grid (OPAC, HEC libraries, Explore Spaces, etc).
///
/// Renders as static (non-tappable) when `onTap` is omitted. Fills whatever
/// width its parent gives it — callers are responsible for sizing (e.g.
/// wrapping two of these in a `Row`/`Wrap` with fixed widths).
class ResourceCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final AppAccent accent;

  const ResourceCard({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
    this.accent = AppAccent.brand,
  });

  @override
  Widget build(BuildContext context) {
    final colors = useTheme(context);
    final accentColor = resolveAccent(colors, accent);

    return AppCard(
      onTap: onTap,
      child: ConstrainedBox(
        // AppCard's default padding is AppSpacing.ms on all sides, so the
        // content area needs to be tall enough that padding + content
        // matches the original's minHeight: 116 on the outer card.
        constraints: const BoxConstraints(minHeight: 116 - AppSpacing.ms * 2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadius.sm),
                color: withOpacity(accentColor, 0.12),
              ),
              alignment: Alignment.center,
              child: Icon(icon, size: 20, color: accentColor),
            ),
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.sm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppText(
                    title,
                    variant: 'bodyBase',
                    tone: 'primary',
                    maxLines: 2,
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: AppSpacing.xs),
                    AppText(
                      subtitle!,
                      variant: 'bodySmall',
                      tone: 'secondary',
                      maxLines: 1,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
