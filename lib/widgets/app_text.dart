import 'package:flutter/widgets.dart';

import '../theme/theme.dart';

/// Base text primitive. Every other text-rendering widget (Heading, labels
/// inside ListRow/Badge, etc.) should compose this rather than calling
/// Flutter's own [Text] directly, so type scale and color-tier resolution
/// stay centralized in one place.
class AppText extends StatelessWidget {
  final String text;
  final String variant;
  final String tone;
  final TextStyle? style;
  final int? maxLines;
  final TextAlign? textAlign;
  final String? semanticsLabel;

  const AppText(
    this.text, {
    super.key,
    this.variant = 'bodyBase',
    this.tone = 'primary',
    this.style,
    this.maxLines,
    this.textAlign,
    this.semanticsLabel,
  });

  @override
  Widget build(BuildContext context) {
    final colors = useTheme(context);
    final type = AppTypography.byVariant[variant] ?? AppTypography.bodyBase;

    final Color color;
    switch (tone) {
      case 'secondary':
        color = colors.text.secondary;
        break;
      case 'tertiary':
        color = colors.text.tertiary;
        break;
      case 'onBrand':
        color = colors.text.onBrand;
        break;
      case 'brand':
        color = colors.brand;
        break;
      case 'error':
        color = colors.error;
        break;
      case 'primary':
      default:
        color = colors.text.primary;
    }

    final baseStyle = type.toTextStyle(color: color);
    final resolvedStyle = style == null ? baseStyle : baseStyle.merge(style);

    return Text(
      text,
      style: resolvedStyle,
      maxLines: maxLines,
      textAlign: textAlign,
      semanticsLabel: semanticsLabel,
    );
  }
}
