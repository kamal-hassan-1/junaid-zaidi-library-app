import 'package:flutter/widgets.dart';

import '../theme/theme.dart';

/// Shared screen shell: safe-area handling, the design system's grid
/// margin, and an optional near-white background photo. Any screen can opt
/// into the same photo treatment by passing `backgroundImage`.
///
/// Safe area excludes the bottom edge — the bottom tab bar/nested stack
/// handles that, matching the original's `edges: ["top", "left", "right"]`.
class ScreenContainer extends StatelessWidget {
  final Widget child;
  final bool scroll;
  final ImageProvider? backgroundImage;
  final double backgroundImageOpacity;
  final EdgeInsetsGeometry? contentPadding;

  const ScreenContainer({
    super.key,
    required this.child,
    this.scroll = false,
    this.backgroundImage,
    this.backgroundImageOpacity = 0.06,
    this.contentPadding,
  });

  @override
  Widget build(BuildContext context) {
    final colors = useTheme(context);

    Widget content = scroll
        ? SingleChildScrollView(
            padding: contentPadding ??
                EdgeInsets.all(AppGrid.margin).copyWith(bottom: AppGrid.margin * 2),
            child: child,
          )
        : Padding(
            padding: contentPadding ?? const EdgeInsets.all(AppGrid.margin),
            child: child,
          );

    // Non-scrolling content mirrors the original's `flex: 1` View — fill
    // whatever space the screen shell is given.
    if (!scroll) {
      content = SizedBox.expand(child: content);
    }

    return Container(
      color: colors.background.primary,
      child: SafeArea(
        top: true,
        left: true,
        right: true,
        bottom: false,
        child: backgroundImage != null
            ? Stack(
                children: [
                  Positioned.fill(
                    child: Opacity(
                      opacity: backgroundImageOpacity,
                      child: Image(image: backgroundImage!, fit: BoxFit.cover),
                    ),
                  ),
                  scroll ? content : Positioned.fill(child: content),
                ],
              )
            : content,
      ),
    );
  }
}
