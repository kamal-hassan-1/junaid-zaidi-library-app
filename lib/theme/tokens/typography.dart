import 'package:flutter/widgets.dart';

/// Font family: GT America Trial (originally specified) is an unlicensed
/// trial font. Substituted with Inter, matching the original Expo build's
/// own substitution (@expo-google-fonts/inter).
///
/// Font weights: Regular(400) for body tiers, Medium(500) for H4-H5,
/// Semibold(600) for H1-H3/Display.
class AppTypeSpec {
  final double fontSize;
  final double lineHeight; // px, matches the RN value this was ported from
  final FontWeight fontWeight;

  const AppTypeSpec({
    required this.fontSize,
    required this.lineHeight,
    required this.fontWeight,
  });

  TextStyle toTextStyle({Color? color}) {
    return TextStyle(
      fontFamily: 'Inter',
      fontSize: fontSize,
      height: lineHeight / fontSize,
      fontWeight: fontWeight,
      color: color,
    );
  }
}

/// Type scale, base 15px, ratio 1.25.
class AppTypography {
  const AppTypography._();

  static const display1 = AppTypeSpec(fontSize: 89, lineHeight: 100, fontWeight: FontWeight.w600);
  static const display2 = AppTypeSpec(fontSize: 72, lineHeight: 82, fontWeight: FontWeight.w600);
  static const h1 = AppTypeSpec(fontSize: 57, lineHeight: 66, fontWeight: FontWeight.w600);
  static const h2 = AppTypeSpec(fontSize: 46, lineHeight: 54, fontWeight: FontWeight.w600);
  static const h3 = AppTypeSpec(fontSize: 37, lineHeight: 44, fontWeight: FontWeight.w600);
  static const h4 = AppTypeSpec(fontSize: 29, lineHeight: 36, fontWeight: FontWeight.w500);
  static const h5 = AppTypeSpec(fontSize: 23, lineHeight: 29, fontWeight: FontWeight.w500);
  static const bodyLarge = AppTypeSpec(fontSize: 19, lineHeight: 26, fontWeight: FontWeight.w400);
  static const bodyBase = AppTypeSpec(fontSize: 15, lineHeight: 21, fontWeight: FontWeight.w400);
  static const bodySmall = AppTypeSpec(fontSize: 13, lineHeight: 18, fontWeight: FontWeight.w400);
  static const caption = AppTypeSpec(fontSize: 10, lineHeight: 14, fontWeight: FontWeight.w400);

  /// Name -> spec lookup, mirrors the JS `typography[variant]` pattern.
  static const Map<String, AppTypeSpec> byVariant = {
    'display1': display1,
    'display2': display2,
    'h1': h1,
    'h2': h2,
    'h3': h3,
    'h4': h4,
    'h5': h5,
    'bodyLarge': bodyLarge,
    'bodyBase': bodyBase,
    'bodySmall': bodySmall,
    'caption': caption,
  };
}
