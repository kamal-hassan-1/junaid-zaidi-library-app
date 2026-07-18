import 'package:flutter/widgets.dart';

import 'semantic/semantic_colors.dart';

/// Decorative (not semantic) accent resolution — used by ResourceCard,
/// ListRow, etc. to tint icon chips. `accent` names one of the theme's four
/// non-gray hues purely as a visual categorization device (like iOS
/// Settings' colored icon squares) — it does not signal status.
enum AppAccent { brand, success, warning, error }

Color resolveAccent(SemanticColors colors, AppAccent? accent) {
  switch (accent) {
    case AppAccent.success:
      return colors.success;
    case AppAccent.warning:
      return colors.warning;
    case AppAccent.error:
      return colors.error;
    case AppAccent.brand:
    case null:
      return colors.brand;
  }
}

/// Applies alpha to a color, mirroring the JS withOpacity(hex, alphaHex)
/// helper (e.g. "1F" ~= 12% opacity).
Color withOpacity(Color color, double opacity) {
  return color.withValues(alpha: opacity);
}
