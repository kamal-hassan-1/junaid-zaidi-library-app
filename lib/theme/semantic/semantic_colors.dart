import 'package:flutter/widgets.dart';

/// A background/foreground pair used by toast-style intent colors.
class ColorPair {
  final Color bg;
  final Color fg;
  const ColorPair({required this.bg, required this.fg});
}

/// "light" (subtle) and "filled" (solid) treatments for one semantic intent.
class IntentColors {
  final ColorPair light;
  final ColorPair filled;
  const IntentColors({required this.light, required this.filled});
}

class IntentPalette {
  final IntentColors info;
  final IntentColors warning;
  final IntentColors success;
  final IntentColors error;
  const IntentPalette({
    required this.info,
    required this.warning,
    required this.success,
    required this.error,
  });
}

class BackgroundTiers {
  final Color primary;
  final Color secondary;
  final Color tertiary;
  const BackgroundTiers({required this.primary, required this.secondary, required this.tertiary});
}

class TextTiers {
  final Color primary;
  final Color secondary;
  final Color tertiary;
  final Color onBrand;
  const TextTiers({
    required this.primary,
    required this.secondary,
    required this.tertiary,
    required this.onBrand,
  });
}

class SnackbarColors {
  final Color background;
  final Color primaryText;
  final Color secondaryText;
  final Color actionText;
  const SnackbarColors({
    required this.background,
    required this.primaryText,
    required this.secondaryText,
    required this.actionText,
  });
}

/// Full semantic color mapping for one theme mode (light or dark).
///
/// Key rule: brand and status colors (brand, error, success, warning) never
/// change between light/dark — only the gray-based structural colors invert.
class SemanticColors {
  final String mode; // "light" | "dark"
  final BackgroundTiers background;
  final Color border;
  final Color icon;
  final TextTiers text;
  final Color brand;
  final Color brandPressed;
  final Color error;
  final Color success;
  final Color warning;
  final IntentPalette intents;
  final SnackbarColors snackbar;

  const SemanticColors({
    required this.mode,
    required this.background,
    required this.border,
    required this.icon,
    required this.text,
    required this.brand,
    required this.brandPressed,
    required this.error,
    required this.success,
    required this.warning,
    required this.intents,
    required this.snackbar,
  });

  bool get isDark => mode == 'dark';
}
