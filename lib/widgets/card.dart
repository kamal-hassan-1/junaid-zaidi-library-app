import 'package:flutter/material.dart';

import '../theme/theme.dart';

/// Cross-platform elevation for surfaces sitting on top of the screen
/// background (AppCard, and any grouped-list containers that mirror
/// AppCard's surface treatment). Shadows read poorly on dark backgrounds,
/// so dark mode gets a 1px hairline border instead of a shadow — light
/// mode gets neither.
BoxDecoration cardShadowDecoration(SemanticColors colors) {
  if (colors.isDark) {
    return BoxDecoration(border: Border.all(color: colors.border, width: 1));
  }
  return const BoxDecoration(
    boxShadow: [
      BoxShadow(
        color: Color(0x140A1018),
        offset: Offset(0, 4),
        blurRadius: 12,
      ),
    ],
  );
}

/// Generic elevated surface container. Renders as a plain [Container] when
/// `onTap` is omitted so purely-static content never gets touch feedback it
/// can't act on; pass `onTap` to make it interactive.
class AppCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;

  const AppCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final colors = useTheme(context);
    final shadow = cardShadowDecoration(colors);

    final decoration = BoxDecoration(
      color: colors.background.secondary,
      borderRadius: BorderRadius.circular(AppRadius.md),
      border: shadow.border,
      boxShadow: shadow.boxShadow,
    );

    final resolvedPadding = padding ?? const EdgeInsets.all(AppSpacing.ms);

    if (onTap == null) {
      return Container(
        padding: resolvedPadding,
        decoration: decoration,
        child: child,
      );
    }

    return Container(
      decoration: decoration,
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: Padding(
            padding: resolvedPadding,
            child: child,
          ),
        ),
      ),
    );
  }
}
